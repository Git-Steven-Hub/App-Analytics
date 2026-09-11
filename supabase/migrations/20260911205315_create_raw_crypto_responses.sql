CREATE TABLE IF NOT EXISTS raw_crypto_responses (
    raw_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    endpoint VARCHAR(100) NOT NULL,
    payload_json JSONB NOT NULL,
    ingested_at_utc TIMESTAMPTZ DEFAULT NOW()
)