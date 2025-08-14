#!/usr/bin/env bash
set -euo pipefail

# If pnpm is already available, print version and exit
if command -v pnpm >/dev/null 2>&1; then
  echo "[pnpm_ensure] pnpm on PATH: $(pnpm -v)"
  exit 0
fi

echo "[pnpm_ensure] pnpm not found on PATH; installing via npm..."
# Node should already be in the runner; install pnpm globally
npm install -g pnpm@9

# Re-check
if ! command -v pnpm >/dev/null 2>&1; then
  echo "[pnpm_ensure] ERROR: pnpm installation failed"; exit 1
fi

echo "[pnpm_ensure] Installed pnpm: $(pnpm -v)"
