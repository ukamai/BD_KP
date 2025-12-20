SELECT set_config('app.user_id', (SELECT user_id::text FROM users WHERE username='manager'), true);

SELECT property_id, address, updated_at FROM properties ORDER BY property_id;
UPDATE properties
SET address = address || ' (upd)'
WHERE property_id = (SELECT MIN(property_id) FROM properties);
SELECT property_id, address, updated_at FROM properties ORDER BY property_id;

SELECT po_id, po_number, total_amount
FROM purchase_orders
WHERE po_number='PO-2025-0001';

INSERT INTO purchase_order_items (po_id, material_id, quantity_ordered, unit_price, delivered_quantity, line_total)
VALUES (
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0001'),
  (SELECT m.material_id
   FROM materials m
   WHERE NOT EXISTS (
     SELECT 1
     FROM purchase_order_items i
     WHERE i.po_id = (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0001')
       AND i.material_id = m.material_id
   )
   ORDER BY m.material_id
   LIMIT 1),
  2, 10, 0, 0
);

SELECT *
FROM purchase_order_items
WHERE po_id = (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0001')
ORDER BY po_item_id;

SELECT po_id, po_number, total_amount
FROM purchase_orders
WHERE po_number='PO-2025-0001';

UPDATE project_tasks
SET status='completed', actual_end_date=CURRENT_DATE
WHERE task_name='Плитка на фартук';

SELECT entity_type, entity_id, action_type, user_id, action_timestamp, old_values, new_values
FROM audit_log
ORDER BY action_timestamp DESC
LIMIT 20;
