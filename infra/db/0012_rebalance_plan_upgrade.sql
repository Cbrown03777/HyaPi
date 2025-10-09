-- Migration: upgrade rebalance_plans schema to new allocation engine format
-- Idempotent: guards each change

DO $$
BEGIN
	-- Rename columns if they exist in legacy form
	IF EXISTS (
		SELECT 1 FROM information_schema.columns
			WHERE table_name='rebalance_plans' AND column_name='orders'
	) THEN
		EXECUTE 'ALTER TABLE rebalance_plans RENAME COLUMN orders TO actions_json';
	END IF;
	IF EXISTS (
		SELECT 1 FROM information_schema.columns
			WHERE table_name='rebalance_plans' AND column_name='total_usd'
	) THEN
		EXECUTE 'ALTER TABLE rebalance_plans RENAME COLUMN total_usd TO tvl_usd';
	END IF;

	-- Add new columns if missing
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
			WHERE table_name='rebalance_plans' AND column_name='buffer_usd'
	) THEN
		EXECUTE 'ALTER TABLE rebalance_plans ADD COLUMN buffer_usd numeric(24,6) NOT NULL DEFAULT 0';
	END IF;
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
			WHERE table_name='rebalance_plans' AND column_name='drift_bps'
	) THEN
		EXECUTE 'ALTER TABLE rebalance_plans ADD COLUMN drift_bps integer NOT NULL DEFAULT 0';
	END IF;
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
			WHERE table_name='rebalance_plans' AND column_name='target_json'
	) THEN
		EXECUTE 'ALTER TABLE rebalance_plans ADD COLUMN target_json jsonb NOT NULL DEFAULT ''{}''::jsonb';
	END IF;
	IF NOT EXISTS (
		SELECT 1 FROM information_schema.columns
			WHERE table_name='rebalance_plans' AND column_name='status'
	) THEN
		EXECUTE 'ALTER TABLE rebalance_plans ADD COLUMN status text NOT NULL DEFAULT ''planned''';
	END IF;

	-- Ensure actions_json column has jsonb type & default
	IF EXISTS (
		SELECT 1 FROM information_schema.columns WHERE table_name='rebalance_plans' AND column_name='actions_json'
	) THEN
		EXECUTE 'ALTER TABLE rebalance_plans ALTER COLUMN actions_json SET DEFAULT ''[]''::jsonb';
	END IF;

	-- Index for history queries (created_at DESC) – btree on created_at
	IF NOT EXISTS (
		SELECT 1 FROM pg_class c JOIN pg_index i ON c.oid=i.indexrelid JOIN pg_class t ON t.oid=i.indrelid
		 WHERE c.relname='idx_rebalance_plans_created_at'
			 AND t.relname='rebalance_plans'
	) THEN
		EXECUTE 'CREATE INDEX idx_rebalance_plans_created_at ON rebalance_plans(created_at DESC)';
	END IF;
END$$;

-- Seed initial holdings if empty, to avoid full-allocation plans every time
INSERT INTO venue_holdings(key, usd_notional)
SELECT v.key, v.usd_notional FROM (
	VALUES
		('aave:USDT', 2500.0),
		('justlend:USDT', 1500.0),
		('stride:stATOM', 3000.0)
) AS v(key, usd_notional)
WHERE NOT EXISTS (SELECT 1 FROM venue_holdings);
