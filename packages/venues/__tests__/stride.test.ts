import { test } from 'node:test';
import assert from 'node:assert/strict';
import { stride } from '../src/stride';

test('stride.getLiveRates returns fallback env APRs', async () => {
	process.env.STRIDE_STATOM_APR = '0.12';
	process.env.STRIDE_STTIA_APR = '0.14';
	const rates = await stride.getLiveRates();
	// Should contain at least stATOM & stTIA
	const stAtom = rates.find(r => r.market === 'stATOM');
	const stTia = rates.find(r => r.market === 'stTIA');
	assert.ok(stAtom && stTia);
	assert.ok(Math.abs(stAtom.baseApr - 0.12) < 1e-9);
	assert.ok(stAtom.baseApy && stAtom.baseApy > stAtom.baseApr);
});
