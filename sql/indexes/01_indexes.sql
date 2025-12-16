BEGIN;

CREATE INDEX IF NOT EXISTS idx_properties_owner_id      ON properties(owner_id);
CREATE INDEX IF NOT EXISTS idx_rooms_property_id        ON property_rooms(property_id);
CREATE INDEX IF NOT EXISTS idx_contracts_property_id    ON contracts(property_id);
CREATE INDEX IF NOT EXISTS idx_contracts_contractor_id  ON contracts(contractor_id);
CREATE INDEX IF NOT EXISTS idx_projects_property_id     ON projects(property_id);
CREATE INDEX IF NOT EXISTS idx_projects_contract_id     ON projects(contract_id);
CREATE INDEX IF NOT EXISTS idx_phases_project_id        ON project_phases(project_id);

CREATE INDEX IF NOT EXISTS idx_tasks_project_id         ON project_tasks(project_id);
CREATE INDEX IF NOT EXISTS idx_tasks_phase_id           ON project_tasks(phase_id);
CREATE INDEX IF NOT EXISTS idx_tasks_room_id            ON project_tasks(room_id);
CREATE INDEX IF NOT EXISTS idx_tasks_work_type_id       ON project_tasks(work_type_id);
CREATE INDEX IF NOT EXISTS idx_tasks_contractor_id      ON project_tasks(contractor_id);
CREATE INDEX IF NOT EXISTS idx_tasks_project_status     ON project_tasks(project_id, status);

CREATE INDEX IF NOT EXISTS idx_orders_project_id        ON purchase_orders(project_id);
CREATE INDEX IF NOT EXISTS idx_orders_supplier_id       ON purchase_orders(supplier_id);
CREATE INDEX IF NOT EXISTS idx_orders_status            ON purchase_orders(status);
CREATE INDEX IF NOT EXISTS idx_orders_order_date        ON purchase_orders(order_date);

CREATE INDEX IF NOT EXISTS idx_po_items_po_id           ON purchase_order_items(po_id);
CREATE INDEX IF NOT EXISTS idx_po_items_material_id     ON purchase_order_items(material_id);

CREATE INDEX IF NOT EXISTS idx_inv_project_id           ON inventory_transactions(project_id);
CREATE INDEX IF NOT EXISTS idx_inv_material_id          ON inventory_transactions(material_id);
CREATE INDEX IF NOT EXISTS idx_inv_task_id              ON inventory_transactions(task_id);
CREATE INDEX IF NOT EXISTS idx_inv_po_item_id           ON inventory_transactions(po_item_id);
CREATE INDEX IF NOT EXISTS idx_inv_project_material_date ON inventory_transactions(project_id, material_id, transaction_date);

CREATE INDEX IF NOT EXISTS idx_defects_task_id          ON defects(task_id);
CREATE INDEX IF NOT EXISTS idx_defects_contractor_id    ON defects(contractor_id);
CREATE INDEX IF NOT EXISTS idx_defects_contractor_status ON defects(contractor_id, status);

CREATE INDEX IF NOT EXISTS idx_audit_user_id            ON audit_log(user_id);
CREATE INDEX IF NOT EXISTS idx_audit_entity             ON audit_log(entity_type, entity_id);
CREATE INDEX IF NOT EXISTS idx_audit_timestamp          ON audit_log(action_timestamp);

COMMIT;
