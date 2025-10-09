-- 0019_alloc_buffer_baskets.sql
-- Adds TVL buffer, allocation baskets, and liquidity event journal.

-- 1) TVL buffer (singleton row id=1)
CREATE TABLE IF NOT EXISTS public.tvl_buffer (
  id          smallint PRIMARY KEY DEFAULT 1,
  buffer_usd  NUMERIC(20,6) NOT NULL DEFAULT 0,
  updated_at  timestamptz   NOT NULL DEFAULT now()
);

INSERT INTO public.tvl_buffer (id) VALUES (1)
ON CONFLICT (id) DO NOTHING;

-- 2) Allocation baskets (optional logical groupings of venues)
CREATE TABLE IF NOT EXISTS public.allocation_baskets (
  basket_id     text PRIMARY KEY,
  name          text NOT NULL,
  description   text,
  strategy_tag  text,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS public.allocation_basket_venues (
  basket_id      text NOT NULL REFERENCES public.allocation_baskets(basket_id) ON DELETE CASCADE,
  venue_key      text NOT NULL,
  basket_cap_bps integer,
  PRIMARY KEY (basket_id, venue_key)
);

-- 3) Liquidity / allocation event journal
-- Robust enum creation (idempotent). If type already exists we add any missing labels.
DO $$
BEGIN
  BEGIN
    CREATE TYPE public.liquidity_kind AS ENUM ('deposit','withdraw','rebalance_in','rebalance_out','fee','yield');
  EXCEPTION
    WHEN duplicate_object THEN
      -- Type exists: ensure each value present (ignore duplicates)
      BEGIN EXECUTE 'ALTER TYPE public.liquidity_kind ADD VALUE ' || quote_literal('deposit'); EXCEPTION WHEN duplicate_object THEN NULL; END;
      BEGIN EXECUTE 'ALTER TYPE public.liquidity_kind ADD VALUE ' || quote_literal('withdraw'); EXCEPTION WHEN duplicate_object THEN NULL; END;
      BEGIN EXECUTE 'ALTER TYPE public.liquidity_kind ADD VALUE ' || quote_literal('rebalance_in'); EXCEPTION WHEN duplicate_object THEN NULL; END;
      BEGIN EXECUTE 'ALTER TYPE public.liquidity_kind ADD VALUE ' || quote_literal('rebalance_out'); EXCEPTION WHEN duplicate_object THEN NULL; END;
      BEGIN EXECUTE 'ALTER TYPE public.liquidity_kind ADD VALUE ' || quote_literal('fee'); EXCEPTION WHEN duplicate_object THEN NULL; END;
      BEGIN EXECUTE 'ALTER TYPE public.liquidity_kind ADD VALUE ' || quote_literal('yield'); EXCEPTION WHEN duplicate_object THEN NULL; END;
  END;
END $$;

CREATE TABLE IF NOT EXISTS public.liquidity_events (
  id            bigserial PRIMARY KEY,
  kind          liquidity_kind NOT NULL,
  amount_usd    NUMERIC(20,6)  NOT NULL,
  venue_key     text,
  tx_ref        text,
  idem_key      text,
  plan_version  bigint,
  created_at    timestamptz NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_liq_events_kind_created_at ON public.liquidity_events(kind, created_at DESC);
CREATE UNIQUE INDEX IF NOT EXISTS uq_liq_events_idem_key ON public.liquidity_events(idem_key) WHERE idem_key IS NOT NULL;
