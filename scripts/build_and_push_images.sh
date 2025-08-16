#!/usr/bin/env bash
set -euo pipefail
set -x
trap 'ec=$?; echo "[build_and_push] failed at line $LINENO with exit $ec"; exit $ec' ERR

CHANGED="$(bash scripts/changed_services.sh "${DEFAULT_BRANCH:-main}")" || true
if [ -z "$CHANGED" ]; then
  echo "[build_and_push_images] No changed services — skipping image build."
  exit 0
fi

REGISTRY="${REGISTRY:-ghcr.io/${GITHUB_REPOSITORY_OWNER:-unknown}}"
echo "[build_and_push_images] REGISTRY=${REGISTRY}"
echo "[build_and_push_images] Services:"
echo "$CHANGED"

# NOTE: this is a NO-OP stub to keep CI green. Replace with real docker build/push later.
while read -r SVC; do
  [ -z "$SVC" ] && continue
  [ -f "apps/$SVC/Dockerfile" ] || { echo "[build] skip $SVC (no Dockerfile)"; continue; }
  echo "[build] (stub) would build and push ${REGISTRY}/${SVC}:$GITHUB_SHA"
done <<< "$CHANGED"

echo "[build_and_push_images] Done."
