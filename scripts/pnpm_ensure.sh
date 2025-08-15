#!/usr/bin/env bash
set -euo pipefail

echo "[pnpm_ensure] node: $(node -v || echo 'not found')"
echo "[pnpm_ensure] npm:  $(npm -v || echo 'not found')"
echo "[pnpm_ensure] PATH: $PATH"

if command -v pnpm >/dev/null 2>&1; then
  echo "[pnpm_ensure] pnpm already on PATH: $(pnpm -v)"
  exit 0
fi

# --- Try Corepack first (preferred on GitHub runners) ---
if command -v corepack >/dev/null 2>&1; then
  echo "[pnpm_ensure] enabling corepack + preparing pnpm@9..."
  corepack enable || true
  corepack prepare pnpm@9 --activate || true
fi

if command -v pnpm >/dev/null 2>&1; then
  echo "[pnpm_ensure] pnpm available after corepack: $(pnpm -v)"
  exit 0
fi

# --- Fallback to npm global install ---
echo "[pnpm_ensure] corepack failed or missing; installing pnpm@9 via npm -g..."
npm install -g pnpm@9

# Some images require adding npm global bin to PATH explicitly
NPM_BIN="$(npm bin -g 2>/dev/null || true)"
if [ -n "${NPM_BIN}" ] && ! echo "$PATH" | grep -q "${NPM_BIN}"; then
  export PATH="${NPM_BIN}:$PATH"
  echo "[pnpm_ensure] added npm global bin to PATH: ${NPM_BIN}"
fi

if ! command -v pnpm >/dev/null 2>&1; then
  echo "[pnpm_ensure] ERROR: pnpm still not found after install. PATH=$PATH"
  exit 1
fi

echo "[pnpm_ensure] pnpm ready: $(pnpm -v)"
