#!/usr/bin/env node
/**
 * Automated Buffer Flow Check
 * Preconditions: API server running on :8080, DATABASE_URL set, migrations applied, tvl_buffer row exists.
 * Uses deterministic PI_USD_PRICE=1 for math clarity.
 * 1. Seed targets + holdings, zero buffer.
 * 2. Deposit 100000 PI -> expect buffer routes excess to target (10% = 20000) creating supply planned_actions totalling ~80000.
 * 3. Redeem 50000 PI -> expect buffer consumption of 20000 then redeem planned_actions totalling ~30000.
 * Exits non‑zero on assertion failure. Prints JSON summary.
 */
require('dotenv').config();
const axios = require('axios');
const { Pool } = require('pg');

const DB_URL = process.env.DATABASE_URL;
if (!DB_URL) { console.error('DATABASE_URL required'); process.exit(1); }

process.env.PI_USD_PRICE = '1'; // deterministic

const db = new Pool({ connectionString: DB_URL });
const AUTH = { headers: { Authorization: 'Bearer dev pi_dev_address:1' } };

async function q(sql,p){ return db.query(sql,p); }
const sleep = ms => new Promise(r=>setTimeout(r,ms));

async function seed() {
  await q(`DELETE FROM allocation_targets`);
  await q(`DELETE FROM venue_holdings`);
  await q(`DELETE FROM planned_actions`);
  await q(`DELETE FROM liquidity_events`);
  await q(`UPDATE tvl_buffer SET buffer_usd=0, updated_at=now() WHERE id=1`);
  const targets = [ ['stride:stJUNO',0.40], ['stride:stLUNA',0.35], ['stride:stATOM',0.25] ];
  for (const [k,w] of targets) await q(`INSERT INTO allocation_targets(key, weight_fraction, source, applied_at) VALUES ($1,$2,'gov',now())`, [k,w]);
  const holdings = [ ['stride:stJUNO',40000], ['stride:stLUNA',35000], ['stride:stATOM',25000] ];
  for (const [k,usd] of holdings) await q(`INSERT INTO venue_holdings(key, usd_notional, updated_at) VALUES ($1,$2,now())`, [k,usd]);
  // user + balance
  const u = await q(`SELECT id FROM users WHERE id=1`); if (!u.rowCount) await q(`INSERT INTO users(id, username) VALUES (1,'dev')`);
  const b = await q(`SELECT user_id FROM balances WHERE user_id=1`); if (!b.rowCount) await q(`INSERT INTO balances(user_id, hyapi_amount) VALUES (1,0)`);
}

async function current(){ return (await axios.get('http://localhost:8080/v1/alloc/current', AUTH)).data; }
async function deposit(n){ return (await axios.post('http://localhost:8080/v1/stake/deposit', { amountPi:n, lockupWeeks:0 }, AUTH)).data; }
async function redeem(n){ return (await axios.post('http://localhost:8080/v1/stake/redeem', { amountPi:n }, AUTH)).data; }
async function planned(){ return (await q(`SELECT kind, venue_key, amount_usd, reason FROM planned_actions ORDER BY id`)).rows; }

function approx(a,b,eps=1e-6){ return Math.abs(a-b) <= eps; }

(async () => {
  const out = { steps: [] };
  try {
    await seed();
    const before = await current();
    out.steps.push({ step:'before', bufferUsd: before.data.bufferUsd, planned: await planned() });
    if (!approx(before.data.bufferUsd,0)) throw new Error('Expected zero buffer before deposit');

    await deposit(100000);
    await sleep(300); // allow async routing
    const afterDep = await current();
    const paAfterDep = await planned();
    const supply = paAfterDep.filter(p=>p.kind==='supply' && p.reason==='route_excess_buffer');
    const supplyTotal = supply.reduce((s,r)=>s+Number(r.amount_usd),0);
    out.steps.push({ step:'afterDeposit', bufferUsd: afterDep.data.bufferUsd, supplyTotal });

    const target = afterDep.data.buffer.target; // 20000 expected
    if (!approx(afterDep.data.bufferUsd, target, 0.5)) throw new Error(`Buffer after deposit should be ~target (${target}) got ${afterDep.data.bufferUsd}`);
    if (!approx(supplyTotal, 80000, 0.5)) throw new Error(`Supply planned_actions total expected 80000 got ${supplyTotal}`);

    await redeem(50000);
    const afterRed = await current();
    const paAfterRed = await planned();
    const redeemActs = paAfterRed.filter(p=>p.kind==='redeem' && p.reason==='user_withdraw');
    const redeemTotal = redeemActs.reduce((s,r)=>s+Number(r.amount_usd),0);
    out.steps.push({ step:'afterRedeem', bufferUsd: afterRed.data.bufferUsd, redeemTotal });

    if (!approx(afterRed.data.bufferUsd,0,0.5)) throw new Error(`Buffer after redeem should be ~0 got ${afterRed.data.bufferUsd}`);
    if (!approx(redeemTotal, 30000, 0.5)) throw new Error(`Redeem planned_actions total expected 30000 got ${redeemTotal}`);

    out.success = true;
  } catch (e) {
    out.success = false;
    out.error = e.message;
    process.exitCode = 1;
  } finally {
    console.log(JSON.stringify(out,null,2));
    await db.end();
  }
})();
