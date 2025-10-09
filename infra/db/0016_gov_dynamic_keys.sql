-- 0016_gov_dynamic_keys.sql
-- Transition governance proposal allocations from fixed chain enum (sui/aptos/cosmos)
-- to dynamic allocation keys (e.g. aave:USDT, stride:stATOM, etc.).
--
-- Idempotent operations: drop old CHECK constraint if present, rename column, and
-- adjust any dependent objects safely. Existing rows are preserved.

DO $$
BEGIN
  -- Drop old check constraint if it exists
  IF EXISTS (
    SELECT 1 FROM pg_constraint WHERE conname = 'gov_proposal_allocations_chain_check'
  ) THEN
    ALTER TABLE gov_proposal_allocations DROP CONSTRAINT gov_proposal_allocations_chain_check;
  END IF;

  -- Rename column chain -> key if still named chain
  IF EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_name='gov_proposal_allocations' AND column_name='chain'
  ) AND NOT EXISTS (
    SELECT 1 FROM information_schema.columns
     WHERE table_name='gov_proposal_allocations' AND column_name='key'
  ) THEN
    ALTER TABLE gov_proposal_allocations RENAME COLUMN chain TO key;
  END IF;

  -- Ensure primary key still (proposal_id, key). Recreate if missing.
  IF NOT EXISTS (
    SELECT 1 FROM pg_constraint
     WHERE conrelid = 'gov_proposal_allocations'::regclass
       AND contype = 'p'
  ) THEN
    ALTER TABLE gov_proposal_allocations ADD PRIMARY KEY (proposal_id, key);
  END IF;
END$$;

-- Optional: future constraint could validate basic shape (length) of key
-- but we intentionally allow broad set (validated at application layer).
