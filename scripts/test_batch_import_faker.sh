#!/usr/bin/env bash
set -euo pipefail

BASE_URL="${BASE_URL:-http://localhost:8000}"
COUNT="${COUNT:-500}"
INVALID_RATE="${INVALID_RATE:-0.05}"
FAIL_FAST="${FAIL_FAST:-false}"

echo "POST ${BASE_URL}/api/v1/inventory-transactions/batch/faker count=${COUNT} invalid_rate=${INVALID_RATE} fail_fast=${FAIL_FAST}"
RESP="$(curl -sS -X POST "${BASE_URL}/api/v1/inventory-transactions/batch/faker" \
  -H 'Content-Type: application/json' \
  -d "{\"count\":${COUNT},\"invalid_rate\":${INVALID_RATE},\"fail_fast\":${FAIL_FAST},\"source\":\"faker\"}")"

echo "${RESP}"

RUN_ID="$(echo "${RESP}" | python3 -c 'import json,sys; print(json.load(sys.stdin).get("run_id") or "")' 2>/dev/null || true)"
if [[ -n "${RUN_ID}" ]]; then
  echo "GET ${BASE_URL}/api/v1/import-runs/${RUN_ID}"
  curl -sS "${BASE_URL}/api/v1/import-runs/${RUN_ID}" >/dev/null
  echo "OK"

  echo "GET ${BASE_URL}/api/v1/import-errors?run_id=${RUN_ID}"
  curl -sS "${BASE_URL}/api/v1/import-errors?run_id=${RUN_ID}" >/dev/null
  echo "OK"
fi

echo "GET ${BASE_URL}/api/v1/inventory-transactions"
curl -sS "${BASE_URL}/api/v1/inventory-transactions" >/dev/null
echo "OK"

echo "GET ${BASE_URL}/api/v1/import-errors"
curl -sS "${BASE_URL}/api/v1/import-errors" >/dev/null
echo "OK"
