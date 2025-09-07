// src/services/gov.ts
import { db } from './db';
import { aave, justlend, stride, Rate } from '@hyapi/venues';

export async function ensureSnapshot() {
  // take latest balances.hyapi_amount snapshot
  const total = (await db.query(`SELECT COALESCE(SUM(hyapi_amount),0) total FROM balances`)).rows[0].total ?? '0';
  const snap = (await db.query(`INSERT INTO gov_power_snapshots(snap_ts,total_hyapi_supply) VALUES (now(),$1) RETURNING id`, [total])).rows[0];
  await db.query(`
    INSERT INTO gov_power_snapshot_items(snapshot_id,user_id,voting_power)
    SELECT $1, u.id, b.hyapi_amount
    FROM users u LEFT JOIN balances b ON b.user_id=u.id
  `, [snap.id]);
  return { snapshot_id: snap.id, total_supply: total };
}

export async function hasProposerPower(userId: number, snapshotId: number) {
  const [{ total }] = (await db.query(`SELECT total_hyapi_supply AS total FROM gov_power_snapshots WHERE id=$1`, [snapshotId])).rows;
  const [{ power }] = (await db.query(`SELECT COALESCE(voting_power,0) AS power FROM gov_power_snapshot_items WHERE snapshot_id=$1 AND user_id=$2`, [snapshotId, userId])).rows;
  const [{ bps }] = (await db.query(`SELECT min_proposer_power_bps AS bps FROM gov_params WHERE id=1`)).rows;
  return Number(power) >= Number(total) * (bps/10000);
}

export async function scheduleWindow() {
  // simple: start now, end now + 7d (align to cadence in production)
  const start = new Date();
  const end = new Date(Date.now() + 7*24*3600*1000);
  return { start_ts: start.toISOString(), end_ts: end.toISOString() };
}

export async function getSnapshotPower(snapshotId: number, userId: number) {
  const row = (await db.query(`SELECT voting_power FROM gov_power_snapshot_items WHERE snapshot_id=$1 AND user_id=$2`, [snapshotId, userId])).rows[0];
  return row?.voting_power ?? '0';
}

export async function getGovParams() {
  return (await db.query(`SELECT * FROM gov_params WHERE id=1`)).rows[0];
}

export async function computeNextEpochStart(cadence: 'monthly'|'quarterly'|string) {
  const now = new Date();
  if (cadence === 'monthly') {
    const d = new Date(Date.UTC(now.getUTCFullYear(), now.getUTCMonth()+1, 1, 0,0,0));
    return d;
  }
  // quarterly
  const month = now.getUTCMonth();
  const qStartMonth = month - (month % 3) + 3; // next quarter start
  const d = new Date(Date.UTC(now.getUTCFullYear() + (qStartMonth>11?1:0), qStartMonth%12, 1, 0,0,0));
  return d;
}

// ---- Composite external venue rates (read-only) ----
export async function getCompositeRates(): Promise<Rate[]> {
  const [a, j, s] = await Promise.all([
    aave.getLiveRates(['USDT','USDC','DAI']).catch(()=>[]),
    justlend.getLiveRates(['USDT','USDD']).catch(()=>[]),
    stride.getLiveRates(['stATOM','stTIA']).catch(()=>[])
  ]);
  return [...a, ...j, ...s];
}
