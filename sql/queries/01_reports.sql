-- =========================================
-- REPAIR-DB: Запросы для отчётов/аналитики
-- =========================================

-- Q1. Обзор проектов + объект + владелец + подрядчик/договор
SELECT *
FROM v_projects_overview
ORDER BY project_id;

-- Q2. Прогресс проектов по задачам (шт/проценты)
SELECT *
FROM v_project_progress
ORDER BY pct_completed DESC, project_id;

-- Q3. Детальные задачи: комната, этап, тип работ, исполнитель, приёмка
SELECT *
FROM v_tasks_detailed
ORDER BY project_id, phase_order, task_id;

-- Q4. Просроченные задачи (по planned_end_date)
SELECT *
FROM v_overdue_tasks
ORDER BY planned_end_date;

-- Q5. Статистика задач по проекту и статусам
SELECT
  p.project_id,
  p.project_name,
  t.status,
  COUNT(*) AS cnt
FROM projects p
JOIN project_tasks t ON t.project_id = p.project_id
GROUP BY p.project_id, p.project_name, t.status
ORDER BY p.project_id, t.status;

-- Q6. Вариация затрат по задачам (planned vs actual) + отклонение
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

-- Q7. Бюджет проекта: total_budget vs сумма planned_cost задач (контроль планирования)
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

-- Q8. Дефекты: по подрядчикам и статусам
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

-- Q9. Список дефектов детально (с проектом/задачей/подрядчиком)
SELECT *
FROM v_defects_detailed
ORDER BY defect_date DESC, defect_id DESC;

-- Q10. Материалы: баланс по проекту (склад/остаток)
SELECT *
FROM v_material_balance_by_project
ORDER BY project_id, material_id;

-- Q11. Расход материалов по задачам (OUT) + стоимость
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

-- Q12. Закупки: заказы + позиции + % поставки
SELECT *
FROM v_purchase_orders_detailed
ORDER BY po_id, po_item_id;

-- Q13. Заказы с недопоставкой (delivered < ordered)
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

-- Q14. Приёмка: задачи, где акт ещё не принят/не заполнен
SELECT
  t.task_id, t.task_name, t.status AS task_status,
  a.acceptance_date, a.result_status, a.accepted_by, a.comment
FROM project_tasks t
JOIN acceptance_acts a ON a.task_id = t.task_id
WHERE a.result_status IS NULL OR a.acceptance_date IS NULL
ORDER BY t.task_id;

-- Q15. Аудит: последние изменения по сущности project_tasks
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
