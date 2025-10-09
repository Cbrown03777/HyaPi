-- Debug portfolio vs deposits/credits mapping (local only)

-- Sum all final user_to_app payments (by uid) using pi_payments
SELECT uid AS user_uid, SUM(amount_pi) AS total_pi_deposited
  FROM pi_payments
 WHERE direction = 'user_to_app'
   AND COALESCE(status_text,status) IN ('completed','approved','submitted','success')
 GROUP BY uid
 ORDER BY 1;

-- What liquidity events did we mint? (join meta->paymentId back to pi_payments for uid)
SELECT p.uid AS user_uid, le.kind, COUNT(*) AS c, COALESCE(SUM(le.amount),0) AS sum_pi
  FROM liquidity_events le
  JOIN pi_payments p ON p.pi_payment_id = (le.meta::jsonb)->>'paymentId'
 GROUP BY p.uid, le.kind
 ORDER BY 1,2;

-- User balances snapshot (replace :uid)
-- SELECT * FROM balances b JOIN pi_identities i ON i.user_id=b.user_id WHERE i.uid = ':uid';

-- Stakes snapshot (replace :uid)
-- SELECT s.* FROM stakes s JOIN pi_identities i ON i.user_id=s.user_id WHERE i.uid=':uid' AND s.status='active';
