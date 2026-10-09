{{ config(
    materialized="table",
    post_hook=[
        "ALTER TABLE {{ this }} ENABLE ROW LEVEL SECURITY;",
        "DROP POLICY IF EXISTS public_read_policy ON {{ this }};",
        "CREATE POLICY public_read_policy ON {{ this }} FOR SELECT TO anon, authenticated USING (true);"
        ]
    ) 
}}


WITH base_chart AS (
    SELECT *
    FROM {{ ref('fct_ohlc_chart') }}
),

calculated AS (
    SELECT
        symbol,
        timestamp_ms,
        price_timestamp,
        day_utc,
        open,
        high,
        low,
        close,
        AVG(close) OVER (
            PARTITION BY symbol 
            ORDER BY day_utc ASC
            ROWS BETWEEN 19 PRECEDING AND CURRENT ROW
        ) AS sma_20,

        AVG(close) OVER (
            PARTITION BY symbol 
            ORDER BY day_utc ASC
            ROWS BETWEEN 49 PRECEDING AND CURRENT ROW
        ) AS sma_50,
        
        LAG(close, 1) OVER (
            PARTITION BY symbol 
            ORDER BY day_utc ASC
        ) AS prev_close
        
    FROM base_chart
)

SELECT
    symbol,
    timestamp_ms,
    price_timestamp,
    day_utc,
    open,
    high,
    low,
    close,
    sma_20,
    sma_50,
    CASE 
        WHEN prev_close IS NULL OR prev_close = 0 THEN 0.0
        ELSE ((close - prev_close) / prev_close) * 100.0
    END AS pct_daily_change
FROM calculated
ORDER BY symbol, timestamp_ms ASC