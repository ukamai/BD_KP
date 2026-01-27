# Repair DB + API — информационная система планирования и учёта ремонта

Репозиторий содержит:
- **PostgreSQL-схему** и демонстрационные SQL-скрипты для темы  
  **«Информационная система планирования и учёта ремонта жилых помещений»**
- **backend (FastAPI)** для работы с БД и демонстрации сценариев через Swagger

---

## Быстрый старт (Docker)

### 1) Подготовить окружение

Требуется установленный Docker + Docker Compose.

Создать локальный файл окружения:

```bash
cp .env.example .env
```

```env (пример)
HOST_PORT=5434
POSTGRES_USER=repair_user
POSTGRES_PASSWORD=some_password
POSTGRES_DB=repair_db
```

### 2) Запустить сервисы (PostgreSQL + API)

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

### 3) Инициализировать схему + данные (seed)

```bash
chmod +x scripts/reset_db_docker.sh
./scripts/reset_db_docker.sh
```

Если нужно перезапустить БД (с удалением volume):

```bash
docker compose down -v --remove-orphans
docker compose up -d --build
./scripts/reset_db_docker.sh
```

---

