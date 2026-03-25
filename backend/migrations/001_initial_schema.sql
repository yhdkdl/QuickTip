CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS workers (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name            VARCHAR(100) NOT NULL,
    phone           VARCHAR(15) UNIQUE NOT NULL,
    email           VARCHAR(255) UNIQUE,
    password_hash   TEXT NOT NULL,
    profession      VARCHAR(100),
    avatar_url      TEXT,
    qr_code_url     TEXT,
    nfc_enabled     BOOLEAN DEFAULT false,
    is_active       BOOLEAN DEFAULT true,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS tip_sessions (
    id                          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id                   UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    amount                      DECIMAL(10,2) NOT NULL,
    customer_phone              VARCHAR(15) NOT NULL,
    mpesa_checkout_request_id   TEXT UNIQUE,
    status                      VARCHAR(20) NOT NULL DEFAULT 'pending'
                                    CHECK (status IN ('pending','completed','failed','cancelled')),
    initiated_via               VARCHAR(10) NOT NULL DEFAULT 'qr'
                                    CHECK (initiated_via IN ('qr','nfc')),
    created_at                  TIMESTAMPTZ DEFAULT NOW(),
    completed_at                TIMESTAMPTZ
);

CREATE TABLE IF NOT EXISTS tips (
    id              UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id      UUID NOT NULL REFERENCES tip_sessions(id),
    worker_id       UUID NOT NULL REFERENCES workers(id),
    gross_amount    DECIMAL(10,2) NOT NULL,
    platform_fee    DECIMAL(10,2) NOT NULL,
    worker_payout   DECIMAL(10,2) NOT NULL,
    mpesa_receipt   VARCHAR(50) UNIQUE NOT NULL,
    created_at      TIMESTAMPTZ DEFAULT NOW()
);

CREATE TABLE IF NOT EXISTS notifications (
    id          UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    worker_id   UUID NOT NULL REFERENCES workers(id) ON DELETE CASCADE,
    title       VARCHAR(100) NOT NULL,
    message     TEXT NOT NULL,
    is_read     BOOLEAN DEFAULT false,
    created_at  TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_tip_sessions_worker_id
    ON tip_sessions(worker_id);

CREATE INDEX IF NOT EXISTS idx_tip_sessions_checkout_request_id
    ON tip_sessions(mpesa_checkout_request_id);

CREATE INDEX IF NOT EXISTS idx_tips_worker_id
    ON tips(worker_id);

CREATE INDEX IF NOT EXISTS idx_notifications_worker_unread
    ON notifications(worker_id, is_read);