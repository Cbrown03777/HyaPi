-- Upgrade existing venue_rates table (0011_alloc.sql) to richer schema if columns missing
ALTER TABLE venue_rates ADD COLUMN IF NOT EXISTS venue TEXT;
ALTER TABLE venue_rates ADD COLUMN IF NOT EXISTS chain TEXT;
ALTER TABLE venue_rates ADD COLUMN IF NOT EXISTS market TEXT;
ALTER TABLE venue_rates ADD COLUMN IF NOT EXISTS base_apy DOUBLE PRECISION;
ALTER TABLE venue_rates ADD COLUMN IF NOT EXISTS source TEXT;
ALTER TABLE venue_rates ADD COLUMN IF NOT EXISTS fetched_at TIMESTAMPTZ DEFAULT now();
-- Backfill venue/market/chain by splitting key when possible
UPDATE venue_rates SET venue = split_part(key,':',1), market = split_part(key,':',2) WHERE venue IS NULL;
-- Chain not derivable from old key; leave NULL for historical rows.
-- Create new composite index for queries by venue/chain/market/time
CREATE INDEX IF NOT EXISTS idx_venue_rates_vcm_fetch ON venue_rates (venue, chain, market, fetched_at DESC);
