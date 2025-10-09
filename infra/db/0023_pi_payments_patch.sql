-- 0023_pi_payments_patch.sql
-- Align pi_payments & liquidity_events schema to current code expectations.
-- Idempotent and safe on re-run.

-- 1) Ensure columns exist
ALTER TABLE pi_payments
  ADD COLUMN IF NOT EXISTS from_address TEXT,
  ADD COLUMN IF NOT EXISTS to_address   TEXT,
  ADD COLUMN IF NOT EXISTS direction    TEXT,
  ADD COLUMN IF NOT EXISTS status       TEXT,
  ADD COLUMN IF NOT EXISTS txid         TEXT,
  ADD COLUMN IF NOT EXISTS payload      JSONB;

-- 2) Drop any previous direction check constraint (name unknown)
DO $$
DECLARE
  c TEXT;
BEGIN
  SELECT pc.conname
    INTO c
    FROM pg_constraint pc
   WHERE pc.conrelid = 'pi_payments'::regclass
     AND pc.contype = 'c'
     AND pg_get_constraintdef(pc.oid) ILIKE '%direction%';
  IF c IS NOT NULL THEN
    EXECUTE format('ALTER TABLE pi_payments DROP CONSTRAINT %I', c);
  END IF;
END $$;

-- 3) Normalize existing direction values BEFORE adding new constraint
--    Treat anything non-canonical as 'user_to_app' (all current flows are U->A).
UPDATE pi_payments
   SET direction = 'user_to_app'
 WHERE direction IS NULL
    OR direction IN ('', 'U2A', 'user-to-app', 'USER_TO_APP', 'user_to_app ')
    OR direction NOT IN ('user_to_app','app_to_user');

-- 4) Enforce NOT NULL + canonical set
ALTER TABLE pi_payments
  ALTER COLUMN direction SET NOT NULL;

-- Guarded add of canonical check constraint
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint c
     WHERE c.conname = 'pi_payments_direction_check'
       AND c.conrelid = 'pi_payments'::regclass
  ) THEN
    ALTER TABLE pi_payments
      ADD CONSTRAINT pi_payments_direction_check
      CHECK (direction IN ('user_to_app','app_to_user'));
  END IF;
END $$;

-- 5) Liquidity events idempotency columns & index
ALTER TABLE liquidity_events
  ADD COLUMN IF NOT EXISTS idem_key TEXT,
  ADD COLUMN IF NOT EXISTS amount NUMERIC(20,6),
  ADD COLUMN IF NOT EXISTS meta JSONB;

CREATE UNIQUE INDEX IF NOT EXISTS uq_liq_events_idem_key
  ON liquidity_events(idem_key) WHERE idem_key IS NOT NULL;
