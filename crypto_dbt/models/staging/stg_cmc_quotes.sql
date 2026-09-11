{{ config(materialized="view") }}

WITH raw AS (
    SELECT
        raw_id,
        payload_json,
        ingested_at_utc
    FROM {{ source('supabase_raw', 'raw_crypto_responses') }}
    WHERE endpoint = '/cryptocurrency/quotes/latest'
),

extracted_coins AS (
    SELECT
        raw_id,
        ingested_at_utc,
        coin_kv.key AS symbol,
        coin_kv.value AS coin_data
    FROM raw,
    LATERAL jsonb_each(raw.payload_json->'data') AS coin_kv
)

SELECT
    raw_id,
    UPPER(symbol) AS symbol,
    coin_data->>'name' AS coin_name,
    (coin_data->>'quote'->'USD'->>'price')::NUMERIC(18, 8) AS price_usd,
    (coin_data->>'quote'->'USD'->>'market_cap')::NUMERIC(18, 2) AS market_cap_usd,
    (coin_data->>'quote'->'USD'->>'volume_24h')::NUMERIC(18, 2)AS volume_24h_usd,
    (coin_data->>'quote'->'USD'->>'percent_change_24h')::NUMERIC(10, 4) AS pct_change_24h,
    (coin_data->>'quote'->'USD'->>'percent_change_7d')::NUMERIC(10, 4) AS pct_change_7d,
    (coin_data->>'quote'->'USD'->>'last_updated')::TIMESTAMPTZ AS price_timestamp,
    ingested_at_utc
FROM extracted_coins