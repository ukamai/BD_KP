#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

if [[ -f ".env" ]]; then
  set -a
  # shellcheck disable=SC1091
  source ".env"
  set +a
else
  echo "ERROR: .env not found."
  echo "Create it from template:"
  echo "  cp .env.example .env"
  exit 1
fi

: "${POSTGRES_USER:?POSTGRES_USER is required in .env}"
: "${POSTGRES_DB:?POSTGRES_DB is required in .env}"

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

run_sql sql/ddl/03_import_schema.sql
run_sql sql/functions/01_functions.sql
run_sql sql/procedures/01_batch_import.sql

run_sql sql/views/01_views.sql
run_sql sql/indexes/01_indexes.sql

run_sql sql/dml/01_seed.sql

if [[ "${GENERATE_BIG_DATA:-0}" == "1" ]]; then
  run_sql sql/dml/02_generate_big_data.sql
fi

run_sql sql/triggers/03_audit_crud.sql

if [[ "${GENERATE_BIG_DATA:-0}" == "1" ]]; then
  run_sql sql/dml/03_generate_audit_activity.sql
fi

echo "==> OK"
