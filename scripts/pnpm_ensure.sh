#!/usr/bin/env bash
set -euo pipefail

echo "[pnpm_ensure] node: $(node -v || echo 'not found')"
echo "[pnpm_ensure] npm:  $(npm -v || echo 'not found')"
echo "[pnpm_ensure] PATH: $PATH"

if command -v pnpm >/dev/null 2>&1; then
  echo "[pnpm_ensure] pnpm already on PATH: $(pnpm -v)"
  exit 0
fi

# Prefer corepack on GH runners
if command -v corepack >/dev/null 2>&1; then
  echo "[pnpm_ensure] enabling corepack + preparing pnpm@9..."
  corepack enable || true
  corepack prepare pnpm@9 --activate || true
fi

if command -v pnpm >/dev/null 2>&1; then
  echo "[pnpm_ensure] pnpm available after corepack: $(pnpm -v)"
  exit 0
fi

echo "[pnpm_ensure] installing pnpm@9 via npm -g..."
npm install -g pnpm@9

NPM_BIN="$(npm bin -g 2>/dev/null || true)"
if [ -n "${NPM_BIN}" ] && ! echo "$PATH" | grep -q "${NPM_BIN}"; then
  export PATH="${NPM_BIN}:$PATH"
  echo "[pnpm_ensure] added npm global bin to PATH: ${NPM_BIN}"
fi

command -v pnpm >/dev/null 2>&1 || { echo "[pnpm_ensure] ERROR: pnpm still not found"; exit 1; }
echo "[pnpm_ensure] pnpm ready: $(pnpm -v)"
