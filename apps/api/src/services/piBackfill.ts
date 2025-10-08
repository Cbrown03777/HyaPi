import { db } from './db';

/**
 * Backfills memo and lockup_weeks for historic pi_payments rows using stored payload JSON.
 * Idempotent and safe to run repeatedly.
 */
export async function backfillPiPaymentMetadata() {
  // 1) Backfill memo where empty / null and payload has memo
  const r1 = await db.query(`
    WITH cte AS (
      UPDATE pi_payments p
         SET memo = p.payload->>'memo'
       WHERE (p.memo IS NULL OR p.memo='')
         AND p.payload ? 'memo'
         AND (p.payload->>'memo') IS NOT NULL
       RETURNING 1
    ) SELECT COUNT(*)::int AS cnt FROM cte;`);

  // 2) Backfill lockup_weeks where 0 or null but payload.metadata.lockupWeeks > 0
  const r2 = await db.query(`
    WITH cte AS (
      UPDATE pi_payments p
         SET lockup_weeks = ((p.payload->'metadata'->>'lockupWeeks')::int)
       WHERE (p.lockup_weeks IS NULL OR p.lockup_weeks = 0)
         AND (p.payload->'metadata'->>'lockupWeeks') ~ '^[0-9]+'
         AND ((p.payload->'metadata'->>'lockupWeeks')::int) > 0
       RETURNING 1
    ) SELECT COUNT(*)::int AS cnt FROM cte;`);

  // 3) Optionally backfill status_text if null
  const r3 = await db.query(`
    WITH cte AS (
      UPDATE pi_payments p
         SET status_text = CASE
              WHEN (p.payload->'status'->>'developer_completed')::text = 'true' THEN 'completed'
              WHEN (p.payload->'status'->>'developer_approved')::text = 'true' THEN 'approved'
              ELSE COALESCE(p.status_text,'created') END
       WHERE p.status_text IS NULL
       RETURNING 1
    ) SELECT COUNT(*)::int AS cnt FROM cte;`);

  // 4) Backfill addresses if missing in columns but present in payload
  const r4 = await db.query(`
    WITH cte AS (
      UPDATE pi_payments p
         SET from_address = COALESCE(p.from_address, p.payload->>'from_address'),
             to_address = COALESCE(p.to_address, p.payload->>'to_address')
       WHERE (p.from_address IS NULL AND (p.payload ? 'from_address'))
          OR (p.to_address IS NULL AND (p.payload ? 'to_address'))
       RETURNING 1
    ) SELECT COUNT(*)::int AS cnt FROM cte;`);

  const updated = {
    memo: r1.rows[0]?.cnt ?? 0,
    lockup_weeks: r2.rows[0]?.cnt ?? 0,
    status_text: r3.rows[0]?.cnt ?? 0,
    addresses: r4.rows[0]?.cnt ?? 0
  };
  if (Object.values(updated).some(c => c > 0)) {
    console.log('[piPayments/backfill]', updated);
  }
  return updated;
}
