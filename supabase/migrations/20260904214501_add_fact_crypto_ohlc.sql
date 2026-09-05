CREATE TABLE IF NOT EXISTS fact_crypto_ohlc (
    ohlc_fact_id BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    coin_id VARCHAR(50) NOT NULL,
    time_id BIGINT NOT NULL,
    currency_id BIGINT NOT NULL,
    open_price NUMERIC NOT NULL CHECK (open_price >= 0),
    high_price NUMERIC NOT NULL CHECK (high_price >= 0),
    low_price NUMERIC NOT NULL CHECK (low_price >= 0),
    close_price NUMERIC NOT NULL CHECK (close_price >= 0),
    created_at_utc TIMESTAMPTZ DEFAULT CURRENT_TIMESTAMP,
    
    CONSTRAINT fk_coin FOREIGN KEY (coin_id) REFERENCES dim_coin (coin_id),
    CONSTRAINT fk_time FOREIGN KEY (time_id) REFERENCES dim_time (time_id),
    CONSTRAINT fk_currency FOREIGN KEY (currency_id) REFERENCES dim_currency (currency_id),
    
    CONSTRAINT uq_coin_time_currency UNIQUE (coin_id, time_id, currency_id)
)