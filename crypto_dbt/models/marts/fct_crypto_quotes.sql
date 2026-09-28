{{ config(materialized="table") }}

WITH clean_stg AS (
    SELECT *
    FROM {{ ref('stg_cmc_quotes') }}
    WHERE price_usd IS NOT NULL
)

SELECT DISTINCT ON (symbol)
    raw_id,
    symbol,
    coin_name,
    price_usd,
    market_cap_usd,
    volume_24h_usd,
    pct_change_24h,
    pct_change_7d,
    COALESCE (price_timestamp, ingested_at_utc) AS price_timestamp,
    ingested_at_utc
FROM clean_stg
ORDER BY symbol, COALESCE(price_timestamp, ingested_at_utc) DESC