#!/usr/bin/env bash
set -euo pipefail

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
