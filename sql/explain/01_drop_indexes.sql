BEGIN;

DROP INDEX IF EXISTS idx_properties_owner_id;
DROP INDEX IF EXISTS idx_rooms_property_id;
DROP INDEX IF EXISTS idx_contracts_property_id;
DROP INDEX IF EXISTS idx_contracts_contractor_id;
DROP INDEX IF EXISTS idx_projects_property_id;
DROP INDEX IF EXISTS idx_projects_contract_id;
DROP INDEX IF EXISTS idx_phases_project_id;

DROP INDEX IF EXISTS idx_tasks_project_id;
DROP INDEX IF EXISTS idx_tasks_phase_id;
DROP INDEX IF EXISTS idx_tasks_room_id;
DROP INDEX IF EXISTS idx_tasks_work_type_id;
DROP INDEX IF EXISTS idx_tasks_contractor_id;
DROP INDEX IF EXISTS idx_tasks_project_status;

DROP INDEX IF EXISTS idx_orders_project_id;
DROP INDEX IF EXISTS idx_orders_supplier_id;
DROP INDEX IF EXISTS idx_orders_status;
DROP INDEX IF EXISTS idx_orders_order_date;

DROP INDEX IF EXISTS idx_po_items_po_id;
DROP INDEX IF EXISTS idx_po_items_material_id;

DROP INDEX IF EXISTS idx_inv_project_id;
DROP INDEX IF EXISTS idx_inv_material_id;
DROP INDEX IF EXISTS idx_inv_task_id;
DROP INDEX IF EXISTS idx_inv_po_item_id;
DROP INDEX IF EXISTS idx_inv_project_material_date;

DROP INDEX IF EXISTS idx_defects_task_id;
DROP INDEX IF EXISTS idx_defects_contractor_id;
DROP INDEX IF EXISTS idx_defects_contractor_status;

DROP INDEX IF EXISTS idx_audit_user_id;
DROP INDEX IF EXISTS idx_audit_entity;
DROP INDEX IF EXISTS idx_audit_timestamp;

COMMIT;
