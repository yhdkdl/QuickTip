ALTER TABLE payout_accounts
    ADD COLUMN IF NOT EXISTS is_default BOOLEAN DEFAULT false;

UPDATE payout_accounts
SET is_default = true
WHERE id IN (
    SELECT DISTINCT ON (worker_id) id
    FROM payout_accounts
    WHERE is_active = true
    ORDER BY worker_id, created_at ASC
);

CREATE UNIQUE INDEX IF NOT EXISTS one_default_per_worker
    ON payout_accounts(worker_id)
    WHERE is_default = true AND is_active = true;