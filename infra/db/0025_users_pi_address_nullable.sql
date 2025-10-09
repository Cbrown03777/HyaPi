-- 0025_users_pi_address_nullable.sql
-- Relax users.pi_address NOT NULL to prevent /v1/pi/complete failures when Pi address is absent.

-- Make pi_address nullable (safe if already nullable)
ALTER TABLE IF EXISTS public.users ALTER COLUMN pi_address DROP NOT NULL;

-- Ensure a unique index exists on pi_address for auth mapping (safe if exists)
CREATE UNIQUE INDEX IF NOT EXISTS users_pi_address_key ON public.users(pi_address);
