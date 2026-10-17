FROM oven/bun:1.3.10

ARG TSCIRCUIT_REF=main
ENV NODE_ENV=development \
    HOST=0.0.0.0 \
    PORT=5173

WORKDIR /app

RUN apt-get update \
    && apt-get install --yes --no-install-recommends git ca-certificates \
    && rm -rf /var/lib/apt/lists/* \
    && git clone --depth 1 --branch "$TSCIRCUIT_REF" https://github.com/tscircuit/tscircuit.com.git . \
    && chown -R bun:bun /app

USER bun

RUN bun install --frozen-lockfile \
    && bun run build

EXPOSE 5173

HEALTHCHECK --interval=30s --timeout=5s --start-period=90s --retries=3 \
  CMD bun -e 'fetch("http://127.0.0.1:5173/").then(r => process.exit(r.ok ? 0 : 1)).catch(() => process.exit(1))'

CMD ["sh", "-c", "bun run build:fake-api && exec bunx vite --host 0.0.0.0 --port 5173"]
