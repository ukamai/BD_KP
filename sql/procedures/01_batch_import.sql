BEGIN;

CREATE OR REPLACE FUNCTION fn_batch_import_inventory_transactions(
  p_rows JSONB,
  p_source TEXT DEFAULT 'inventory_transactions_batch',
  p_fail_fast BOOLEAN DEFAULT FALSE,
  p_meta JSONB DEFAULT NULL
)
RETURNS TABLE (
  run_id BIGINT,
  total_rows INT,
  inserted_rows INT,
  failed_rows INT,
  status TEXT
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

  v_run_id BIGINT;
  v_inserted INT := 0;
  v_failed INT := 0;
  v_status TEXT := 'running';
BEGIN
  IF p_rows IS NULL OR jsonb_typeof(p_rows) <> 'array' THEN
    RAISE EXCEPTION 'p_rows must be JSON array';
  END IF;

  v_user_id := audit_get_user_id();
  v_len := jsonb_array_length(p_rows);

  INSERT INTO import_runs(source, entity, total_rows, inserted_rows, failed_rows, fail_fast, status, user_id, meta)
  VALUES (COALESCE(p_source, 'inventory_transactions_batch'), 'inventory_transactions', v_len, 0, 0, COALESCE(p_fail_fast, FALSE), 'running', v_user_id, p_meta)
  RETURNING import_runs.run_id INTO v_run_id;

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

      v_inserted := v_inserted + 1;

    EXCEPTION WHEN OTHERS THEN
      v_failed := v_failed + 1;

      INSERT INTO import_errors(run_id, source, payload, error_message, user_id, details)
      VALUES (
        v_run_id,
        COALESCE(p_source, 'inventory_transactions_batch'),
        v_row,
        SQLERRM,
        v_user_id,
        jsonb_build_object('sqlstate', SQLSTATE, 'index', v_i)
      );

      IF COALESCE(p_fail_fast, FALSE) THEN
        v_status := 'failed';
        EXIT;
      END IF;
    END;
  END LOOP;

  IF v_status <> 'failed' THEN
    IF v_failed > 0 THEN
      v_status := 'completed_with_errors';
    ELSE
      v_status := 'completed';
    END IF;
  END IF;

  UPDATE import_runs
  SET
    finished_at = now(),
    inserted_rows = v_inserted,
    failed_rows = v_failed,
    status = v_status
  WHERE import_runs.run_id = v_run_id;

  run_id := v_run_id;
  total_rows := v_len;
  inserted_rows := v_inserted;
  failed_rows := v_failed;
  status := v_status;
  RETURN NEXT;
END;
$$;

CREATE OR REPLACE PROCEDURE sp_batch_import_inventory_transactions(
  p_rows JSONB,
  p_source TEXT DEFAULT 'inventory_transactions_batch',
  p_fail_fast BOOLEAN DEFAULT FALSE
)
LANGUAGE plpgsql
AS $$
BEGIN
  PERFORM * FROM fn_batch_import_inventory_transactions(p_rows, p_source, p_fail_fast, NULL);
END;
$$;

COMMIT;
