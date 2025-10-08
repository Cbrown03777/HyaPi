import { db } from './db';

/**
 * One-time idempotent hotfixes for production DBs where infra/db migrations are not available.
 * Safe to run on every boot. Adds jsonb payload + auxiliary columns to pi_payments and
 * (optionally) meta support to liquidity_events for richer activity feeds.
 */
export async function runDbHotfixes() {
  await db.query(`
    DO $$
    BEGIN
      -- pi_payments payload jsonb
      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='pi_payments' AND column_name='payload'
      ) THEN
        ALTER TABLE public.pi_payments ADD COLUMN payload jsonb DEFAULT '{}'::jsonb NOT NULL;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='pi_payments' AND column_name='txid'
      ) THEN
        ALTER TABLE public.pi_payments ADD COLUMN txid text;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='pi_payments' AND column_name='status_text'
      ) THEN
        ALTER TABLE public.pi_payments ADD COLUMN status_text text;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='pi_payments' AND column_name='memo'
      ) THEN
        ALTER TABLE public.pi_payments ADD COLUMN memo text;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='pi_payments' AND column_name='lockup_weeks'
      ) THEN
        ALTER TABLE public.pi_payments ADD COLUMN lockup_weeks integer;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='pi_payments' AND column_name='from_address'
      ) THEN
        ALTER TABLE public.pi_payments ADD COLUMN from_address text;
      END IF;

      IF NOT EXISTS (
        SELECT 1 FROM information_schema.columns
        WHERE table_schema='public' AND table_name='pi_payments' AND column_name='to_address'
      ) THEN
        ALTER TABLE public.pi_payments ADD COLUMN to_address text;
      END IF;

      -- Optional liquidity_events enrichment (amount Pi + meta jsonb) – backward compatible
      IF EXISTS (
        SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='liquidity_events'
      ) THEN
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema='public' AND table_name='liquidity_events' AND column_name='amount'
        ) THEN
          ALTER TABLE public.liquidity_events ADD COLUMN amount numeric(20,6);
        END IF;
        IF NOT EXISTS (
          SELECT 1 FROM information_schema.columns
          WHERE table_schema='public' AND table_name='liquidity_events' AND column_name='meta'
        ) THEN
          ALTER TABLE public.liquidity_events ADD COLUMN meta jsonb;
        END IF;
      END IF;
    END$$;
  `);
}
