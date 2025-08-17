FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache curl

# Copy only manifests first for better cache
COPY package.json package-lock.json* ./

# Install deps (use lockfile if present; otherwise normal install)
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi

# Copy source
COPY . .

# --- runtime stage ---
FROM node:20-alpine
WORKDIR /app
RUN apk add --no-cache curl
# copy node_modules and app
COPY --from=base /app /app

ENV NODE_ENV=production
ENV PORT=3000
EXPOSE 3000

HEALTHCHECK --interval=20s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost:3000/health || exit 1

USER node
CMD ["npm","start"]
