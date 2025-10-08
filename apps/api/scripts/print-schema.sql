-- Print table definitions for key payment-related tables
\d+ pi_payments
\d+ stakes
\d+ balances
\d+ liquidity_events

SELECT conname, pg_get_constraintdef(c.oid) AS def
FROM pg_constraint c
JOIN pg_class t ON c.conrelid = t.oid
WHERE t.relname IN ('pi_payments','liquidity_events');
