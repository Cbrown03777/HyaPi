-- 0026_test_flags_and_user_address_guard.sql
-- Add is_test flags to key tables and supporting indexes (idempotent).

ALTER TABLE IF EXISTS public.pi_payments      ADD COLUMN IF NOT EXISTS is_test boolean DEFAULT false;
ALTER TABLE IF EXISTS public.liquidity_events ADD COLUMN IF NOT EXISTS is_test boolean DEFAULT false;
ALTER TABLE IF EXISTS public.stakes           ADD COLUMN IF NOT EXISTS is_test boolean DEFAULT false;

CREATE INDEX IF NOT EXISTS pi_payments_is_test_idx ON public.pi_payments(is_test);
CREATE INDEX IF NOT EXISTS liquidity_events_is_test_idx ON public.liquidity_events(is_test);
CREATE INDEX IF NOT EXISTS stakes_is_test_idx ON public.stakes(is_test);

-- Note: users unique key for pi_address remains; code guards unique_violation and skips overwrite.
