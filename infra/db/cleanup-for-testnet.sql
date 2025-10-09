BEGIN;

-- Keep: nav_history (APY story), _migrations (history).
-- Scrub: simulated stakes, redemptions, allocations, planned actions, venue balances, token transfers, dev payments, governance proposals (simulated), votes (simulated).

-- Helper: safely truncate if table exists
DO $$
DECLARE
  t TEXT;
  tables TEXT[] := ARRAY[
    -- Staking domain
    'stakes',
    'redemptions',
    'token_transfers',
    -- Allocation domain
    'allocation_history',
    'gov_allocation_history',
    'allocation_targets',
    'alloc_buffer_baskets',
    'planned_actions',
    -- Venue/rates/balances
    'venue_balances',
    'venue_rates',
    -- Payments (dev/test only)
    'pi_payments',
    -- Governance (only if your current data is simulated; remove lines if you want to keep real history)
    'proposals',
    'proposal_votes',
    'proposal_suggestions'
  ];
BEGIN
  FOREACH t IN ARRAY tables LOOP
    IF EXISTS (
      SELECT 1
      FROM information_schema.tables
      WHERE table_schema='public' AND table_name=t
    ) THEN
      EXECUTE format('TRUNCATE TABLE public.%I RESTART IDENTITY CASCADE;', t);
    END IF;
  END LOOP;
END $$;

-- (Optional) If you have materialized views or summary tables, refresh or clear them here.

COMMIT;
