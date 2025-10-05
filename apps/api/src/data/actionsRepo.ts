import { PoolClient } from 'pg';
import { db, withTx } from '../services/db';
import type { VenueKey, PlannedAction } from '../types/actions';

function err(code: string, message: string, status = 400) {
  const e: any = new Error(message);
  e.code = code; e.status = status; e.message = message; return e;
}

function rowToAction(r: any): PlannedAction {
  return {
    id: String(r.id),
    venue: String(r.venue_key ?? r.venue ?? ''),
    amountPI: Number(r.amount_pi ?? r.amountpi ?? r.amount_pi_num ?? 0),
    status: (String(r.status || r.state || 'Planned').toLowerCase() === 'confirmed') ? 'Confirmed' : 'Planned',
    createdAt: new Date(r.created_at ?? r.createdAt ?? Date.now()).toISOString(),
    note: r.note ?? undefined,
  };
}

// Helpers for buffer and venue balances
async function getBufferPI(client: PoolClient): Promise<number> {
  // Mirror table referenced in staking.ts (treasury.buffer_pi)
  const q = await client.query(`SELECT buffer_pi::text FROM treasury WHERE id=true`);
  return Number(q.rows[0]?.buffer_pi ?? 0);
}

async function setBufferPI(client: PoolClient, newVal: number) {
  await client.query(`UPDATE treasury SET buffer_pi = $1, last_updated=now() WHERE id=true`, [newVal]);
}

async function getVenuePI(client: PoolClient, venue: VenueKey): Promise<number> {
  // We don't have a PI mirror per venue, but we do have USD notionals. For this repo, track a new table if present; else store PI in an aux table.
  // Minimal approach: reuse venue_holdings to reflect USD; for returned venuePI, approximate via USD / price. However caller expects numbers, not exact accounting.
  // We'll keep a shadow table venue_balances_pi if exists else compute 0.
  const exists = await client.query(`SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='venue_balances_pi'`);
  if (exists.rowCount && exists.rows.length) {
    const r = await client.query(`SELECT deployed_pi::text FROM venue_balances_pi WHERE venue=$1`, [venue]);
    return Number(r.rows[0]?.deployed_pi ?? 0);
  }
  return 0;
}

async function addVenuePI(client: PoolClient, venue: VenueKey, deltaPI: number): Promise<number> {
  const exists = await client.query(`SELECT 1 FROM information_schema.tables WHERE table_schema='public' AND table_name='venue_balances_pi'`);
  if (exists.rowCount && exists.rows.length) {
    const r = await client.query(`INSERT INTO venue_balances_pi(venue, deployed_pi, updated_at) VALUES ($1,$2,now())
      ON CONFLICT (venue) DO UPDATE SET deployed_pi = venue_balances_pi.deployed_pi + EXCLUDED.deployed_pi, updated_at=now()
      RETURNING deployed_pi::text`, [venue, deltaPI]);
    return Number(r.rows[0]?.deployed_pi ?? 0);
  }
  // If shadow table missing, no-op and return 0 baseline
  return 0;
}

export async function createPlannedAction(venue: VenueKey, amountPI: number, note?: string): Promise<PlannedAction> {
  if (!venue || !(amountPI > 0)) throw err('INVALID_INPUT', 'venue and amountPI>0 required');
  try {
    const r = await db.query(`INSERT INTO planned_actions(kind, venue_key, amount_usd, status, reason)
      VALUES ('supply',$1,$2,'pending',$3) RETURNING id, venue_key, amount_usd, status, created_at`, [venue, amountPI /* store PI in amount_usd pending dedicated PI col */, note ?? null]);
    // For now, we overload amount_usd to carry PI notional until a dedicated column exists (documented quirk)
    return rowToAction({ ...r.rows[0], amount_pi: amountPI, status: 'Planned' });
  } catch (e:any) {
    throw err('DB_ERROR', e.message || 'create planned action failed', 500);
  }
}

export async function listActions(status?: 'Planned'|'Confirmed'): Promise<PlannedAction[]> {
  try {
    const rows = await db.query(`SELECT id, venue_key, amount_usd, status, created_at, reason AS note FROM planned_actions ORDER BY created_at DESC LIMIT 500`);
    return rows.rows.map(r => rowToAction({ ...r, amount_pi: Number(r.amount_usd ?? 0), status: (String(r.status).toLowerCase()==='confirmed')?'Confirmed':'Planned' }))
      .filter(a => !status || a.status === status);
  } catch (e:any) { throw err('DB_ERROR', e.message || 'list actions failed', 500); }
}

export async function getActionById(id: string): Promise<PlannedAction|null> {
  try {
    const r = await db.query(`SELECT id, venue_key, amount_usd, status, created_at, reason AS note FROM planned_actions WHERE id=$1`, [id]);
    const row = r.rows[0]; if (!row) return null;
    return rowToAction({ ...row, amount_pi: Number(row.amount_usd ?? 0), status: (String(row.status).toLowerCase()==='confirmed')?'Confirmed':'Planned' });
  } catch (e:any) { throw err('DB_ERROR', e.message || 'get action failed', 500); }
}

export async function markConfirmed(id: string, confirmAt: Date): Promise<void> {
  try { await db.query(`UPDATE planned_actions SET status='confirmed', updated_at=$2 WHERE id=$1`, [id, confirmAt]); }
  catch (e:any) { throw err('DB_ERROR', e.message || 'mark confirmed failed', 500); }
}

export async function wasIdempotencyKeyApplied(key: string): Promise<boolean> {
  try {
    const q = await db.query(`SELECT 1 FROM liquidity_events WHERE idem_key=$1`, [key]);
    return !!(q && typeof q.rowCount === 'number' && q.rowCount > 0);
  } catch (e:any) { throw err('DB_ERROR', e.message || 'idempotency check failed', 500); }
}

export async function insertLiquidityEvent(params: { actionId:string; venue:VenueKey; amountPI:number; avgPriceUSD:number; feeUSD:number; txUrl:string; filledAt:Date; idempotencyKey?:string }): Promise<{ auditId:string }>{
  try {
    // Record both a rebalance_in and a fee entry for audit clarity
    const amountUsd = params.amountPI * params.avgPriceUSD - (params.feeUSD || 0);
    const ins = await db.query(`INSERT INTO liquidity_events(kind, amount_usd, venue_key, tx_ref, idem_key, created_at)
      VALUES ('rebalance_in',$1,$2,$3,$4,$5)
      ON CONFLICT (idem_key) DO NOTHING
      RETURNING id`, [amountUsd, params.venue, params.txUrl, params.idempotencyKey || null, params.filledAt]);
    const id = String(ins.rows[0]?.id ?? 'rebalance_in');
    if (params.feeUSD && params.feeUSD > 0) {
      await db.query(`INSERT INTO liquidity_events(kind, amount_usd, venue_key, tx_ref, created_at)
        VALUES ('fee',$1,$2,$3,$4)`, [params.feeUSD, params.venue, params.txUrl, params.filledAt]);
    }
    return { auditId: id };
  } catch (e:any) { throw err('DB_ERROR', e.message || 'insert liquidity_event failed', 500); }
}

export async function applyBalancesDelta(params: { amountPI:number; venue:VenueKey }): Promise<{ bufferPI:number; venuePI:number }>{
  const { amountPI, venue } = params;
  try {
    return await withTx(async (client) => {
      const before = await getBufferPI(client);
      let newBuffer = before - amountPI;
      if (newBuffer < 0) { console.warn('[actionsRepo] buffer underflow, clamping to 0'); newBuffer = 0; }
      await setBufferPI(client, newBuffer);
      const venuePI = await addVenuePI(client, venue, amountPI);
      return { bufferPI: newBuffer, venuePI };
    });
  } catch (e:any) { throw err('DB_ERROR', e.message || 'apply balances failed', 500); }
}
