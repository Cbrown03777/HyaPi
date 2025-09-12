import { db } from './db';

export async function ensurePiIntegration() {
  // Safety-net creation (idempotent) for Pi tables if migrations not yet applied.
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
  await db.query(`CREATE INDEX IF NOT EXISTS idx_pi_payments_uid ON public.pi_payments(uid);`);
  await db.query(`
    CREATE TABLE IF NOT EXISTS public.pi_identities (
      uid        text PRIMARY KEY,
      user_id    bigint NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
      username   text,
      created_at timestamptz NOT NULL DEFAULT now(),
      updated_at timestamptz NOT NULL DEFAULT now()
    );
  `);
}

export async function ensureBootstrap() {
  // Ensure singleton buffer row exists (after migration 0019, but safe if run earlier)
  try {
    await db.query(`INSERT INTO public.tvl_buffer (id) VALUES (1) ON CONFLICT (id) DO NOTHING;`);
  } catch (e: any) {
    // If table doesn't exist yet, swallow (migration not applied) – run after migrations in server.
    if (!/relation \"tvl_buffer\" does not exist/i.test(e?.message ?? '')) throw e;
  }
}
