{{ config(materialized="table") }}

WITH clean_stg AS (
    SELECT *
    FROM {{ ref("stg_coingecko_ohlc") }}
)

SELECT DISTINCT ON (symbol, timestamp_ms)
    symbol,
    coin_id,
    timestamp_ms,
    price_timestamp,
    TO_CHAR(price_timestamp, 'DD/MM/YYYY HH24:MI') AS date_str,
    open_price AS open,
    high_price AS high,
    low_price AS low,
    close_price AS close,
FROM stg_ohlc
ORDER BY symbol, timestamp_ms ASC, price_timestamp DESC