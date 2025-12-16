BEGIN;

CREATE OR REPLACE FUNCTION trg_set_updated_at()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at := now();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS set_properties_updated_at ON properties;
CREATE TRIGGER set_properties_updated_at
BEFORE UPDATE ON properties
FOR EACH ROW
EXECUTE FUNCTION trg_set_updated_at();

CREATE OR REPLACE FUNCTION trg_po_item_set_line_total()
RETURNS TRIGGER AS $$
BEGIN
  NEW.line_total := COALESCE(NEW.quantity_ordered, 0) * COALESCE(NEW.unit_price, 0);
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS po_item_set_line_total_insupd ON purchase_order_items;
CREATE TRIGGER po_item_set_line_total_insupd
BEFORE INSERT OR UPDATE OF quantity_ordered, unit_price ON purchase_order_items
FOR EACH ROW
EXECUTE FUNCTION trg_po_item_set_line_total();

CREATE OR REPLACE FUNCTION trg_po_recalc_total_amount()
RETURNS TRIGGER AS $$
DECLARE
  v_po_id BIGINT;
BEGIN
  IF (TG_OP = 'DELETE') THEN
    v_po_id := OLD.po_id;
  ELSE
    v_po_id := NEW.po_id;
  END IF;

  UPDATE purchase_orders po
  SET total_amount = COALESCE((
    SELECT SUM(line_total) FROM purchase_order_items i WHERE i.po_id = v_po_id
  ), 0)
  WHERE po.po_id = v_po_id;

  IF (TG_OP = 'UPDATE') AND (OLD.po_id IS DISTINCT FROM NEW.po_id) THEN
    UPDATE purchase_orders po
    SET total_amount = COALESCE((
      SELECT SUM(line_total) FROM purchase_order_items i WHERE i.po_id = OLD.po_id
    ), 0)
    WHERE po.po_id = OLD.po_id;
  END IF;

  RETURN NULL;
END;
$$ LANGUAGE plpgsql;

DROP TRIGGER IF EXISTS po_recalc_total_amount_after_change ON purchase_order_items;
CREATE TRIGGER po_recalc_total_amount_after_change
AFTER INSERT OR UPDATE OR DELETE ON purchase_order_items
FOR EACH ROW
EXECUTE FUNCTION trg_po_recalc_total_amount();

COMMIT;
