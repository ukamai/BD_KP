BEGIN;

ALTER TABLE properties      DROP CONSTRAINT IF EXISTS fk_properties_owner;
ALTER TABLE properties      ADD  CONSTRAINT fk_properties_owner FOREIGN KEY (owner_id) REFERENCES owners(owner_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE property_rooms  DROP CONSTRAINT IF EXISTS fk_rooms_property;
ALTER TABLE property_rooms  ADD  CONSTRAINT fk_rooms_property FOREIGN KEY (property_id) REFERENCES properties(property_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE contracts       DROP CONSTRAINT IF EXISTS fk_contracts_property;
ALTER TABLE contracts       ADD  CONSTRAINT fk_contracts_property FOREIGN KEY (property_id) REFERENCES properties(property_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE contracts       DROP CONSTRAINT IF EXISTS fk_contracts_contractor;
ALTER TABLE contracts       ADD  CONSTRAINT fk_contracts_contractor FOREIGN KEY (contractor_id) REFERENCES contractors(contractor_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE projects        DROP CONSTRAINT IF EXISTS fk_projects_property;
ALTER TABLE projects        ADD  CONSTRAINT fk_projects_property FOREIGN KEY (property_id) REFERENCES properties(property_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE projects        DROP CONSTRAINT IF EXISTS fk_projects_contract;
ALTER TABLE projects        ADD  CONSTRAINT fk_projects_contract FOREIGN KEY (contract_id) REFERENCES contracts(contract_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE project_phases  DROP CONSTRAINT IF EXISTS fk_phases_project;
ALTER TABLE project_phases  ADD  CONSTRAINT fk_phases_project FOREIGN KEY (project_id) REFERENCES projects(project_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE project_tasks   DROP CONSTRAINT IF EXISTS fk_tasks_project;
ALTER TABLE project_tasks   ADD  CONSTRAINT fk_tasks_project FOREIGN KEY (project_id) REFERENCES projects(project_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE project_tasks   DROP CONSTRAINT IF EXISTS fk_tasks_phase;
ALTER TABLE project_tasks   ADD  CONSTRAINT fk_tasks_phase FOREIGN KEY (phase_id) REFERENCES project_phases(phase_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE project_tasks   DROP CONSTRAINT IF EXISTS fk_tasks_room;
ALTER TABLE project_tasks   ADD  CONSTRAINT fk_tasks_room FOREIGN KEY (room_id) REFERENCES property_rooms(room_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE project_tasks   DROP CONSTRAINT IF EXISTS fk_tasks_work_type;
ALTER TABLE project_tasks   ADD  CONSTRAINT fk_tasks_work_type FOREIGN KEY (work_type_id) REFERENCES work_types(work_type_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE project_tasks   DROP CONSTRAINT IF EXISTS fk_tasks_contractor;
ALTER TABLE project_tasks   ADD  CONSTRAINT fk_tasks_contractor FOREIGN KEY (contractor_id) REFERENCES contractors(contractor_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE acceptance_acts DROP CONSTRAINT IF EXISTS fk_acceptance_task;
ALTER TABLE acceptance_acts ADD  CONSTRAINT fk_acceptance_task FOREIGN KEY (task_id) REFERENCES project_tasks(task_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE purchase_orders DROP CONSTRAINT IF EXISTS fk_orders_project;
ALTER TABLE purchase_orders ADD  CONSTRAINT fk_orders_project FOREIGN KEY (project_id) REFERENCES projects(project_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE purchase_orders DROP CONSTRAINT IF EXISTS fk_orders_supplier;
ALTER TABLE purchase_orders ADD  CONSTRAINT fk_orders_supplier FOREIGN KEY (supplier_id) REFERENCES suppliers(supplier_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE purchase_order_items DROP CONSTRAINT IF EXISTS fk_po_items_po;
ALTER TABLE purchase_order_items ADD  CONSTRAINT fk_po_items_po FOREIGN KEY (po_id) REFERENCES purchase_orders(po_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE purchase_order_items DROP CONSTRAINT IF EXISTS fk_po_items_material;
ALTER TABLE purchase_order_items ADD  CONSTRAINT fk_po_items_material FOREIGN KEY (material_id) REFERENCES materials(material_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE inventory_transactions DROP CONSTRAINT IF EXISTS fk_inv_project;
ALTER TABLE inventory_transactions ADD  CONSTRAINT fk_inv_project FOREIGN KEY (project_id) REFERENCES projects(project_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE inventory_transactions DROP CONSTRAINT IF EXISTS fk_inv_material;
ALTER TABLE inventory_transactions ADD  CONSTRAINT fk_inv_material FOREIGN KEY (material_id) REFERENCES materials(material_id) ON UPDATE CASCADE ON DELETE RESTRICT;

ALTER TABLE inventory_transactions DROP CONSTRAINT IF EXISTS fk_inv_task;
ALTER TABLE inventory_transactions ADD  CONSTRAINT fk_inv_task FOREIGN KEY (task_id) REFERENCES project_tasks(task_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE inventory_transactions DROP CONSTRAINT IF EXISTS fk_inv_po_item;
ALTER TABLE inventory_transactions ADD  CONSTRAINT fk_inv_po_item FOREIGN KEY (po_item_id) REFERENCES purchase_order_items(po_item_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE defects DROP CONSTRAINT IF EXISTS fk_defects_task;
ALTER TABLE defects ADD  CONSTRAINT fk_defects_task FOREIGN KEY (task_id) REFERENCES project_tasks(task_id) ON UPDATE CASCADE ON DELETE CASCADE;

ALTER TABLE defects DROP CONSTRAINT IF EXISTS fk_defects_contractor;
ALTER TABLE defects ADD  CONSTRAINT fk_defects_contractor FOREIGN KEY (contractor_id) REFERENCES contractors(contractor_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS fk_audit_user;
ALTER TABLE audit_log ADD  CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(user_id) ON UPDATE CASCADE ON DELETE SET NULL;

ALTER TABLE property_rooms       DROP CONSTRAINT IF EXISTS uq_rooms_property_name;
ALTER TABLE property_rooms       ADD  CONSTRAINT uq_rooms_property_name UNIQUE (property_id, room_name);

ALTER TABLE purchase_order_items DROP CONSTRAINT IF EXISTS uq_po_items_po_material;
ALTER TABLE purchase_order_items ADD  CONSTRAINT uq_po_items_po_material UNIQUE (po_id, material_id);

ALTER TABLE work_types           DROP CONSTRAINT IF EXISTS uq_work_types_name;
ALTER TABLE work_types           ADD  CONSTRAINT uq_work_types_name UNIQUE (work_type_name);

ALTER TABLE suppliers            DROP CONSTRAINT IF EXISTS uq_suppliers_name;
ALTER TABLE suppliers            ADD  CONSTRAINT uq_suppliers_name UNIQUE (supplier_name);

ALTER TABLE materials            DROP CONSTRAINT IF EXISTS uq_materials_name;
ALTER TABLE materials            ADD  CONSTRAINT uq_materials_name UNIQUE (material_name);

ALTER TABLE properties              DROP CONSTRAINT IF EXISTS chk_properties_area;
ALTER TABLE properties              ADD  CONSTRAINT chk_properties_area CHECK (total_area > 0);

ALTER TABLE property_rooms          DROP CONSTRAINT IF EXISTS chk_rooms_area;
ALTER TABLE property_rooms          ADD  CONSTRAINT chk_rooms_area CHECK (area > 0);

ALTER TABLE contracts               DROP CONSTRAINT IF EXISTS chk_contracts_amount;
ALTER TABLE contracts               ADD  CONSTRAINT chk_contracts_amount CHECK (total_amount >= 0);

ALTER TABLE projects                DROP CONSTRAINT IF EXISTS chk_projects_budget;
ALTER TABLE projects                ADD  CONSTRAINT chk_projects_budget CHECK (total_budget >= 0 AND actual_cost >= 0);

ALTER TABLE project_phases          DROP CONSTRAINT IF EXISTS chk_phases_order;
ALTER TABLE project_phases          ADD  CONSTRAINT chk_phases_order CHECK (phase_order > 0);

ALTER TABLE project_tasks           DROP CONSTRAINT IF EXISTS chk_tasks_costs;
ALTER TABLE project_tasks           ADD  CONSTRAINT chk_tasks_costs CHECK (volume >= 0 AND planned_cost >= 0 AND actual_cost >= 0);

ALTER TABLE purchase_orders         DROP CONSTRAINT IF EXISTS chk_orders_amount;
ALTER TABLE purchase_orders         ADD  CONSTRAINT chk_orders_amount CHECK (total_amount >= 0);

ALTER TABLE purchase_order_items    DROP CONSTRAINT IF EXISTS chk_po_items_qty_price;
ALTER TABLE purchase_order_items    ADD  CONSTRAINT chk_po_items_qty_price CHECK (
  quantity_ordered > 0 AND unit_price >= 0 AND delivered_quantity >= 0
);

ALTER TABLE inventory_transactions  DROP CONSTRAINT IF EXISTS chk_inv_qty_price;
ALTER TABLE inventory_transactions  ADD  CONSTRAINT chk_inv_qty_price CHECK (quantity > 0 AND unit_price >= 0);

ALTER TABLE defects                 DROP CONSTRAINT IF EXISTS chk_defects_rework_cost;
ALTER TABLE defects                 ADD  CONSTRAINT chk_defects_rework_cost CHECK (rework_cost >= 0);

ALTER TABLE contracts      DROP CONSTRAINT IF EXISTS chk_contracts_dates;
ALTER TABLE contracts      ADD  CONSTRAINT chk_contracts_dates CHECK (end_date IS NULL OR end_date >= start_date);

ALTER TABLE projects       DROP CONSTRAINT IF EXISTS chk_projects_planned_dates;
ALTER TABLE projects       ADD  CONSTRAINT chk_projects_planned_dates CHECK (
  planned_end_date IS NULL OR planned_start_date IS NULL OR planned_end_date >= planned_start_date
);

ALTER TABLE project_phases DROP CONSTRAINT IF EXISTS chk_phases_planned_dates;
ALTER TABLE project_phases ADD  CONSTRAINT chk_phases_planned_dates CHECK (
  planned_end_date IS NULL OR planned_start_date IS NULL OR planned_end_date >= planned_start_date
);

ALTER TABLE project_tasks  DROP CONSTRAINT IF EXISTS chk_tasks_planned_dates;
ALTER TABLE project_tasks  ADD  CONSTRAINT chk_tasks_planned_dates CHECK (
  planned_end_date IS NULL OR planned_start_date IS NULL OR planned_end_date >= planned_start_date
);

ALTER TABLE project_tasks  DROP CONSTRAINT IF EXISTS chk_tasks_actual_dates;
ALTER TABLE project_tasks  ADD  CONSTRAINT chk_tasks_actual_dates CHECK (
  actual_end_date IS NULL OR actual_start_date IS NULL OR actual_end_date >= actual_start_date
);

ALTER TABLE properties     DROP CONSTRAINT IF EXISTS chk_properties_status;
ALTER TABLE properties     ADD  CONSTRAINT chk_properties_status CHECK (status IN ('active','inactive','archived'));

ALTER TABLE contracts      DROP CONSTRAINT IF EXISTS chk_contracts_status;
ALTER TABLE contracts      ADD  CONSTRAINT chk_contracts_status CHECK (status IN ('draft','active','closed','cancelled'));

ALTER TABLE projects       DROP CONSTRAINT IF EXISTS chk_projects_status;
ALTER TABLE projects       ADD  CONSTRAINT chk_projects_status CHECK (status IN ('planned','active','completed','cancelled'));

ALTER TABLE project_phases DROP CONSTRAINT IF EXISTS chk_phases_status;
ALTER TABLE project_phases ADD  CONSTRAINT chk_phases_status CHECK (status IN ('planned','active','completed','cancelled'));

ALTER TABLE project_tasks  DROP CONSTRAINT IF EXISTS chk_tasks_status;
ALTER TABLE project_tasks  ADD  CONSTRAINT chk_tasks_status CHECK (status IN ('planned','in_progress','blocked','completed','cancelled'));

ALTER TABLE purchase_orders DROP CONSTRAINT IF EXISTS chk_orders_status;
ALTER TABLE purchase_orders ADD  CONSTRAINT chk_orders_status CHECK (status IN ('draft','ordered','delivered','cancelled'));

ALTER TABLE acceptance_acts DROP CONSTRAINT IF EXISTS chk_acts_result;
ALTER TABLE acceptance_acts ADD  CONSTRAINT chk_acts_result CHECK (result_status IS NULL OR result_status IN ('accepted','rejected','partial'));

ALTER TABLE inventory_transactions DROP CONSTRAINT IF EXISTS chk_inv_type;
ALTER TABLE inventory_transactions ADD  CONSTRAINT chk_inv_type CHECK (transaction_type IN ('IN','OUT','ADJUST'));

ALTER TABLE defects DROP CONSTRAINT IF EXISTS chk_defects_severity;
ALTER TABLE defects ADD  CONSTRAINT chk_defects_severity CHECK (severity IN ('low','medium','high','critical'));

ALTER TABLE defects DROP CONSTRAINT IF EXISTS chk_defects_status;
ALTER TABLE defects ADD  CONSTRAINT chk_defects_status CHECK (status IN ('open','in_progress','resolved','closed'));

ALTER TABLE audit_log DROP CONSTRAINT IF EXISTS chk_audit_action;
ALTER TABLE audit_log ADD  CONSTRAINT chk_audit_action CHECK (action_type IN ('INSERT','UPDATE','DELETE'));

COMMIT;
