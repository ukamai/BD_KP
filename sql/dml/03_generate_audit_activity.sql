BEGIN;

SELECT set_config('app.audit_disabled', '0', true);
SELECT set_config('app.user_id', (SELECT user_id::text FROM users WHERE username='admin'), true);

DO $$
DECLARE
  v_target_audit INT := 6000; 
  v_tasks_cnt    INT;
  v_rounds       INT;
  i              INT;
BEGIN
  SELECT COUNT(*) INTO v_tasks_cnt FROM project_tasks;
  IF v_tasks_cnt <= 0 THEN
    RAISE EXCEPTION 'project_tasks пустая — нечего аудировать';
  END IF;

  v_rounds := CEIL(v_target_audit::numeric / v_tasks_cnt)::int;

  FOR i IN 1..v_rounds LOOP
    UPDATE project_tasks
    SET
      actual_cost = actual_cost + 1,
      status = CASE WHEN status='completed' THEN 'in_progress' ELSE 'completed' END
    WHERE task_id IN (SELECT task_id FROM project_tasks ORDER BY task_id);
  END LOOP;

  RAISE NOTICE 'audit_log rows: %', (SELECT COUNT(*) FROM audit_log);
END $$;

COMMIT;
