FROM node:20-alpine AS base
WORKDIR /app
RUN apk add --no-cache curl
COPY package.json package-lock.json* ./
RUN if [ -f package-lock.json ]; then npm ci --omit=dev; else npm install --omit=dev; fi
COPY . .

FROM node:20-alpine
WORKDIR /app
RUN apk add --no-cache curl
COPY --from=base /app /app
ENV NODE_ENV=production
ENV PORT=3001
EXPOSE 3001
HEALTHCHECK --interval=20s --timeout=3s --start-period=5s --retries=3 \
  CMD curl -fsS http://localhost:3001/health || exit 1
USER node
CMD ["npm","start"]
