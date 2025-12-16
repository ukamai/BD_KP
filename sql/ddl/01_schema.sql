BEGIN;

CREATE TABLE IF NOT EXISTS users (
  user_id     BIGSERIAL PRIMARY KEY,
  username    VARCHAR(50)  NOT NULL UNIQUE,
  full_name   VARCHAR(100) NOT NULL,
  email       VARCHAR(100) NOT NULL UNIQUE,
  role        VARCHAR(30)  NOT NULL,
  is_active   BOOLEAN      NOT NULL DEFAULT TRUE,
  created_at  TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS owners (
  owner_id           BIGSERIAL PRIMARY KEY,
  full_name          VARCHAR(100) NOT NULL,
  phone              VARCHAR(20),
  email              VARCHAR(100),
  preferred_contact  VARCHAR(20),
  notes              TEXT,
  created_at         TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS properties (
  property_id    BIGSERIAL PRIMARY KEY,
  owner_id       BIGINT       NOT NULL,
  address        VARCHAR(200) NOT NULL,
  property_type  VARCHAR(20)  NOT NULL,
  total_area     DECIMAL(8,2) NOT NULL,
  status         VARCHAR(20)  NOT NULL,
  created_at     TIMESTAMP    NOT NULL DEFAULT now(),
  updated_at     TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS property_rooms (
  room_id         BIGSERIAL PRIMARY KEY,
  property_id     BIGINT       NOT NULL,
  room_name       VARCHAR(50)  NOT NULL,
  room_type       VARCHAR(30)  NOT NULL,
  area            DECIMAL(8,2) NOT NULL,
  ceiling_height  DECIMAL(4,2),
  has_window      BOOLEAN      NOT NULL DEFAULT FALSE,
  notes           TEXT,
  created_at      TIMESTAMP    NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS contractors (
  contractor_id  BIGSERIAL PRIMARY KEY,
  name           VARCHAR(200) NOT NULL,
  inn            VARCHAR(12)  NOT NULL UNIQUE,
  phone          VARCHAR(20),
  email          VARCHAR(100),
  specialization VARCHAR(100),
  rating         DECIMAL(3,2),
  created_at     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS contracts (
  contract_id     BIGSERIAL PRIMARY KEY,
  property_id     BIGINT       NOT NULL,
  contractor_id   BIGINT       NOT NULL,
  contract_number VARCHAR(50)  NOT NULL UNIQUE,
  status          VARCHAR(20)  NOT NULL,
  total_amount    DECIMAL(12,2) NOT NULL,
  start_date      DATE         NOT NULL,
  end_date        DATE,
  signed_at       DATE
);

CREATE TABLE IF NOT EXISTS projects (
  project_id          BIGSERIAL PRIMARY KEY,
  property_id         BIGINT       NOT NULL,
  contract_id         BIGINT,
  project_name        VARCHAR(200) NOT NULL,
  status              VARCHAR(20)  NOT NULL,
  total_budget        DECIMAL(12,2) NOT NULL,
  actual_cost         DECIMAL(12,2) NOT NULL DEFAULT 0,
  planned_start_date  DATE,
  planned_end_date    DATE,
  created_at          TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS project_phases (
  phase_id            BIGSERIAL PRIMARY KEY,
  project_id          BIGINT       NOT NULL,
  phase_name          VARCHAR(100) NOT NULL,
  phase_order         INTEGER      NOT NULL,
  status              VARCHAR(20)  NOT NULL,
  planned_start_date  DATE,
  planned_end_date    DATE
);

CREATE TABLE IF NOT EXISTS work_types (
  work_type_id   BIGSERIAL PRIMARY KEY,
  work_type_name VARCHAR(100) NOT NULL,
  category       VARCHAR(50),
  default_unit   VARCHAR(20)  NOT NULL,
  standard_rate  DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_active      BOOLEAN      NOT NULL DEFAULT TRUE,
  description    TEXT
);

CREATE TABLE IF NOT EXISTS project_tasks (
  task_id             BIGSERIAL PRIMARY KEY,
  project_id          BIGINT       NOT NULL,
  phase_id            BIGINT       NOT NULL,
  room_id             BIGINT,
  work_type_id        BIGINT       NOT NULL,
  contractor_id       BIGINT,
  task_name           VARCHAR(200) NOT NULL,
  volume              DECIMAL(10,2) NOT NULL DEFAULT 0,
  planned_cost        DECIMAL(10,2) NOT NULL DEFAULT 0,
  actual_cost         DECIMAL(10,2) NOT NULL DEFAULT 0,
  status              VARCHAR(20)  NOT NULL,
  planned_start_date  DATE,
  planned_end_date    DATE,
  actual_start_date   DATE,
  actual_end_date     DATE
);

CREATE TABLE IF NOT EXISTS acceptance_acts (
  task_id         BIGINT PRIMARY KEY,
  acceptance_date DATE,
  accepted_by     VARCHAR(100),
  result_status   VARCHAR(20),
  comment         TEXT,
  created_at      TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS materials (
  material_id    BIGSERIAL PRIMARY KEY,
  material_name  VARCHAR(200) NOT NULL,
  category       VARCHAR(50),
  unit           VARCHAR(20)  NOT NULL,
  manufacturer   VARCHAR(100),
  current_price  DECIMAL(10,2) NOT NULL DEFAULT 0,
  is_active      BOOLEAN      NOT NULL DEFAULT TRUE
);

CREATE TABLE IF NOT EXISTS suppliers (
  supplier_id    BIGSERIAL PRIMARY KEY,
  supplier_name  VARCHAR(200) NOT NULL,
  phone          VARCHAR(20),
  email          VARCHAR(100),
  address        VARCHAR(200),
  contact_person VARCHAR(100),
  created_at     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_orders (
  po_id                  BIGSERIAL PRIMARY KEY,
  project_id             BIGINT      NOT NULL,
  supplier_id            BIGINT      NOT NULL,
  po_number              VARCHAR(50) NOT NULL UNIQUE,
  status                 VARCHAR(20) NOT NULL,
  total_amount           DECIMAL(12,2) NOT NULL DEFAULT 0,
  order_date             DATE        NOT NULL,
  expected_delivery_date DATE,
  created_at             TIMESTAMP   NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS purchase_order_items (
  po_item_id         BIGSERIAL PRIMARY KEY,
  po_id              BIGINT       NOT NULL,
  material_id        BIGINT       NOT NULL,
  quantity_ordered   DECIMAL(10,2) NOT NULL,
  unit_price         DECIMAL(10,2) NOT NULL,
  delivered_quantity DECIMAL(10,2) NOT NULL DEFAULT 0,
  line_total         DECIMAL(12,2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS inventory_transactions (
  inv_tx_id         BIGSERIAL PRIMARY KEY,
  project_id        BIGINT       NOT NULL,
  material_id       BIGINT       NOT NULL,
  task_id           BIGINT,
  po_item_id        BIGINT,
  transaction_type  VARCHAR(20)  NOT NULL,
  quantity          DECIMAL(10,2) NOT NULL,
  unit_price        DECIMAL(10,2) NOT NULL DEFAULT 0,
  transaction_date  DATE         NOT NULL,
  comment           TEXT
);

CREATE TABLE IF NOT EXISTS defects (
  defect_id       BIGSERIAL PRIMARY KEY,
  task_id         BIGINT      NOT NULL,
  contractor_id   BIGINT,
  description     TEXT        NOT NULL,
  severity        VARCHAR(20) NOT NULL,
  status          VARCHAR(20) NOT NULL,
  defect_date     DATE        NOT NULL,
  resolution_date DATE,
  rework_cost     DECIMAL(10,2) NOT NULL DEFAULT 0
);

CREATE TABLE IF NOT EXISTS audit_log (
  audit_id         BIGSERIAL PRIMARY KEY,
  entity_type      VARCHAR(50) NOT NULL,
  entity_id        BIGINT      NOT NULL,
  action_type      VARCHAR(10) NOT NULL,
  action_timestamp TIMESTAMP   NOT NULL DEFAULT now(),
  user_id          BIGINT,
  old_values       JSONB,
  new_values       JSONB
);

COMMIT;
