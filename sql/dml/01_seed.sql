BEGIN;

TRUNCATE
  audit_log,
  defects,
  inventory_transactions,
  purchase_order_items,
  purchase_orders,
  suppliers,
  materials,
  acceptance_acts,
  project_tasks,
  work_types,
  project_phases,
  projects,
  contracts,
  contractors,
  property_rooms,
  properties,
  owners,
  users
RESTART IDENTITY CASCADE;

-- ======================
-- USERS
-- ======================
INSERT INTO users (username, full_name, email, role)
VALUES
  ('admin',   'Admin User',       'admin@example.com', 'admin'),
  ('manager', 'Project Manager',  'pm@example.com',    'manager'),
  ('inspector','Quality Inspector','qc@example.com',   'inspector');

-- ======================
-- OWNERS + PROPERTIES + ROOMS (2 объекта)
-- ======================
INSERT INTO owners (full_name, phone, email, preferred_contact, notes)
VALUES
  ('Иванов Иван Иванович', '+79990000001', 'ivanov@example.com', 'phone', 'Ключи у консьержа'),
  ('Петрова Анна Сергеевна', '+79990000004', 'petrova@example.com', 'email', 'Просьба писать в WhatsApp');

INSERT INTO properties (owner_id, address, property_type, total_area, status)
VALUES
(
  (SELECT owner_id FROM owners WHERE email='ivanov@example.com'),
  'г. Москва, ул. Примерная, д. 10, кв. 5',
  'apartment',
  54.30,
  'active'
),
(
  (SELECT owner_id FROM owners WHERE email='petrova@example.com'),
  'г. Москва, пр-т Новаторов, д. 3, кв. 18',
  'apartment',
  61.80,
  'active'
);

-- комнаты для 1-го объекта
INSERT INTO property_rooms (property_id, room_name, room_type, area, ceiling_height, has_window, notes)
VALUES
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%'),
  'Кухня', 'kitchen', 10.20, 2.70, TRUE, 'Фартук + розетки'
),
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%'),
  'Комната', 'bedroom', 18.50, 2.70, TRUE, NULL
),
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%'),
  'Санузел', 'bathroom', 4.30, 2.55, FALSE, 'Гидроизоляция обязательна'
);

-- комнаты для 2-го объекта
INSERT INTO property_rooms (property_id, room_name, room_type, area, ceiling_height, has_window, notes)
VALUES
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%'),
  'Кухня', 'kitchen', 11.10, 2.70, TRUE, NULL
),
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%'),
  'Гостиная', 'living_room', 20.40, 2.70, TRUE, NULL
),
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%'),
  'Коридор', 'hallway', 6.20, 2.70, FALSE, NULL
);

-- ======================
-- CONTRACTORS + CONTRACTS (2 подрядчика / 2 договора)
-- ======================
INSERT INTO contractors (name, inn, phone, email, specialization, rating)
VALUES
  ('ООО "РемонтПрофи"',  '770123456789', '+79990000002', 'remontprofi@example.com', 'Отделка/плитка', 4.70),
  ('ИП Сидоров А.А.',    '500987654321', '+79990000005', 'sidorov@example.com',     'Электрика/сантехника', 4.40);

INSERT INTO contracts (property_id, contractor_id, contract_number, status, total_amount, start_date, end_date, signed_at)
VALUES
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'C-2025-0001',
  'active',
  900000.00,
  DATE '2025-12-01',
  DATE '2026-02-15',
  DATE '2025-12-01'
),
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%'),
  (SELECT contractor_id FROM contractors WHERE inn='500987654321'),
  'C-2025-0002',
  'active',
  650000.00,
  DATE '2025-11-20',
  DATE '2026-01-30',
  DATE '2025-11-20'
);

-- ======================
-- PROJECTS + PHASES (2 проекта)
-- ======================
INSERT INTO projects (property_id, contract_id, project_name, status, total_budget, actual_cost, planned_start_date, planned_end_date)
VALUES
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%'),
  (SELECT contract_id FROM contracts WHERE contract_number='C-2025-0001'),
  'Ремонт квартиры (ул. Примерная)',
  'active',
  900000.00,
  0.00,
  DATE '2025-12-01',
  DATE '2026-02-15'
),
(
  (SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%'),
  (SELECT contract_id FROM contracts WHERE contract_number='C-2025-0002'),
  'Ремонт квартиры (пр-т Новаторов)',
  'active',
  650000.00,
  0.00,
  DATE '2025-11-20',
  DATE '2026-01-30'
);

-- фазы проекта 1
INSERT INTO project_phases (project_id, phase_name, phase_order, status, planned_start_date, planned_end_date)
VALUES
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  'Черновые работы', 1, 'active', DATE '2025-12-01', DATE '2025-12-20'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  'Чистовая отделка', 2, 'planned', DATE '2025-12-21', DATE '2026-02-15'
);

-- фазы проекта 2
INSERT INTO project_phases (project_id, phase_name, phase_order, status, planned_start_date, planned_end_date)
VALUES
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  'Подготовка', 1, 'completed', DATE '2025-11-20', DATE '2025-11-30'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  'Основные работы', 2, 'active', DATE '2025-12-01', DATE '2026-01-10'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  'Сдача', 3, 'planned', DATE '2026-01-11', DATE '2026-01-30'
);

-- ======================
-- WORK TYPES
-- ======================
INSERT INTO work_types (work_type_name, category, default_unit, standard_rate, is_active, description)
VALUES
  ('Демонтаж',        'Подготовительные', 'm2',  350.00, TRUE, NULL),
  ('Штукатурка стен', 'Черновые',         'm2',  650.00, TRUE, NULL),
  ('Укладка плитки',  'Отделочные',       'm2', 1800.00, TRUE, 'Керамическая плитка'),
  ('Покраска стен',   'Отделочные',       'm2',  450.00, TRUE, NULL),
  ('Электромонтаж',   'Инженерные',       'pcs', 900.00, TRUE, 'Розетки/выводы'),
  ('Сантехника',      'Инженерные',       'pcs', 1200.00, TRUE, NULL);

-- ======================
-- TASKS (14 задач, разный статус, есть просрочка)
-- ======================

-- Проект 1: Примерная
INSERT INTO project_tasks (
  project_id, phase_id, room_id, work_type_id, contractor_id,
  task_name, volume, planned_cost, actual_cost, status,
  planned_start_date, planned_end_date, actual_start_date, actual_end_date
)
VALUES
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)') AND phase_name='Черновые работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Кухня' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Демонтаж'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Демонтаж кухни',
  10.20, 3600.00, 3800.00, 'completed',
  DATE '2025-12-02', DATE '2025-12-03', DATE '2025-12-02', DATE '2025-12-03'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)') AND phase_name='Черновые работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Комната' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Штукатурка стен'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Штукатурка стен в комнате',
  45.00, 29250.00, 0.00, 'in_progress',
  DATE '2025-12-05', DATE '2025-12-12', DATE '2025-12-06', NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)') AND phase_name='Черновые работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Санузел' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Сантехника'),
  (SELECT contractor_id FROM contractors WHERE inn='500987654321'),
  'Замена труб в санузле',
  4, 4800.00, 0.00, 'blocked',
  DATE '2025-12-04', DATE '2025-12-07', DATE '2025-12-05', NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)') AND phase_name='Черновые работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Кухня' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Электромонтаж'),
  (SELECT contractor_id FROM contractors WHERE inn='500987654321'),
  'Перенос розеток на кухне',
  6, 5400.00, 0.00, 'planned',
  DATE '2025-12-08', DATE '2025-12-09', NULL, NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)') AND phase_name='Чистовая отделка'),
  (SELECT room_id FROM property_rooms WHERE room_name='Кухня' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Укладка плитки'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Плитка на фартук',
  6.50, 11700.00, 0.00, 'in_progress',
  DATE '2025-12-10', DATE '2025-12-12', DATE '2025-12-11', NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)') AND phase_name='Чистовая отделка'),
  (SELECT room_id FROM property_rooms WHERE room_name='Комната' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Покраска стен'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Покраска стен в комнате',
  45.00, 20250.00, 0.00, 'planned',
  DATE '2025-12-22', DATE '2025-12-24', NULL, NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)') AND phase_name='Черновые работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Кухня' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, ул. Примерная%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Штукатурка стен'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Штукатурка стен на кухне (просрочено)',
  25.00, 16250.00, 0.00, 'in_progress',
  DATE '2025-12-03', DATE '2025-12-08', DATE '2025-12-04', NULL
);

-- Проект 2: Новаторов
INSERT INTO project_tasks (
  project_id, phase_id, room_id, work_type_id, contractor_id,
  task_name, volume, planned_cost, actual_cost, status,
  planned_start_date, planned_end_date, actual_start_date, actual_end_date
)
VALUES
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)') AND phase_name='Подготовка'),
  (SELECT room_id FROM property_rooms WHERE room_name='Коридор' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Демонтаж'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Демонтаж коридора',
  6.20, 2200.00, 2100.00, 'completed',
  DATE '2025-11-22', DATE '2025-11-23', DATE '2025-11-22', DATE '2025-11-23'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)') AND phase_name='Основные работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Гостиная' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Штукатурка стен'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Штукатурка стен в гостиной',
  55.00, 35750.00, 20000.00, 'in_progress',
  DATE '2025-12-01', DATE '2025-12-10', DATE '2025-12-02', NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)') AND phase_name='Основные работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Кухня' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Электромонтаж'),
  (SELECT contractor_id FROM contractors WHERE inn='500987654321'),
  'Электрика на кухне',
  5, 4500.00, 4500.00, 'completed',
  DATE '2025-12-03', DATE '2025-12-04', DATE '2025-12-03', DATE '2025-12-04'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)') AND phase_name='Основные работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Гостиная' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Покраска стен'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Покраска гостиной (просрочено)',
  55.00, 24750.00, 0.00, 'planned',
  DATE '2025-12-05', DATE '2025-12-09', NULL, NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)') AND phase_name='Сдача'),
  (SELECT room_id FROM property_rooms WHERE room_name='Гостиная' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Укладка плитки'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Плинтусы/декор (отменено)',
  10.00, 5000.00, 0.00, 'cancelled',
  DATE '2026-01-12', DATE '2026-01-13', NULL, NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)') AND phase_name='Основные работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Кухня' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Сантехника'),
  (SELECT contractor_id FROM contractors WHERE inn='500987654321'),
  'Подключение мойки/смесителя',
  2, 2400.00, 0.00, 'planned',
  DATE '2025-12-14', DATE '2025-12-15', NULL, NULL
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT phase_id FROM project_phases WHERE project_id=(SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)') AND phase_name='Основные работы'),
  (SELECT room_id FROM property_rooms WHERE room_name='Коридор' AND property_id=(SELECT property_id FROM properties WHERE address LIKE 'г. Москва, пр-т Новаторов%')),
  (SELECT work_type_id FROM work_types WHERE work_type_name='Штукатурка стен'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Штукатурка коридора',
  20.00, 13000.00, 0.00, 'planned',
  DATE '2025-12-18', DATE '2025-12-20', NULL, NULL
);

-- ======================
-- AUDIT (генерируем триггерами: set_config + несколько UPDATE status)
-- ======================
SELECT set_config('app.user_id', (SELECT user_id::text FROM users WHERE username='manager'), true);

UPDATE project_tasks
SET status='in_progress', actual_start_date=COALESCE(actual_start_date, CURRENT_DATE)
WHERE task_name IN ('Перенос розеток на кухне','Подключение мойки/смесителя');

UPDATE purchase_orders
SET status='ordered'
WHERE po_number='PO-2025-0003';

-- ======================
-- ACCEPTANCE ACTS (для всех задач)
-- ======================
INSERT INTO acceptance_acts (task_id, acceptance_date, accepted_by, result_status, comment)
SELECT
  t.task_id,
  CASE WHEN t.status='completed' THEN t.actual_end_date ELSE NULL END AS acceptance_date,
  CASE WHEN t.status='completed' THEN 'Инспектор ОТК' ELSE NULL END AS accepted_by,
  CASE WHEN t.status='completed' THEN 'accepted' ELSE NULL END AS result_status,
  CASE
    WHEN t.status='completed' THEN 'Работы приняты'
    WHEN t.status='cancelled' THEN 'Работы отменены'
    ELSE 'Ожидает приёмки'
  END AS comment
FROM project_tasks t;

-- ======================
-- MATERIALS + SUPPLIERS (6 материалов, 2 поставщика)
-- ======================
INSERT INTO materials (material_name, category, unit, manufacturer, current_price, is_active)
VALUES
  ('Плитка 20x20 белая', 'Плитка', 'pcs', 'Kerama', 120.00, TRUE),
  ('Клей плиточный', 'Сухие смеси', 'kg', 'Knauf', 35.00, TRUE),
  ('Грунтовка универсальная', 'ЛКМ', 'l', 'Tikkurila', 210.00, TRUE),
  ('Краска белая матовая', 'ЛКМ', 'l', 'Dulux', 390.00, TRUE),
  ('Провод ВВГнг 3x2.5', 'Электрика', 'm', 'Конкорд', 55.00, TRUE),
  ('Смеситель кухонный', 'Сантехника', 'pcs', 'Grohe', 7800.00, TRUE);

INSERT INTO suppliers (supplier_name, phone, email, address, contact_person)
VALUES
  ('СтройМаркет', '+79990000003', 'sales@stroymarket.example', 'г. Москва, ул. Складская, 1', 'Петров Пётр'),
  ('ДомРемонт',   '+79990000006', 'info@domremont.example',    'г. Москва, ул. Логистическая, 7', 'Иванова Мария');

-- ======================
-- PURCHASE ORDERS (3 заказа: delivered/ordered/draft)
-- ======================
INSERT INTO purchase_orders (project_id, supplier_id, po_number, status, total_amount, order_date, expected_delivery_date)
VALUES
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT supplier_id FROM suppliers WHERE supplier_name='СтройМаркет'),
  'PO-2025-0001',
  'delivered',
  0.00,
  DATE '2025-12-03',
  DATE '2025-12-06'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT supplier_id FROM suppliers WHERE supplier_name='ДомРемонт'),
  'PO-2025-0002',
  'ordered',
  0.00,
  DATE '2025-12-02',
  DATE '2025-12-10'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT supplier_id FROM suppliers WHERE supplier_name='СтройМаркет'),
  'PO-2025-0003',
  'draft',
  0.00,
  DATE '2025-12-15',
  DATE '2025-12-20'
);

-- позиции PO-2025-0001 (доставлено полностью)
INSERT INTO purchase_order_items (po_id, material_id, quantity_ordered, unit_price, delivered_quantity, line_total)
VALUES
(
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0001'),
  (SELECT material_id FROM materials WHERE material_name='Плитка 20x20 белая'),
  120, 120.00, 120, 0
),
(
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0001'),
  (SELECT material_id FROM materials WHERE material_name='Клей плиточный'),
  80, 35.00, 80, 0
),
(
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0001'),
  (SELECT material_id FROM materials WHERE material_name='Грунтовка универсальная'),
  10, 210.00, 10, 0
);

-- позиции PO-2025-0002 (частично доставлено)
INSERT INTO purchase_order_items (po_id, material_id, quantity_ordered, unit_price, delivered_quantity, line_total)
VALUES
(
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0002'),
  (SELECT material_id FROM materials WHERE material_name='Краска белая матовая'),
  20, 390.00, 12, 0
),
(
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0002'),
  (SELECT material_id FROM materials WHERE material_name='Провод ВВГнг 3x2.5'),
  200, 55.00, 200, 0
),
(
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0002'),
  (SELECT material_id FROM materials WHERE material_name='Смеситель кухонный'),
  1, 7800.00, 0, 0
);

-- позиции PO-2025-0003 (пока draft — но позиции можно уже набить)
INSERT INTO purchase_order_items (po_id, material_id, quantity_ordered, unit_price, delivered_quantity, line_total)
VALUES
(
  (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0003'),
  (SELECT material_id FROM materials WHERE material_name='Краска белая матовая'),
  5, 390.00, 0, 0
);

-- ======================
-- INVENTORY TRANSACTIONS (IN/OUT)
-- ======================

-- IN по PO-2025-0001 (всё доставлено)
INSERT INTO inventory_transactions (project_id, material_id, task_id, po_item_id, transaction_type, quantity, unit_price, transaction_date, comment)
SELECT
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  i.material_id,
  NULL,
  i.po_item_id,
  'IN',
  i.delivered_quantity,
  i.unit_price,
  DATE '2025-12-06',
  'Поставка по PO-2025-0001'
FROM purchase_order_items i
WHERE i.po_id = (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0001');

-- OUT: списание плитки на фартук (Примерная)
INSERT INTO inventory_transactions (project_id, material_id, task_id, po_item_id, transaction_type, quantity, unit_price, transaction_date, comment)
VALUES
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT material_id FROM materials WHERE material_name='Плитка 20x20 белая'),
  (SELECT task_id FROM project_tasks WHERE task_name='Плитка на фартук'),
  NULL,
  'OUT',
  70,
  120.00,
  DATE '2025-12-12',
  'Списание плитки на фартук'
),
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (ул. Примерная)'),
  (SELECT material_id FROM materials WHERE material_name='Клей плиточный'),
  (SELECT task_id FROM project_tasks WHERE task_name='Плитка на фартук'),
  NULL,
  'OUT',
  25,
  35.00,
  DATE '2025-12-12',
  'Списание клея на фартук'
);

-- IN по PO-2025-0002 (частично)
INSERT INTO inventory_transactions (project_id, material_id, task_id, po_item_id, transaction_type, quantity, unit_price, transaction_date, comment)
SELECT
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  i.material_id,
  NULL,
  i.po_item_id,
  'IN',
  i.delivered_quantity,
  i.unit_price,
  DATE '2025-12-10',
  'Частичная поставка по PO-2025-0002'
FROM purchase_order_items i
WHERE i.po_id = (SELECT po_id FROM purchase_orders WHERE po_number='PO-2025-0002')
  AND i.delivered_quantity > 0;

-- OUT: списание краски на "Покраска гостиной (просрочено)" (хотя задача planned — допустим подготовили материал)
INSERT INTO inventory_transactions (project_id, material_id, task_id, po_item_id, transaction_type, quantity, unit_price, transaction_date, comment)
VALUES
(
  (SELECT project_id FROM projects WHERE project_name='Ремонт квартиры (пр-т Новаторов)'),
  (SELECT material_id FROM materials WHERE material_name='Краска белая матовая'),
  (SELECT task_id FROM project_tasks WHERE task_name='Покраска гостиной (просрочено)'),
  NULL,
  'OUT',
  6,
  390.00,
  DATE '2025-12-11',
  'Списание краски под покраску'
);

-- ======================
-- DEFECTS (несколько дефектов, разный статус)
-- ======================
INSERT INTO defects (task_id, contractor_id, description, severity, status, defect_date, resolution_date, rework_cost)
VALUES
(
  (SELECT task_id FROM project_tasks WHERE task_name='Плитка на фартук'),
  (SELECT contractor_id FROM contractors WHERE inn='770123456789'),
  'Неровный шов в правом углу',
  'low',
  'open',
  DATE '2025-12-13',
  NULL,
  0.00
),
(
  (SELECT task_id FROM project_tasks WHERE task_name='Электрика на кухне'),
  (SELECT contractor_id FROM contractors WHERE inn='500987654321'),
  'Одна розетка без заземления (исправлено)',
  'high',
  'resolved',
  DATE '2025-12-04',
  DATE '2025-12-05',
  0.00
),
(
  (SELECT task_id FROM project_tasks WHERE task_name='Замена труб в санузле'),
  (SELECT contractor_id FROM contractors WHERE inn='500987654321'),
  'Протечка на соединении',
  'critical',
  'in_progress',
  DATE '2025-12-06',
  NULL,
  1500.00
);

-- один апдейт дефекта, чтобы аудит зафиксировал смену статуса
SELECT set_config('app.user_id', (SELECT user_id::text FROM users WHERE username='inspector'), true);

UPDATE defects
SET status='closed', resolution_date=CURRENT_DATE
WHERE description='Одна розетка без заземления (исправлено)';

COMMIT;
