#!/usr/bin/env bash
set -euo pipefail

ENV_SUFFIX="${1:-staging}"        # e.g., 'staging', 'prod'
DEPLOY_MODE="${2:-staging}"       # 'preview' | 'staging' | 'prod-canary' | 'prod'
CHANGED=$(bash scripts/changed_services.sh "${GITHUB_BASE_REF:-main}")

echo "Deploying services to ${DEPLOY_MODE} with suffix ${ENV_SUFFIX}:"
echo "$CHANGED"

# --- Config via env (optional) ---
: "${FLY_REGION:=iad}"            # Default primary region
: "${FLY_ORG:=}"                  # Optional: your Fly org slug (set in repo Secrets/Vars)
: "${IMAGE_TAG:=${GITHUB_SHA:-latest}}"

# Install flyctl
if ! command -v fly >/dev/null 2>&1; then
  echo "Installing flyctl..."
  curl -L https://fly.io/install.sh | sh
  export FLYCTL_INSTALL="$HOME/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
fi

# Helper: create app if not exists
ensure_app() {
  local app_name="$1"

  set +e
  fly status --app "$app_name" >/dev/null 2>&1
  local exists=$?
  set -e

  if [ "$exists" -ne 0 ]; then
    echo "App $app_name not found. Creating..."
    if [ -n "$FLY_ORG" ]; then
      fly apps create "$app_name" --org "$FLY_ORG" --region "$FLY_REGION"
    else
      fly apps create "$app_name" --region "$FLY_REGION"
    fi
  else
    echo "App $app_name exists."
  fi
}

while read -r SVC; do
  [ -z "$SVC" ] && continue
  APP_NAME="${SVC}-${ENV_SUFFIX}"
  CFG="apps/$SVC/fly.toml"

  # Generate a fly.toml if missing
  if [ ! -f "$CFG" ]; then
    echo "No fly.toml for $SVC; generating from template"
    mkdir -p "apps/$SVC"
    cp templates/fly.toml "$CFG"
    sed -i "s/__APP_NAME__/${APP_NAME}/g" "$CFG"
    # Optional: stamp service name into image line if you use template image
    sed -i "s/__SERVICE__/${SVC}/g" "$CFG"
  else
    # Make sure the app name matches the environment
    sed -i "s/^app = \".*\"/app = \"${APP_NAME}\"/" "$CFG"
  fi

  # Ensure the Fly app exists (non-interactive)
  ensure_app "$APP_NAME"

  echo "Deploying $APP_NAME ..."
  if [ "$DEPLOY_MODE" = "prod-canary" ]; then
    fly deploy --config "$CFG" --strategy canary --auto-confirm
  else
    fly deploy --config "$CFG" --strategy immediate --auto-confirm
  fi

done <<< "$CHANGED"
