#!/usr/bin/env bash
set -euo pipefail
DB_URL="${1:?Provide DB connection URL}"
echo "Running EXPAND migrations..."
for f in $(ls db/migrations/expand/*.sql 2>/dev/null); do
  echo "Applying $f"
  psql "$DB_URL" -v ON_ERROR_STOP=1 -f "$f"
done
echo "Done."
