#!/usr/bin/env node
/**
 * Buffer Flow Demo Script
 * Steps:
 * 1. Seed targets (stride:stJUNO 40%, stride:stLUNA 35%, stride:stATOM 25%)
 * 2. Seed venue_holdings with some initial deployed capital and zero buffer.
 * 3. Deposit 100000 PI (price 1 PI=1 USD override for deterministic math)
 * 4. Show /v1/alloc/current and planned_actions (expect supply actions if above upper band)
 * 5. Redeem 50000 PI
 * 6. Show /v1/alloc/current and planned_actions (expect redeem actions for remainder after buffer consumption)
 */
const axios = require('axios');
const { Pool } = require('pg');
require('dotenv').config();

const DB_URL = process.env.DATABASE_URL;
if (!DB_URL) {
  console.error('DATABASE_URL required');
  process.exit(1);
}

const db = new Pool({ connectionString: DB_URL });

async function q(sql, params) { return db.query(sql, params); }

async function seedTargets() {
  await q(`DELETE FROM allocation_targets`);
  const now = new Date();
  const rows = [
    ['stride:stJUNO', 0.40],
    ['stride:stLUNA', 0.35],
    ['stride:stATOM', 0.25]
  ];
  for (const [k,w] of rows) {
    await q(`INSERT INTO allocation_targets(key, weight_fraction, source, applied_at) VALUES ($1,$2,'gov',now())`, [k, w]);
  }
}

async function seedHoldings() {
  await q(`DELETE FROM venue_holdings`);
  const rows = [
    ['stride:stJUNO', 40000],
    ['stride:stLUNA', 35000],
    ['stride:stATOM', 25000]
  ];
  for (const [k,usd] of rows) {
    await q(`INSERT INTO venue_holdings(key, usd_notional, updated_at) VALUES ($1,$2, now())`, [k, usd]);
  }
  await q(`UPDATE tvl_buffer SET buffer_usd=0, updated_at=now() WHERE id=1`);
}

async function ensureUser() {
  // create a dev user if not present (id=1)
  const u = await q(`SELECT id FROM users WHERE id=1`);
  if (!u.rowCount) {
    await q(`INSERT INTO users(id, username) VALUES (1,'dev')`);
  }
  const b = await q(`SELECT user_id FROM balances WHERE user_id=1`);
  if (!b.rowCount) await q(`INSERT INTO balances(user_id, hyapi_amount) VALUES (1,0)`);
}

async function deposit(amount) {
  const r = await axios.post('http://localhost:8080/v1/stake/deposit', { amountPi: amount, lockupWeeks:0 }, {
    headers: { Authorization: 'Bearer dev pi_dev_address:1' }
  });
  return r.data;
}

async function redeem(amount) {
  const r = await axios.post('http://localhost:8080/v1/stake/redeem', { amountPi: amount }, {
    headers: { Authorization: 'Bearer dev pi_dev_address:1' }
  });
  return r.data;
}

async function allocCurrent() {
  const r = await axios.get('http://localhost:8080/v1/alloc/current', {
    headers: { Authorization: 'Bearer dev pi_dev_address:1' }
  });
  return r.data;
}

async function plannedActions() {
  const r = await q(`SELECT id, kind, venue_key, amount_usd, status, reason FROM planned_actions ORDER BY id`);
  return r.rows;
}

async function run() {
  // Use deterministic price for test: 1 PI = 1 USD
  process.env.PI_USD_PRICE = '1';
  console.log('Seeding targets & holdings...');
  await seedTargets();
  await seedHoldings();
  await ensureUser();

  console.log('State before deposit:', await allocCurrent());
  console.log('--- Deposit 100000 ---');
  await deposit(100000);
  await new Promise(r=>setTimeout(r,300)); // allow async routing
  const afterDeposit = await allocCurrent();
  console.log('State after deposit:', JSON.stringify(afterDeposit, null, 2));
  console.log('Planned actions after deposit:', await plannedActions());

  console.log('--- Redeem 50000 ---');
  await redeem(50000);
  const afterRedeem = await allocCurrent();
  console.log('State after redeem:', JSON.stringify(afterRedeem, null, 2));
  console.log('Planned actions after redeem:', await plannedActions());
}

run().catch(e=> { console.error(e); process.exit(1); }).finally(()=> db.end());
