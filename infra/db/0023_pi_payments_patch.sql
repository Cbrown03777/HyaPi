-- 0023_pi_payments_patch.sql
-- Idempotent patch to align pi_payments & liquidity_events with current code expectations.

-- Add missing columns on pi_payments
ALTER TABLE pi_payments
  ADD COLUMN IF NOT EXISTS from_address TEXT,
  ADD COLUMN IF NOT EXISTS to_address   TEXT,
  ADD COLUMN IF NOT EXISTS direction    TEXT,
  ADD COLUMN IF NOT EXISTS status       TEXT,
  ADD COLUMN IF NOT EXISTS txid         TEXT,
  ADD COLUMN IF NOT EXISTS payload      JSONB;

-- Normalize direction values to canonical 'user_to_app' / 'app_to_user'
UPDATE pi_payments
   SET direction = 'user_to_app'
 WHERE direction IS NULL
    OR direction IN ('U2A','user-to-app','USER_TO_APP','user_to_app ');

-- Drop any existing direction check constraint (name unknown) and add canonical one
DO $$
DECLARE
  conname TEXT;
BEGIN
  SELECT conname INTO conname
    FROM pg_constraint
   WHERE conrelid = 'pi_payments'::regclass
     AND contype = 'c'
     AND pg_get_constraintdef(oid) ILIKE '%direction%';
  IF conname IS NOT NULL THEN
    EXECUTE format('ALTER TABLE pi_payments DROP CONSTRAINT %I', conname);
  END IF;
END $$;

ALTER TABLE pi_payments
  ALTER COLUMN direction SET NOT NULL;
ALTER TABLE pi_payments
  ADD CONSTRAINT pi_payments_direction_check
    CHECK (direction IN ('user_to_app','app_to_user'));

-- Liquidity event idempotency support (amount/meta columns may already have been added elsewhere)
ALTER TABLE liquidity_events
  ADD COLUMN IF NOT EXISTS idem_key TEXT,
  ADD COLUMN IF NOT EXISTS amount NUMERIC(20,6),
  ADD COLUMN IF NOT EXISTS meta JSONB;

CREATE UNIQUE INDEX IF NOT EXISTS uq_liq_events_idem_key
  ON liquidity_events(idem_key) WHERE idem_key IS NOT NULL;
