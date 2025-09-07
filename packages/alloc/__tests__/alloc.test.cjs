const assert = require('node:assert/strict');
const test = require('node:test');
const { previewAllocation, planRebalance } = require('../dist');

test('previewAllocation basic deposits and withdrawals with guardrails', () => {
  const holdings = [
    { key: 'aave:usdc', usd: 600 },
    { key: 'justlend:usdt', usd: 400 },
  ];
  const targets = [
    { key: 'aave:usdc', weight: 0.3 },
    { key: 'justlend:usdt', weight: 0.7 },
  ];
  const guards = {
    maxSingleVenuePct: 0.6,
    maxNewAllocationPct: 0.25,
    minTicketUsd: 10,
    dustUsd: 0.01,
  };

  const actions = previewAllocation(holdings, targets, guards);
  const byKey = new Map(actions.map(a => [a.key, a]));
  assert.equal(byKey.get('aave:usdc')?.action, 'withdraw');
  assert.equal(Math.round((byKey.get('aave:usdc')?.usd ?? 0)), 300);
  assert.equal(byKey.get('justlend:usdt')?.action, 'deposit');
  // desired 700 is capped by maxSingleVenuePct (0.6 * 1000 = 600) => delta 600-400 = 200
  assert.equal(Math.round((byKey.get('justlend:usdt')?.usd ?? 0)), 200);
});

test('planRebalance creates concrete orders without dust', () => {
  const holdings = [ { key: 'stride:stAtom', usd: 0 } ];
  const targets = [ { key: 'stride:stAtom', weight: 1 } ];
  const guards = {
    maxSingleVenuePct: 0.5,
    maxNewAllocationPct: 0.1,
    minTicketUsd: 5,
    dustUsd: 0.5,
  };

  const plan = planRebalance(holdings, targets, guards);
  assert.equal(plan.orders.length, 0);

  const holdings2 = [ { key: 'stride:stAtom', usd: 1000 } ];
  const plan2 = planRebalance(holdings2, targets, guards);
  assert.equal(plan2.orders.length, 1);
  assert.equal(plan2.orders[0].action, 'withdraw');
  assert.equal(Math.round(plan2.orders[0].usd), 500);
});
