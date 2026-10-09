.pragma library

function getTs(item) {
    if (!item) return 0;

    let raw = item.timestamp_ms ?? item.timestamp ?? item.price_timestamp;

    if (typeof raw === "number") {
        return raw < 10000000000 ? raw * 1000 : raw;
    }

    if (typeof raw === "string") {
        let parsed = Date.parse(raw);
        return isNaN(parsed) ? 0 : parsed;
    }

    return 0;
}

function getDisplayTs(item) {
    let ts = getTs(item);
    if (ts === 0 ) return 0;

    let d = new Date(ts);

    return new Date(d.getUTCFullYear(), d.getUTCMonth(), d.getUTCDate()).getTime();
}

function formatTimestamp(ts) {
    let d = new Date(ts);
    if (isNaN(d.getTime())) return "---";

    let day = ("0" + d.getUTCDate()).slice(-2);
    let month = ("0" + (d.getUTCMonth() + 1)).slice(-2);
    let year = d.getUTCFullYear();
 
    return day + "/" + month + "/" + year;
}

function getFilterBounds(rawDataMap, currentRangeFilter) {
    if (!rawDataMap || rawDataMap.length === 0) return [0, 0];

    let dayMs = 6 * 60 * 60 * 1000;
    let paddingLeft = 12 * 60 * 60 * 1000;
    let paddingRight = 1.5 * dayMs;

    let timestamps = rawDataMap.map(getDisplayTs).filter(ts => ts > 0);
    if (timestamps.length === 0) return [0, 0];

    let maxTs = Math.max(...timestamps);
    let minTs = Math.min(...timestamps);

    let allowedMinTs = minTs;

    switch (currentRangeFilter) {
        case "7D":
            allowedMinTs = Math.max(minTs, maxTs - (7 * dayMs));
            break;
        case "30D":
            allowedMinTs = Math.max(minTs, maxTs - (30 * dayMs));
            break;
        case "90D":
            allowedMinTs = Math.max(minTs, maxTs - (90 * dayMs));
            break;
        case "1Y":
        default:
            allowedMinTs = minTs;
            break;
    }

    return [allowedMinTs - paddingLeft, maxTs + paddingRight];
}

function calculateYLimits(rawDataMap, targetMinTs, maxTs) {
    let dayMs = 24 * 60 * 60 * 1000;
    let halfDayMs = 12 * 60 * 60 * 1000;

    let visibleItems = rawDataMap.filter(item => {
        let ts = getDisplayTs(item);
        return ts >= (targetMinTs - (2 * dayMs)) && ts <= (maxTs + halfDayMs);
    });

    if (visibleItems.length === 0) return null;

    let minPrice = Number(visibleItems[0].low);
    let maxPrice = Number(visibleItems[0].high);

    for (let i = 0; i < visibleItems.length; i++) {
        let item = visibleItems[i];
        let low = Number(item.low);
        let high = Number(item.high);

        if (!isNaN(low) && low < minPrice) minPrice = low;
        if (!isNaN(high) && high > maxPrice) maxPrice = high;
    }

    let range = maxPrice - minPrice;
    let margin = range === 0 ? maxPrice * 0.05 : range * 0.08;

    return {
        min: Math.max(0, minPrice - margin),
        max: maxPrice + margin
    };
}

function calculateAnimatedBounds(rawDataMap, rangeKey, currentAxisX, currentAxisY) {
    let xBounds = getFilterBounds(rawDataMap, rangeKey);

    if (!xBounds || xBounds[0] === 0) return null;

    let targetMinX = xBounds[0];
    let targetMaxX = xBounds[1];

    let yLimits = calculateYLimits(rawDataMap, targetMinX, targetMaxX);

    return {
        startMinX: currentAxisX.min.getTime(),
        startMaxX: currentAxisX.max.getTime(),

        targetMinX: targetMinX,
        targetMaxX: targetMaxX,

        targetMinY: yLimits ? yLimits.min : currentAxisY.min,
        targetMaxY: yLimits ? yLimits.max : currentAxisY.max
    };
}

function clampAxisX(axisX, newMinMs, newMaxMs, boundsMin, boundsMax) {
    let currentRange = newMaxMs - newMinMs;
    let maxAllowedRange = boundsMax - boundsMin;

    if (currentRange >= maxAllowedRange) {
        axisX.min = new Date(boundsMin);
        axisX.max = new Date(boundsMax);
        return;
    }

    if (newMinMs < boundsMin) {
        newMinMs = boundsMin;
        newMaxMs = boundsMin + currentRange;
    }

    if (newMaxMs > boundsMax) {
        newMaxMs = boundsMax;
        newMinMs = boundsMax - currentRange;
        if (newMinMs < boundsMin) newMinMs = boundsMin;
    }

    axisX.min = new Date(newMinMs);
    axisX.max = new Date(newMaxMs);
}