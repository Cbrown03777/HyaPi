import { withTx } from '../services/db';
import { PoolClient } from 'pg';

interface RecordPaymentArgs {
  identifier: string;
  user_uid: string;
  username?: string | null;
  amount: number;
  txid?: string | null;
  metadata?: any;
  from_address?: string | null;
  to_address?: string | null;
  raw?: any;
}

export async function recordPiPayment(args: RecordPaymentArgs) {
  const { identifier, user_uid, username, amount, txid, metadata, from_address, to_address, raw } = args;
  const memo = (raw?.memo ?? null) as string | null;
  const lockupWeeks = Number(raw?.metadata?.lockupWeeks ?? 0) || 0;
  const direction = 'user_to_app';
  await withTx(async (tx: PoolClient) => {
    // Ensure a user exists (by pi_uid) and keep latest username if provided
    await tx.query(
      `INSERT INTO users(pi_uid, username)
       VALUES ($1, $2)
       ON CONFLICT (pi_uid) DO UPDATE SET username = COALESCE(EXCLUDED.username, users.username)`,
      [user_uid, username ?? null]
    );
    await tx.query(
      `INSERT INTO pi_payments (pi_payment_id, uid, amount_pi, status, txid, payload, from_address, to_address, memo, lockup_weeks, direction)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11)
       ON CONFLICT (pi_payment_id) DO UPDATE SET
         amount_pi = EXCLUDED.amount_pi,
         status = EXCLUDED.status,
         txid = COALESCE(pi_payments.txid, EXCLUDED.txid),
         payload = EXCLUDED.payload,
         from_address = COALESCE(EXCLUDED.from_address, pi_payments.from_address),
         to_address = COALESCE(EXCLUDED.to_address, pi_payments.to_address),
         memo = COALESCE(EXCLUDED.memo, pi_payments.memo),
         lockup_weeks = COALESCE(EXCLUDED.lockup_weeks, pi_payments.lockup_weeks),
         direction = 'user_to_app',
         updated_at = now()`,
      [identifier, user_uid, amount, 'completed', txid || null, raw || null, from_address || null, to_address || null, memo, lockupWeeks, direction]
    );
  });
}

interface CreditArgs { user_uid: string; username?: string | null; amount: number; lockWeeks: number; paymentId: string; txid?: string | null; memo?: string | null }

export async function creditStakeForDeposit(args: CreditArgs) {
  const { user_uid, username, amount, lockWeeks, paymentId, txid, memo } = args;
  return withTx(async (tx: PoolClient) => {
    // Upsert user by pi_uid and retrieve id
    const u = await tx.query<{ id: number }>(
      `INSERT INTO users(pi_uid, username)
       VALUES ($1, $2)
       ON CONFLICT (pi_uid) DO UPDATE SET username = COALESCE(EXCLUDED.username, users.username)
       RETURNING id`,
      [user_uid, username ?? null]
    );
    const userId = u.rows[0]?.id;
    if (!userId) throw new Error('user_not_found');

    // Determine APY (simplified): pick highest tier min_weeks <= lockWeeks
    const apyQ = await tx.query<{ apy_bps: number }>(
      `SELECT apy_bps FROM apy_tiers WHERE min_weeks <= $1 ORDER BY min_weeks DESC LIMIT 1`,
      [lockWeeks]
    );
    const apy_bps = apyQ.rows[0]?.apy_bps ?? 500;
    const init_fee_bps = lockWeeks === 0 ? 50 : 0;

    // Idempotency via liquidity_events.idem_key
    const idemKey = paymentId; // canonical: raw identifier
    const existed = await tx.query(`SELECT 1 FROM liquidity_events WHERE idem_key=$1 LIMIT 1`, [idemKey]);
    if ((existed?.rowCount || 0) > 0) {
      return { stakeId: undefined, amount, lockWeeks, apy_bps };
    }

    const stake = await tx.query<{ id: number; amount_pi: string; lockup_weeks: number }>(
      `INSERT INTO stakes (user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT DO NOTHING RETURNING id, amount_pi, lockup_weeks`,
      [userId, amount, lockWeeks, apy_bps, init_fee_bps]
    );

    // Credit balances table
    await tx.query(
      `INSERT INTO balances (user_id, hyapi_amount)
       VALUES ($1,$2)
       ON CONFLICT (user_id) DO UPDATE SET hyapi_amount = balances.hyapi_amount + EXCLUDED.hyapi_amount`,
      [userId, amount]
    );

    // Insert liquidity event (idempotent by unique index)
    const piUsd = Number(process.env.PI_USD_PRICE ?? '0.35');
    try {
      await tx.query(
        `INSERT INTO liquidity_events(kind, amount_usd, tx_ref, idem_key, amount, meta)
         VALUES ('deposit', $1, $2, $3, $4, $5::jsonb)`,
        [amount * piUsd, txid ? `pi:${paymentId}:${txid}` : `pi:${paymentId}`, idemKey, amount, JSON.stringify({ paymentId, txid: txid ?? null, memo: memo ?? null, lockupWeeks: lockWeeks })]
      );
    } catch {}

    return { stakeId: stake.rows[0]?.id, amount, lockWeeks, apy_bps };
  });
}
