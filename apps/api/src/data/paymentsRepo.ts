import { withTx } from '../services/db';
import { PoolClient } from 'pg';

interface RecordPaymentArgs {
  identifier: string;
  user_uid: string;
  amount: number;
  txid?: string | null;
  metadata?: any;
  from_address?: string | null;
  to_address?: string | null;
  raw?: any;
}

export async function recordPiPayment(args: RecordPaymentArgs) {
  const { identifier, user_uid, amount, txid, metadata, from_address, to_address, raw } = args;
  await withTx(async (tx: PoolClient) => {
    await tx.query(
      `INSERT INTO pi_payments (pi_payment_id, uid, amount_pi, status, txid, payload, from_address, to_address)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8)
       ON CONFLICT (pi_payment_id) DO UPDATE SET amount_pi=EXCLUDED.amount_pi, txid=COALESCE(pi_payments.txid, EXCLUDED.txid), payload=EXCLUDED.payload, updated_at=now()`,
      [identifier, user_uid, amount, 'completed', txid || null, raw || null, from_address || null, to_address || null]
    );
  });
}

interface CreditArgs { user_uid: string; amount: number; lockWeeks: number; paymentId: string; txid?: string | null; }

export async function creditStakeForDeposit(args: CreditArgs) {
  const { user_uid, amount, lockWeeks, paymentId } = args;
  // For now we require mapping from user_uid -> user_id; assuming users table has uid column.
  return withTx(async (tx: PoolClient) => {
    const u = await tx.query<{ id: number }>(`SELECT id FROM users WHERE uid=$1`, [user_uid]);
    const userId = u.rows[0]?.id;
    if (!userId) throw new Error('user_not_found');

    // Determine APY (simplified): pick highest tier min_weeks <= lockWeeks
    const apyQ = await tx.query<{ apy_bps: number }>(
      `SELECT apy_bps FROM apy_tiers WHERE min_weeks <= $1 ORDER BY min_weeks DESC LIMIT 1`,
      [lockWeeks]
    );
    const apy_bps = apyQ.rows[0]?.apy_bps ?? 500;
    const init_fee_bps = lockWeeks === 0 ? 50 : 0;

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

    return { stakeId: stake.rows[0]?.id, amount, lockWeeks, apy_bps };
  });
}
