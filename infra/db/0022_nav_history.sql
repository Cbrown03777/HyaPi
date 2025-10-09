-- 0022_nav_history.sql (DDL only)
-- Purpose: daily PPS snapshots for APY/EMA/lifetime calculations.

BEGIN;

CREATE TABLE IF NOT EXISTS public.nav_history (
  d           DATE PRIMARY KEY,
  pps         NUMERIC NOT NULL CHECK (pps > 0),
  created_at  TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_nav_history_created_at ON public.nav_history (created_at);

COMMIT;
