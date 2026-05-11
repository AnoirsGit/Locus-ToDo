# Deployment Guide

## Overview

The app deploys as four Docker containers behind Nginx on a single VPS:

```
Internet
   │
   ▼
[Nginx :443]  ──  TLS termination, reverse proxy
   ├── /api/*  →  [API :3000]   Fastify + Node.js
   └── /*      →  [Web :3000]   SvelteKit + Node.js
                       │
              [Postgres :5432]
              [Redis    :6379]
```

CI/CD is handled by GitHub Actions:
- **Push to any branch** → typecheck + build (CI)
- **Push to `main`** → build Docker images → push to GHCR → SSH deploy to VPS

---

## What was set up

### Dockerfiles

**`apps/api/Dockerfile`** — 3-stage build:
1. `builder` — installs all deps, compiles TypeScript (`tsc` → `dist/`)
2. `deployer` — runs `pnpm deploy --prod` to extract only production node_modules
3. `runner` — lean `node:22-alpine` image with just `dist/` + prod deps (~150MB)

**`apps/web/Dockerfile`** — same pattern:
1. `builder` — installs deps, runs `vite build` (output: `build/`)
2. `deployer` — `pnpm deploy --prod`
3. `runner` — `node build` serves the SvelteKit app

> **Why adapter-node?** `svelte.config.js` was switched from `adapter-auto` to `adapter-node`.
> `adapter-auto` is designed for managed platforms (Vercel, Netlify, Cloudflare).
> On a plain VPS Docker container it produces an unreliable output.
> `adapter-node` gives a deterministic `build/index.js` that runs as a standard Node.js server.

### docker-compose.prod.yml

Production compose file with all five services:

| Service  | Image                        | Role |
|----------|------------------------------|------|
| postgres | `postgres:16-alpine`         | Database (data persisted in Docker volume) |
| redis    | `redis:7-alpine`             | Session / scheduler state |
| api      | `ghcr.io/.../locus-api`      | Fastify API |
| web      | `ghcr.io/.../locus-web`      | SvelteKit frontend |
| nginx    | `nginx:alpine`               | TLS termination + reverse proxy |

Startup order is enforced via `depends_on` + healthchecks — API waits for Postgres to be ready before accepting traffic.

### docker/nginx/nginx.conf

- Port 80 → 301 redirect to HTTPS (except `/.well-known/` for Let's Encrypt)
- Port 443 → TLS with your certificates
- `/api/*` → proxied to `api:3000` with a rate limit (30 req/s, burst 60)
- `/*` → proxied to `web:3000` with WebSocket upgrade headers
- Gzip enabled for JS/CSS/JSON

### .github/workflows/ci.yml

Runs on every push and PR to `main`:
1. `pnpm typecheck` — TypeScript across all packages
2. `pnpm --filter @locus/api build` — API compiles without errors
3. `pnpm --filter @locus/web build` — Web builds without errors

### .github/workflows/deploy.yml

Runs only on push to `main`, after CI passes:
1. Logs into GHCR with `GITHUB_TOKEN` (no extra secret needed)
2. Builds API image → pushes as `locus-api:latest` + `locus-api:<sha>`
3. Builds Web image → pushes as `locus-web:latest` + `locus-web:<sha>`
4. Docker layer cache stored in GitHub Actions cache (speeds up rebuilds ~3×)
5. SSHes into VPS:
   - Writes `.env` from the `PROD_ENV` secret
   - `docker compose pull` — downloads new images
   - Runs DB migrations
   - `docker compose up -d --remove-orphans` — rolling restart
   - `docker image prune -f` — removes old image layers

---

## First deploy (one-time VPS setup)

### 1. Provision the VPS

Recommended minimum: **2 vCPU / 2 GB RAM / 20 GB SSD** (Ubuntu 24.04).

```bash
# Install Docker
curl -fsSL https://get.docker.com | sh
usermod -aG docker $USER

# Create deploy directory
mkdir -p /opt/locus/docker/nginx/certs
```

### 2. Copy files to VPS

```bash
# From your local machine
scp docker-compose.prod.yml user@your-vps:/opt/locus/
scp docker/nginx/nginx.conf user@your-vps:/opt/locus/docker/nginx/
```

### 3. Get TLS certificates (Let's Encrypt)

Point your domain's DNS A record to the VPS IP first, then:

```bash
# On the VPS
apt install certbot
certbot certonly --standalone -d your-domain.com

# Copy certs to the expected location
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/locus/docker/nginx/certs/
cp /etc/letsencrypt/live/your-domain.com/privkey.pem   /opt/locus/docker/nginx/certs/

# Auto-renew hook (runs after each renewal)
cat >> /etc/letsencrypt/renewal-hooks/deploy/locus.sh << 'EOF'
#!/bin/sh
cp /etc/letsencrypt/live/your-domain.com/fullchain.pem /opt/locus/docker/nginx/certs/
cp /etc/letsencrypt/live/your-domain.com/privkey.pem   /opt/locus/docker/nginx/certs/
docker exec locus-nginx nginx -s reload
EOF
chmod +x /etc/letsencrypt/renewal-hooks/deploy/locus.sh
```

### 4. Create the production .env on VPS

```bash
# /opt/locus/.env
nano /opt/locus/.env
```

Fill in (see `.env.example` for all keys):

```env
DB_USER=postgres
DB_PASSWORD=<strong random password>
DB_NAME=locus_todo
DATABASE_URL=postgres://postgres:<password>@postgres:5432/locus_todo

REDIS_URL=redis://redis:6379

JWT_SECRET=<64 char random string>

PORT=3000
HOST=0.0.0.0
NODE_ENV=production

CORS_ORIGIN=https://your-domain.com
ORIGIN=https://your-domain.com
PUBLIC_API_URL=https://your-domain.com

DOMAIN=your-domain.com
GITHUB_REPOSITORY=your-github-username/locus-todo
IMAGE_TAG=latest
```

### 5. Add GitHub Actions secrets

Go to **GitHub repo → Settings → Secrets and variables → Actions → New repository secret**:

| Secret | Value |
|--------|-------|
| `VPS_HOST` | Your VPS public IP |
| `VPS_USER` | SSH user (e.g. `ubuntu`, `root`) |
| `VPS_SSH_KEY` | Contents of `~/.ssh/id_rsa` (private key) |
| `PROD_ENV` | Full contents of `/opt/locus/.env` |
| `PUBLIC_API_URL` | `https://your-domain.com` |

To generate an SSH key pair for deploy:
```bash
ssh-keygen -t ed25519 -C "github-actions-deploy" -f ~/.ssh/locus_deploy
# Add public key to VPS
cat ~/.ssh/locus_deploy.pub >> ~/.ssh/authorized_keys
# Paste private key content into VPS_SSH_KEY secret
cat ~/.ssh/locus_deploy
```

### 6. Run the first deploy

```bash
# Local — update lockfile after adapter change
pnpm install

# Commit and push to main — GitHub Actions handles the rest
git add -A
git commit -m "chore: add docker ci/cd"
git push origin main
```

Watch the deploy at: **GitHub repo → Actions**

---

## Day-to-day workflow

```
code → commit → push to main
                    │
                    ▼
              GitHub Actions
              ┌─────────────┐
              │ CI (2 min)  │  typecheck + build
              └──────┬──────┘
                     │ passes
              ┌──────▼──────┐
              │ Deploy      │  build images → push → SSH restart
              └─────────────┘
                    │
                    ▼
                VPS updated  (~3-5 min total)
```

Zero-downtime: `docker compose up -d` replaces containers one by one, old container keeps serving until the new one is healthy.

---

## DB migrations on deploy

Migrations run automatically before the API restarts (in the deploy workflow).
The migration script is idempotent — safe to run multiple times.

To run manually on VPS:
```bash
cd /opt/locus
docker compose -f docker-compose.prod.yml run --rm api node dist/db/migrate.js
```

---

## Monitoring & logs

```bash
# All services
docker compose -f docker-compose.prod.yml logs -f

# Specific service
docker compose -f docker-compose.prod.yml logs -f api
docker compose -f docker-compose.prod.yml logs -f nginx

# Health check
curl https://your-domain.com/health
# → {"status":"ok","timestamp":"..."}
```

---

## Rollback

Each deploy tags images with the Git SHA. To rollback:

```bash
cd /opt/locus
# Replace <previous-sha> with the commit hash you want
IMAGE_TAG=<previous-sha> \
GITHUB_REPOSITORY=your-github-username/locus-todo \
docker compose -f docker-compose.prod.yml up -d api web
```

---

## Checklist before first push

- [ ] VPS provisioned, Docker installed
- [ ] Domain DNS A record → VPS IP
- [ ] TLS certs obtained and placed in `docker/nginx/certs/`
- [ ] `/opt/locus/.env` created with production values
- [ ] All 5 GitHub Actions secrets added
- [ ] `pnpm install` run locally (lockfile updated for adapter-node)
- [ ] `nginx.conf` — replace `${DOMAIN}` placeholder with your actual domain
