-- Idempotent create / upgrade for venue_rates
DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.tables WHERE table_name='venue_rates'
  ) THEN
    CREATE TABLE venue_rates (
      id          bigserial PRIMARY KEY,
      key         text,                 -- legacy composite key (venue:market)
      venue       text NOT NULL,
      chain       text,                 -- optional multi-chain
      market      text NOT NULL,
      base_apr    numeric(12,8) NOT NULL,
      base_apy    double precision,
      reward_apr  double precision,
      reward_apy  double precision,
      source      text,
      as_of       timestamptz NOT NULL,
      created_at  timestamptz NOT NULL DEFAULT now(),
      fetched_at  timestamptz NOT NULL DEFAULT now()
    );
  ELSE
    -- Add columns if missing
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='venue') THEN
      ALTER TABLE venue_rates ADD COLUMN venue text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='chain') THEN
      ALTER TABLE venue_rates ADD COLUMN chain text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='market') THEN
      ALTER TABLE venue_rates ADD COLUMN market text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='base_apy') THEN
      ALTER TABLE venue_rates ADD COLUMN base_apy double precision;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='reward_apr') THEN
      ALTER TABLE venue_rates ADD COLUMN reward_apr double precision;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='reward_apy') THEN
      ALTER TABLE venue_rates ADD COLUMN reward_apy double precision;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='source') THEN
      ALTER TABLE venue_rates ADD COLUMN source text;
    END IF;
    IF NOT EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='fetched_at') THEN
      ALTER TABLE venue_rates ADD COLUMN fetched_at timestamptz DEFAULT now();
    END IF;
    -- Backfill venue & market from legacy key if they are still NULL
    IF EXISTS (SELECT 1 FROM information_schema.columns WHERE table_name='venue_rates' AND column_name='key') THEN
      UPDATE venue_rates
         SET venue = COALESCE(venue, split_part(key,':',1)),
             market = COALESCE(market, split_part(key,':',2))
       WHERE (venue IS NULL OR market IS NULL) AND key IS NOT NULL;
    END IF;
  END IF;
END $$;

CREATE INDEX IF NOT EXISTS idx_venue_rates_lookup ON venue_rates (venue, chain, market, fetched_at DESC);
