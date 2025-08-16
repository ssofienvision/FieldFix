FROM node:20-alpine

# Make pnpm available inside the container (works on GH runners & locally)
RUN corepack enable && corepack prepare pnpm@9.0.0 --activate || true

WORKDIR /app
# Copy minimal files first for better layer caching
COPY package.json ./
RUN (pnpm install --prod) || (npm i --omit=dev)

# Copy the rest of the app
COPY . .

ENV PORT=3000
EXPOSE 3000
CMD ["node","server.js"]
