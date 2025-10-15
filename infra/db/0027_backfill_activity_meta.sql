-- 0027_backfill_activity_meta.sql
-- Idempotent backfill: copy lockupWeeks/txid/paymentId into liquidity_events.meta
-- and normalize kind to the enum 'deposit' where appropriate.

-- 1) Backfill meta fields from pi_payments into liquidity_events
UPDATE liquidity_events le
SET meta =
  COALESCE(le.meta, '{}'::jsonb)
  || jsonb_strip_nulls(
       jsonb_build_object(
         'paymentId', COALESCE(le.idem_key, le.meta->>'paymentId', pp.pi_payment_id),
         'txid',      COALESCE(le.meta->>'txid', pp.txid),
         'lockupWeeks',
           COALESCE(
             NULLIF(le.meta->>'lockupWeeks','')::int,
             NULLIF(pp.payload->'metadata'->>'lockupWeeks','')::int,
             pp.lockup_weeks,
             0
           )
       )
     )
FROM pi_payments pp
WHERE COALESCE(le.idem_key, le.meta->>'paymentId') = pp.pi_payment_id
  AND (
      (le.meta->>'paymentId')  IS NULL
   OR (le.meta->>'txid')       IS NULL
   OR (le.meta->>'lockupWeeks') IS NULL
  );

-- 2) Normalize kind to 'deposit' (enum) when it is missing or looks like deposit
UPDATE liquidity_events
SET kind = 'deposit'::liquidity_kind
WHERE kind IS NULL
   OR (kind::text LIKE 'deposit%');
