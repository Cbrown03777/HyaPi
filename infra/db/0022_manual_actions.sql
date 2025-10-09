-- 0022_manual_actions.sql
-- Minimal structures to support Manual Conversion Mode if not already present.

-- Treasury buffer mirror in PI units (singleton row id=true)
CREATE TABLE IF NOT EXISTS public.treasury (
  id boolean PRIMARY KEY DEFAULT true,
  buffer_pi numeric(24,6) NOT NULL DEFAULT 0,
  last_updated timestamptz NOT NULL DEFAULT now()
);
INSERT INTO public.treasury(id) VALUES (true) ON CONFLICT (id) DO NOTHING;

-- Shadow table to track deployed PI per venue for admin reporting
CREATE TABLE IF NOT EXISTS public.venue_balances_pi (
  venue text PRIMARY KEY,
  deployed_pi numeric(24,6) NOT NULL DEFAULT 0,
  updated_at timestamptz NOT NULL DEFAULT now()
);

-- Optional note column for planned_actions to store freeform comments
ALTER TABLE public.planned_actions ADD COLUMN IF NOT EXISTS reason text;
