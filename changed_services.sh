#!/usr/bin/env bash
set -euo pipefail

BASE_REF="${1:-main}"
# List of macro-services
SERVICES=(identity-access customer-property assets-warranty work-management technicians-dispatch inventory-parts billing-payments communications-audit)

# Find changed paths vs base ref
git fetch --depth=1000 origin +refs/heads/$BASE_REF:refs/remotes/origin/$BASE_REF >/dev/null 2>&1 || true
CHANGED_FILES=$(git diff --name-only origin/$BASE_REF...HEAD)

CHANGED_SERVICES=()
for SVC in "${SERVICES[@]}"; do
  if echo "$CHANGED_FILES" | grep -q "^apps/$SVC/"; then
    CHANGED_SERVICES+=("$SVC")
  fi
done

# Always include gateway if contracts changed
if echo "$CHANGED_FILES" | grep -q "^apps/api-gateway/"; then
  CHANGED_SERVICES+=("api-gateway")
fi

# Fallback: if nothing detected, deploy gateway only
if [ ${#CHANGED_SERVICES[@]} -eq 0 ]; then
  echo "api-gateway"
else
  printf "%s\n" "${CHANGED_SERVICES[@]}" | sort -u
fi
