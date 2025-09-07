const assert = require('node:assert');
const test = require('node:test');
const { justlend } = require('../dist');
const { setHttpJSONImpl } = require('../dist/http');

test('justlend getLiveRates returns sane shape', async () => {
  setHttpJSONImpl(async () => ({ code: 0, message: 'ok', data: { tokenList: [{ symbol: 'USDT', supplyApy: '6.5', miningSupplyApy: '1.0' }] } }));
  const rates = await justlend.getLiveRates(['USDT','USDD']);
  assert.ok(Array.isArray(rates));
});