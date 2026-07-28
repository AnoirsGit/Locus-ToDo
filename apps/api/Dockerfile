# ─── Stage 1: install + build ─────────────────────────────────────────────────
FROM node:22-alpine AS builder
RUN corepack enable

WORKDIR /repo

# Copy workspace manifests first (better layer caching)
COPY package.json pnpm-lock.yaml pnpm-workspace.yaml .npmrc ./
COPY packages/shared/package.json ./packages/shared/
COPY apps/api/package.json ./apps/api/

# Install all deps (needed for workspace resolution)
RUN pnpm install --frozen-lockfile

# Copy source
COPY packages/shared ./packages/shared
COPY apps/api ./apps/api

# Compile TypeScript
RUN pnpm --filter @locus/api build

# ─── Stage 2: prune to production deps ────────────────────────────────────────
FROM node:22-alpine AS deployer
RUN corepack enable

WORKDIR /repo
COPY --from=builder /repo ./

# pnpm deploy creates a self-contained dir with only prod node_modules
RUN pnpm deploy --filter=@locus/api --prod /prod/api

# ─── Stage 3: lean runtime image ──────────────────────────────────────────────
FROM node:22-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=deployer /prod/api ./

EXPOSE 3000
CMD ["node", "dist/server.js"]
