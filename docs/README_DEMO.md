cp .env.example .env
docker compose up -d --build

chmod +x scripts/reset_db_docker.sh
./scripts/reset_db_docker.sh

set -a
source .env
set +a

docker compose exec -T db psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < sql/diagnostics/check_tables.sql




\x on
\timing on

SELECT * FROM v_projects_overview LIMIT 5;
SELECT * FROM v_project_progress LIMIT 5;
SELECT * FROM v_overdue_tasks LIMIT 5;
SELECT * FROM v_purchase_orders_detailed LIMIT 5;
SELECT * FROM v_material_balance_by_project LIMIT 5;

### Пункт 3 — Триггеры и аудит

#### 3.1 Аудит
- `GET /api/v1/tasks`
- `PATCH /api/v1/tasks/{task_id}`
SELECT audit_id, entity_type, entity_id, action_type, action_timestamp, user_id
FROM audit_log
ORDER BY action_timestamp DESC, audit_id DESC
LIMIT 20;

#### 3.2 Триггер updated_at
SELECT property_id, address, updated_at
FROM properties
ORDER BY property_id DESC
LIMIT 1;

- `PATCH /api/v1/properties/{property_id}`
{ "address": "Москва, Демонстрационная 99" }

SELECT property_id, address, updated_at
FROM properties
WHERE property_id = <14>;

#### 3.3 Пересчёт суммы заказа
SELECT po_id, total_amount
FROM purchase_orders
ORDER BY po_id DESC
LIMIT 1;

SELECT po_item_id, po_id, quantity_ordered, unit_price, line_total
FROM purchase_order_items
WHERE po_id = 7
LIMIT 1;

UPDATE purchase_order_items
SET unit_price = unit_price + 10
WHERE po_item_id = 45;

SELECT po_item_id, line_total
FROM purchase_order_items
WHERE po_item_id = 45;

SELECT po_id, total_amount
FROM purchase_orders
WHERE po_id = 7;

### Пункт 4 — Индексы и оптимизация

set -a; source .env; set +a

psql -h localhost -p "$HOST_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f sql/explain/01_drop_indexes.sql
psql -h localhost -p "$HOST_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f sql/explain/02_explain_no_indexes.sql

psql -h localhost -p "$HOST_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f sql/explain/03_create_indexes.sql
psql -h localhost -p "$HOST_PORT" -U "$POSTGRES_USER" -d "$POSTGRES_DB" -f sql/explain/04_explain_with_indexes.sql


### Пункт 5 — Батч-импорт + обработка ошибок

`POST /api/v1/inventory-transactions/batch/faker`

{
  "count": 2000,
  "invalid_rate": 0.03,
  "fail_fast": false,
  "source": "faker"
}

- `GET /api/v1/import-runs`
- `GET /api/v1/import-errors`


### Пункт 6 — Функции

SELECT * FROM v_project_progress LIMIT 10;
SELECT * FROM v_material_balance_by_project LIMIT 10;

SELECT project_id FROM projects ORDER BY project_id LIMIT 1;
SELECT fn_project_total_spent(117);

SELECT project_id FROM projects ORDER BY project_id DESC LIMIT 1;
SELECT task_id FROM project_tasks ORDER BY task_id DESC LIMIT 1;
SELECT supplier_id FROM suppliers ORDER BY supplier_id DESC LIMIT 1;
SELECT material_id FROM materials ORDER BY material_id DESC LIMIT 1;
SELECT property_id FROM properties ORDER BY property_id DESC LIMIT 1;

### use case
`POST /api/v1/properties`
{
  "owner_id": 1,
  "address": "Москва, Демонстрационная 10, кв. 15",
  "property_type": "apartment",
  "total_area": 56.7,
  "status": "active"
}

`POST /api/v1/rooms`

{
  "property_id": 0,
  "room_name": "Кухня",
  "room_type": "kitchen",
  "area": 10.5,
  "ceiling_height": 2.7,
  "has_window": true,
  "notes": "Перенос розеток"
}

{
  "property_id": 0,
  "room_name": "Гостиная",
  "room_type": "living",
  "area": 18.0,
  "ceiling_height": 2.7,
  "has_window": true,
  "notes": ""
}

`POST /api/v1/contractors`
{
  "name": "ООО РемСтрой",
  "inn": "7701234567",
  "phone": "+7-900-111-22-33",
  "email": "remstroy@example.com",
  "specialization": "Отделочные работы",
  "rating": 4.7
}

`POST /api/v1/contracts`
{
  "property_id": 0,
  "contractor_id": 0,
  "contract_number": "CN-2025-0001",
  "status": "active",
  "total_amount": 450000,
  "start_date": "2025-12-01",
  "end_date": "2026-02-15",
  "signed_at": "2025-12-01"
}

`POST /api/v1/projects`
{
  "property_id": 0,
  "contract_id": 0,
  "project_name": "Ремонт кв. 15 (под ключ)",
  "status": "active",
  "total_budget": 500000,
  "planned_start_date": "2025-12-01",
  "planned_end_date": "2026-02-15"
}

`POST /api/v1/phases`
{
  "project_id": 0,
  "phase_name": "Черновые работы",
  "phase_order": 1,
  "status": "planned",
  "planned_start_date": "2025-12-01",
  "planned_end_date": "2025-12-20"
}

`POST /api/v1/phases`
{
  "project_id": 0,
  "phase_name": "Чистовые работы",
  "phase_order": 2,
  "status": "planned",
  "planned_start_date": "2025-12-21",
  "planned_end_date": "2026-02-10"
}

`POST /api/v1/work-types`
{
  "work_type_name": "Шпаклёвка стен",
  "category": "Отделка",
  "default_unit": "m2",
  "standard_rate": 450,
  "is_active": true,
  "description": "Подготовка стен под покраску"
}

`POST /api/v1/tasks`
{
  "project_id": 0,
  "phase_id": 0,
  "room_id": 0,
  "work_type_id": 0,
  "contractor_id": 0,
  "task_name": "Шпаклёвка стен кухни",
  "volume": 28.0,
  "planned_cost": 12600,
  "actual_cost": 0,
  "status": "planned",
  "planned_start_date": "2025-12-02",
  "planned_end_date": "2025-12-05"
}

`PATCH /api/v1/tasks/{task_id}`
{
  "status": "in_progress"
}

`PATCH /api/v1/tasks/batch/status`
{
  "task_ids": [1, 2, 3],
  "status": "completed"
}

`POST /api/v1/materials`
{
  "material_name": "Шпаклевка Demo",
  "category": "Сухие смеси",
  "unit": "kg",
  "manufacturer": "DemoFactory",
  "current_price": 350.5,
  "is_active": true
}

`POST /api/v1/suppliers`
{
  "supplier_name": "ООО Поставщик Demo",
  "phone": "+7-900-111-22-33",
  "email": "demo_supplier@example.com",
  "address": "Москва, ул. Примерная, 1",
  "contact_person": "Иван Петров"
}

`POST /api/v1/purchase-orders`
{
  "project_id": 0,
  "supplier_id": 0,
  "order_date": "2025-12-02",
  "expected_delivery_date": "2025-12-04",
  "status": "ordered",
  "items": [
    { "material_id": 0, "quantity_ordered": 20, "unit_price": 350.5 }
  ]
}

`PATCH /api/v1/properties/{property_id}`
{
  "address": "Москва, Демонстрационная 99"
}

`GET /api/v1/reports/projects?status=active`

`POST /api/v1/inventory-transactions/batch/faker`
{
  "count": 2000,
  "invalid_rate": 0.03,
  "fail_fast": false,
  "source": "faker"
}

`GET /api/v1/import-runs`
`GET /api/v1/import-errors`