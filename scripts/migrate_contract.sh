#!/usr/bin/env bash
set -euo pipefail
DB_URL="${1:?Provide DB connection URL}"
echo "Guarding contract migrations..."
node scripts/contract-migration-guard.js || { echo "Guard failed"; exit 1; }
echo "Running CONTRACT migrations..."
for f in $(ls db/migrations/contract/*.sql 2>/dev/null); do
  echo "Applying $f"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$f"
done
echo "Done."
