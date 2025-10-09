-- Pi payments bookkeeping and uid mapping

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

CREATE INDEX IF NOT EXISTS idx_pi_payments_uid ON public.pi_payments(uid);

-- Map Pi uid <-> local users.id (multiple devices same uid)
CREATE TABLE IF NOT EXISTS public.pi_identities (
  uid        text PRIMARY KEY,
  user_id    bigint NOT NULL REFERENCES public.users(id) ON DELETE CASCADE,
  username   text,
  created_at timestamptz NOT NULL DEFAULT now(),
  updated_at timestamptz NOT NULL DEFAULT now()
);
