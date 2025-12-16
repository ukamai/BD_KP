BEGIN;

-- СКАЛЯРНАЯ ФУНКЦИЯ:
-- “Сколько всего потрачено по проекту” = actual_cost задач + стоимость OUT материалов + стоимость переделок (defects.rework_cost)
CREATE OR REPLACE FUNCTION fn_project_total_spent(p_project_id BIGINT)
RETURNS NUMERIC(14,2)
LANGUAGE sql
STABLE
AS $$
  SELECT
    ROUND((
      COALESCE((SELECT SUM(t.actual_cost) FROM project_tasks t WHERE t.project_id = p_project_id), 0)
      +
      COALESCE((
        SELECT SUM(it.quantity * it.unit_price)
        FROM inventory_transactions it
        WHERE it.project_id = p_project_id AND it.transaction_type = 'OUT'
      ), 0)
      +
      COALESCE((
        SELECT SUM(d.rework_cost)
        FROM defects d
        JOIN project_tasks t ON t.task_id = d.task_id
        WHERE t.project_id = p_project_id
      ), 0)
    )::numeric, 2);
$$;


-- ТАБЛИЧНАЯ ФУНКЦИЯ (отчёт):
-- Возвращает агрегаты по проектам с фильтрами.
CREATE OR REPLACE FUNCTION fn_report_projects(
  p_status    TEXT DEFAULT NULL,
  p_date_from DATE DEFAULT NULL,
  p_date_to   DATE DEFAULT NULL
)
RETURNS TABLE (
  project_id       BIGINT,
  project_name     TEXT,
  status           TEXT,
  planned_start    DATE,
  planned_end      DATE,
  total_budget     NUMERIC(12,2),

  tasks_total      BIGINT,
  tasks_completed  BIGINT,
  pct_completed    NUMERIC(6,2),

  tasks_actual_sum NUMERIC(14,2),
  materials_out_sum NUMERIC(14,2),
  defects_cnt      BIGINT,
  rework_sum       NUMERIC(14,2),

  total_spent      NUMERIC(14,2),
  budget_delta     NUMERIC(14,2)
)
LANGUAGE sql
STABLE
AS $$
  WITH base AS (
    SELECT p.*
    FROM projects p
    WHERE (p_status IS NULL OR p.status = p_status)
      AND (p_date_from IS NULL OR p.planned_start_date IS NULL OR p.planned_start_date >= p_date_from)
      AND (p_date_to IS NULL OR p.planned_end_date IS NULL OR p.planned_end_date <= p_date_to)
  ),
  t AS (
    SELECT
      project_id,
      COUNT(*) AS tasks_total,
      COUNT(*) FILTER (WHERE status = 'completed') AS tasks_completed,
      COALESCE(SUM(actual_cost), 0)::numeric(14,2) AS tasks_actual_sum
    FROM project_tasks
    GROUP BY project_id
  ),
  m AS (
    SELECT
      project_id,
      COALESCE(SUM(quantity * unit_price) FILTER (WHERE transaction_type = 'OUT'), 0)::numeric(14,2) AS materials_out_sum
    FROM inventory_transactions
    GROUP BY project_id
  ),
  d AS (
    SELECT
      t.project_id,
      COUNT(*) AS defects_cnt,
      COALESCE(SUM(d.rework_cost), 0)::numeric(14,2) AS rework_sum
    FROM defects d
    JOIN project_tasks t ON t.task_id = d.task_id
    GROUP BY t.project_id
  )
  SELECT
    b.project_id,
    b.project_name::text,
    b.status::text,
    b.planned_start_date,
    b.planned_end_date,
    b.total_budget,

    COALESCE(t.tasks_total, 0) AS tasks_total,
    COALESCE(t.tasks_completed, 0) AS tasks_completed,
    CASE WHEN COALESCE(t.tasks_total, 0) = 0 THEN 0
         ELSE ROUND(100.0 * COALESCE(t.tasks_completed, 0) / COALESCE(t.tasks_total, 0), 2)
    END AS pct_completed,

    COALESCE(t.tasks_actual_sum, 0)::numeric(14,2) AS tasks_actual_sum,
    COALESCE(m.materials_out_sum, 0)::numeric(14,2) AS materials_out_sum,
    COALESCE(d.defects_cnt, 0) AS defects_cnt,
    COALESCE(d.rework_sum, 0)::numeric(14,2) AS rework_sum,

    fn_project_total_spent(b.project_id) AS total_spent,
    ROUND((b.total_budget - fn_project_total_spent(b.project_id))::numeric, 2) AS budget_delta
  FROM base b
  LEFT JOIN t ON t.project_id = b.project_id
  LEFT JOIN m ON m.project_id = b.project_id
  LEFT JOIN d ON d.project_id = b.project_id
  ORDER BY b.project_id;
$$;

COMMIT;
