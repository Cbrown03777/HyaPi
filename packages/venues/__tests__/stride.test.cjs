const assert = require('node:assert');
const test = require('node:test');
const { stride } = require('../dist');

test('stride getLiveRates returns fallback rates', async () => {
  const rates = await stride.getLiveRates(['stATOM']);
  assert.ok(Array.isArray(rates));
  if (rates.length) {
    assert.equal(rates[0].venue, 'stride');
  }
});