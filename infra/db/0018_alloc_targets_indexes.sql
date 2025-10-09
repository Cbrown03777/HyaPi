-- 0018_alloc_targets_indexes.sql
-- Add indexes for allocation_targets and normalization column for gov_allocation_history.

-- Indexes to optimize precedence lookups and recency queries.
CREATE INDEX IF NOT EXISTS idx_allocation_targets_source_applied_at
  ON allocation_targets(source, applied_at DESC);
CREATE INDEX IF NOT EXISTS idx_allocation_targets_key_source
  ON allocation_targets(key, source);

-- Add normalization column to history table to record original sum of weights prior to normalization.
ALTER TABLE gov_allocation_history
  ADD COLUMN IF NOT EXISTS normalization NUMERIC(10,8);

-- Backfill null normalization values to 1 (legacy rows assumed already normalized).
UPDATE gov_allocation_history SET normalization = 1
 WHERE normalization IS NULL;
