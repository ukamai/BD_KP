BEGIN;

CREATE OR REPLACE FUNCTION audit_get_user_id()
RETURNS BIGINT AS $$
DECLARE
  v TEXT;
BEGIN
  v := current_setting('app.user_id', true);
  IF v IS NULL OR v = '' THEN
    RETURN NULL;
  END IF;
  BEGIN
    RETURN v::BIGINT;
  EXCEPTION WHEN others THEN
    RETURN NULL;
  END;
END;
$$ LANGUAGE plpgsql;

CREATE OR REPLACE FUNCTION audit_write(
  p_entity_type TEXT,
  p_entity_id   BIGINT,
  p_action_type TEXT,
  p_old_values  JSONB,
  p_new_values  JSONB
)
RETURNS VOID AS $$
BEGIN
  INSERT INTO audit_log(entity_type, entity_id, action_type, action_timestamp, user_id, old_values, new_values)
  VALUES (p_entity_type, p_entity_id, p_action_type, now(), audit_get_user_id(), p_old_values, p_new_values);
END;
$$ LANGUAGE plpgsql;

COMMIT;
