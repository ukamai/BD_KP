SELECT 'users' t, COUNT(*) c FROM users
UNION ALL SELECT 'owners', COUNT(*) FROM owners
UNION ALL SELECT 'properties', COUNT(*) FROM properties
UNION ALL SELECT 'property_rooms', COUNT(*) FROM property_rooms
UNION ALL SELECT 'contractors', COUNT(*) FROM contractors
UNION ALL SELECT 'contracts', COUNT(*) FROM contracts
UNION ALL SELECT 'projects', COUNT(*) FROM projects
UNION ALL SELECT 'project_phases', COUNT(*) FROM project_phases
UNION ALL SELECT 'work_types', COUNT(*) FROM work_types
UNION ALL SELECT 'project_tasks', COUNT(*) FROM project_tasks
UNION ALL SELECT 'acceptance_acts', COUNT(*) FROM acceptance_acts
UNION ALL SELECT 'materials', COUNT(*) FROM materials
UNION ALL SELECT 'suppliers', COUNT(*) FROM suppliers
UNION ALL SELECT 'purchase_orders', COUNT(*) FROM purchase_orders
UNION ALL SELECT 'purchase_order_items', COUNT(*) FROM purchase_order_items
UNION ALL SELECT 'inventory_transactions', COUNT(*) FROM inventory_transactions
UNION ALL SELECT 'defects', COUNT(*) FROM defects
UNION ALL SELECT 'audit_log', COUNT(*) FROM audit_log
UNION ALL SELECT 'import_runs', COUNT(*) FROM import_runs
UNION ALL SELECT 'import_errors', COUNT(*) FROM import_errors
ORDER BY t;

SELECT * FROM users ORDER BY user_id LIMIT 5;
SELECT * FROM owners ORDER BY owner_id DESC LIMIT 5;
SELECT * FROM properties ORDER BY property_id DESC LIMIT 5;
SELECT * FROM property_rooms ORDER BY room_id DESC LIMIT 10;

SELECT * FROM contractors ORDER BY contractor_id DESC LIMIT 5;
SELECT * FROM contracts ORDER BY contract_id DESC LIMIT 5;

SELECT * FROM projects ORDER BY project_id DESC LIMIT 5;
SELECT * FROM project_phases ORDER BY phase_id DESC LIMIT 10;
SELECT * FROM work_types ORDER BY work_type_id DESC LIMIT 10;
SELECT * FROM project_tasks ORDER BY task_id DESC LIMIT 10;

SELECT * FROM acceptance_acts ORDER BY created_at DESC LIMIT 10;

SELECT * FROM materials ORDER BY material_id DESC LIMIT 10;
SELECT * FROM suppliers ORDER BY supplier_id DESC LIMIT 10;

SELECT * FROM purchase_orders ORDER BY po_id DESC LIMIT 10;
SELECT * FROM purchase_order_items ORDER BY po_item_id DESC LIMIT 10;

SELECT * FROM inventory_transactions ORDER BY inv_tx_id DESC LIMIT 10;
SELECT * FROM defects ORDER BY defect_id DESC LIMIT 10;

SELECT * FROM audit_log ORDER BY action_timestamp DESC, audit_id DESC LIMIT 20;

SELECT * FROM v_project_progress LIMIT 20;
SELECT * FROM v_material_balance_by_project LIMIT 20;
