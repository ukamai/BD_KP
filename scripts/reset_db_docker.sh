#!/usr/bin/env bash
set -euo pipefail

source .env

run_sql () {
  local file="$1"
  echo "==> $file"
  test -f "$file" || { echo "File not found on host: $file"; exit 1; }
  docker compose exec -T db psql -v ON_ERROR_STOP=1 -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$file"
}

run_sql sql/ddl/01_schema.sql
run_sql sql/ddl/02_constraints.sql
run_sql sql/triggers/01_triggers.sql
run_sql sql/triggers/02_audit_triggers.sql
run_sql sql/views/01_views.sql
run_sql sql/indexes/01_indexes.sql
run_sql sql/dml/01_seed.sql

echo "==> OK"
