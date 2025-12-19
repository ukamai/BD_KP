BEGIN;

SELECT set_config('app.audit_disabled', '1', true);

DO $$
DECLARE
  t_users           INT := 500;
  t_work_types      INT := 100;
  t_contractors     INT := 500;
  t_suppliers       INT := 500;
  t_materials       INT := 800;

  t_projects         INT := 500;   
  t_rooms            INT := 1000;  

  t_phases           INT := 1000;  
  t_tasks            INT := 1000;  
  t_acceptance_acts  INT := 700;   
  t_defects          INT := 800;   

  t_purchase_orders  INT := 800;   
  t_inventory_tx     INT := 8000;  

  v_add_users        INT;
  v_add_work_types   INT;
  v_add_contractors  INT;
  v_add_suppliers    INT;
  v_add_materials    INT;

  v_add_projects     INT;
  v_add_rooms        INT;
  v_extra_rooms      INT;

  v_add_phases       INT;
  v_add_phase2       INT;

  v_add_tasks        INT;
  v_add_task2        INT;

  v_add_acceptance   INT;
  v_add_defects      INT;

  v_add_po           INT;
  v_items_per_order  INT := 7;

  v_add_inv_tx       INT;

  v_po_offset        BIGINT;

BEGIN
  v_add_users       := GREATEST(t_users      - (SELECT COUNT(*) FROM users), 0);
  v_add_work_types  := GREATEST(t_work_types - (SELECT COUNT(*) FROM work_types), 0);
  v_add_contractors := GREATEST(t_contractors- (SELECT COUNT(*) FROM contractors), 0);
  v_add_suppliers   := GREATEST(t_suppliers  - (SELECT COUNT(*) FROM suppliers), 0);
  v_add_materials   := GREATEST(t_materials  - (SELECT COUNT(*) FROM materials), 0);

  v_add_projects := GREATEST(t_projects - (SELECT COUNT(*) FROM projects), 0);

  v_add_rooms := GREATEST(t_rooms - (SELECT COUNT(*) FROM property_rooms), 0);
  v_extra_rooms := GREATEST(v_add_rooms - v_add_projects, 0);

  v_add_phases := GREATEST(t_phases - (SELECT COUNT(*) FROM project_phases), 0);
  v_add_phase2 := GREATEST(v_add_phases - v_add_projects, 0);

  v_add_tasks := GREATEST(t_tasks - (SELECT COUNT(*) FROM project_tasks), 0);
  v_add_task2 := GREATEST(v_add_tasks - v_add_projects, 0);

  v_add_acceptance := GREATEST(t_acceptance_acts - (SELECT COUNT(*) FROM acceptance_acts), 0);
  v_add_defects    := GREATEST(t_defects - (SELECT COUNT(*) FROM defects), 0);

  v_add_po     := GREATEST(t_purchase_orders - (SELECT COUNT(*) FROM purchase_orders), 0);
  v_add_inv_tx := GREATEST(t_inventory_tx    - (SELECT COUNT(*) FROM inventory_transactions), 0);

  IF v_add_users > 0 THEN
    INSERT INTO users (username, full_name, email, role, is_active)
    SELECT
      'user_big_' || lpad(gs::text, 4, '0'),
      'User BIG ' || gs,
      'user_big_' || lpad(gs::text, 4, '0') || '@example.com',
      CASE WHEN gs % 10 = 0 THEN 'inspector'
           WHEN gs % 3  = 0 THEN 'manager'
           ELSE 'user' END,
      TRUE
    FROM generate_series(1, v_add_users) gs;
  END IF;

  IF v_add_work_types > 0 THEN
    INSERT INTO work_types (work_type_name, category, default_unit, standard_rate, is_active, description)
    SELECT
      'Работа BIG ' || lpad(gs::text, 3, '0'),
      CASE WHEN gs % 4 = 0 THEN 'Электрика'
           WHEN gs % 4 = 1 THEN 'Сантехника'
           WHEN gs % 4 = 2 THEN 'Отделка'
           ELSE 'Демонтаж' END,
      CASE WHEN gs % 2 = 0 THEN 'pcs' ELSE 'm2' END,
      (500 + (gs % 50) * 20)::numeric(10,2),
      TRUE,
      'generated'
    FROM generate_series(1, v_add_work_types) gs
    ON CONFLICT (work_type_name) DO NOTHING;
  END IF;

  IF v_add_suppliers > 0 THEN
    INSERT INTO suppliers (supplier_name, phone, email, address, contact_person)
    SELECT
      'Поставщик BIG ' || lpad(gs::text, 5, '0'),
      '+7999' || lpad(gs::text, 7, '0'),
      'supplier_big_' || lpad(gs::text, 5, '0') || '@example.com',
      'г. Москва, ул. Складская, д.' || (10 + (gs % 200)),
      'Контакт ' || gs
    FROM generate_series(1, v_add_suppliers) gs
    ON CONFLICT (supplier_name) DO NOTHING;
  END IF;

  IF v_add_materials > 0 THEN
    INSERT INTO materials (material_name, category, unit, manufacturer, current_price, is_active)
    SELECT
      'Материал BIG ' || lpad(gs::text, 5, '0'),
      CASE WHEN gs % 5 = 0 THEN 'ЛКМ'
           WHEN gs % 5 = 1 THEN 'Электрика'
           WHEN gs % 5 = 2 THEN 'Сантехника'
           WHEN gs % 5 = 3 THEN 'Сухие смеси'
           ELSE 'Плитка' END,
      CASE WHEN gs % 3 = 0 THEN 'kg'
           WHEN gs % 3 = 1 THEN 'pcs'
           ELSE 'm' END,
      'Завод ' || (1 + (gs % 50)),
      (50 + (gs % 300) * 3)::numeric(10,2),
      TRUE
    FROM generate_series(1, v_add_materials) gs
    ON CONFLICT (material_name) DO NOTHING;
  END IF;

  IF v_add_contractors > 0 THEN
    INSERT INTO contractors (name, inn, phone, email, specialization, rating)
    SELECT
      'Подрядчик BIG ' || lpad(gs::text, 5, '0'),
      '88' || lpad(gs::text, 10, '0'),  
      '+7998' || lpad(gs::text, 7, '0'),
      'contractor_big_' || lpad(gs::text, 5, '0') || '@example.com',
      CASE WHEN gs % 4 = 0 THEN 'Электрика'
           WHEN gs % 4 = 1 THEN 'Сантехника'
           WHEN gs % 4 = 2 THEN 'Отделка'
           ELSE 'Универсал' END,
      (3.5 + ((gs % 15)::numeric / 10))::numeric(3,2)
    FROM generate_series(1, v_add_contractors) gs;
  END IF;

  IF v_add_projects > 0 THEN
    CREATE TEMP TABLE tmp_new_properties (
      property_id BIGINT,
      rn INT
    ) ON COMMIT DROP;

    CREATE TEMP TABLE tmp_new_projects (
      project_id BIGINT,
      property_id BIGINT,
      rn INT,
      planned_start DATE,
      planned_end DATE
    ) ON COMMIT DROP;

    CREATE TEMP TABLE tmp_new_phases (
      phase_id BIGINT,
      project_id BIGINT,
      phase_order INT
    ) ON COMMIT DROP;

    CREATE TEMP TABLE tmp_new_tasks (
      task_id BIGINT,
      project_id BIGINT
    ) ON COMMIT DROP;

    WITH ins_owners AS (
      INSERT INTO owners (full_name, phone, email, preferred_contact, notes)
      SELECT
        'Владелец BIG ' || lpad(gs::text, 5, '0'),
        '+7997' || lpad(gs::text, 7, '0'),
        'owner_big_' || lpad(gs::text, 5, '0') || '@example.com',
        CASE WHEN gs % 2 = 0 THEN 'phone' ELSE 'email' END,
        'generated'
      FROM generate_series(1, v_add_projects) gs
      RETURNING owner_id
    ),
    ins_props AS (
      INSERT INTO properties (owner_id, address, property_type, total_area, status)
      SELECT
        o.owner_id,
        'г. Москва, ул. Генераторная, д.' || (200 + (row_number() OVER())) || ', кв.' || (100 + (row_number() OVER())),
        'apartment',
        (35 + (random() * 80))::numeric(8,2),
        'active'
      FROM ins_owners o
      RETURNING property_id
    )
    INSERT INTO tmp_new_properties(property_id, rn)
    SELECT property_id, row_number() OVER () FROM ins_props;

    INSERT INTO property_rooms (property_id, room_name, room_type, area, ceiling_height, has_window, notes)
    SELECT
      p.property_id,
      'Кухня',
      'kitchen',
      (8 + (random() * 6))::numeric(8,2),
      2.70,
      TRUE,
      'generated'
    FROM tmp_new_properties p;

    IF v_extra_rooms > 0 THEN
      INSERT INTO property_rooms (property_id, room_name, room_type, area, ceiling_height, has_window, notes)
      SELECT
        p.property_id,
        'Комната',
        'bedroom',
        (14 + (random() * 12))::numeric(8,2),
        2.70,
        TRUE,
        'generated'
      FROM tmp_new_properties p
      WHERE p.rn <= v_extra_rooms;
    END IF;

    WITH ctr_stats AS (
  SELECT MIN(contractor_id) AS min_id, COUNT(*) AS cnt FROM contractors
),
ins_contracts AS (
  INSERT INTO contracts (
    property_id, contractor_id, contract_number, status, total_amount,
    start_date, end_date, signed_at
  )
  SELECT
    p.property_id,
    (cs.min_id + ((p.rn - 1) % cs.cnt))::bigint,
    'C-BIG-' || lpad(p.rn::text, 6, '0'),
    'active',
    (300000 + (random() * 1200000))::numeric(12,2),
    (CURRENT_DATE - (p.rn % 180)::int),
    (CURRENT_DATE - (p.rn % 180)::int + (30 + (p.rn % 120))::int),
    (CURRENT_DATE - (p.rn % 180)::int)
  FROM tmp_new_properties p
  CROSS JOIN ctr_stats cs
  RETURNING contract_id, property_id
),
ins_projects AS (
  INSERT INTO projects (
    property_id, contract_id, project_name, status, total_budget, actual_cost,
    planned_start_date, planned_end_date
  )
  SELECT
    c.property_id,
    c.contract_id,
    'Проект BIG ' || lpad((row_number() OVER())::text, 6, '0'),
    'active',
    (300000 + (random() * 1200000))::numeric(12,2),
    0,
    (CURRENT_DATE - ((row_number() OVER()) % 180)::int),
    (CURRENT_DATE - ((row_number() OVER()) % 180)::int + (60 + ((row_number() OVER()) % 180))::int)
  FROM ins_contracts c
  RETURNING project_id, property_id, planned_start_date, planned_end_date
)
INSERT INTO tmp_new_projects(project_id, property_id, rn, planned_start, planned_end)
SELECT
  project_id,
  property_id,
  row_number() OVER(),
  planned_start_date,
  planned_end_date
FROM ins_projects;


    CREATE TEMP TABLE _ph1 (phase_id BIGINT, project_id BIGINT, phase_order INT) ON COMMIT DROP;

    WITH ins AS (
      INSERT INTO project_phases (project_id, phase_name, phase_order, status, planned_start_date, planned_end_date)
      SELECT
        p.project_id,
        'Подготовка',
        1,
        'active',
        p.planned_start,
        p.planned_start + 14
      FROM tmp_new_projects p
      RETURNING phase_id, project_id, phase_order
    )
    INSERT INTO _ph1
    SELECT phase_id, project_id, phase_order FROM ins;

    INSERT INTO tmp_new_phases(phase_id, project_id, phase_order)
    SELECT phase_id, project_id, phase_order FROM _ph1;

    IF v_add_phase2 > 0 THEN
      CREATE TEMP TABLE _ph2 (phase_id BIGINT, project_id BIGINT, phase_order INT) ON COMMIT DROP;

      WITH ins AS (
        INSERT INTO project_phases (project_id, phase_name, phase_order, status, planned_start_date, planned_end_date)
        SELECT
          p.project_id,
          'Основные работы',
          2,
          'planned',
          p.planned_start + 15,
          LEAST(p.planned_end, p.planned_start + 45)
        FROM tmp_new_projects p
        WHERE p.rn <= v_add_phase2
        RETURNING phase_id, project_id, phase_order
      )
      INSERT INTO _ph2
      SELECT phase_id, project_id, phase_order FROM ins;

      INSERT INTO tmp_new_phases(phase_id, project_id, phase_order)
      SELECT phase_id, project_id, phase_order FROM _ph2;

      DROP TABLE IF EXISTS _ph2;
    END IF;

    DROP TABLE IF EXISTS _ph1;

    WITH wt AS (
      SELECT array_agg(work_type_id ORDER BY work_type_id) AS ids FROM work_types
    ),
    ctr AS (
      SELECT array_agg(contractor_id ORDER BY contractor_id) AS ids FROM contractors
    ),
    rm AS (
      SELECT property_id, array_agg(room_id ORDER BY room_id) AS room_ids
      FROM property_rooms
      GROUP BY property_id
    ),
    ph1 AS (
      SELECT project_id, phase_id FROM tmp_new_phases WHERE phase_order = 1
    ),
    ins_t1 AS (
      INSERT INTO project_tasks (
        project_id, phase_id, room_id, work_type_id, contractor_id,
        task_name, volume, planned_cost, actual_cost, status,
        planned_start_date, planned_end_date, actual_start_date, actual_end_date
      )
      SELECT
        p.project_id,
        ph1.phase_id,
        (rm.room_ids)[1],
        (wt.ids)[1 + ((p.rn - 1) % array_length(wt.ids, 1))],
        (ctr.ids)[1 + ((p.rn - 1) % array_length(ctr.ids, 1))],
        'Задача BIG ' || p.project_id || '-1',
        (5 + (random() * 20))::numeric(10,2),
        (10000 + (random() * 40000))::numeric(10,2),
        0,
        'planned',
        p.planned_start + (p.rn % 10),
        p.planned_start + (p.rn % 10) + 3,
        NULL,
        NULL
      FROM tmp_new_projects p
      JOIN ph1 ON ph1.project_id = p.project_id
      JOIN rm  ON rm.property_id  = p.property_id
      CROSS JOIN wt
      CROSS JOIN ctr
      RETURNING task_id, project_id
    )
    INSERT INTO tmp_new_tasks(task_id, project_id)
    SELECT task_id, project_id FROM ins_t1;

    IF v_add_task2 > 0 THEN
      WITH wt AS (
        SELECT array_agg(work_type_id ORDER BY work_type_id) AS ids FROM work_types
      ),
      ctr AS (
        SELECT array_agg(contractor_id ORDER BY contractor_id) AS ids FROM contractors
      ),
      rm AS (
        SELECT property_id, array_agg(room_id ORDER BY room_id) AS room_ids
        FROM property_rooms
        GROUP BY property_id
      ),
      ph2 AS (
        SELECT project_id, phase_id FROM tmp_new_phases WHERE phase_order = 2
      ),
      ins_t2 AS (
        INSERT INTO project_tasks (
          project_id, phase_id, room_id, work_type_id, contractor_id,
          task_name, volume, planned_cost, actual_cost, status,
          planned_start_date, planned_end_date, actual_start_date, actual_end_date
        )
        SELECT
          p.project_id,
          ph2.phase_id,
          (rm.room_ids)[2],
          (wt.ids)[1 + ((p.rn) % array_length(wt.ids, 1))],
          (ctr.ids)[1 + ((p.rn) % array_length(ctr.ids, 1))],
          'Задача BIG ' || p.project_id || '-2',
          (5 + (random() * 20))::numeric(10,2),
          (10000 + (random() * 40000))::numeric(10,2),
          0,
          'planned',
          p.planned_start + 15 + (p.rn % 10),
          p.planned_start + 15 + (p.rn % 10) + 5,
          NULL,
          NULL
        FROM tmp_new_projects p
        JOIN ph2 ON ph2.project_id = p.project_id
        JOIN rm  ON rm.property_id  = p.property_id
        CROSS JOIN wt
        CROSS JOIN ctr
        WHERE p.rn <= v_add_task2
        RETURNING task_id, project_id
      )
      INSERT INTO tmp_new_tasks(task_id, project_id)
      SELECT task_id, project_id FROM ins_t2;
    END IF;

  END IF; 

  IF v_add_acceptance > 0 THEN
  INSERT INTO acceptance_acts (task_id, acceptance_date, accepted_by, result_status, comment)
  SELECT
    t.task_id,
    CASE WHEN (row_number() OVER()) % 3 = 0
         THEN (CURRENT_DATE - ((row_number() OVER()) % 30)::int)
         ELSE NULL
    END,
    CASE WHEN (row_number() OVER()) % 3 = 0 THEN 'Инспектор ОТК' ELSE NULL END,
    CASE WHEN (row_number() OVER()) % 3 = 0 THEN 'accepted' ELSE NULL END,
    'generated'
  FROM (
    SELECT pt.task_id
    FROM project_tasks pt
    LEFT JOIN acceptance_acts aa ON aa.task_id = pt.task_id
    WHERE aa.task_id IS NULL
    ORDER BY pt.task_id
    LIMIT v_add_acceptance
  ) t;
END IF;

  IF v_add_po > 0 THEN
    v_po_offset := COALESCE((SELECT MAX(po_id) FROM purchase_orders), 0);

    CREATE TEMP TABLE tmp_new_po (po_id BIGINT) ON COMMIT DROP;

    WITH pr AS (SELECT array_agg(project_id ORDER BY project_id) AS ids FROM projects),
         sp AS (SELECT array_agg(supplier_id ORDER BY supplier_id) AS ids FROM suppliers),
         ins_po AS (
           INSERT INTO purchase_orders (
             project_id, supplier_id, po_number, status, total_amount, order_date, expected_delivery_date
           )
           SELECT
             (pr.ids)[1 + ((gs - 1) % array_length(pr.ids, 1))],
             (sp.ids)[1 + ((gs - 1) % array_length(sp.ids, 1))],
             'PO-BIG-' || lpad((v_po_offset + gs)::text, 6, '0'),
             CASE WHEN gs % 10 = 0 THEN 'draft'
                  WHEN gs % 5  = 0 THEN 'delivered'
                  ELSE 'ordered' END,
             0,
             (CURRENT_DATE - (gs % 120)),
             (CURRENT_DATE - (gs % 120) + (3 + (gs % 14)))
           FROM generate_series(1, v_add_po) gs
           CROSS JOIN pr
           CROSS JOIN sp
           RETURNING po_id
         )
    INSERT INTO tmp_new_po(po_id)
    SELECT po_id FROM ins_po;

    WITH m AS (SELECT array_agg(material_id ORDER BY material_id) AS ids FROM materials)
    INSERT INTO purchase_order_items (po_id, material_id, quantity_ordered, unit_price, delivered_quantity, line_total)
    SELECT
      po.po_id,
      (m.ids)[1 + (((row_number() OVER (PARTITION BY po.po_id ORDER BY gs_item) - 1) + (po.po_id % 1000)) % array_length(m.ids, 1))],
      (1 + (gs_item % 20))::numeric(10,2),
      (50 + (gs_item % 300) * 3)::numeric(10,2),
      CASE WHEN (po.po_id % 5) = 0 THEN (1 + (gs_item % 20))::numeric(10,2)
           WHEN (po.po_id % 7) = 0 THEN ((1 + (gs_item % 20)) / 2)::numeric(10,2)
           ELSE 0 END,
      0
    FROM tmp_new_po po
    CROSS JOIN generate_series(1, v_items_per_order) gs_item
    CROSS JOIN m;
  END IF;

  IF v_add_inv_tx > 0 THEN
    WITH pr AS (SELECT array_agg(project_id ORDER BY project_id) AS ids FROM projects),
         m  AS (SELECT array_agg(material_id ORDER BY material_id) AS ids FROM materials),
         t  AS (SELECT array_agg(task_id ORDER BY task_id) AS ids FROM project_tasks),
         poi AS (SELECT array_agg(po_item_id ORDER BY po_item_id) AS ids FROM purchase_order_items)
    INSERT INTO inventory_transactions (
      project_id, material_id, task_id, po_item_id, transaction_type,
      quantity, unit_price, transaction_date, comment
    )
    SELECT
      (pr.ids)[1 + ((gs - 1) % array_length(pr.ids, 1))],
      (m.ids)[1 + ((gs - 1) % array_length(m.ids, 1))],
      CASE WHEN (gs % 2) = 0 THEN (t.ids)[1 + ((gs - 1) % array_length(t.ids, 1))] ELSE NULL END,
      CASE WHEN (gs % 2) = 1 THEN (poi.ids)[1 + ((gs - 1) % array_length(poi.ids, 1))] ELSE NULL END,
      CASE WHEN (gs % 10) = 0 THEN 'ADJUST'
           WHEN (gs % 2)  = 0 THEN 'OUT'
           ELSE 'IN' END,
      (1 + (gs % 25))::numeric(10,2),
      (30 + (gs % 500) * 2)::numeric(10,2),
      (CURRENT_DATE - (gs % 365)),
      'generated'
    FROM generate_series(1, v_add_inv_tx) gs
    CROSS JOIN pr CROSS JOIN m CROSS JOIN t CROSS JOIN poi;
  END IF;

  IF v_add_defects > 0 THEN
    WITH t AS (SELECT array_agg(task_id ORDER BY task_id) AS ids FROM project_tasks),
         c AS (SELECT array_agg(contractor_id ORDER BY contractor_id) AS ids FROM contractors)
    INSERT INTO defects (
      task_id, contractor_id, description, severity, status, defect_date, resolution_date, rework_cost
    )
    SELECT
      (t.ids)[1 + ((gs - 1) % array_length(t.ids, 1))],
      (c.ids)[1 + ((gs - 1) % array_length(c.ids, 1))],
      'Дефект BIG ' || gs,
      CASE WHEN gs % 4 = 0 THEN 'critical'
           WHEN gs % 4 = 1 THEN 'high'
           WHEN gs % 4 = 2 THEN 'medium'
           ELSE 'low' END,
      CASE WHEN gs % 4 = 0 THEN 'open'
           WHEN gs % 4 = 1 THEN 'in_progress'
           WHEN gs % 4 = 2 THEN 'resolved'
           ELSE 'closed' END,
      (CURRENT_DATE - (gs % 180)),
      CASE WHEN gs % 4 IN (2,3) THEN (CURRENT_DATE - (gs % 180) + (1 + (gs % 20))) ELSE NULL END,
      (1000 + (gs % 200) * 50)::numeric(10,2)
    FROM generate_series(1, v_add_defects) gs
    CROSS JOIN t
    CROSS JOIN c;
  END IF;

END $$;

SELECT set_config('app.audit_disabled', '0', true);

COMMIT;
