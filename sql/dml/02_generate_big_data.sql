BEGIN;

-- На случай, если кто-то запустит генератор после включения аудита:
SELECT set_config('app.audit_disabled', '1', true);

-- Параметры (можешь менять числа)
DO $$
DECLARE
  v_owners       INT := 200;
  v_contractors  INT := 50;
  v_suppliers    INT := 50;
  v_materials    INT := 200;

  v_projects     INT := 200;
  v_tasks_per_project INT := 8;      -- 200 * 8 = 1600 задач

  v_purchase_orders INT := 500;
  v_items_per_order INT := 3;        -- 1500 позиций

  v_inv_tx       INT := 6000;        -- >= 5000 транзакций
  v_defects      INT := 500;
BEGIN
  -- ===== suppliers =====
  INSERT INTO suppliers(supplier_name, phone, email, address, contact_person)
  SELECT
    format('Поставщик BIG %s', lpad(gs::text, 4, '0')),
    format('+7999%07s', gs),
    format('supplier_big_%s@example.com', gs),
    format('г. Москва, ул. Поставщиков, д.%s', 200 + gs),
    format('Контакт %s', gs)
  FROM generate_series(1, v_suppliers) gs
  ON CONFLICT (supplier_name) DO NOTHING;

  -- ===== materials =====
  INSERT INTO materials(material_name, category, unit, manufacturer, current_price, is_active)
  SELECT
    format('Материал BIG %s', lpad(gs::text, 4, '0')),
    'BIG',
    'pcs',
    format('Завод BIG %s', (gs % 20) + 1),
    (50 + (gs % 200))::numeric,
    true
  FROM generate_series(1, v_materials) gs
  ON CONFLICT (material_name) DO NOTHING;

  -- ===== owners + properties + rooms =====
  CREATE TEMP TABLE tmp_new_props(property_id BIGINT, owner_id BIGINT) ON COMMIT DROP;

  WITH ins_owners AS (
    INSERT INTO owners(full_name, phone, email, preferred_contact, notes)
    SELECT
      format('Владелец BIG %s', lpad(gs::text, 4, '0')),
      format('+7998%07s', gs),
      format('owner_big_%s@example.com', gs),
      'phone',
      'generated'
    FROM generate_series(1, v_owners) gs
    RETURNING owner_id
  ),
  ins_props AS (
    INSERT INTO properties(owner_id, address, property_type, total_area, status, created_at, updated_at)
    SELECT
      o.owner_id,
      format('г. Москва, ул. Генераторная, д.%s, кв.%s', 100 + row_number() over(), row_number() over()),
      'apartment',
      (40 + (random() * 60))::numeric(8,2),
      'active',
      now(),
      now()
    FROM ins_owners o
    RETURNING property_id, owner_id
  )
  INSERT INTO tmp_new_props(property_id, owner_id)
  SELECT property_id, owner_id FROM ins_props;

  -- по 3 комнаты на объект (Кухня/Комната/Санузел)
  INSERT INTO property_rooms(property_id, room_name, room_type, area, ceiling_height, has_window, notes, created_at)
  SELECT
    p.property_id,
    v.room_name,
    v.room_type,
    v.area,
    2.70,
    (v.room_type <> 'bathroom'),
    'generated',
    now()
  FROM tmp_new_props p
  CROSS JOIN (VALUES
    ('Кухня','kitchen', 10.0::numeric),
    ('Комната','bedroom', 18.0::numeric),
    ('Санузел','bathroom', 4.0::numeric)
  ) AS v(room_name, room_type, area);

  -- ===== contractors =====
  INSERT INTO contractors(name, inn, phone, email, specialization, rating, created_at)
  SELECT
    format('Подрядчик BIG %s', lpad(gs::text, 3, '0')),
    ('99' || lpad(gs::text, 10, '0')),
    format('+7997%07s', gs),
    format('contractor_big_%s@example.com', gs),
    'BIG',
    (3.50 + (random() * 1.5))::numeric(3,2),
    now()
  FROM generate_series(1, v_contractors) gs
  ON CONFLICT (inn) DO NOTHING;

  -- ===== projects + phases + tasks =====
  CREATE TEMP TABLE tmp_projects(project_id BIGINT, property_id BIGINT, planned_start DATE, planned_end DATE) ON COMMIT DROP;
  CREATE TEMP TABLE tmp_phases(phase_id BIGINT, project_id BIGINT, phase_order INT) ON COMMIT DROP;
  CREATE TEMP TABLE tmp_tasks(task_id BIGINT, project_id BIGINT) ON COMMIT DROP;

  -- создаём проекты на существующих/новых properties (берём последние property_id)
  WITH props AS (
    SELECT property_id
    FROM properties
    ORDER BY property_id DESC
    LIMIT v_projects
  ),
  stats_ctr AS (
    SELECT MIN(contractor_id) AS min_id, COUNT(*) AS cnt
    FROM contractors
  ),
  ins_contracts AS (
    INSERT INTO contracts(property_id, contractor_id, contract_number, status, total_amount, start_date, end_date, signed_at)
    SELECT
      p.property_id,
      (stats_ctr.min_id + ((row_number() over() - 1) % stats_ctr.cnt))::bigint,
      format('C-BIG-%s', lpad(row_number() over()::text, 6, '0')),
      'active',
      (400000 + (random() * 800000))::numeric(12,2),
      (DATE '2025-01-01' + ((row_number() over()) % 300)),
      (DATE '2025-01-01' + ((row_number() over()) % 300) + (30 + ((row_number() over()) % 90))),
      (DATE '2025-01-01' + ((row_number() over()) % 300))
    FROM props p
    CROSS JOIN stats_ctr
    RETURNING contract_id, property_id
  ),
  ins_projects AS (
    INSERT INTO projects(property_id, contract_id, project_name, status, total_budget, actual_cost, planned_start_date, planned_end_date, created_at)
    SELECT
      c.property_id,
      c.contract_id,
      format('Проект BIG %s', lpad(row_number() over()::text, 6, '0')),
      'active',
      (400000 + (random() * 800000))::numeric(12,2),
      0,
      (DATE '2025-01-01' + ((row_number() over()) % 300)),
      (DATE '2025-01-01' + ((row_number() over()) % 300) + (60 + ((row_number() over()) % 120))),
      now()
    FROM ins_contracts c
    RETURNING project_id, property_id, planned_start_date, planned_end_date
  )
  INSERT INTO tmp_projects(project_id, property_id, planned_start, planned_end)
  SELECT project_id, property_id, planned_start_date, planned_end_date
  FROM ins_projects;

  -- фазы 1..3
  WITH ins_ph AS (
    INSERT INTO project_phases(project_id, phase_name, phase_order, status, planned_start_date, planned_end_date)
    SELECT
      p.project_id,
      CASE v.phase_order
        WHEN 1 THEN 'Подготовка'
        WHEN 2 THEN 'Основные работы'
        ELSE 'Сдача'
      END,
      v.phase_order,
      CASE v.phase_order WHEN 1 THEN 'active' WHEN 2 THEN 'planned' ELSE 'planned' END,
      (p.planned_start + (v.phase_order - 1) * 14),
      (p.planned_start + (v.phase_order) * 14)
    FROM tmp_projects p
    CROSS JOIN (VALUES (1),(2),(3)) AS v(phase_order)
    RETURNING phase_id, project_id, phase_order
  )
  INSERT INTO tmp_phases(phase_id, project_id, phase_order)
  SELECT phase_id, project_id, phase_order FROM ins_ph;

  -- задачи
  WITH wt AS (
    SELECT array_agg(work_type_id ORDER BY work_type_id) AS ids
    FROM work_types
  ),
  ctr AS (
    SELECT array_agg(contractor_id ORDER BY contractor_id) AS ids
    FROM contractors
  ),
  rm AS (
    SELECT property_id, array_agg(room_id ORDER BY room_id) AS room_ids
    FROM property_rooms
    GROUP BY property_id
  ),
  ins_tasks AS (
    INSERT INTO project_tasks(
      project_id, phase_id, room_id, work_type_id, contractor_id,
      task_name, volume, planned_cost, actual_cost, status,
      planned_start_date, planned_end_date, actual_start_date, actual_end_date
    )
    SELECT
      p.project_id,
      ph.phase_id,
      (rm.room_ids)[1 + ((gs_task - 1) % 3)],
      (wt.ids)[1 + ((gs_task - 1) % array_length(wt.ids,1))],
      (ctr.ids)[1 + ((gs_task - 1) % array_length(ctr.ids,1))],
      format('Задача BIG %s/%s', p.project_id, gs_task),
      (1 + (gs_task % 10))::numeric(10,2),
      (1000 + (gs_task % 2000))::numeric(10,2),
      CASE WHEN (gs_task % 5) = 0 THEN 0 ELSE (900 + (gs_task % 2200))::numeric(10,2) END,
      CASE
        WHEN (gs_task % 10) = 0 THEN 'blocked'
        WHEN (gs_task % 4) = 0 THEN 'completed'
        WHEN (gs_task % 3) = 0 THEN 'in_progress'
        ELSE 'planned'
      END,
      (p.planned_start + (gs_task % 20)),
      (p.planned_start + (gs_task % 20) + 3),
      CASE WHEN (gs_task % 3) = 0 THEN (p.planned_start + (gs_task % 20)) ELSE NULL END,
      CASE WHEN (gs_task % 4) = 0 THEN (p.planned_start + (gs_task % 20) + 2) ELSE NULL END
    FROM tmp_projects p
    JOIN tmp_phases ph ON ph.project_id = p.project_id
    JOIN rm ON rm.property_id = p.property_id
    CROSS JOIN wt
    CROSS JOIN ctr
    CROSS JOIN generate_series(1, v_tasks_per_project) gs_task
    WHERE ph.phase_order = (1 + ((gs_task - 1) % 3))
    RETURNING task_id, project_id
  )
  INSERT INTO tmp_tasks(task_id, project_id)
  SELECT task_id, project_id FROM ins_tasks;

  -- ===== purchase_orders + items =====
  WITH pr AS (
    SELECT array_agg(project_id ORDER BY project_id) AS ids FROM projects
  ),
  sp AS (
    SELECT array_agg(supplier_id ORDER BY supplier_id) AS ids FROM suppliers
  ),
  ins_po AS (
    INSERT INTO purchase_orders(project_id, supplier_id, po_number, status, total_amount, order_date, expected_delivery_date, created_at)
    SELECT
      (pr.ids)[1 + ((gs - 1) % array_length(pr.ids,1))],
      (sp.ids)[1 + ((gs - 1) % array_length(sp.ids,1))],
      format('PO-BIG-%s', lpad(gs::text, 6, '0')),
      'ordered',
      0,
      (CURRENT_DATE - (gs % 200)),
      (CURRENT_DATE - (gs % 200) + 7),
      now()
    FROM generate_series(1, v_purchase_orders) gs
    CROSS JOIN pr
    CROSS JOIN sp
    RETURNING po_id
  )
  INSERT INTO purchase_order_items(po_id, material_id, quantity_ordered, unit_price, delivered_quantity, line_total)
  SELECT
    po.po_id,
    (m.ids)[1 + ((po.po_id + gs_item) % array_length(m.ids,1))],
    (1 + (gs_item % 5))::numeric(10,2),
    (50 + ((po.po_id + gs_item) % 200))::numeric(10,2),
    0,
    0
  FROM ins_po po
  CROSS JOIN (SELECT array_agg(material_id ORDER BY material_id) AS ids FROM materials) m
  CROSS JOIN generate_series(1, v_items_per_order) gs_item;

  -- ===== inventory_transactions (>=5000) =====
  WITH pr AS (SELECT array_agg(project_id ORDER BY project_id) AS ids FROM projects),
       mt AS (SELECT array_agg(material_id ORDER BY material_id) AS ids FROM materials),
       tk AS (SELECT array_agg(task_id ORDER BY task_id) AS ids FROM project_tasks)
  INSERT INTO inventory_transactions(
    project_id, material_id, task_id, po_item_id,
    transaction_type, quantity, unit_price, transaction_date, comment
  )
  SELECT
    (pr.ids)[1 + ((gs - 1) % array_length(pr.ids,1))],
    (mt.ids)[1 + ((gs - 1) % array_length(mt.ids,1))],
    CASE
      WHEN (gs % 2) = 0 THEN (tk.ids)[1 + ((gs - 1) % array_length(tk.ids,1))]
      ELSE NULL
    END,
    NULL,
    CASE
      WHEN (gs % 10) = 0 THEN 'ADJUST'
      WHEN (gs % 2) = 0 THEN 'OUT'
      ELSE 'IN'
    END,
    (1 + (gs % 5))::numeric(10,2),
    (50 + (gs % 200))::numeric(10,2),
    (CURRENT_DATE - (gs % 365)),
    'generated'
  FROM generate_series(1, v_inv_tx) gs
  CROSS JOIN pr
  CROSS JOIN mt
  CROSS JOIN tk;

  -- ===== defects =====
  WITH tk AS (
    SELECT array_agg(task_id ORDER BY task_id) AS ids
    FROM project_tasks
  ),
  ctr AS (
    SELECT array_agg(contractor_id ORDER BY contractor_id) AS ids
    FROM contractors
  )
  INSERT INTO defects(task_id, contractor_id, description, severity, status, defect_date, resolution_date, rework_cost)
  SELECT
    (tk.ids)[1 + ((gs - 1) % array_length(tk.ids,1))],
    (ctr.ids)[1 + ((gs - 1) % array_length(ctr.ids,1))],
    format('Дефект BIG %s', gs),
    CASE
      WHEN (gs % 10) = 0 THEN 'critical'
      WHEN (gs % 4) = 0 THEN 'high'
      WHEN (gs % 3) = 0 THEN 'medium'
      ELSE 'low'
    END,
    CASE
      WHEN (gs % 5) = 0 THEN 'resolved'
      WHEN (gs % 7) = 0 THEN 'closed'
      ELSE 'open'
    END,
    (CURRENT_DATE - (gs % 200)),
    CASE WHEN (gs % 5) = 0 THEN (CURRENT_DATE - (gs % 200) + 5) ELSE NULL END,
    (gs % 2000)::numeric(10,2)
  FROM generate_series(1, v_defects) gs
  CROSS JOIN tk
  CROSS JOIN ctr;

END $$;

-- включаем аудит обратно (на будущее)
SELECT set_config('app.audit_disabled', '0', true);

COMMIT;
