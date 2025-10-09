/**
 * Copilot: If "Cannot find module" errors occur for axios/zod/express/etc,
 * suggest `pnpm -F @hyapi/api add <pkg>` and `pnpm -F @hyapi/api add -D <types>`.
 * Do not touch client (web) deps or any @mui/* packages.
 */
import path from 'node:path';
import dotenv from 'dotenv';
import express from 'express';
import morgan from 'morgan';
import cors from 'cors';
import helmet from 'helmet';

import { proposalsRouter } from './web/proposals';
import { piPublicDebugRouter } from './web/piPublicDebug';
import { piRoutesPayments } from './web/piPayments';
import { votesRouter } from './web/votes';
import { finalizeRouter } from './web/finalize';
import { executeRouter } from './web/execute';
import { stakingRouter, simulateDailyYieldIfNeeded } from './web/staking';
import { portfolioRouter, portfolioPublicRouter } from './web/portfolio';
import { activityRouter } from './web/activity';
import { piRouter } from './web/pi';
import { metadataRouter } from './web/metadata';
import { allocRouter, allocGovPublicRouter } from './web/alloc';
import { allocCurrentRouter } from './web/alloc_current';
import { adminAllocatorRouter } from './web/adminAllocator';
import { venuesRouter } from './web/venues';
import { walletRouter } from './web/wallet';
import { manualActionsRouter } from './web/manualActions';
import { govBoostRouter, govBoostPublicRouter } from './web/govBoost';
import { govProposalsPublicRouter } from './web/govProposals';
import { proofRouter } from './web/proof';

import { auth } from './web/middleware/auth';
import { idempotency } from './web/middleware/idempotency';
import { ensurePiIntegration, ensureBootstrap } from './services/bootstrap';
import { clearApyScalingFlags } from './data/govRepo';
import { runMigrations } from './services/migrate';
import { startPiPayoutWorker } from './services/piPayoutWorker';
import { recordAllocationSnapshot } from './services/alloc';
import { runDbHotfixes } from './services/db_ddl_hotfix';
import { backfillPiPaymentMetadata } from './services/piBackfill';

// Load local env only if not production (do not override Render env in prod)
const isProd = process.env.NODE_ENV === 'production';
if (!isProd) {
  dotenv.config({ path: path.resolve(__dirname, '../.env') });
}

// CORS allowlist via hostname/suffix matcher
const DEBUG_CORS = process.env.DEBUG_CORS === '1';
console.log('[boot] ALLOWED_ORIGINS raw =', process.env.ALLOWED_ORIGINS);

// Exact hostnames we always allow
const HOST_ALLOWLIST = new Set<string>([
  'hyapi.net',
  'www.hyapi.net',
  'api.hyapi.net',
  'localhost',
  '127.0.0.1',
  'wsl.localhost',
]);

// Hostname suffixes we allow (covers Vercel previews & Pi domains)
const SUFFIX_ALLOWLIST: string[] = [
  '.vercel.app',
  '.minepi.com', // sandbox.minepi.com, other Pi surfaces
  '.pinet.com',  // wallet.pinet.com etc.
];

// Merge env ALLOWED_ORIGINS (comma-separated hostnames or full URLs)
if (process.env.ALLOWED_ORIGINS) {
  for (const raw of process.env.ALLOWED_ORIGINS.split(',')) {
    const s = raw.trim();
    if (!s) continue;
    try {
      const u = new URL(s);
      HOST_ALLOWLIST.add(u.hostname.toLowerCase());
    } catch {
      const v = s.toLowerCase();
      if (v.startsWith('*.')) SUFFIX_ALLOWLIST.push(v.slice(1)); // "*.foo.com" -> ".foo.com"
      else HOST_ALLOWLIST.add(v);
    }
  }
}

function isAllowedOrigin(origin?: string | null): boolean {
  if (!origin) return true; // health checks, curl, same-origin SSR
  let hostname: string;
  try {
    const u = new URL(origin);
    if (!['https:', 'http:'].includes(u.protocol)) return false;
    hostname = u.hostname.toLowerCase();
  } catch {
    return false;
  }
  if (HOST_ALLOWLIST.has(hostname)) return true;
  // Allow localhost ports explicitly
  if (hostname === 'localhost' || hostname === '127.0.0.1' || hostname === 'wsl.localhost') return true;
  return SUFFIX_ALLOWLIST.some(sfx => hostname.endsWith(sfx));
}

const corsOptions: cors.CorsOptions = {
  origin(origin, cb) {
    const ok = isAllowedOrigin(origin);
    if (ok) return cb(null, true);
    if (DEBUG_CORS) {
      // Best-effort: origin callback doesn't expose req; attempt to grab via arguments
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const reqLike: any = (arguments as any)?.[2]?.req;
      console.warn('[CORS block]', {
        origin,
        path: reqLike?.url,
      });
    } else {
      // Minimal, but include captured headers if present via earlier middleware
      // eslint-disable-next-line @typescript-eslint/no-explicit-any
      const reqLike: any = (arguments as any)?.[2]?.req;
      console.warn('[CORS block]', {
        origin,
        referer: reqLike?.headers?.referer,
        xfh: reqLike?.headers?.['x-forwarded-host'],
      });
    }
    return cb(new Error('Not allowed by CORS'));
  },
  methods: ['GET', 'POST', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'Idempotency-Key'],
  credentials: false,
  maxAge: 86400,
  preflightContinue: false,
  optionsSuccessStatus: 204,
};

const app = express();
const DEBUG_PI = process.env.DEBUG_PI === '1';
app.use(helmet({contentSecurityPolicy: false}));
// Stash headers for potential CORS logging
app.use((req, _res, next) => {
  (req as any).__origin = req.headers.origin || null;
  (req as any).__referer = req.headers.referer || null;
  (req as any).__xfh = req.headers['x-forwarded-host'] || null;
  next();
});
// CORS FIRST
app.use(cors(corsOptions));
// Then body parsing
app.use(express.json());
app.use(morgan(':method :url :status :res[content-length] - :response-time ms'));
app.use((req, _res, next) => {
  if (DEBUG_PI && req.url.startsWith('/v1/pi')) {
    console.log('[pi:req]', {
      method: req.method,
      url: req.url,
      headers: {
        origin: req.headers.origin,
        authorization: req.headers.authorization ? '<present>' : '<absent>'
      },
      body: req.body ?? null,
      ts: new Date().toISOString()
    });
  }
  next();
});
// Public health endpoints
app.get('/v1/health', (_req,res)=>{
  try {
    // eslint-disable-next-line @typescript-eslint/no-var-requires
    const pkg = require('../package.json');
    return res.status(200).json({ ok: true, uptime: process.uptime(), version: pkg.version });
  } catch {
    return res.status(200).json({ ok: true, uptime: process.uptime(), version: '0.0.0' });
  }
});
app.get('/v1/health/prices', async (_req, res) => {
  try {
    const { getPrices } = require('@hyapi/prices');
    const { degraded } = await getPrices(['PI','LUNA','BAND','JUNO','ATOM','TIA','DAI'], { force: true });
    return res.status(200).json({ ok: true, degraded });
  } catch {
    return res.status(200).json({ ok: false, degraded: true });
  }
});
app.get('/health', (_req,res)=>res.json({ ok:true, time:new Date().toISOString() })); // legacy public
// Pi payment server credential health
import axios from 'axios';
app.get('/v1/health/pi', async (_req, res) => {
  const PI_API_BASE = process.env.PI_API_BASE ?? 'https://api.minepi.com/v2';
  try {
    const scheme = process.env.PI_SERVER_AUTH_SCHEME || 'Key';
    const secret = process.env.PI_APP_SECRET || process.env.PI_API_KEY || '';
    if (!secret) throw new Error('no secret configured');
    const r = await axios.get(`${PI_API_BASE}/payments?limit=1`, { headers: { Authorization: `${scheme} ${secret}` }, timeout: 8000 });
    res.json({ ok: true, status: r.status, network: process.env.PI_NETWORK || 'unknown' });
  } catch (e: any) {
    res.status(500).json({ ok: false, error: e?.message || 'unhealthy', network: process.env.PI_NETWORK || 'unknown' });
  }
});
// Public venues rates and public alloc history before auth
app.use('/v1/venues', venuesRouter);
// Public Pi payment approval/completion (called rapidly from client during SDK flow) & public debug endpoints
app.use('/v1/pi', piRoutesPayments);
app.use('/v1/pi', piPublicDebugRouter);
app.use('/v1/alloc', allocGovPublicRouter);
// Public governance config (boost terms)
app.use('/v1/gov', govBoostPublicRouter);
// Public governance proposals list
app.use('/v1/gov', govProposalsPublicRouter);
// Public portfolio metrics
app.use('/v1/portfolio', portfolioPublicRouter);
// Public proof of reserves
app.use('/v1/proof', proofRouter);
// NOTE: /v1/venues mounted earlier (public). Everything after this requires auth.
app.use(auth);
app.use(idempotency);

// Simple token rate limiter for POST routes: 5 req/sec burst, window sliding.
interface Bucket { ts: number; count: number }
const buckets: Record<string, Bucket> = {};
const MAX_PER_SEC = Number(process.env.RL_MAX_PER_SEC ?? 5); // configurable within 2-5 suggested
app.use((req, res, next) => {
  if (req.method !== 'POST') return next();
  const token = (req as any).authToken || (req.headers['authorization'] ?? 'anon');
  const key = String(token);
  const now = Date.now();
  const sec = Math.floor(now / 1000);
  const b = buckets[key];
  if (!b || b.ts !== sec) {
    buckets[key] = { ts: sec, count: 1 };
    return next();
  }
  if (b.count >= MAX_PER_SEC) {
    res.status(429).json({ success:false, error:{ code:'RATE_LIMIT', message:`Too many requests (>${MAX_PER_SEC}/s)` }});
    return;
  }
  b.count++;
  next();
});

app.use('/v1/gov', auth);
app.use('/v1/gov', auth, proposalsRouter);
app.use('/v1/gov', auth, votesRouter);
app.use('/v1/gov', auth, finalizeRouter);
app.use('/v1/gov', auth, govBoostRouter);
app.use('/v1/gov/execution', auth, executeRouter);
app.use('/v1/wallet', auth, walletRouter);
app.use('/v1/stake', auth, stakingRouter);
app.use('/v1/portfolio', auth, portfolioRouter);
app.use('/v1/activity', auth, activityRouter);
app.use('/v1/pi', auth, piRouter);
app.use('/v1/metadata', metadataRouter);
app.use('/v1/alloc', auth, allocRouter);
app.use('/v1/alloc', auth, allocCurrentRouter);
app.use('/v1/admin/allocator', auth, adminAllocatorRouter);
app.use('/v1/admin', auth, manualActionsRouter);
// Public venues rates (no bearer required) – mount before auth
// (Already mounted publicly above)
// Masked boot env logging for diagnostics
console.log('[boot]', {
  NODE_ENV: process.env.NODE_ENV,
  MIGRATIONS_ENABLED: process.env.MIGRATIONS_ENABLED,
  PI_API_BASE: process.env.PI_API_BASE,
  PI_NETWORK: process.env.PI_NETWORK,
  PI_APP_PUBLIC_present: !!process.env.PI_APP_PUBLIC,
  PI_API_KEY_prefix: (process.env.PI_API_KEY || '').slice(0,6)
});

const port = Number(process.env.PORT || 8080);
app.listen(port, '0.0.0.0', async () => {
  console.log(`API on ${port}`);
  try { await runDbHotfixes(); } catch (e:any) { console.error('[hotfix] ddl error', e?.message); }
  try { await backfillPiPaymentMetadata(); } catch (e:any) { console.error('[hotfix] backfill error', e?.message); }

  const MIG_ENABLED = (process.env.MIGRATIONS_ENABLED ?? 'false').toLowerCase() === 'true';
  if (MIG_ENABLED) {
    try { await runMigrations(); } catch (e:any) { console.error('migration error (non-fatal)', e?.message); }
  } else {
    console.warn('[migrate] skipped (MIGRATIONS_ENABLED=false)');
  }

  try { await ensurePiIntegration(); } catch (e: any) { console.error('pi bootstrap error', e?.message); }
  try { await ensureBootstrap(); } catch (e:any) { console.error('alloc bootstrap error', e?.message); }
  try { await clearApyScalingFlags(); } catch (e:any) { console.error('clear apy flags error', e?.message); }
  try { startPiPayoutWorker(); } catch (e: any) { console.error('payout worker start error', e?.message); }
});

setInterval(async () => {
  try {
    await simulateDailyYieldIfNeeded();
  } catch (e) {
    console.error('pps job error:', (e as any).message);
  }
}, 60_000);

// Periodic allocation snapshot (even if no execute) every 15 minutes
setInterval(async () => {
  try { await recordAllocationSnapshot(); } catch (e) { console.warn('alloc snapshot cron error', (e as any)?.message); }
}, 15 * 60_000);
