-- Idempotent backfill: enrich liquidity_events.meta with lockupWeeks, txid, paymentId from pi_payments
-- Safe to run multiple times

-- Backfill from pi_payments.payload.metadata and txid
UPDATE liquidity_events le
SET meta = COALESCE(le.meta, '{}'::jsonb) || jsonb_build_object(
  'lockupWeeks', COALESCE( (pp.payload->'metadata'->>'lockupWeeks')::int, 0 ),
  'txid', COALESCE( pp.txid, le.meta->>'txid' ),
  'paymentId', COALESCE( le.idem_key, pp.pi_payment_id )
)
FROM pi_payments pp
WHERE pp.pi_payment_id = le.idem_key
  AND (
    (le.meta->>'lockupWeeks') IS NULL OR
    (le.meta->>'paymentId')  IS NULL OR
    (le.meta->>'txid')       IS NULL
  );

-- Normalize deposit kinds to DEPOSIT
UPDATE liquidity_events
SET kind = 'DEPOSIT'
WHERE kind IS NULL OR kind ILIKE 'deposit%';
