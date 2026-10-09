{{ config(
    materialized="view",
    post_hook="ALTER VIEW {{ this }} SET (security_invoker = true);"
    ) 
}}

WITH latest_raw AS (
    SELECT
        payload_json::jsonb AS payload_json,
        ingested_at_utc
    FROM {{ source('supabase_raw', 'raw_crypto_responses') }}
    WHERE endpoint = '/cryptocurrency/quotes/latest'
    ORDER BY ingested_at_utc DESC
    LIMIT 1
),

flattened AS (
    SELECT
        (data.value->>'symbol')::TEXT AS symbol,
        (data.value->>'name')::TEXT AS coin_name,
        (data.value->'quote'->'USD'->>'price')::NUMERIC(18, 8) AS current_price,
        (data.value->'quote'->'USD'->>'percent_change_24h')::NUMERIC(10, 4) AS change_24h,
        (data.value->'quote'->'USD'->>'percent_change_7d')::NUMERIC(10, 4) AS change_7d,
        (data.value->'quote'->'USD'->>'market_cap')::NUMERIC(20, 2) AS market_cap,
        (data.value->'quote'->'USD'->>'volume_24h')::NUMERIC(20, 2) AS volume_24h,
        raw.ingested_at_utc
    FROM latest_raw raw,
    LATERAL jsonb_each(raw.payload_json->'data') AS data
)

SELECT
    UPPER(symbol) AS symbol,
    coin_name,
    current_price,
    change_24h,
    change_7d,
    market_cap,
    volume_24h,
    ingested_at_utc,
    DATE_TRUNC('day', ingested_at_utc) AS day_utc,
    FLOOR(EXTRACT(EPOCH FROM DATE_TRUNC('day', ingested_at_utc)) * 1000)::BIGINT AS timestamp_ms
FROM flattened