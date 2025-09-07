import { db } from './db';

export async function ensurePiIntegration() {
  // Create required tables if they don't exist (safety net when container init scripts haven't run)
  await db.query(`
    CREATE TABLE IF NOT EXISTS public.pi_payments (
      id             bigserial PRIMARY KEY,
      pi_payment_id  text UNIQUE NOT NULL,
      direction      text NOT NULL CHECK (direction IN ('U2A','A2U')),
      uid            text NOT NULL,
      amount_pi      numeric(24,6) NOT NULL DEFAULT 0,
      status         text NOT NULL CHECK (status IN ('created','approved','completed','failed')),
      txid           text,
      created_at     timestamptz NOT NULL DEFAULT now(),
      updated_at     timestamptz NOT NULL DEFAULT now()
    );
  `);
  await db.query(`
    CREATE INDEX IF NOT EXISTS idx_pi_payments_uid ON public.pi_payments(uid);
  `);
  await db.query(`
    CREATE TABLE IF NOT EXISTS public.pi_identities (
      uid        text PRIMARY KEY,
      user_id    bigint NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      username   text,
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now()
    );
  `);

  // Minimal table to persist allocation plans (execute stub)
  await db.query(`
    CREATE TABLE IF NOT EXISTS public.rebalance_plans (
      id         bigserial PRIMARY KEY,
      total_usd  numeric(24,6) NOT NULL DEFAULT 0,
      orders     jsonb NOT NULL DEFAULT '[]'::jsonb,
      created_at timestamptz NOT NULL DEFAULT now()
    );
  `);
}
