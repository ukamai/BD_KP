BEGIN;

CREATE TABLE IF NOT EXISTS import_runs (
  run_id        BIGSERIAL PRIMARY KEY,
  started_at    TIMESTAMP NOT NULL DEFAULT now(),
  finished_at   TIMESTAMP,
  source        TEXT      NOT NULL,
  entity        TEXT      NOT NULL DEFAULT 'inventory_transactions',
  total_rows    INT       NOT NULL,
  inserted_rows INT       NOT NULL DEFAULT 0,
  failed_rows   INT       NOT NULL DEFAULT 0,
  fail_fast     BOOLEAN   NOT NULL DEFAULT FALSE,
  status        TEXT      NOT NULL DEFAULT 'running',
  user_id       BIGINT,
  meta          JSONB
);

ALTER TABLE import_runs DROP CONSTRAINT IF EXISTS fk_import_runs_user;
ALTER TABLE import_runs
  ADD CONSTRAINT fk_import_runs_user
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

CREATE TABLE IF NOT EXISTS import_errors (
  error_id       BIGSERIAL PRIMARY KEY,
  occurred_at    TIMESTAMP NOT NULL DEFAULT now(),
  run_id         BIGINT,
  source         TEXT      NOT NULL,
  payload        JSONB,
  error_message  TEXT      NOT NULL,
  user_id        BIGINT,
  details        JSONB
);

ALTER TABLE import_errors DROP CONSTRAINT IF EXISTS fk_import_errors_user;
ALTER TABLE import_errors
  ADD CONSTRAINT fk_import_errors_user
  FOREIGN KEY (user_id) REFERENCES users(user_id) ON DELETE SET NULL;

ALTER TABLE import_errors DROP CONSTRAINT IF EXISTS fk_import_errors_run;
ALTER TABLE import_errors
  ADD CONSTRAINT fk_import_errors_run
  FOREIGN KEY (run_id) REFERENCES import_runs(run_id) ON DELETE SET NULL;

CREATE INDEX IF NOT EXISTS idx_import_errors_run_id ON import_errors(run_id);

COMMIT;
