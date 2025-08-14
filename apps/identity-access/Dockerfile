FROM node:20-alpine

# Enable pnpm inside the container; fallback to npm if needed
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate || true

WORKDIR /app
COPY package.json ./
RUN (pnpm install --prod) || (npm i --omit=dev)

COPY server.js ./

ENV PORT=3000
EXPOSE 3000
CMD ["node","server.js"]
