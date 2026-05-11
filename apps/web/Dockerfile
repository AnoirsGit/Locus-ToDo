# ─── Stage 1: install + build ─────────────────────────────────────────────────
FROM node:22-alpine AS builder
RUN corepack enable

WORKDIR /repo

COPY package.json pnpm-lock.yaml pnpm-workspace.yaml ./
COPY packages/shared/package.json ./packages/shared/
COPY apps/web/package.json ./apps/web/

RUN pnpm install --frozen-lockfile

COPY packages/shared ./packages/shared
COPY apps/web ./apps/web

# PUBLIC_API_URL is baked in at build time; pass via --build-arg
ARG PUBLIC_API_URL=https://api.example.com
ENV PUBLIC_API_URL=$PUBLIC_API_URL

RUN pnpm --filter @locus/web build

# ─── Stage 2: prune to production deps ────────────────────────────────────────
FROM node:22-alpine AS deployer
RUN corepack enable

WORKDIR /repo
COPY --from=builder /repo ./
RUN pnpm deploy --filter=@locus/web --prod /prod/web

# ─── Stage 3: lean runtime image ──────────────────────────────────────────────
FROM node:22-alpine AS runner

WORKDIR /app
ENV NODE_ENV=production

COPY --from=deployer /prod/web ./
# SvelteKit adapter-node output lives in build/
COPY --from=builder /repo/apps/web/build ./build

EXPOSE 3000
CMD ["node", "build"]
