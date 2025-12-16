BEGIN;

DROP FUNCTION IF EXISTS trg_audit_crud(TEXT);

CREATE OR REPLACE FUNCTION trg_audit_crud()
RETURNS TRIGGER AS $$
DECLARE
  p_pk_column TEXT;
  v_entity_id BIGINT;
  v_old JSONB;
  v_new JSONB;
  v_disabled TEXT;
BEGIN
  IF TG_NARGS < 1 THEN
    RAISE EXCEPTION 'trg_audit_crud требует аргумент: имя PK-колонки (например project_id)';
  END IF;
  p_pk_column := TG_ARGV[0];

  v_disabled := current_setting('app.audit_disabled', true);
  IF v_disabled IN ('1','true','on','yes') THEN
    IF TG_OP = 'DELETE' THEN
      RETURN OLD;
    ELSE
      RETURN NEW;
    END IF;
  END IF;

  IF TG_OP = 'INSERT' THEN
    v_entity_id := NULLIF(to_jsonb(NEW)->>p_pk_column, '')::BIGINT;
    v_old := NULL;
    v_new := to_jsonb(NEW);
    PERFORM audit_write(TG_TABLE_NAME, v_entity_id, 'INSERT', v_old, v_new);
    RETURN NEW;

  ELSIF TG_OP = 'UPDATE' THEN
    v_entity_id := NULLIF(to_jsonb(NEW)->>p_pk_column, '')::BIGINT;
    v_old := to_jsonb(OLD);
    v_new := to_jsonb(NEW);

    IF v_old IS DISTINCT FROM v_new THEN
      PERFORM audit_write(TG_TABLE_NAME, v_entity_id, 'UPDATE', v_old, v_new);
    END IF;

    RETURN NEW;

  ELSIF TG_OP = 'DELETE' THEN
    v_entity_id := NULLIF(to_jsonb(OLD)->>p_pk_column, '')::BIGINT;
    v_old := to_jsonb(OLD);
    v_new := NULL;
    PERFORM audit_write(TG_TABLE_NAME, v_entity_id, 'DELETE', v_old, v_new);
    RETURN OLD;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;



-- users
DROP TRIGGER IF EXISTS audit_users_crud ON users;
CREATE TRIGGER audit_users_crud
AFTER INSERT OR UPDATE OR DELETE ON users
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('user_id');

-- owners
DROP TRIGGER IF EXISTS audit_owners_crud ON owners;
CREATE TRIGGER audit_owners_crud
AFTER INSERT OR UPDATE OR DELETE ON owners
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('owner_id');

-- properties
DROP TRIGGER IF EXISTS audit_properties_crud ON properties;
CREATE TRIGGER audit_properties_crud
AFTER INSERT OR UPDATE OR DELETE ON properties
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('property_id');

-- property_rooms
DROP TRIGGER IF EXISTS audit_property_rooms_crud ON property_rooms;
CREATE TRIGGER audit_property_rooms_crud
AFTER INSERT OR UPDATE OR DELETE ON property_rooms
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('room_id');

-- contractors
DROP TRIGGER IF EXISTS audit_contractors_crud ON contractors;
CREATE TRIGGER audit_contractors_crud
AFTER INSERT OR UPDATE OR DELETE ON contractors
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('contractor_id');

-- contracts
DROP TRIGGER IF EXISTS audit_contracts_crud ON contracts;
CREATE TRIGGER audit_contracts_crud
AFTER INSERT OR UPDATE OR DELETE ON contracts
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('contract_id');

-- projects
DROP TRIGGER IF EXISTS audit_projects_crud ON projects;
CREATE TRIGGER audit_projects_crud
AFTER INSERT OR UPDATE OR DELETE ON projects
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('project_id');

-- project_phases
DROP TRIGGER IF EXISTS audit_project_phases_crud ON project_phases;
CREATE TRIGGER audit_project_phases_crud
AFTER INSERT OR UPDATE OR DELETE ON project_phases
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('phase_id');

-- work_types
DROP TRIGGER IF EXISTS audit_work_types_crud ON work_types;
CREATE TRIGGER audit_work_types_crud
AFTER INSERT OR UPDATE OR DELETE ON work_types
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('work_type_id');

-- project_tasks
DROP TRIGGER IF EXISTS audit_project_tasks_crud ON project_tasks;
CREATE TRIGGER audit_project_tasks_crud
AFTER INSERT OR UPDATE OR DELETE ON project_tasks
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('task_id');

-- acceptance_acts (PK = task_id)
DROP TRIGGER IF EXISTS audit_acceptance_acts_crud ON acceptance_acts;
CREATE TRIGGER audit_acceptance_acts_crud
AFTER INSERT OR UPDATE OR DELETE ON acceptance_acts
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('task_id');

-- materials
DROP TRIGGER IF EXISTS audit_materials_crud ON materials;
CREATE TRIGGER audit_materials_crud
AFTER INSERT OR UPDATE OR DELETE ON materials
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('material_id');

-- suppliers
DROP TRIGGER IF EXISTS audit_suppliers_crud ON suppliers;
CREATE TRIGGER audit_suppliers_crud
AFTER INSERT OR UPDATE OR DELETE ON suppliers
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('supplier_id');

-- purchase_orders
DROP TRIGGER IF EXISTS audit_purchase_orders_crud ON purchase_orders;
CREATE TRIGGER audit_purchase_orders_crud
AFTER INSERT OR UPDATE OR DELETE ON purchase_orders
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('po_id');

-- purchase_order_items
DROP TRIGGER IF EXISTS audit_purchase_order_items_crud ON purchase_order_items;
CREATE TRIGGER audit_purchase_order_items_crud
AFTER INSERT OR UPDATE OR DELETE ON purchase_order_items
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('po_item_id');

-- inventory_transactions
DROP TRIGGER IF EXISTS audit_inventory_transactions_crud ON inventory_transactions;
CREATE TRIGGER audit_inventory_transactions_crud
AFTER INSERT OR UPDATE OR DELETE ON inventory_transactions
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('inv_tx_id');

-- defects
DROP TRIGGER IF EXISTS audit_defects_crud ON defects;
CREATE TRIGGER audit_defects_crud
AFTER INSERT OR UPDATE OR DELETE ON defects
FOR EACH ROW EXECUTE FUNCTION trg_audit_crud('defect_id');

COMMIT;
