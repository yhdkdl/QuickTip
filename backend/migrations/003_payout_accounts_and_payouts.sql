-- Migration 003: Payout accounts and payout tracking

-- Stores worker payout destination details
-- Kept separate from workers table for clean separation of concerns
CREATE TABLE IF NOT EXISTS payout_accounts (
    id               UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id        UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    method           VARCHAR(10) NOT NULL
                         CHECK (method IN ('telebirr', 'bank')),

    -- Telebirr payout fields
    telebirr_phone   VARCHAR(15),

    -- Bank payout fields
    bank_name        VARCHAR(100),
    account_number   VARCHAR(50),
    account_name     VARCHAR(100),

    is_active        BOOLEAN DEFAULT true,
    created_at       TIMESTAMPTZ DEFAULT NOW(),

    -- Ensure a worker only has one active payout account at a time
    CONSTRAINT unique_active_payout
        UNIQUE (worker_id, is_active)
);

-- Tracks every payout attempt per tip
-- Separated from tips table so financial records stay immutable
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
    failure_reason      TEXT,
    created_at          TIMESTAMPTZ DEFAULT NOW()
);

-- Indexes for common queries
CREATE INDEX IF NOT EXISTS idx_payout_accounts_worker_id
    ON payout_accounts(worker_id);

CREATE INDEX IF NOT EXISTS idx_payouts_tip_id
    ON payouts(tip_id);

CREATE INDEX IF NOT EXISTS idx_payouts_worker_id
    ON payouts(worker_id);

CREATE INDEX IF NOT EXISTS idx_payouts_status
    ON payouts(status);