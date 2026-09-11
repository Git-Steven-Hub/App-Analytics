{{ config(materialiez="view") }}

WITH source_data as (
    SELECT *
    FROM {{ source("supabase_raw", "raw_crypto_ohlc")}}
)

SELECT
    UPPER(symbol) AS symbol,
    CAST(open AS NUMERIC(18, 8)) AS open_price,
    CAST(high AS NUMERIC(18, 8)) AS high_price,
    CAST(low AS NUMERIC(18, 8)) AS low_price,
    CAST(close AS NUMERIC(18, 8)) AS close_price,
    CAST(volume AS NUMERIC(18, 8)) AS volume_usd,
    timestamp_ms,
    TO_TIMESTAMP(timestamp_ms / 1000.0) AT TIME ZONE 'UTC' AS price_timestamp
FROM source_data
WHERE open IS NOT NULL
    AND close IS NOT NULL
    AND timestamp_ms > 0