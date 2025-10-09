-- 0015_allocation_targets.sql
-- Table for governance & emergency override allocation targets
CREATE TABLE IF NOT EXISTS allocation_targets (
	id              SERIAL PRIMARY KEY,
	key             text NOT NULL,
	weight_fraction numeric(9,6) NOT NULL CHECK (weight_fraction >= 0),
	source          text NOT NULL CHECK (source IN ('gov','override')),
	applied_at      timestamptz NOT NULL DEFAULT now(),
	expires_at      timestamptz,
	UNIQUE(key, source, applied_at)
);
CREATE INDEX IF NOT EXISTS allocation_targets_source_idx ON allocation_targets(source, applied_at DESC);

