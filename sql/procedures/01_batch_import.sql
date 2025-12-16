BEGIN;

-- Batch import для inventory_transactions.
-- p_rows: JSON-массив объектов:
-- [
--   {"project_id":1,"material_id":2,"task_id":10,"po_item_id":null,"transaction_type":"OUT","quantity":3,"unit_price":120,"transaction_date":"2025-12-01","comment":"..."},
--   ...
-- ]
CREATE OR REPLACE PROCEDURE sp_batch_import_inventory_transactions(
  p_rows JSONB,
  p_source TEXT DEFAULT 'inventory_transactions_batch',
  p_fail_fast BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
DECLARE
  v_row JSONB;
  v_project_id BIGINT;
  v_material_id BIGINT;
  v_task_id BIGINT;
  v_po_item_id BIGINT;
  v_transaction_type TEXT;
  v_quantity NUMERIC;
  v_unit_price NUMERIC;
  v_transaction_date DATE;
  v_comment TEXT;
  v_i INT;
  v_len INT;
  v_user_id BIGINT;
BEGIN
  IF p_rows IS NULL OR jsonb_typeof(p_rows) <> 'array' THEN
    RAISE EXCEPTION 'p_rows must be JSON array';
  END IF;

  v_user_id := audit_get_user_id();
  v_len := jsonb_array_length(p_rows);

  FOR v_i IN 0..v_len-1 LOOP
    v_row := p_rows->v_i;

    BEGIN
      v_project_id := NULLIF(v_row->>'project_id','')::BIGINT;
      v_material_id := NULLIF(v_row->>'material_id','')::BIGINT;
      v_task_id := NULLIF(v_row->>'task_id','')::BIGINT;
      v_po_item_id := NULLIF(v_row->>'po_item_id','')::BIGINT;

      v_transaction_type := NULLIF(v_row->>'transaction_type','');
      v_quantity := NULLIF(v_row->>'quantity','')::NUMERIC;
      v_unit_price := COALESCE(NULLIF(v_row->>'unit_price','')::NUMERIC, 0);
      v_transaction_date := COALESCE(NULLIF(v_row->>'transaction_date','')::DATE, CURRENT_DATE);
      v_comment := v_row->>'comment';

      IF v_project_id IS NULL OR v_material_id IS NULL OR v_transaction_type IS NULL OR v_quantity IS NULL THEN
        RAISE EXCEPTION 'Missing required fields: project_id, material_id, transaction_type, quantity';
      END IF;

      INSERT INTO inventory_transactions(
        project_id, material_id, task_id, po_item_id,
        transaction_type, quantity, unit_price, transaction_date, comment
      )
      VALUES (
        v_project_id, v_material_id, v_task_id, v_po_item_id,
        v_transaction_type, v_quantity, v_unit_price, v_transaction_date, v_comment
      );

    EXCEPTION WHEN OTHERS THEN
      INSERT INTO import_errors(source, payload, error_message, user_id, details)
      VALUES (
        p_source,
        v_row,
        SQLERRM,
        v_user_id,
        jsonb_build_object('sqlstate', SQLSTATE, 'index', v_i)
      );

      IF p_fail_fast THEN
        RAISE;
      END IF;
    END;
  END LOOP;
END;
$$;

COMMIT;
