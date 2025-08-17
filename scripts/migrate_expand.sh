#!/usr/bin/env bash
set -euo pipefail

DB_SPEC="${1:-}"

echo "[migrate_expand] Running EXPAND migrations..."

if [[ -z "$DB_SPEC" ]]; then
  echo "[migrate_expand] STAGING_DB_URL missing — skipping migrations (non-blocking)."
  exit 0
fi

# Quick connectivity test with a clear error
if ! psql "$DB_SPEC" -Atc "select 'db_ok'"; then
  echo "[migrate_expand] ERROR: cannot connect using STAGING_DB_URL."
  echo "  -> If you used a URI, ensure it's like: postgresql://USER:PASSWORD@HOST:5432/postgres?sslmode=require"
  echo "  -> If PASSWORD contains @ : / ? # &, it must be URL-encoded (Supabase URI button does this)."
  echo "  -> Alternative: use keyword form: host=HOST port=5432 dbname=postgres user=USER password=PASS sslmode=require"
  exit 2
fi

shopt -s nullglob
for file in db/migrations/expand/*.sql; do
  echo "Applying $file"
  psql "$DB_SPEC" -v ON_ERROR_STOP=1 -f "$file"
done

echo "[migrate_expand] Done."
