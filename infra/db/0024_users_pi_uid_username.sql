-- 0024_users_pi_uid_username.sql
-- Ensure users has pi_uid and username columns with unique index on pi_uid (idempotent)

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='pi_uid'
  ) THEN
    ALTER TABLE public.users ADD COLUMN pi_uid TEXT;
  END IF;

  IF NOT EXISTS (
    SELECT 1 FROM information_schema.columns
    WHERE table_schema='public' AND table_name='users' AND column_name='username'
  ) THEN
    ALTER TABLE public.users ADD COLUMN username TEXT;
  END IF;

  -- Unique index on pi_uid
  IF NOT EXISTS (
    SELECT 1 FROM pg_indexes WHERE schemaname='public' AND tablename='users' AND indexname='users_pi_uid_key'
  ) THEN
    CREATE UNIQUE INDEX users_pi_uid_key ON public.users(pi_uid);
  END IF;
END$$;
