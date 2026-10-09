{{ config(
    materialized="view",
    post_hook="ALTER VIEW {{ this }} SET (security_invoker = true);"
    ) 
}}

WITH latest_raw AS (
    SELECT DISTINCT ON (payload_json->'_metadata'->>'symbol')
        raw_id,
        endpoint,
        payload_json::jsonb AS payload_json,
        payload_json->'_metadata'->>'symbol' AS symbol,
        payload_json->'_metadata'->>'coin_id' AS coin_id,
        ingested_at_utc
    FROM {{ source('supabase_raw', 'raw_crypto_responses') }}
    WHERE endpoint = '/coingecko/ohlc'
    ORDER BY (payload_json->'_metadata'->>'symbol'), ingested_at_utc DESC
),

flattened AS (
    SELECT
        raw.symbol,
        raw.coin_id,
        (item->>0)::BIGINT AS timestamp_ms,
        (item->>1)::NUMERIC(18, 8) AS open_price,
        (item->>2)::NUMERIC(18, 8) AS high_price,
        (item->>3)::NUMERIC(18, 8) AS low_price,
        (item->>4)::NUMERIC(18, 8) AS close_price,
        raw.ingested_at_utc
    FROM latest_raw raw,
    LATERAL jsonb_array_elements(raw.payload_json->'ohlc_data') AS item
)

SELECT
    UPPER(symbol) AS symbol,
    coin_id,
    timestamp_ms,
    TO_TIMESTAMP(timestamp_ms / 1000.0) AT TIME ZONE 'UTC' AS price_timestamp,
    open_price,
    high_price,
    low_price,
    close_price
FROM flattened
WHERE open_price IS NOT NULL