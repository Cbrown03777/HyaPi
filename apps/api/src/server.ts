/**
 * Copilot: If "Cannot find module" errors occur for axios/zod/express/etc,
 * suggest `pnpm -F @hyapi/api add <pkg>` and `pnpm -F @hyapi/api add -D <types>`.
 * Do not touch client (web) deps or any @mui/* packages.
 */
import path from 'node:path';
import dotenv from 'dotenv';
// Load env from apps/api/.env explicitly so running from monorepo root still picks it up
dotenv.config({ path: path.resolve(__dirname, '../.env') });
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';

import { proposalsRouter } from './web/proposals';
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

const allowedOrigins = [
  'http://localhost:3000',
  'http://localhost:300',
  'http://127.0.0.1:3000',
  'http://127.0.0.1:300',
  'http://wsl.localhost:3000',
  'http://localhost:3001',
  'http://127.0.0.1:3001',
  'https://hyapi.net',
  // Pi Browser Sandbox if it forwards origin; mostly we call via Next proxy so origin may be our web host
  'https://sandbox.minepi.com'
];

// Merge env-provided origins
if (process.env.ALLOWED_ORIGINS) {
  for (const o of process.env.ALLOWED_ORIGINS.split(',')) {
    const trimmed = o.trim();
    if (trimmed && !allowedOrigins.includes(trimmed)) allowedOrigins.push(trimmed);
  }
}


const corsOptions: cors.CorsOptions = {
  origin(origin, cb) {
    if (!origin) return cb(null, true); // curl / Postman / same-origin
    if (allowedOrigins.includes(origin)) return cb(null, true);
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
app.use(helmet({contentSecurityPolicy: false}));
app.use(express.json());
app.use(cors(corsOptions));
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
// Public venues rates and public alloc history before auth
app.use('/v1/venues', venuesRouter);
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


const port = Number(process.env.PORT || 8080);
app.listen(port, '0.0.0.0', async () => {
  console.log(`API on ${port}`);
  try { await runMigrations(); } catch (e:any) { console.error('migration error', e?.message); }
  try { await ensurePiIntegration(); } catch (e: any) { console.error('pi bootstrap error', e?.message); }
  try { await ensureBootstrap(); } catch (e:any) { console.error('alloc bootstrap error', e?.message); }
  try { await clearApyScalingFlags(); } catch (e:any) { console.error('clear apy flags error', e?.message); }
  // Start background worker to track A2U payouts
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
