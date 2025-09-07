import { describe, it, expect, beforeAll } from 'vitest';
import request from 'supertest';
import { app } from '../server';
import { db } from '../services/db';

beforeAll(async () => {
  process.env.ALLOW_DEV_TOKENS = '1';
  // Minimal DDL safety (idempotent) so test doesn't rely on external migration runner.
  await db.query(`CREATE TABLE IF NOT EXISTS allocations_current (
    chain text PRIMARY KEY,
    weight_fraction numeric(12,6) NOT NULL DEFAULT 0
  )`);
  await db.query(`CREATE TABLE IF NOT EXISTS venue_holdings (
    key text PRIMARY KEY,
    usd_notional numeric(24,6) NOT NULL DEFAULT 0,
    updated_at timestamptz NOT NULL DEFAULT now()
  )`);
  await db.query(`CREATE TABLE IF NOT EXISTS rebalance_plans (
    id bigserial PRIMARY KEY,
    tvl_usd numeric(24,6) NOT NULL DEFAULT 0,
    actions_json jsonb NOT NULL DEFAULT '[]'::jsonb,
    created_at timestamptz NOT NULL DEFAULT now(),
    buffer_usd numeric(24,6) NOT NULL DEFAULT 0,
    drift_bps integer NOT NULL DEFAULT 0,
    target_json jsonb NOT NULL DEFAULT '{}'::jsonb,
    status text NOT NULL DEFAULT 'planned'
  )`);
  await db.query(`CREATE INDEX IF NOT EXISTS idx_rebalance_plans_created_at ON rebalance_plans(created_at DESC)`);
  await db.query(`INSERT INTO allocations_current(chain, weight_fraction) VALUES
    ('sui',0.3),('aptos',0.3),('cosmos',0.4)
    ON CONFLICT (chain) DO UPDATE SET weight_fraction = EXCLUDED.weight_fraction`);
  await db.query(`INSERT INTO venue_holdings(key, usd_notional) VALUES
    ('aave:USDT',1200),('justlend:USDT',1500),('stride:stATOM',800)
    ON CONFLICT (key) DO UPDATE SET usd_notional = EXCLUDED.usd_notional`);
});

describe('allocation preview/execute (integration)', () => {
  it('round trip preview then execute persists plan', async () => {
    const bearer = 'dev pi_dev_address:1';
    const tvl = 5000;
    const prev = await request(app)
      .get(`/v1/alloc/preview?tvlUSD=${tvl}`)
      .set('Authorization', `Bearer ${bearer}`)
      .expect(200);
    expect(prev.body.success).toBe(true);
    expect(prev.body.data.plan).toBeDefined();
    const actions = prev.body.data.plan.actions || [];
    expect(Array.isArray(actions)).toBe(true);

    const exec = await request(app)
      .post('/v1/alloc/execute')
      .set('Authorization', `Bearer ${bearer}`)
      .send({ tvlUSD: tvl })
      .expect(200);
    expect(exec.body.success).toBe(true);
    const planId = exec.body.data.plan_id;
    expect(planId).toBeTruthy();

    const row = await db.query(`SELECT id, tvl_usd, actions_json FROM rebalance_plans WHERE id=$1`, [planId]);
    expect(row.rows.length).toBe(1);
    expect(Number(row.rows[0].tvl_usd)).toBeGreaterThan(0);
  });
});
