import { test } from 'node:test';
import assert from 'node:assert/strict';
import { aave } from '../src/aave';

// Mock fetch via monkey patch global fetch
const mockFetch: typeof fetch = async (_url, init?: any) => {
	const body = JSON.parse(init.body);
	assert.ok(/reserves/i.test(body.query));
	const fivePctRay = (0.05 * 1e27).toString();
	const payload = { data: { reserves: [ { symbol: 'USDC', liquidityRate: fivePctRay } ] } };
	return new Response(JSON.stringify(payload), { status: 200, headers: { 'Content-Type': 'application/json' } });
};

test('aave.getLiveRates parses ray APR to Rate schema', async () => {
	// Monkey patch global fetch since connector uses httpJSON (undici request not used here)
	// We'll simulate by intercepting httpJSON via global.fetch fallback if added later.
	// Directly call underlying with mock by temporarily swapping fetch is unnecessary with current implementation.
	const realFetch = (globalThis as any).fetch;
	(globalThis as any).fetch = mockFetch;
	try {
		const rates = await aave.getLiveRates();
		assert.equal(rates.length, 1);
		const r = rates[0];
		assert.equal(r.market, 'USDC');
		assert.ok(Math.abs(r.baseApr - 0.05) < 1e-6);
		assert.ok(r.baseApy && r.baseApy > 0.0505 && r.baseApy < 0.0513);
	} finally {
		(globalThis as any).fetch = realFetch;
	}
});
