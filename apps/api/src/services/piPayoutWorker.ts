import { db, withTx } from './db';
import { platformGetPayment } from './piPlatform';

type SweepResult = { checked: number; completed: number; updated: number; errors: number };

export async function runPiPayoutSweep(limit = 10): Promise<SweepResult> {
  const res: SweepResult = { checked: 0, completed: 0, updated: 0, errors: 0 };
  // Find A2U payments that are not completed yet
  const q = await db.query<{ pi_payment_id: string }>(
    `SELECT pi_payment_id
       FROM pi_payments
      WHERE direction='A2U' AND status <> 'completed'
      ORDER BY updated_at ASC NULLS FIRST, created_at ASC
      LIMIT $1`,
    [limit]
  );
  for (const row of q.rows) {
    res.checked++;
    const pid = row.pi_payment_id;
    try {
      // Skip dev placeholder IDs created when ALLOW_DEV_TOKENS=1
      if (pid.startsWith('dev-')) {
        await db.query(
          `UPDATE pi_payments SET status='completed', txid = COALESCE(txid, $2), updated_at=now() WHERE pi_payment_id=$1`,
          [pid, `dev-txid-${Date.now()}`]
        );
        res.completed++;
        continue;
      }
      const r = await platformGetPayment(pid);
      const data: any = r?.data ?? {};
      const status: string = data?.status ?? '';
      const amount = Number(data?.amount ?? 0);
      const metadata = data?.metadata ?? {};
      const txid = data?.txid ?? data?.transaction_id ?? data?.transaction?.txid ?? null;

      if (!status) continue;

      if (status === 'completed' || status === 'succeeded' || status === 'paid') {
        await withTx(async (tx) => {
          await tx.query(
            `UPDATE pi_payments
                SET status='completed', txid=COALESCE($2, txid), amount_pi=COALESCE($3, amount_pi), updated_at=now()
              WHERE pi_payment_id=$1`,
            [pid, txid, Number.isFinite(amount) ? amount : null]
          );
          // If tied to a redemption, mark it paid
          const redemptionId = Number(metadata?.redemptionId ?? NaN);
          if (Number.isFinite(redemptionId)) {
            await tx.query(
              `UPDATE redemptions SET status='paid', updated_at=now() WHERE id=$1 AND status <> 'paid'`,
              [redemptionId]
            );
          }
        });
        res.completed++;
      } else if (status !== 'created' && status !== 'pending' && status !== 'approved') {
        // Any other terminal state—still update our status string for visibility
        await db.query(
          `UPDATE pi_payments SET status=$2, updated_at=now() WHERE pi_payment_id=$1`,
          [pid, status]
        );
        res.updated++;
      } else {
        // Mirror intermediate status to keep UI in sync
        await db.query(
          `UPDATE pi_payments SET status=$2, updated_at=now() WHERE pi_payment_id=$1 AND status <> $2`,
          [pid, status]
        );
        res.updated++;
      }
    } catch (e: any) {
      res.errors++;
      const msg = e?.message ?? String(e);
      console.error('pi payout sweep error', pid, msg);
    }
  }
  return res;
}

let intervalHandle: NodeJS.Timer | null = null;
export function startPiPayoutWorker() {
  const ms = Number(process.env.PI_POLL_INTERVAL_MS ?? 15000);
  if (intervalHandle) return; // already running
  intervalHandle = setInterval(() => {
    runPiPayoutSweep().catch((e) => console.error('pi payout sweep tick error', e?.message ?? e));
  }, Math.max(5000, ms));
}
