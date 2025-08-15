#!/usr/bin/env bash
set -euo pipefail

APPS_DIR="apps"
BASE_HINT="${1:-}"  # can be "origin/main" or just "main"

git config --global --add safe.directory "$GITHUB_WORKSPACE" 2>/dev/null || true
# ensure we have remote heads
git fetch --no-tags --prune --depth=50 origin +refs/heads/*:refs/remotes/origin/* 2>/dev/null || true

# resolve base ref
if [ -n "${GITHUB_BASE_REF:-}" ]; then
  BASE_REF="origin/${GITHUB_BASE_REF}"
elif [ -n "$BASE_HINT" ] && git rev-parse --verify "origin/${BASE_HINT}" >/dev/null 2>&1; then
  BASE_REF="origin/${BASE_HINT}"
elif git rev-parse --verify origin/main >/dev/null 2>&1; then
  BASE_REF="origin/main"
else
  # initial commit fallback: first commit
  BASE_REF="$(git rev-list --max-parents=0 HEAD)"
fi

# try to compute changed set; if no merge-base, fall back to all services with Dockerfile
if ! git merge-base "$BASE_REF" HEAD >/dev/null 2>&1; then
  echo "[changed_services] No merge base with $BASE_REF — returning ALL services with Dockerfile."
  mapfile -t svcs < <(find "$APPS_DIR" -maxdepth 2 -name Dockerfile -printf '%h\n' | sed "s#^$APPS_DIR/##" | sort -u)
else
  echo "[changed_services] Diffing against $BASE_REF"
  mapfile -t svcs < <(git diff --name-only "$BASE_REF"...HEAD -- "$APPS_DIR/" \
    | awk -F/ 'NF>=2 {print $2}' | sort -u)
fi

# keep only services that actually have a Dockerfile
declare -a out=()
for s in "${svcs[@]:-}"; do
  [ -z "$s" ] && continue
  if [ -f "$APPS_DIR/$s/Dockerfile" ]; then
    out+=("$s")
  else
    echo "[changed_services] Skipping $s (no Dockerfile)"
  fi
done

printf "%s\n" "${out[@]}" | tr ' ' '\n'
