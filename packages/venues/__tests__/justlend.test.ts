import { test } from 'node:test';
import assert from 'node:assert/strict';
import { justlend } from '../src/justlend';

// Mock fetch for JustLend (new schema expects data.tokenList with percentage strings)
const mockFetch: typeof fetch = async (url) => {
	assert.ok(/jtoken/.test(url.toString()));
	const payload = { data: { tokenList: [ { symbol: 'TRX', supplyApy: '12' }, { symbol: 'USDT', supplyApy: '8' } ] } };
	return new Response(JSON.stringify(payload), { status: 200, headers: { 'Content-Type': 'application/json' } });
};

test('justlend.getLiveRates derives baseApr/baseApy', async () => {
	const realFetch = (globalThis as any).fetch;
	(globalThis as any).fetch = mockFetch;
	try {
		const rates = await justlend.getLiveRates();
		// Filter only symbols we allow (TRX & USDT are in allow list)
		assert.equal(rates.length, 2);
		const trx = rates.find(r => r.market === 'TRX');
		assert.ok(trx);
		assert.ok(Math.abs(trx!.baseApr - Math.log(1+0.12)) < 1e-6);
		const usdt = rates.find(r => r.market === 'USDT');
		assert.ok(usdt);
		assert.ok(Math.abs(usdt!.baseApr - Math.log(1+0.08)) < 1e-6);
	} finally {
		(globalThis as any).fetch = realFetch;
	}
});
