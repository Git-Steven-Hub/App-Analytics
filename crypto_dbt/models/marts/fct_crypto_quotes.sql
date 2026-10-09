{{ config(
    materialized="table",
    post_hook=[
        "ALTER TABLE {{ this }} ENABLE ROW LEVEL SECURITY;",
        "DROP POLICY IF EXISTS public_read_policy ON {{ this }};",
        "CREATE POLICY public_read_policy ON {{ this }} FOR SELECT TO anon, authenticated USING (true);"
        ]
    ) 
}}

WITH clean_stg AS (
    SELECT *
    FROM {{ ref('stg_cmc_quotes') }}
    WHERE current_price IS NOT NULL
)

SELECT DISTINCT ON (symbol)
    symbol,
    coin_name,
    current_price AS price_usd,
    market_cap AS market_cap_usd,
    volume_24h AS volume_24h_usd,
    change_24h AS pct_change_24h,
    change_7d AS pct_change_7d,
    ingested_at_utc AS price_timestamp,
    ingested_at_utc
FROM clean_stg
ORDER BY symbol, ingested_at_utc DESC