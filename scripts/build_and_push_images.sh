#!/usr/bin/env bash
set -euo pipefail
CHANGED="$(bash scripts/changed_services.sh "${DEFAULT_BRANCH:-main}")"
if [ -z "$CHANGED" ]; then
  echo "[build_and_push_images] No changed services — skipping image build."
  exit 0
fi

REGISTRY="${REGISTRY:-ghcr.io/${GITHUB_REPOSITORY_OWNER}}"
OWNER="$(echo "${GITHUB_REPOSITORY}" | cut -d'/' -f1)"
REPO="$(echo "${GITHUB_REPOSITORY}" | cut -d'/' -f2)"
IMAGE_TAG="${GITHUB_SHA}"
CHANGED=$(bash scripts/changed_services.sh "${GITHUB_BASE_REF:-main}")
echo "Changed services:"
echo "$CHANGED"

echo "${{ secrets.GITHUB_TOKEN }}" | docker login ghcr.io -u "${OWNER}" --password-stdin || true

while read -r SVC; do
  [ -z "$SVC" ] && continue
  if [ -f "apps/$SVC/Dockerfile" ]; then
    IMAGE="$REGISTRY/$SVC:$IMAGE_TAG"
    echo "Building $IMAGE ..."
    docker build -t "$IMAGE" "apps/$SVC"
    echo "Pushing $IMAGE ..."
    docker push "$IMAGE"
  else
    echo "Skipping $SVC (no Dockerfile)"
  fi
done <<< "$CHANGED"
