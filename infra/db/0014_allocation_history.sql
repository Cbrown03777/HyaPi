-- 0014_allocation_history.sql
-- Stores executed allocation snapshots for historical APY & EMA smoothing
CREATE TABLE IF NOT EXISTS allocation_history (
  id SERIAL PRIMARY KEY,
  as_of TIMESTAMPTZ NOT NULL DEFAULT now(),
  total_usd NUMERIC,
  total_gross_apy DOUBLE PRECISION,
  total_net_apy DOUBLE PRECISION,
  baskets_json JSONB
);
CREATE INDEX IF NOT EXISTS allocation_history_asof_idx ON allocation_history(as_of DESC);
