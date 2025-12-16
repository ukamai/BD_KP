# Repair DB + API — информационная система планирования и учёта ремонта

Репозиторий содержит:
- **PostgreSQL-схему** и демонстрационные SQL-скрипты для темы  
  **«Информационная система планирования и учёта ремонта жилых помещений»**
- **минимальный backend (FastAPI)** для работы с БД и демонстрации сценариев через Swagger

---

## Быстрый старт (Docker)

### 1) Подготовь окружение

Требуется установленный Docker + Docker Compose.

Создай локальный файл окружения:

```bash
cp .env.example .env
```

Открой `.env` и задай `POSTGRES_PASSWORD` (и при необходимости `HOST_PORT`).

Пример:

```env
HOST_PORT=5434
POSTGRES_USER=repair_user
POSTGRES_PASSWORD=some_password
POSTGRES_DB=repair_db
```

### 2) Запусти сервисы (PostgreSQL + API)

```bash
docker compose up -d --build
```

Проверка, что всё поднялось:

```bash
docker compose ps
```

Ожидаемо:
- `db` — Up (healthy)
- `api` — Up и проброшен на `http://localhost:8000`

### 3) Инициализируй схему + данные (seed)

```bash
chmod +x scripts/reset_db_docker.sh
./scripts/reset_db_docker.sh
```

Если нужно “чисто” перезапустить БД (с удалением volume):

```bash
docker compose down -v --remove-orphans
docker compose up -d --build
./scripts/reset_db_docker.sh
```

---

## Проверки

### Проверка БД: check_tables.sql

Важно: `psql` внутри контейнера **не видит** файлы проекта, поэтому подаём SQL через stdin:

```bash
docker compose exec -T db psql -v ON_ERROR_STOP=1 -U repair_user -d repair_db < sql/diagnostics/check_tables.sql
```

### Проверка API: health

```bash
curl -i http://localhost:8000/api/v1/health
```

Должно быть `HTTP/1.1 200 OK` и `{"status":"ok"}`.

### Swagger

Открой в браузере:

- `http://localhost:8000/docs`

---

## Как подключиться к базе

Порт берётся из `.env` (`HOST_PORT`). Например, если `HOST_PORT=5434`:

```bash
psql -h localhost -p 5434 -U repair_user -d repair_db
```

---

## Демонстрационные запросы (SQL)

### Отчётные запросы

```bash
psql -h localhost -p 5434 -U repair_user -d repair_db -f sql/queries/01_reports.sql
```

### Демонстрация изменений + аудит

```bash
psql -h localhost -p 5434 -U repair_user -d repair_db -f sql/queries/02_demo_mutations.sql
```

---

## API: быстрый smoke-test (curl)

### Список проектов
```bash
curl -s http://localhost:8000/api/v1/projects
```

### Создать проект (с аудитом; user_id берётся из заголовка X-User-Id)
```bash
curl -i -X POST "http://localhost:8000/api/v1/projects"       -H "Content-Type: application/json"       -H "X-User-Id: 1"       -d '{"property_id":1,"contract_id":null,"project_name":"API demo project","status":"active","total_budget":100000,"planned_start_date":"2025-12-01","planned_end_date":"2026-01-15"}'
```

### Проверить audit_log (последние события)
```bash
docker compose exec -T db psql -U repair_user -d repair_db       -c "SELECT action_timestamp, entity_type, entity_id, action_type, user_id FROM audit_log ORDER BY action_timestamp DESC LIMIT 20;"
```

---

## EXPLAIN ANALYZE: до/после индексов

Все команды ниже выполняй **из корня репозитория**.

1) Удалить индексы:

```bash
psql -h localhost -p 5434 -U repair_user -d repair_db -f sql/explain/01_drop_indexes.sql
```

2) EXPLAIN без индексов:

```bash
psql -h localhost -p 5434 -U repair_user -d repair_db -f sql/explain/02_explain_no_indexes.sql
```

3) Восстановить индексы:

```bash
psql -h localhost -p 5434 -U repair_user -d repair_db -f sql/explain/03_create_indexes.sql
```

4) EXPLAIN с индексами:

```bash
psql -h localhost -p 5434 -U repair_user -d repair_db -f sql/explain/04_explain_with_indexes.sql
```

---

## Структура проекта

- `api/` — FastAPI backend (Swagger: `/docs`)
- `docs/` — инструкции по запуску и заметки
- `sql/ddl` — схема и ограничения
- `sql/triggers` — триггеры (updated_at, аудит)
- `sql/functions` — функции
- `sql/procedures` — процедуры
- `sql/views` — представления
- `sql/indexes` — индексы
- `sql/queries` — отчёты и демонстрационные операции
- `sql/explain` — подготовленные EXPLAIN ANALYZE сценарии
- `sql/diagnostics` — проверки (например, `check_tables.sql`)
- `scripts/reset_db_docker.sh` — инициализация базы в контейнере

---

## Безопасность

Файл `.env` содержит локальные секреты и **не хранится в репозитории**.
Используй `.env.example` как шаблон.
