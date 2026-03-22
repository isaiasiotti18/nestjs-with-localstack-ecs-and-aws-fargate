# ============================================
# Stage 1: Install deps + build
# ============================================
FROM oven/bun:1.1 AS builder

WORKDIR /app

COPY package.json bun.lockb* ./
RUN bun install --frozen-lockfile || bun install

COPY tsconfig.json tsconfig.build.json nest-cli.json ./
COPY src ./src

# NestJS CLI build (tsc under the hood)
RUN bun run build

# ============================================
# Stage 2: Production image
# ============================================
FROM oven/bun:1.1-slim AS production

WORKDIR /app

ENV NODE_ENV=production

COPY package.json bun.lockb* ./
RUN bun install --production --frozen-lockfile || bun install --production

COPY --from=builder /app/dist ./dist

EXPOSE 3000

HEALTHCHECK --interval=15s --timeout=5s --start-period=10s --retries=3 \
  CMD bun -e "fetch('http://localhost:3000/health/live').then(r => r.ok ? process.exit(0) : process.exit(1)).catch(() => process.exit(1))"

CMD ["bun", "run", "dist/main.js"]
