import { Request, Response, NextFunction } from 'express';
import { db } from '../../services/db';
import { platformMe } from '../../services/piPlatform';

export function auth(req: Request, res: Response, next: NextFunction) {
  try {
    const h = req.header('authorization') || req.header('Authorization');
    if (!h?.startsWith('Bearer ')) {
      return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'missing bearer' } });
    }
    const token = h.slice('Bearer '.length).trim();

    // DEV token path: "dev <pi_address>:<userId>"
    if (process.env.ALLOW_DEV_TOKENS === '1' && token.startsWith('dev ')) {
      const rest = token.slice(4).trim(); // "pi_dev_address:1"
      const parts = rest.split(':');
      const userId = Number(parts[1]);
      if (!Number.isFinite(userId)) {
        return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'invalid dev token' } });
      }
      (req as any).user = { userId, piAddress: parts[0], isDev: true };
      return next();
    }

    // Real Pi token path: verify via Platform /me
    (async () => {
      const me = await platformMe(token);
      if (!me?.uid) return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: 'invalid token' } });

      // Map uid -> users.id (create if missing) by pi_uid to align with paymentsRepo and credits
      const upsert = await db.query<{ id: string }>(
        `WITH u AS (
           INSERT INTO users(pi_uid, username)
           VALUES ($1, $2)
           ON CONFLICT (pi_uid) DO UPDATE SET username = COALESCE(EXCLUDED.username, users.username)
           RETURNING id
         )
         INSERT INTO pi_identities(uid, user_id, username)
         VALUES ($1, (SELECT id FROM u), $2)
         ON CONFLICT (uid) DO UPDATE SET user_id = EXCLUDED.user_id, username = COALESCE(EXCLUDED.username, pi_identities.username)
         RETURNING (SELECT id FROM u) AS id`,
        [me.uid, me.username ?? null]
      );
      const userId = Number(upsert.rows[0]?.id);
      (req as any).user = { userId, uid: me.uid, username: me.username };
      return next();
    })().catch((e) => {
      return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: e.message } });
    });
  } catch (e: any) {
    return res.status(401).json({ success: false, error: { code: 'UNAUTH', message: e.message } });
  }
}


