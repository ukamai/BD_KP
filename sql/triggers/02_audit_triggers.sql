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

-- project_tasks.status
CREATE OR REPLACE FUNCTION trg_audit_tasks_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM audit_write(
      'project_tasks',
      OLD.task_id,
      'UPDATE',
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_project_tasks_status ON project_tasks;
CREATE TRIGGER audit_project_tasks_status
BEFORE UPDATE OF status ON project_tasks
FOR EACH ROW EXECUTE FUNCTION trg_audit_tasks_status();

-- projects.status
CREATE OR REPLACE FUNCTION trg_audit_projects_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM audit_write(
      'projects',
      OLD.project_id,
      'UPDATE',
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_projects_status ON projects;
CREATE TRIGGER audit_projects_status
BEFORE UPDATE OF status ON projects
FOR EACH ROW EXECUTE FUNCTION trg_audit_projects_status();

-- purchase_orders.status
CREATE OR REPLACE FUNCTION trg_audit_purchase_orders_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM audit_write(
      'purchase_orders',
      OLD.po_id,
      'UPDATE',
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_purchase_orders_status ON purchase_orders;
CREATE TRIGGER audit_purchase_orders_status
BEFORE UPDATE OF status ON purchase_orders
FOR EACH ROW EXECUTE FUNCTION trg_audit_purchase_orders_status();

-- project_phases.status
CREATE OR REPLACE FUNCTION trg_audit_phases_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM audit_write(
      'project_phases',
      OLD.phase_id,
      'UPDATE',
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_project_phases_status ON project_phases;
CREATE TRIGGER audit_project_phases_status
BEFORE UPDATE OF status ON project_phases
FOR EACH ROW EXECUTE FUNCTION trg_audit_phases_status();

-- contracts.status
CREATE OR REPLACE FUNCTION trg_audit_contracts_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM audit_write(
      'contracts',
      OLD.contract_id,
      'UPDATE',
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_contracts_status ON contracts;
CREATE TRIGGER audit_contracts_status
BEFORE UPDATE OF status ON contracts
FOR EACH ROW EXECUTE FUNCTION trg_audit_contracts_status();

-- defects.status
CREATE OR REPLACE FUNCTION trg_audit_defects_status()
RETURNS TRIGGER AS $$
BEGIN
  IF NEW.status IS DISTINCT FROM OLD.status THEN
    PERFORM audit_write(
      'defects',
      OLD.defect_id,
      'UPDATE',
      jsonb_build_object('status', OLD.status),
      jsonb_build_object('status', NEW.status)
    );
  END IF;
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS audit_defects_status ON defects;
CREATE TRIGGER audit_defects_status
BEFORE UPDATE OF status ON defects
FOR EACH ROW EXECUTE FUNCTION trg_audit_defects_status();

COMMIT;
