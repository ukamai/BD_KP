-- EXPLAIN без наших индексов
-- (Убедись, что перед этим выполнен 01_drop_indexes.sql)
ANALYZE;

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM project_tasks
WHERE project_id = 1 AND status = 'in_progress';

EXPLAIN (ANALYZE, BUFFERS)
SELECT *
FROM inventory_transactions
WHERE project_id = 1 AND material_id = 1
ORDER BY transaction_date DESC
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS)
SELECT d.*
FROM defects d
WHERE d.contractor_id = 1 AND d.status = 'open'
ORDER BY d.defect_date DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT po.*
FROM purchase_orders po
WHERE po.status = 'ordered'
ORDER BY po.order_date DESC;

EXPLAIN (ANALYZE, BUFFERS)
SELECT a.*
FROM audit_log a
WHERE a.entity_type='project_tasks' AND a.entity_id=1
ORDER BY a.action_timestamp DESC
LIMIT 50;

EXPLAIN (ANALYZE, BUFFERS)
SELECT
  p.project_id,
  p.project_name,
  COUNT(t.task_id) AS tasks_total
FROM projects p
LEFT JOIN project_tasks t ON t.project_id = p.project_id
GROUP BY p.project_id, p.project_name
ORDER BY p.project_id;
