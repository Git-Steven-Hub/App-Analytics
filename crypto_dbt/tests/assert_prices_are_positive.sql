SELECT
    symbol,
    timestamp_ms,
    open,
    close
FROM {{ ref('fct_ohlc_chart')}}
WHERE open <= 0
    OR high <= 0
    OR low <= 0
    OR close <= 0