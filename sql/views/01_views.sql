BEGIN;

CREATE OR REPLACE VIEW v_projects_overview AS
SELECT
  p.project_id, p.project_name, p.status AS project_status,
  p.total_budget, p.actual_cost, p.planned_start_date, p.planned_end_date,
  pr.property_id, pr.address, pr.property_type, pr.status AS property_status,
  o.owner_id, o.full_name AS owner_name, o.phone AS owner_phone, o.email AS owner_email,
  c.contract_id, c.contract_number, c.status AS contract_status,
  ctr.contractor_id, ctr.name AS contractor_name
FROM projects p
JOIN properties pr ON pr.property_id = p.property_id
JOIN owners o ON o.owner_id = pr.owner_id
LEFT JOIN contracts c ON c.contract_id = p.contract_id
LEFT JOIN contractors ctr ON ctr.contractor_id = c.contractor_id;

CREATE OR REPLACE VIEW v_project_progress AS
SELECT
  p.project_id, p.project_name,
  COUNT(t.task_id) AS tasks_total,
  COUNT(*) FILTER (WHERE t.status = 'planned') AS tasks_planned,
  COUNT(*) FILTER (WHERE t.status = 'in_progress') AS tasks_in_progress,
  COUNT(*) FILTER (WHERE t.status = 'blocked') AS tasks_blocked,
  COUNT(*) FILTER (WHERE t.status = 'completed') AS tasks_completed,
  COUNT(*) FILTER (WHERE t.status = 'cancelled') AS tasks_cancelled,
  CASE WHEN COUNT(t.task_id)=0 THEN 0
       ELSE ROUND(100.0 * COUNT(*) FILTER (WHERE t.status='completed') / COUNT(t.task_id), 2)
  END AS pct_completed
FROM projects p
LEFT JOIN project_tasks t ON t.project_id = p.project_id
GROUP BY p.project_id, p.project_name;

CREATE OR REPLACE VIEW v_tasks_detailed AS
SELECT
  t.task_id, t.task_name, t.status AS task_status,
  t.volume, t.planned_cost, t.actual_cost,
  t.planned_start_date, t.planned_end_date, t.actual_start_date, t.actual_end_date,
  ph.phase_id, ph.phase_name, ph.phase_order, ph.status AS phase_status,
  p.project_id, p.project_name,
  r.room_id, r.room_name, r.room_type,
  wt.work_type_id, wt.work_type_name, wt.category AS work_category, wt.default_unit,
  ctr.contractor_id, ctr.name AS contractor_name,
  act.acceptance_date, act.result_status AS acceptance_result, act.accepted_by
FROM project_tasks t
JOIN project_phases ph ON ph.phase_id = t.phase_id
JOIN projects p ON p.project_id = t.project_id
LEFT JOIN property_rooms r ON r.room_id = t.room_id
JOIN work_types wt ON wt.work_type_id = t.work_type_id
LEFT JOIN contractors ctr ON ctr.contractor_id = t.contractor_id
LEFT JOIN acceptance_acts act ON act.task_id = t.task_id;

CREATE OR REPLACE VIEW v_overdue_tasks AS
SELECT
  t.task_id, t.task_name, t.status AS task_status,
  t.planned_end_date, t.actual_end_date,
  p.project_id, p.project_name, pr.address,
  r.room_name, ctr.name AS contractor_name
FROM project_tasks t
JOIN projects p ON p.project_id = t.project_id
JOIN properties pr ON pr.property_id = p.property_id
LEFT JOIN property_rooms r ON r.room_id = t.room_id
LEFT JOIN contractors ctr ON ctr.contractor_id = t.contractor_id
WHERE t.planned_end_date IS NOT NULL
  AND t.status NOT IN ('completed','cancelled')
  AND t.planned_end_date < CURRENT_DATE;

CREATE OR REPLACE VIEW v_defects_detailed AS
SELECT
  d.defect_id, d.description, d.severity, d.status AS defect_status,
  d.defect_date, d.resolution_date, d.rework_cost,
  t.task_id, t.task_name, t.status AS task_status,
  p.project_id, p.project_name,
  ctr.contractor_id, ctr.name AS contractor_name
FROM defects d
JOIN project_tasks t ON t.task_id = d.task_id
JOIN projects p ON p.project_id = t.project_id
LEFT JOIN contractors ctr ON ctr.contractor_id = d.contractor_id;

CREATE OR REPLACE VIEW v_material_balance_by_project AS
SELECT
  it.project_id, p.project_name,
  it.material_id, m.material_name, m.unit,
  SUM(CASE it.transaction_type
        WHEN 'IN' THEN it.quantity
        WHEN 'OUT' THEN -it.quantity
        WHEN 'ADJUST' THEN it.quantity
        ELSE 0
      END) AS balance_qty
FROM inventory_transactions it
JOIN projects p ON p.project_id = it.project_id
JOIN materials m ON m.material_id = it.material_id
GROUP BY it.project_id, p.project_name, it.material_id, m.material_name, m.unit;

CREATE OR REPLACE VIEW v_purchase_orders_detailed AS
SELECT
  po.po_id, po.po_number, po.status AS po_status,
  po.order_date, po.expected_delivery_date, po.total_amount,
  s.supplier_id, s.supplier_name,
  p.project_id, p.project_name,
  poi.po_item_id,
  m.material_id, m.material_name, m.unit,
  poi.quantity_ordered, poi.delivered_quantity, poi.unit_price, poi.line_total,
  CASE WHEN poi.quantity_ordered=0 THEN 0
       ELSE ROUND(100.0 * poi.delivered_quantity / poi.quantity_ordered, 2)
  END AS delivered_pct
FROM purchase_orders po
JOIN suppliers s ON s.supplier_id = po.supplier_id
JOIN projects p ON p.project_id = po.project_id
LEFT JOIN purchase_order_items poi ON poi.po_id = po.po_id
LEFT JOIN materials m ON m.material_id = poi.material_id;

COMMIT;
