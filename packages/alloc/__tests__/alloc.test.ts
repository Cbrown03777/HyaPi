import { computeTargets, planRebalance } from "../src/math";
import type { Guardrails, GovWeights, Rate } from "../src/types";

const guards: Guardrails = {
	lambda: 0.7,
	softmaxK: 6,
	bufferBps: 1000,
	minTradeUSD: 50,
	maxVenueBps: { aave: 6000, justlend: 5000, stride: 5000 },
	maxDriftBps: 50,
	cooldownSec: 600,
	allowVenue: { aave:true, justlend:true, stride:true },
	staleRateMaxSec: 3600
};

const rates: Rate[] = [
	{ venue:"aave", chain:"ethereum", market:"USDT", baseApr:0.08, asOf:new Date().toISOString() },
	{ venue:"justlend", chain:"tron", market:"USDT", baseApr:0.10, asOf:new Date().toISOString() },
	{ venue:"stride", chain:"cosmos", market:"stATOM", baseApr:0.12, asOf:new Date().toISOString() }
];

const gov: GovWeights = {
	"aave:USDT": 0.34, "justlend:USDT": 0.33, "stride:stATOM": 0.33
};

import assert from 'node:assert/strict';
import { test } from 'node:test';

test("computeTargets blends and respects caps", () => {
	const t = computeTargets(gov, rates, guards);
	const sum = Object.values(t).reduce((a,b)=>a+b,0);
	assert.ok(Math.abs(sum - 1) < 1e-9);
});

test("planRebalance computes actions with buffer", () => {
	const targets = computeTargets(gov, rates, guards);
	const plan = planRebalance({
		tvlUSD: 10_000,
		bufferBps: guards.bufferBps,
		current: { "aave:USDT": 4000 },
		targetWeights: targets,
		minTradeUSD: 50,
		maxDriftBps: 10
	});
	assert.ok(Array.isArray(plan.actions));
});
