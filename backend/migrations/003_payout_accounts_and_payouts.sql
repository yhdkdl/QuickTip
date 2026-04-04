CREATE TABLE IF NOT EXISTS payout_accounts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id        UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    method           VARCHAR(10) NOT NULL
                         CHECK (method IN ('telebirr', 'bank')),
    telebirr_phone   VARCHAR(15),
    bank_name        VARCHAR(100),
    account_number   VARCHAR(50),
    account_name     VARCHAR(100),
    is_active        BOOLEAN DEFAULT true,
    created_at       TIMESTAMPTZ DEFAULT NOW(),

    CONSTRAINT telebirr_requires_phone
        CHECK (
            method != 'telebirr' OR telebirr_phone IS NOT NULL
        ),
    CONSTRAINT bank_requires_details
        CHECK (
            method != 'bank' OR (
                bank_name IS NOT NULL AND
                account_number IS NOT NULL AND
                account_name IS NOT NULL
            )
        )
);

CREATE TABLE IF NOT EXISTS payouts (
    id                  UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    tip_id              UUID NOT NULL REFERENCES tips(id),
    worker_id           UUID NOT NULL REFERENCES workers(id),
    amount              DECIMAL(10,2) NOT NULL,
    method              VARCHAR(10) NOT NULL
                            CHECK (method IN ('telebirr', 'bank')),
    status              VARCHAR(20) NOT NULL DEFAULT 'pending'
                            CHECK (status IN (
                                'pending',
                                'completed',
                                'failed',
                                'reversed'
                            )),
    chapa_transfer_id   TEXT,
    attempts            INTEGER DEFAULT 0,
    last_attempt_at     TIMESTAMPTZ,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_payout_accounts_worker
    ON payout_accounts(worker_id);

CREATE INDEX IF NOT EXISTS idx_payouts_tip_id
    ON payouts(tip_id);

CREATE INDEX IF NOT EXISTS idx_payouts_worker_status
    ON payouts(worker_id, status);

CREATE INDEX IF NOT EXISTS idx_payouts_pending
    ON payouts(status, last_attempt_at)
    WHERE status = 'pending';