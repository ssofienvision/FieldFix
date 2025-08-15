#!/usr/bin/env bash
set -euo pipefail
set -x
trap 'ec=$?; echo "[deploy] failed at line $LINENO with exit $ec"; exit $ec' ERR

# Ensure pnpm
bash scripts/pnpm_ensure.sh

ENV_SUFFIX="${1:-staging}"        # e.g., 'staging', 'prod', 'pr-123'
DEPLOY_MODE="${2:-staging}"       # 'preview' | 'staging' | 'prod-canary' | 'prod'

# Require token (but fail with a clear message)
if [[ -z "${FLY_API_TOKEN:-}" ]]; then
  echo "[deploy] ERROR: FLY_API_TOKEN is not set for this job. Add repo secret FLY_API_TOKEN."
  exit 2
fi

# Determine changed services (empty -> nothing to do)
CHANGED="$(bash scripts/changed_services.sh "${GITHUB_BASE_REF:-}")" || true
if [[ -z "$CHANGED" ]]; then
  echo "[deploy] No changed services — nothing to deploy. Exiting 0."
  exit 0
fi
echo "[deploy] Will deploy these services:"
echo "$CHANGED"

# Install flyctl if missing
if ! command -v fly >/dev/null 2>&1; then
  curl -L https://fly.io/install.sh | sh
  export FLYCTL_INSTALL="$HOME/.fly"
  export PATH="$FLYCTL_INSTALL/bin:$PATH"
fi

: "${FLY_REGION:=iad}"
: "${FLY_ORG:=}"

ensure_app() {
  local app_name="$1"
  # use token explicitly so fly never prompts
  if ! fly --access-token "$FLY_API_TOKEN" status --app "$app_name" >/dev/null 2>&1; then
    if [[ -n "$FLY_ORG" ]]; then
      fly --access-token "$FLY_API_TOKEN" apps create "$app_name" --org "$FLY_ORG" --region "$FLY_REGION"
    else
      fly --access-token "$FLY_API_TOKEN" apps create "$app_name" --region "$FLY_REGION"
    fi
  fi
}

while read -r SVC; do
  [[ -z "$SVC" ]] && continue
  SERVICE_DIR="apps/$SVC"
  [[ -d "$SERVICE_DIR" ]] || { echo "[deploy] skip $SVC (no apps/$SVC)"; continue; }

  # Must have a Dockerfile to build
  if [[ ! -f "$SERVICE_DIR/Dockerfile" ]]; then
    echo "[deploy] skip $SVC (no Dockerfile)"
    continue
  fi

  APP_NAME="${SVC}-${ENV_SUFFIX}"
  CFG="$SERVICE_DIR/fly.toml"

  # Create or normalize fly.toml
  if [[ ! -f "$CFG" ]]; then
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
    sed -i "s/^app = \".*\"/app = \"${APP_NAME}\"/" "$CFG"
  fi

  ensure_app "$APP_NAME"

  if [[ "$DEPLOY_MODE" == "prod-canary" ]]; then
    fly --access-token "$FLY_API_TOKEN" deploy --config "$CFG" --strategy canary --auto-confirm
  else
    fly --access-token "$FLY_API_TOKEN" deploy --config "$CFG" --strategy immediate --auto-confirm
  fi
done <<< "$CHANGED"

echo "[deploy] Done."
