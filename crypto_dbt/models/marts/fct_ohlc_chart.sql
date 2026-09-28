{{ config(materialized="table") }}

WITH clean_stg AS (
    SELECT *
    FROM {{ ref("stg_coingecko_ohlc") }}
),

daily_grouped AS (
    SELECT
        symbol,
        coin_id,
        DATE_TRUNC('day', price_timestamp) AS day_utc,
        MIN(price_timestamp) AS min_ts,
        MAX(price_timestamp) AS max_ts,
        MAX(high_price) AS high,
        MIN(low_price) AS low
    FROM clean_stg
    GROUP BY symbol, coin_id, DATE_TRUNC('day', price_timestamp)
),

open_prices AS (
    SELECT DISTINCT ON (symbol, DATE_TRUNC('day', price_timestamp))
        symbol,
        DATE_TRUNC('day', price_timestamp) AS day_utc,
        open_price AS open
    FROM clean_stg
    ORDER BY symbol, DATE_TRUNC('day', price_timestamp), price_timestamp ASC
),

close_prices AS (
    SELECT DISTINCT ON (symbol, DATE_TRUNC('day', price_timestamp))
        symbol,
        DATE_TRUNC('day', price_timestamp) AS day_utc,
        close_price AS close
    FROM clean_stg
    ORDER BY symbol, DATE_TRUNC('day', price_timestamp), price_timestamp DESC
)

SELECT 
    dg.symbol,
    dg.coin_id,
    EXTRACT(EPOCH FROM dg.day_utc)::BIGINT * 1000 AS timestamp_ms,
    dg.day_utc AS price_timestamp,
    TO_CHAR(dg.day_utc, 'DD/MM/YYYY') AS date_str,
    op.open,
    dg.high,
    dg.low,
    cp.close
FROM daily_grouped dg
JOIN open_prices op
    ON dg.symbol = op.symbol AND dg.day_utc = op.day_utc
JOIN close_prices cp
    ON dg.symbol = cp.symbol AND dg.day_utc = cp.day_utc
ORDER BY dg.symbol, dg.day_utc ASC