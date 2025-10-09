<!--
Step 0 — Schema introspection snapshot (to be run against Render Postgres):

Paste results of these queries here for quick reference.

-- users: confirm columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='users'
ORDER BY ordinal_position;

-- pi_payments: confirm columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name='pi_payments'
ORDER BY ordinal_position;

-- stakes, balances, liquidity_events: confirm columns
SELECT column_name, data_type, is_nullable
FROM information_schema.columns
WHERE table_schema='public' AND table_name IN ('stakes','balances','liquidity_events')
ORDER BY table_name, ordinal_position;

Notes:
- Code expects users.id (PK), users.pi_uid (TEXT UNIQUE), users.username (TEXT), optionally users.pi_address.
- Code persists pi_payments payload, txid, memo, lockup_weeks, from/to addresses, direction='user_to_app'.
- Liquidity events use idem_key=<payment identifier> and meta JSON with { paymentId, txid, memo, lockupWeeks }.
-->
