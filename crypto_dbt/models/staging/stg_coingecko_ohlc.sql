{{ config(materialized="view") }}

WITH raw AS (
    SELECT
        raw_id,
        endpoint,
        payload_json,
        payload_json->_metadata->>'symbol' AS symbol,
        payload_json->_metadata->>'coin_id' AS coin_id,
        ingested_at_utc
    FROM {{ source('supabase_war', 'raw_crypto_responses') }}
    WHERE endpoint = '/coingecko/ohlc'
),

flattened AS (
    SELECT
        raw.symbol,
        raw.coin_id,
        (item->>0)::BIGINT AS timestamp_ms,
        (item->>1)::NUMERIC(18, 8) AS open_price,
        (item->>2)::NUMERIC(18, 8) AS high_price,
        (item->>3)::NUMERIC(18, 8) AS low_price,
        (item->>4)::NUMERIC(18, 8) AS close_price
    FROM raw,
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