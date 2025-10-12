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
  is_test?: boolean;
}

export async function recordPiPayment(args: RecordPaymentArgs) {
  const { identifier, user_uid, username, amount, txid, metadata, from_address, to_address, raw, is_test } = args;
  const memo = (raw?.memo ?? null) as string | null;
  const lockupWeeks = Number(raw?.metadata?.lockupWeeks ?? 0) || 0;
  const direction = 'user_to_app';
  await withTx(async (tx: PoolClient) => {
    // Upsert user by pi_uid. Only set pi_address when NULL or equal; guard unique violation.
    const existing = await tx.query<{ id:number; pi_address:string|null }>(`SELECT id, pi_address FROM users WHERE pi_uid=$1`, [user_uid]);
    if (existing.rowCount === 0) {
      try {
        await tx.query(
          `INSERT INTO users(pi_uid, username, pi_address)
           VALUES ($1, $2, $3)
           ON CONFLICT (pi_uid) DO UPDATE SET username = COALESCE(EXCLUDED.username, users.username)`,
          [user_uid, username ?? null, from_address ?? null]
        );
      } catch (err:any) {
        if (err?.code === '23505' && /users_pi_address_key/.test(err?.constraint || '')) {
          await tx.query(
            `INSERT INTO users(pi_uid, username)
             VALUES ($1, $2)
             ON CONFLICT (pi_uid) DO UPDATE SET username = COALESCE(EXCLUDED.username, users.username)`,
            [user_uid, username ?? null]
          );
        } else {
          throw err;
        }
      }
    } else {
      const current = existing.rows[0];
      if (!current.pi_address || (from_address && current.pi_address === from_address)) {
        try {
          await tx.query(`UPDATE users SET username = COALESCE($2, username), pi_address = COALESCE($3, pi_address) WHERE pi_uid=$1`, [user_uid, username ?? null, from_address ?? null]);
        } catch (err:any) {
          if (!(err?.code === '23505' && /users_pi_address_key/.test(err?.constraint || ''))) throw err;
          await tx.query(`UPDATE users SET username = COALESCE($2, username) WHERE pi_uid=$1`, [user_uid, username ?? null]);
        }
      } else {
        await tx.query(`UPDATE users SET username = COALESCE($2, username) WHERE pi_uid=$1`, [user_uid, username ?? null]);
      }
    }
    try {
      await tx.query(
        `INSERT INTO pi_payments (pi_payment_id, uid, amount_pi, status, txid, payload, from_address, to_address, memo, lockup_weeks, direction, is_test)
         VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12)
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
           is_test = EXCLUDED.is_test,
           updated_at = now()`,
        [identifier, user_uid, amount, 'completed', txid || null, raw || null, from_address || null, to_address || null, memo, lockupWeeks, direction, !!is_test]
      );
    } catch (e:any) {
      if (e?.code === '42703') { // undefined_column (is_test)
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
      } else {
        throw e;
      }
    }
  });
}

interface CreditArgs { user_uid: string; username?: string | null; amount: number; lockWeeks: number; paymentId: string; txid?: string | null; memo?: string | null; pi_address?: string | null; is_test?: boolean }

export async function creditStakeForDeposit(args: CreditArgs) {
  const { user_uid, username, amount, lockWeeks, paymentId, txid, memo, pi_address, is_test } = args;
  return withTx(async (tx: PoolClient) => {
    // Upsert user by pi_uid (robust pi_address handling)
    let userId: number | null = null;
    const found = await tx.query<{ id:number; pi_address:string|null }>(`SELECT id, pi_address FROM users WHERE pi_uid=$1`, [user_uid]);
    if (found.rowCount === 0) {
      try {
        const ins = await tx.query<{ id:number }>(
          `INSERT INTO users(pi_uid, username, pi_address)
           VALUES ($1,$2,$3)
           ON CONFLICT (pi_uid) DO UPDATE SET username = COALESCE(EXCLUDED.username, users.username)
           RETURNING id`,
          [user_uid, username ?? null, pi_address ?? null]
        );
        userId = ins.rows[0]?.id ?? null;
      } catch (err:any) {
        if (err?.code === '23505' && /users_pi_address_key/.test(err?.constraint || '')) {
          const ins2 = await tx.query<{ id:number }>(
            `INSERT INTO users(pi_uid, username)
             VALUES ($1,$2)
             ON CONFLICT (pi_uid) DO UPDATE SET username = COALESCE(EXCLUDED.username, users.username)
             RETURNING id`,
            [user_uid, username ?? null]
          );
          userId = ins2.rows[0]?.id ?? null;
        } else {
          throw err;
        }
      }
    } else {
      userId = found.rows[0].id;
      const curAddr = found.rows[0].pi_address;
      if (!curAddr || (pi_address && curAddr === pi_address)) {
        try {
          await tx.query(`UPDATE users SET username=COALESCE($2,username), pi_address=COALESCE($3,pi_address) WHERE pi_uid=$1`, [user_uid, username ?? null, pi_address ?? null]);
        } catch (err:any) {
          if (!(err?.code === '23505' && /users_pi_address_key/.test(err?.constraint || ''))) throw err;
          await tx.query(`UPDATE users SET username=COALESCE($2,username) WHERE pi_uid=$1`, [user_uid, username ?? null]);
        }
      } else {
        await tx.query(`UPDATE users SET username=COALESCE($2,username) WHERE pi_uid=$1`, [user_uid, username ?? null]);
      }
    }
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

    let stake;
    try {
      stake = await tx.query<{ id: number; amount_pi: string; lockup_weeks: number }>(
        `INSERT INTO stakes (user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps, is_test)
         VALUES ($1,$2,$3,$4,$5,$6)
         ON CONFLICT DO NOTHING RETURNING id, amount_pi, lockup_weeks`,
        [userId, amount, lockWeeks, apy_bps, init_fee_bps, !!is_test]
      );
    } catch (e:any) {
      if (e?.code === '42703') {
        stake = await tx.query<{ id: number; amount_pi: string; lockup_weeks: number }>(
          `INSERT INTO stakes (user_id, amount_pi, lockup_weeks, apy_bps, init_fee_bps)
           VALUES ($1,$2,$3,$4,$5)
           ON CONFLICT DO NOTHING RETURNING id, amount_pi, lockup_weeks`,
          [userId, amount, lockWeeks, apy_bps, init_fee_bps]
        );
      } else {
        throw e;
      }
    }

    // Credit balances table
    await tx.query(
      `INSERT INTO balances (user_id, hyapi_amount)
       VALUES ($1,$2)
       ON CONFLICT (user_id) DO UPDATE SET hyapi_amount = balances.hyapi_amount + EXCLUDED.hyapi_amount`,
      [userId, amount]
    );
    const bal = await tx.query<{ hyapi_amount: string }>(`SELECT hyapi_amount::text FROM balances WHERE user_id=$1`, [userId]);

    // Insert liquidity event (idempotent by unique index)
    const piUsd = Number(process.env.PI_USD_PRICE ?? '0.35');
    try {
      await tx.query(
        `INSERT INTO liquidity_events(kind, amount_usd, tx_ref, idem_key, amount, meta, is_test)
         VALUES ('deposit', $1, $2, $3, $4, $5::jsonb, $6)`,
        [amount * piUsd, txid ? `pi:${paymentId}:${txid}` : `pi:${paymentId}`, idemKey, amount, JSON.stringify({ paymentId, txid: txid ?? null, memo: memo ?? null, lockupWeeks: lockWeeks }), !!is_test]
      );
    } catch (e:any) {
      if (e?.code === '42703') {
        try {
          await tx.query(
            `INSERT INTO liquidity_events(kind, amount_usd, tx_ref, idem_key, amount, meta)
             VALUES ('deposit', $1, $2, $3, $4, $5::jsonb)`,
            [amount * piUsd, txid ? `pi:${paymentId}:${txid}` : `pi:${paymentId}`, idemKey, amount, JSON.stringify({ paymentId, txid: txid ?? null, memo: memo ?? null, lockupWeeks: lockWeeks })]
          );
        } catch {}
      }
    }

    // Mirror into TVL buffer exactly once per idemKey (same guard as above)
  await tx.query(`UPDATE tvl_buffer SET buffer_usd = buffer_usd + $1, updated_at = now() WHERE id=1`, [amount * piUsd]);

  console.log('[credit][ok]', { userId, amount, stakeId: stake.rows[0]?.id, lockWeeks, paymentId, idemKey, balanceAfter: Number(bal.rows[0]?.hyapi_amount ?? 0), is_test: !!is_test });

    return { stakeId: stake.rows[0]?.id, amount, lockWeeks, apy_bps };
  });
}
