#!/usr/bin/env bash
set -euo pipefail

ROOT="${GITHUB_WORKSPACE:-$(pwd)}"
cd "$ROOT"

echo "[bootstrap] Starting service scaffolding..."

# 0) Root workspace files (safe if they already exist)
if [ ! -f pnpm-workspace.yaml ]; then
  cat > pnpm-workspace.yaml <<'YAML'
packages:
  - apps/*
YAML
  echo "[bootstrap] created pnpm-workspace.yaml"
fi

if [ ! -f package.json ]; then
  cat > package.json <<'JSON'
{
  "name": "fieldfix-monorepo",
  "private": true,
  "packageManager": "pnpm@9",
  "scripts": {
    "lint": "echo \"(todo)\"",
    "typecheck": "echo \"(todo)\"",
    "test": "echo \"(todo)\""
  }
}
JSON
  echo "[bootstrap] created root package.json"
fi

# 1) Services to scaffold (work-management already exists; we'll skip if present)
services=(
  "work-management"
  "identity-access"
  "customer-property"
  "assets-warranty"
  "technicians-dispatch"
  "inventory-parts"
  "billing-payments"
  "communications-audit"
)

mkdir -p apps

for svc in "${services[@]}"; do
  svc_dir="apps/${svc}"
  mkdir -p "$svc_dir"

  # Dockerfile
  if [ ! -f "${svc_dir}/Dockerfile" ]; then
    cat > "${svc_dir}/Dockerfile" <<'DOCKER'
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
DOCKER
    echo "[bootstrap] ${svc}: created Dockerfile"
  else
    echo "[bootstrap] ${svc}: Dockerfile exists, skipping"
  fi

  # package.json
  if [ ! -f "${svc_dir}/package.json" ]; then
    cat > "${svc_dir}/package.json" <<JSON
{
  "name": "${svc}",
  "version": "0.1.0",
  "private": true,
  "type": "module",
  "scripts": {
    "start": "node server.js"
  }
}
JSON
    echo "[bootstrap] ${svc}: created package.json"
  else
    echo "[bootstrap] ${svc}: package.json exists, skipping"
  fi

  # server.js
  if [ ! -f "${svc_dir}/server.js" ]; then
    cat > "${svc_dir}/server.js" <<JS
import http from "http";
const PORT = process.env.PORT || 3000;
http
  .createServer((req, res) => {
    if (req.url === "/health") {
      res.writeHead(200, { "content-type": "application/json" });
      return res.end(JSON.stringify({ status: "ok", service: "${svc}" }));
    }
    res.writeHead(200, { "content-type": "text/plain" });
    res.end("${svc} service is running\\n");
  })
  .listen(PORT, () => console.log("${svc} listening on", PORT));
JS
    echo "[bootstrap] ${svc}: created server.js"
  else
    echo "[bootstrap] ${svc}: server.js exists, skipping"
  fi

  # fly.toml (optional, helpful for Fly deploys; app name auto-updated by your deploy script)
  if [ ! -f "${svc_dir}/fly.toml" ]; then
    cat > "${svc_dir}/fly.toml" <<TOML
app = "${svc}-staging"
primary_region = "iad"

[env]
  PORT = "3000"

[[services]]
  internal_port = 3000
  protocol = "tcp"

  [[services.ports]]
    port = 80
    handlers = ["http"]

  [services.concurrency]
    type = "connections"
    hard_limit = 50
    soft_limit = 40

  [[services.http_checks]]
    interval = "10s"
    timeout = "2s"
    method = "get"
    path = "/health"
    protocol = "http"
    tls_skip_verify = false
TOML
    echo "[bootstrap] ${svc}: created fly.toml"
  else
    echo "[bootstrap] ${svc}: fly.toml exists, skipping"
  fi
done

echo "[bootstrap] All done ✅"
