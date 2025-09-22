import { ConfirmFillInput, ConfirmFillResult } from '../types/actions';
import * as repo from '../data/actionsRepo';

export async function confirmPlannedAction(actionId: string, body: ConfirmFillInput): Promise<ConfirmFillResult> {
  // Validate inputs
  if (!body || !(body.avgPriceUSD > 0) || body.feeUSD == null || body.feeUSD < 0 || !/^https?:\/\//.test(body.txUrl ?? '')) {
    throw { status: 400, code: 'INVALID_INPUT', message: 'avgPriceUSD>0, feeUSD>=0, txUrl required' };
  }
  const action = await repo.getActionById(actionId);
  if (!action) throw { status: 404, code: 'NOT_FOUND', message: 'Action not found' };
  if (action.status === 'Confirmed') {
    return {
      ok: true,
      actionId: action.id,
      newStatus: 'Confirmed',
      updated: await repo.applyBalancesDelta({ amountPI: 0, venue: action.venue }), // no-op read current
      auditId: 'already-confirmed'
    };
  }
  if (body.idempotencyKey && await repo.wasIdempotencyKeyApplied(body.idempotencyKey)) {
    // idempotent return; do not re-apply
    return {
      ok: true,
      actionId: action.id,
      newStatus: 'Confirmed',
      updated: await repo.applyBalancesDelta({ amountPI: 0, venue: action.venue }),
      auditId: 'idem'
    };
  }

  const filledAt = body.filledAt ? new Date(body.filledAt) : new Date();

  // 1) write liquidity_event + audit (include idempotencyKey)
  const audit = await repo.insertLiquidityEvent({
    actionId: action.id,
    venue: action.venue,
    amountPI: action.amountPI,
    avgPriceUSD: body.avgPriceUSD,
    feeUSD: body.feeUSD,
    txUrl: body.txUrl,
    filledAt,
    idempotencyKey: body.idempotencyKey
  });

  // 2) apply balances mutation
  const updated = await repo.applyBalancesDelta({ amountPI: action.amountPI, venue: action.venue });

  // 3) mark action confirmed
  await repo.markConfirmed(action.id, filledAt);

  return { ok: true, actionId: action.id, newStatus: 'Confirmed', updated, auditId: audit.auditId };
}
