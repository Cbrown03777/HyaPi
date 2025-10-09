-- 0020_planned_actions.sql
-- Queue for supply/redeem actions derived from buffer controller.
CREATE TABLE IF NOT EXISTS public.planned_actions (
  id            bigserial PRIMARY KEY,
  kind          text NOT NULL CHECK (kind IN ('supply','redeem')),
  venue_key     text NOT NULL,
  amount_usd    NUMERIC(20,6) NOT NULL CHECK (amount_usd > 0),
  status        text NOT NULL DEFAULT 'pending' CHECK (status IN ('pending','sent','confirmed','failed','canceled')),
  reason        text,
  created_at    timestamptz NOT NULL DEFAULT now(),
  updated_at    timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_planned_actions_status ON public.planned_actions(status, created_at);
