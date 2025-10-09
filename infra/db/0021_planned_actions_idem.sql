-- 0021_planned_actions_idem.sql
-- Add idem_key column + unique index for idempotent planned_actions inserts.
ALTER TABLE public.planned_actions ADD COLUMN IF NOT EXISTS idem_key text;
CREATE UNIQUE INDEX IF NOT EXISTS uq_planned_actions_idem_key ON public.planned_actions(idem_key) WHERE idem_key IS NOT NULL;
