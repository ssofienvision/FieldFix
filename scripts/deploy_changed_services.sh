#!/usr/bin/env bash
set -euo pipefail

# --- Ensure pnpm exists (self-heal) ---
bash scripts/pnpm_ensure.sh

ENV_SUFFIX="${1:-staging}"        # e.g., 'staging', 'prod', 'pr-123'
DEPLOY_MODE="${2:-staging}"       # 'preview' | 'staging' | 'prod-canary' | 'prod'
CHANGED=$(bash scripts/changed_services.sh "${GITHUB_BASE_REF:-main}")

echo "Deploying services to ${DEPLOY_MODE} with suffix ${ENV_SUFFIX}:"
echo "$CHANGED"

# Optional config via env vars (set in repo Variables if desired)
: "${FLY_REGION:=iad}"            # default region
: "${FLY_ORG:=}"                  # optional org slug
: "${IMAGE_TAG:=${GITHUB_SHA:-latest}}"

# Install flyctl if missing
if ! command -v fly >/dev/null 2>&1; then
  echo "Installing flyctl..."
  curl -L https://fly.io/install.sh | sh
  export FLYCTL_INSTALL="$HOME/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
fi

# Helper: create app if missing
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
  SERVICE_DIR="apps/$SVC"
  [ -d "$SERVICE_DIR" ] || { echo "Skipping $SVC (no apps/$SVC dir)"; continue; }

  # Skip services with no Dockerfile to avoid hard failures
  if [ ! -f "$SERVICE_DIR/Dockerfile" ]; then
    echo "Skipping $SVC (no Dockerfile)"
    continue
  fi

  APP_NAME="${SVC}-${ENV_SUFFIX}"
  CFG="$SERVICE_DIR/fly.toml"

  # Generate a fly.toml if missing
  if [ ! -f "$CFG" ]; then
    echo "No fly.toml for $SVC; generating minimal config"
    cat > "$CFG" <<TOML
app = "${APP_NAME}"
primary_region = "${FLY_REGION}"

[env]
  PORT = "3000"

[[services]]
  internal_port = 3000
  protocol = "tcp"

  [[services.ports]]
    port = 80
    handlers = ["http"]
TOML
  else
    # ensure app name matches this env suffix
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
