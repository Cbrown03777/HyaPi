-- 0017_gov_allocation_history.sql
-- Track historical governance-approved allocation target weights (dynamic keys).
-- Each execution of a proposal writes its full key set for auditability.

CREATE TABLE IF NOT EXISTS gov_allocation_history (
  id              BIGSERIAL PRIMARY KEY,
  proposal_id     BIGINT REFERENCES gov_proposals(id) ON DELETE CASCADE,
  key             TEXT NOT NULL,
  weight_fraction NUMERIC(10,8) NOT NULL,
  applied_at      TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE INDEX IF NOT EXISTS idx_gov_alloc_hist_proposal ON gov_allocation_history(proposal_id);
CREATE INDEX IF NOT EXISTS idx_gov_alloc_hist_applied_at ON gov_allocation_history(applied_at DESC);
