CREATE TABLE IF NOT EXISTS fact_crypto_price (
    price_fact_id SERIAL PRIMARY KEY,
    coin_id VARCHAR(50) NOT NULL REFERENCES dim_coin(coin_id),
    time_id INT NOT NULL REFERENCES dim_time(time_id),
    currency_id INT NOT NULL REFERENCES dim_currency(currency_id),
    price NUMERIC NOT NULL CHECK (price >= 0),
    market_cap NUMERIC,
    volume_24h NUMERIC,
    price_change_pct_24h NUMERIC,
    created_at_utc TIMESTAMP WITH TIME ZONE DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT unique_coin_time_currency UNIQUE (coin_id, time_id, currency_id)
);