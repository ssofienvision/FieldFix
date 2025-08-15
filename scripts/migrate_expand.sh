#!/usr/bin/env bash
set -euo pipefail

DB_URL="${1:-}"
if [[ -z "$DB_URL" ]]; then
  echo "[migrate_expand] DB_URL missing — skipping migrations (non-blocking)."
  exit 0
fi

echo "Running EXPAND migrations..."
for f in $(ls db/migrations/expand/*.sql 2>/dev/null | sort); do
  echo "Applying $f"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$f"
done
echo "Done."
