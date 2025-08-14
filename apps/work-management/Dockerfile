FROM node:20-alpine
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate
WORKDIR /app
COPY package.json package-lock.json* ./
RUN npm ci --omit=dev || npm i --omit=dev
COPY server.js ./
ENV PORT=3000
EXPOSE 3000
CMD ["node", "server.js"]
