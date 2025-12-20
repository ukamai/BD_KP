
SELECT *
FROM v_projects_overview
ORDER BY project_id;

SELECT *
FROM v_project_progress
ORDER BY pct_completed DESC, project_id;

SELECT *
FROM v_tasks_detailed
ORDER BY project_id, phase_order, task_id;

SELECT *
FROM v_overdue_tasks
ORDER BY planned_end_date;

SELECT
  p.project_id,
  p.project_name,
  t.status,
  COUNT(*) AS cnt
FROM projects p
JOIN project_tasks t ON t.project_id = p.project_id
GROUP BY p.project_id, p.project_name, t.status
ORDER BY p.project_id, t.status;

SELECT
  p.project_id,
  p.project_name,
  SUM(t.planned_cost) AS planned_sum,
  SUM(t.actual_cost) AS actual_sum,
  SUM(t.actual_cost) - SUM(t.planned_cost) AS delta_sum
FROM projects p
JOIN project_tasks t ON t.project_id = p.project_id
GROUP BY p.project_id, p.project_name
ORDER BY delta_sum DESC;

SELECT
  p.project_id,
  p.project_name,
  p.total_budget,
  COALESCE(SUM(t.planned_cost), 0) AS tasks_planned_sum,
  p.total_budget - COALESCE(SUM(t.planned_cost), 0) AS remaining_vs_tasks_plan
FROM projects p
LEFT JOIN project_tasks t ON t.project_id = p.project_id
GROUP BY p.project_id, p.project_name, p.total_budget
ORDER BY p.project_id;

SELECT
  c.contractor_id,
  c.name AS contractor_name,
  d.status AS defect_status,
  COUNT(*) AS defects_cnt,
  SUM(d.rework_cost) AS rework_sum
FROM contractors c
LEFT JOIN defects d ON d.contractor_id = c.contractor_id
GROUP BY c.contractor_id, c.name, d.status
ORDER BY defects_cnt DESC, contractor_id;

SELECT *
FROM v_defects_detailed
ORDER BY defect_date DESC, defect_id DESC;

SELECT *
FROM v_material_balance_by_project
ORDER BY project_id, material_id;

SELECT
  t.project_id,
  p.project_name,
  t.task_id,
  t.task_name,
  m.material_id,
  m.material_name,
  SUM(it.quantity) AS qty_out,
  SUM(it.quantity * it.unit_price) AS cost_out
FROM inventory_transactions it
JOIN projects p ON p.project_id = it.project_id
LEFT JOIN project_tasks t ON t.task_id = it.task_id
JOIN materials m ON m.material_id = it.material_id
WHERE it.transaction_type = 'OUT'
GROUP BY t.project_id, p.project_name, t.task_id, t.task_name, m.material_id, m.material_name
ORDER BY cost_out DESC NULLS LAST;

SELECT *
FROM v_purchase_orders_detailed
ORDER BY po_id, po_item_id;

SELECT
  po.po_id,
  po.po_number,
  s.supplier_name,
  p.project_name,
  poi.po_item_id,
  m.material_name,
  poi.quantity_ordered,
  poi.delivered_quantity
FROM purchase_orders po
JOIN suppliers s ON s.supplier_id = po.supplier_id
JOIN projects p ON p.project_id = po.project_id
JOIN purchase_order_items poi ON poi.po_id = po.po_id
JOIN materials m ON m.material_id = poi.material_id
WHERE poi.delivered_quantity < poi.quantity_ordered
ORDER BY po.po_id, poi.po_item_id;

SELECT
  t.task_id, t.task_name, t.status AS task_status,
  a.acceptance_date, a.result_status, a.accepted_by, a.comment
FROM project_tasks t
JOIN acceptance_acts a ON a.task_id = t.task_id
WHERE a.result_status IS NULL OR a.acceptance_date IS NULL
ORDER BY t.task_id;

SELECT
  action_timestamp,
  user_id,
  entity_type,
  entity_id,
  action_type,
  old_values,
  new_values
FROM audit_log
WHERE entity_type = 'project_tasks'
ORDER BY action_timestamp DESC
LIMIT 50;

SELECT
  p.project_id,
  p.project_name,
  p.total_budget,
  fn_project_total_spent(p.project_id) AS total_spent,
  (p.total_budget - fn_project_total_spent(p.project_id)) AS budget_delta
FROM projects p
ORDER BY p.project_id;

SELECT *
FROM fn_report_projects(NULL, NULL, NULL);

SELECT *
FROM fn_report_projects('active', NULL, NULL);