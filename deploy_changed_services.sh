#!/usr/bin/env bash
set -euo pipefail
ENV_SUFFIX="${1:-staging}"
DEPLOY_MODE="${2:-staging}" # preview | staging | prod-canary | prod

CHANGED=$(bash scripts/changed_services.sh "${GITHUB_BASE_REF:-main}")
echo "Deploying services to ${DEPLOY_MODE} with suffix ${ENV_SUFFIX}:"
echo "$CHANGED"

# Install flyctl
curl -L https://fly.io/install.sh | sh
export FLYCTL_INSTALL="$HOME/.fly"
export PATH="$FLYCTL_INSTALL/bin:$PATH"

while read -r SVC; do
  [ -z "$SVC" ] && continue
  APP_NAME="${SVC}-${ENV_SUFFIX}"
  CFG="apps/$SVC/fly.toml"
  if [ ! -f "$CFG" ]; then
    echo "No fly.toml for $SVC; generating from template"
    mkdir -p "apps/$SVC"
    cp templates/fly.toml "apps/$SVC/fly.toml"
    sed -i "s/__APP_NAME__/${APP_NAME}/g" "apps/$SVC/fly.toml"
  fi

  echo "Deploying $APP_NAME ..."
  if [ "$DEPLOY_MODE" = "prod-canary" ]; then
    fly deploy --config "apps/$SVC/fly.toml" --strategy canary --auto-confirm || exit 1
  else
    fly deploy --config "apps/$SVC/fly.toml" --strategy immediate --auto-confirm || exit 1
  fi
done <<< "$CHANGED"
