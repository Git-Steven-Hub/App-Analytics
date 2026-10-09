{{ config(
    materialized="table",
    post_hook=[
        "ALTER TABLE {{ this }} ENABLE ROW LEVEL SECURITY;",
        "DROP POLICY IF EXISTS public_read_policy ON {{ this }};",
        "CREATE POLICY public_read_policy ON {{ this }} FOR SELECT TO anon, authenticated USING (true);"
        ]
    ) 
}}

WITH historical_ohlc AS (
    SELECT
        symbol,
        timestamp_ms,
        price_timestamp,
        DATE_TRUNC('day', price_timestamp) AS day_utc,
        open_price,
        high_price,
        low_price,
        close_price
    FROM {{ ref('stg_coingecko_ohlc') }}
),

today_quote AS (
    SELECT
        symbol,
        timestamp_ms,
        ingested_at_utc AS price_timestamp,
        day_utc,
        current_price AS open_price,
        current_price AS high_price,
        current_price AS low_price,
        current_price AS close_price
    FROM {{ ref('stg_cmc_quotes') }}
),

combined AS (
    SELECT * FROM historical_ohlc
    UNION ALL
    SELECT t.*
    FROM today_quote t
    WHERE NOT EXISTS (
        SELECT 1 
        FROM historical_ohlc h 
        WHERE h.symbol = t.symbol AND h.day_utc = t.day_utc
    )
)

SELECT
    symbol,
    timestamp_ms,
    price_timestamp,
    day_utc,
    open_price AS open,
    high_price AS high,
    low_price AS low,
    close_price AS close
FROM combined
ORDER BY symbol, timestamp_ms ASC