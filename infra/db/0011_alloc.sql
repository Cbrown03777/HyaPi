-- Allocation engine support tables

-- Holdings per venue:market (USD notionals for planning)
CREATE TABLE IF NOT EXISTS venue_holdings (
	key              text PRIMARY KEY,  -- "venue:market"
	usd_notional     numeric(24,6) NOT NULL DEFAULT 0,
	updated_at       timestamptz NOT NULL DEFAULT now()
);

-- Snapshot of rates (optional, for auditability)
CREATE TABLE IF NOT EXISTS venue_rates (
	id               bigserial PRIMARY KEY,
	key              text NOT NULL,     -- "venue:market"
	base_apr         numeric(12,8) NOT NULL,
	as_of            timestamptz NOT NULL,
	created_at       timestamptz NOT NULL DEFAULT now()
);
CREATE INDEX IF NOT EXISTS idx_venue_rates_key_ts ON venue_rates(key, as_of DESC);

-- Rebalance plans
CREATE TABLE IF NOT EXISTS rebalance_plans (
	id               bigserial PRIMARY KEY,
	created_at       timestamptz NOT NULL DEFAULT now(),
	status           text NOT NULL DEFAULT 'planned', -- planned|executed|cancelled
	tvl_usd          numeric(24,6) NOT NULL,
	buffer_usd       numeric(24,6) NOT NULL,
	drift_bps        integer NOT NULL,
	target_json      jsonb NOT NULL,    -- { "venue:market": weight }
	actions_json     jsonb NOT NULL     -- array of { kind, key, deltaUSD }
);
