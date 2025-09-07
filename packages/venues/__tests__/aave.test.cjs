const assert = require('node:assert');
const test = require('node:test');
const { aave } = require('../dist');
const { setHttpJSONImpl } = require('../dist/http');

test('aave getLiveRates returns sane shape', async () => {
  setHttpJSONImpl(async () => ({ data: { reserves: [{ symbol: 'USDT', liquidityRate: String(0.05 * 1e27) }] } }));
  const rates = await aave.getLiveRates(['USDT','USDC']);
  assert.ok(Array.isArray(rates));
  if (rates.length) {
    const r = rates[0];
    assert.equal(r.venue, 'aave');
    assert.equal(typeof r.baseApr, 'number');
  }
});