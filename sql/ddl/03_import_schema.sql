BEGIN;

CREATE TABLE IF NOT EXISTS import_errors (
  error_id       BIGSERIAL PRIMARY KEY,
  occurred_at    TIMESTAMP NOT NULL DEFAULT now(),
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

COMMIT;
