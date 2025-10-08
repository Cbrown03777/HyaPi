import { Router } from 'express';
import axios from 'axios';

export const piPublicDebugRouter = Router();

// Public key self-test (no bearer). Uses bogus payment id to validate server key without revealing it.
piPublicDebugRouter.get('/debug/keycheck', async (_req, res) => {
  try {
    const PI_BASE = process.env.PI_API_BASE || 'https://api.minepi.com/v2';
    const PI_KEY = (process.env.PI_API_KEY || '').trim();
    if (!PI_KEY) return res.status(500).json({ success:false, error:{ code:'CONFIG', message:'PI_API_KEY missing' } });

    const url = `${PI_BASE}/payments/does-not-exist/approve`;
    const r = await axios.post(url, null, {
      headers: { Authorization: `Key ${PI_KEY}` },
      validateStatus: () => true,
      timeout: 15_000,
    });

    return res.json({
      success: true,
      status: r.status,
      bodySnippet: (typeof r.data === 'string' ? r.data : JSON.stringify(r.data)).slice(0, 300)
    });
  } catch (e:any) {
    return res.status(500).json({ success:false, error:{ code:'EX', message: e?.message || 'unknown' } });
  }
});

// Masked env introspection (public, safe fields only)
piPublicDebugRouter.get('/debug/envmask', (_req, res) => {
  return res.json({
    success: true,
    env: {
      NODE_ENV: process.env.NODE_ENV,
      PI_API_BASE: process.env.PI_API_BASE,
      PI_NETWORK: process.env.PI_NETWORK,
      PI_API_KEY_prefix: (process.env.PI_API_KEY || '').slice(0,6)
    }
  });
});
