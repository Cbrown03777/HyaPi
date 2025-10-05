// apps/api/src/data/govRepo.ts
import { db, withTx, type PoolClient } from '../services/db';
import type { UserLock } from '../gov/types';
import type { ProposalList, ProposalStatus } from '../types/gov';

async function ensureGovernanceLocks(client: PoolClient) {
  await client.query(`
    CREATE TABLE IF NOT EXISTS governance_locks (
      user_id TEXT PRIMARY KEY,
      term_weeks INTEGER NOT NULL CHECK (term_weeks IN (26,52,104)),
      locked_at TIMESTAMPTZ NOT NULL DEFAULT now(),
      unlock_at TIMESTAMPTZ NOT NULL,
      tx_url TEXT
    )
  `);
}

export async function getUserLock(userId: string): Promise<UserLock | null> {
  const q = await db.query<{
    user_id: string; term_weeks: number; locked_at: Date; unlock_at: Date; tx_url: string | null;
  }>(`SELECT user_id, term_weeks, locked_at, unlock_at, tx_url FROM governance_locks WHERE user_id=$1`, [String(userId)]);
  if (!q.rowCount) return null;
  const r = q.rows[0];
  return {
    userId: r.user_id,
    termWeeks: (r.term_weeks as 26|52|104),
    lockedAt: r.locked_at.toISOString(),
    unlockAt: r.unlock_at.toISOString(),
    txUrl: r.tx_url ?? null,
  };
}

export async function upsertUserLock(input: { userId: string; termWeeks: 26|52|104; lockedAt?: Date; txUrl?: string | null }): Promise<UserLock> {
  return withTx(async (tx) => {
    await ensureGovernanceLocks(tx);
    const lockedAt = input.lockedAt ?? new Date();
    const unlockAt = new Date(lockedAt.getTime() + input.termWeeks * 7 * 24 * 60 * 60 * 1000);
    await tx.query(
      `INSERT INTO governance_locks(user_id, term_weeks, locked_at, unlock_at, tx_url)
       VALUES ($1,$2,$3,$4,$5)
       ON CONFLICT (user_id) DO UPDATE SET
         term_weeks = EXCLUDED.term_weeks,
         locked_at = EXCLUDED.locked_at,
         unlock_at = EXCLUDED.unlock_at,
         tx_url = EXCLUDED.tx_url`,
      [String(input.userId), input.termWeeks, lockedAt, unlockAt, input.txUrl ?? null]
    );
    return {
      userId: String(input.userId),
      termWeeks: input.termWeeks,
      lockedAt: lockedAt.toISOString(),
      unlockAt: unlockAt.toISOString(),
      txUrl: input.txUrl ?? null,
    };
  });
}

// Per-user APY scaling is removed. This function may be extended to migrate/clear legacy flags.
export async function clearApyScalingFlags(): Promise<void> {
  try {
    // If a legacy column exists, normalize values to no-op (1.0) or drop. Soft approach: set to NULL/1.0.
    const col = await db.query<{ exists: boolean }>(
      `SELECT EXISTS (
         SELECT 1 FROM information_schema.columns
          WHERE table_schema='public' AND table_name='users' AND column_name='apy_multiplier'
       ) AS exists`
    );
    if (col.rows[0]?.exists) {
      await db.query(`UPDATE users SET apy_multiplier = 1.0 WHERE apy_multiplier IS DISTINCT FROM 1.0`).catch(()=>{});
    }
  } catch {/* ignore */}
}

// ---- Governance proposals (read-only helpers) ----
export function toUiStatus(dbRow: any): ProposalStatus {
  const raw = String(dbRow?.status ?? '').toLowerCase();
  switch (raw) {
    case 'active': return 'Open';
    case 'finalized': return 'Closed';
    case 'executed': return 'Passed';
    case 'rejected': return 'Rejected';
    case 'failed': return 'Failed';
    case 'canceled': return 'Canceled';
    default: {
      // derive from end_time if available
      try {
        const endISO = dbRow?.end_ts || dbRow?.end_time || dbRow?.endTimeISO;
        if (endISO && new Date(endISO).getTime() < Date.now()) return 'Closed';
      } catch {}
      return 'Open';
    }
  }
}

export async function listProposals(opts: { limit: number; cursor?: string | null; status?: ProposalStatus | 'All' }): Promise<ProposalList> {
  const limit = Math.max(1, Math.min(100, Number(opts.limit || 20)));
  const status = opts.status ?? 'All';
  let cursorEndISO: string | null = null;
  if (opts.cursor) {
    try {
      const decoded = Buffer.from(String(opts.cursor), 'base64').toString('utf8');
      const parts = decoded.split('|');
      cursorEndISO = parts[0] || null;
    } catch { cursorEndISO = opts.cursor; }
  }
  try {
    const params: any[] = [];
    let where = '1=1';
    if (status && status !== 'All') {
      if (status === 'Open') {
        where += ` AND p.status = 'active' AND p.end_ts > now()`;
      } else if (status === 'Closed') {
        where += ` AND (p.status <> 'active' OR p.end_ts <= now())`;
      } else if (status === 'Passed') {
        where += ` AND p.status = 'executed'`;
      } else if (status === 'Rejected') {
        where += ` AND p.status = 'rejected'`;
      } else if (status === 'Failed') {
        where += ` AND p.status = 'failed'`;
      } else if (status === 'Canceled') {
        where += ` AND p.status = 'canceled'`;
      }
    }
    if (cursorEndISO) { params.push(cursorEndISO); where += ` AND p.end_ts < $${params.length}::timestamptz`; }
    params.push(limit + 1); // fetch one extra to decide nextCursor
    const sql = `
      SELECT p.id, p.title, SUBSTRING(COALESCE(p.description,'') FOR 140) AS summary,
             p.status, p.start_ts, p.end_ts,
             COALESCE(t.for_power,'0') AS for_power,
             COALESCE(t.against_power,'0') AS against_power,
             COALESCE(t.abstain_power,'0') AS abstain_power,
             COALESCE(p.created_at, p.start_ts) AS created_at,
             COALESCE(p.updated_at, COALESCE(p.created_at, p.start_ts)) AS updated_at
      FROM gov_proposals p
      LEFT JOIN gov_tallies t ON t.proposal_id = p.id
      WHERE ${where}
      ORDER BY p.end_ts DESC, COALESCE(p.created_at, p.start_ts) DESC
      LIMIT $${params.length}
    `;
    const q = await db.query<any>(sql, params);
    const rows = q.rows.slice(0, limit);
    const items = rows.map((r: any) => {
      const id = String(r.id);
      const yes = Number(r.for_power ?? 0) / 1e18;
      const no = Number(r.against_power ?? 0) / 1e18;
      const abstain = Number(r.abstain_power ?? 0) / 1e18;
      const startISO = new Date(r.start_ts).toISOString();
      const endISO = new Date(r.end_ts).toISOString();
      const createdISO = r.created_at ? new Date(r.created_at).toISOString() : startISO;
      const updatedISO = r.updated_at ? new Date(r.updated_at).toISOString() : createdISO;
      const s = toUiStatus(r);
      return {
        id,
        title: r.title || 'Untitled',
        summary: r.summary || '',
        status: s,
        startTimeISO: startISO,
        endTimeISO: endISO,
        yes,
        no,
        abstain,
        turnout: null,
        createdAtISO: createdISO,
        updatedAtISO: updatedISO,
      } as const;
    });
    let nextCursor: string | null = null;
    if (q.rows.length > limit && rows.length) {
      const last = rows[rows.length - 1];
      nextCursor = Buffer.from(`${new Date(last.end_ts).toISOString()}|${last.id}`, 'utf8').toString('base64');
    }
    return { items, nextCursor };
  } catch (e) {
    console.error('listProposals error:', e);
    return { items: [], nextCursor: null };
  }
}

