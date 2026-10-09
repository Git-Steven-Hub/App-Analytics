import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts
import "../theme"
import "ChartUtils.js" as ChartUtils

Rectangle {
    id: root
    color: Style.bgSurface
    radius: Style.radiusMd
    border.color: Style.borderBase

    property var rawDataMap: []
    property string currentRangeFilter: "1Y"
    property string pendingSymbol: ""
    property bool isLoading: true
    property var createdCandles: []
    property bool showSma20: true
    property bool showSma50: true
    property alias chartOpacity: chartView.opacity

    NumberAnimation {
        id: fadeOutAnimation
        target: chartView
        property: "opacity"
        to: 0.05
        duration: 180
        easing.type: Easing.OutQuad

        onStarted: {
            root.isLoading = true
        }

        onFinished: {
            if (root.pendingSymbol !== "") {
                cryptoBridge.load_ohlc_async(root.pendingSymbol, 365)
            }
        }
    }

    NumberAnimation {
        id: fadeInAnimation
        target: chartView
        property: "opacity"
        to: 1.0
        duration: 350
        easing.type: Easing.OutCubic

        onStarted: {
            chartView.visible = true
        }

        onFinished: {
            root.isLoading = false
            root.pendingSymbol = ""
        }
    }


    /// Animation for axis transitions
    property real animCurrentMinX: 0
    onAnimCurrentMinXChanged: axisX.min = new Date(animCurrentMinX)

    property real animCurrentMaxX: 0
    onAnimCurrentMaxXChanged: axisX.max = new Date(animCurrentMaxX)

    property real animCurrentMinY: 0
    onAnimCurrentMinYChanged: axisY.min = animCurrentMinY

    property real animCurrentMaxY: 0
    onAnimCurrentMaxYChanged: axisY.max = animCurrentMaxY

    ParallelAnimation {
        id: axisAnimation

        NumberAnimation {
            id: animMinX
            target: root
            property: "animCurrentMinX"
            duration: 300
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: animMaxX
            target: root
            property: "animCurrentMaxX"
            duration: 300
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: animMinY
            target: root
            property: "animCurrentMinY"
            duration: 300
            easing.type: Easing.OutCubic
        }

        NumberAnimation {
            id: animMaxY
            target: root
            property: "animCurrentMaxY"
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    /// Functions of control
    function loadSymbolChart(symbol) {
        if (!symbol || (isLoading && pendingSymbol === symbol)) return

        fadeOutAnimation.stop()
        fadeInAnimation.stop()

        isLoading = true
        pendingSymbol = symbol

        if (chartView.opacity === 0.05) {
            cryptoBridge.load_ohlc_async(pendingSymbol, 365)
        }
        else {
            fadeOutAnimation.restart()
        }
    }

    function clearCandles() {
        candlestickSeries.clear()
        createdCandles = []
    }

    function setTimeRange(rangeKey, animated = true) {
        if (!rawDataMap || rawDataMap.length === 0) return

        root.currentRangeFilter = rangeKey

        let bounds = ChartUtils.calculateAnimatedBounds(rawDataMap, rangeKey, axisX, axisY)
        if (!bounds) return

        if (!animated) {
            axisX.min = new Date(bounds.targetMinX)
            axisX.max = new Date(bounds.targetMaxX)

            axisY.min = bounds.targetMinY
            axisY.max = bounds.targetMaxY

            return
        }

        axisAnimation.stop()
        root.animCurrentMinX = bounds.startMinX
        root.animCurrentMaxX = bounds.startMaxX

        root.animCurrentMinY = axisY.min
        root.animCurrentMaxY = axisY.max

        animMinX.from = bounds.startMinX; animMinX.to = bounds.targetMinX
        animMaxX.from = bounds.startMaxX; animMaxX.to = bounds.targetMaxX

        animMinY.from = axisY.min; animMinY.to = bounds.targetMinY
        animMaxY.from = axisY.max; animMaxY.to = bounds.targetMaxY

        axisAnimation.start()
    }

    function updateHeaderInfo(item) {
        if (!item) return

        ohlcHeader.dateText = item.date_str ?? "---"
        ohlcHeader.openText = "O: $" + Number(item.open).toFixed(2)
        ohlcHeader.highText = "H: $" + Number(item.high).toFixed(2)
        ohlcHeader.lowText = "L: $" + Number(item.low).toFixed(2)
        ohlcHeader.closeText = "C: $" + Number(item.close).toFixed(2)
        ohlcHeader.sma20Text = "SMA20: " + (item.sma_20 ? "$" + Number(item.sma_20).toFixed(2) : "$---")
        ohlcHeader.sma50Text = "SMA50: " + (item.sma_50 ? "$" + Number(item.sma_50).toFixed(2) : "$---")
    }

    Component {
        id: candlestickFactory
        CandlestickSet {}
    }

    Connections {
        target: cryptoBridge

        function onOhlcError(errorMsg) {
            root.clearCandles()
            root.rawDataMap = []
            sma_20.clear()
            sma_50.clear()

            fadeOutAnimation.stop()
            fadeInAnimation.stop()
            root.isLoading = false
            root.pendingSymbol = ""
            chartView.opacity = 1.0

            ohlcHeader.dateText = "Without Data"
            ohlcHeader.openText = "O: ---"
            ohlcHeader.highText = "H: ---"
            ohlcHeader.lowText = "L: ---"
            ohlcHeader.closeText = "C: ---"
            ohlcHeader.sma20Text = "SMA20: ---"
            ohlcHeader.sma50Text = "SMA50: ---"
        }

        function onOhlcDataReady(ohlcData) {
            root.clearCandles()

            if (!ohlcData || ohlcData.length === 0) {
                root.rawDataMap = []
                sma_20.clear()
                sma_50.clear()

                fadeOutAnimation.stop()
                fadeInAnimation.start()
                return
            }

            ohlcData.sort((a, b) => ChartUtils.getTs(a) - ChartUtils.getTs(b))

            root.rawDataMap = ohlcData

            sma_20.clear()
            sma_50.clear()

            let chunkSize = 35
            let index = 0

            function processBatch() {
                let limit = Math.min(index + chunkSize, ohlcData.length)
                
                for (; index < limit; index++) {
                    let item = ohlcData[index]
                    let ts = ChartUtils.getDisplayTs(item)
                    let o = Number(item.open)
                    let h = Number(item.high)
                    let l = Number(item.low)
                    let c = Number(item.close)

                    if (isNaN(ts) || isNaN(o) || isNaN(h) || isNaN(l) || isNaN(c)) continue

                    let setObj = candlestickFactory.createObject(candlestickSeries, 
                        {
                        "timestamp": ts,
                        "open": o,
                        "high": h,
                        "low": l,
                        "close": c
                        }
                    )

                    if (setObj) {
                        candlestickSeries.append(setObj)
                        root.createdCandles.push(setObj)
                    }

                    if (item.sma_20 !== undefined && item.sma_20 !== null && !isNaN(Number(item.sma_20))) {
                        sma_20.append(ts, Number(item.sma_20))
                    }

                    if (item.sma_50 !== undefined && item.sma_50 !== null && !isNaN(Number(item.sma_50))) {
                        sma_50.append(ts, Number(item.sma_50))
                    }
                }

                if (index < ohlcData.length) {
                    Qt.callLater(processBatch)
                }

                else {
                    Qt.callLater(() => {
                        root.setTimeRange(root.currentRangeFilter, false)

                        if (ohlcData.length > 0 ) {
                            root.updateHeaderInfo(ohlcData[ohlcData.length - 1])
                        }

                        fadeOutAnimation.stop()
                        renderDelayTimer.start()
                        }
                    )
                }
            }

            processBatch()
        }
    }

    Timer {
        id: renderDelayTimer
        interval: 30
        repeat: false
        onTriggered: fadeInAnimation.start()
    }

    /// Ui components
    RowLayout {
        id: topControls
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 16
        anchors.topMargin: 12
        spacing: 12
        z: 10

        SMAToggle {
            showSma20: root.showSma20
            showSma50: root.showSma50
            onShowSma20Changed: root.showSma20 = showSma20
            onShowSma50Changed: root.showSma50 = showSma50
        }

        TimeFilterBar {
            id: timeFilterBar
            currentFilter: root.currentRangeFilter
            onFilterSelected: (rangeKey) => root.setTimeRange(rangeKey)
        }
    }
    
    OhlcHeader {
        id: ohlcHeader
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.right: topControls.left
        anchors.leftMargin: 20
        anchors.rightMargin: 15
        anchors.topMargin: 12
        z: 10

        showSma20: root.showSma20
        showSma50: root.showSma50
    }

    ChartView {
        id: chartView
        anchors.fill: parent
        anchors.topMargin: 45
        anchors.bottomMargin: 5
        anchors.leftMargin: 10
        anchors.rightMargin: 10
        backgroundColor: "transparent"
        legend.visible: false
        antialiasing: true
        opacity: 0.0

        DateTimeAxis {
            id: axisX
            format: "dd/MM"
            labelsColor: Style.textMuted
            gridLineColor: Style.gridLine
            labelsFont.pixelSize: 10
            lineVisible: false
            tickCount: chartView.width < 600 ? 5 : 9
        }

        ValueAxis {
            id: axisY
            labelsColor: Style.textMuted
            gridLineColor: Style.gridLine
            labelFormat: "$%.2f"
            labelsFont.pixelSize: 10
            lineVisible: false
        }

        CandlestickSeries {
            id: candlestickSeries
            axisX: axisX
            axisY: axisY
            increasingColor: Style.teal
            decreasingColor: Style.danger
            bodyOutlineVisible: false
            capsVisible: false
            maximumColumnWidth: 28
            minimumColumnWidth: 6

            onHovered: (status, candlestickSet) => {
                if (status) {
                    let setTs = candlestickSet.timestamp

                    if (!root.rawDataMap || root.rawDataMap.length === 0) return
                    
                    let found = root.rawDataMap.find(item => {
                        let itemsDisplayTs = ChartUtils.getDisplayTs(item)

                        return Math.abs(itemsDisplayTs - setTs) < 43200000
                        }
                    )

                    if (found) {
                        root.updateHeaderInfo(found)
                    }
                }
            }
        }

        LineSeries {
            id: sma_20
            name: "SMA 20"
            axisX: axisX
            axisY: axisY
            color: root.showSma20 ? Style.warning : "#00f9e2af"
            width: 2

            Behavior on color {
                ColorAnimation {
                    duration: 220
                    easing.type: Easing.InOutQuad
                }
            }
        }

        LineSeries {
            id: sma_50
            name: "SMA 50"
            axisX: axisX
            axisY: axisY
            color: root.showSma50 ? Style.primary : "#0089b4fa"
            width: 2

            Behavior on color {
                ColorAnimation {
                    duration: 220
                    easing.type: Easing.InOutQuad
                }
            }
        }

        ChartToolTip {
            id: chartTooltip
            active: chartMouseArea.containsMouse && !root.isLoading
        }

        MouseArea {
            id: chartMouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property point lastMousePos: Qt.point(0, 0)

            onExited: {
                chartTooltip.dateVal = ""
            }

            onPositionChanged: (mouse) => {
                if (!root.rawDataMap || root.rawDataMap.length === 0) return

                let pArea = chartView.plotArea
                let insidePlot = (mouse.x >= pArea.x && mouse.x <= pArea.x + pArea.width && 
                                    mouse.y >= pArea.y && mouse.y <= pArea.y + pArea.height)

                if (!insidePlot) {
                    chartTooltip.dateVal = ""
                    return
                }

                let val = chartView.mapToValue(Qt.point(mouse.x, mouse.y), candlestickSeries)

                if (!isNaN(val.x) && !isNaN(val.y) && val.x > 0) {
                    let closestItem = null
                    let minDiff = Number.MAX_VALUE

                    for (let i = 0; i < root.rawDataMap.length; i++) {
                        let item = root.rawDataMap[i]
                        let itemTs = ChartUtils.getDisplayTs(item)

                        let diff = Math.abs(itemTs - val.x)

                        if (diff < minDiff) {
                            minDiff = diff
                            closestItem = item
                        }
                    }

                    if (closestItem) {
                        let itemTs = ChartUtils.getTs(closestItem)
                        
                        let displayTs = ChartUtils.getDisplayTs(closestItem)
                        let candlePos = chartView.mapToPosition(Qt.point(displayTs, Number(closestItem.close)), candlestickSeries)
                        
                        chartTooltip.updateCrosshair(candlePos, mouse.y, chartView.plotArea)
                        
                        chartTooltip.dateVal = ChartUtils.formatTimestamp(itemTs)
                        chartTooltip.priceVal = "$" + Number(val.y).toFixed(2)
                        
                        root.updateHeaderInfo(closestItem)
                    }
                }

                if (mouse.buttons & Qt.LeftButton) {
                    let dx = mouse.x - lastMousePos.x
                    lastMousePos = Qt.point(mouse.x, mouse.y)
                    if (dx === 0) return

                    let bounds = ChartUtils.getFilterBounds(root.rawDataMap, root.currentRangeFilter)
                    let currentMin = axisX.min.getTime()
                    let currentMax = axisX.max.getTime()
                    let deltaMs = dx * ((currentMax - currentMin) / chartView.width)

                    ChartUtils.clampAxisX(axisX, currentMin - deltaMs, currentMax - deltaMs, bounds[0], bounds[1])
                }
            }            

            onPressed: (mouse) => lastMousePos = Qt.point(mouse.x, mouse.y)

            onWheel: (wheel) => {
                if (!root.rawDataMap || root.rawDataMap.length === 0) return

                let bounds = ChartUtils.getFilterBounds(root.rawDataMap, root.currentRangeFilter)
                
                let currentMin = axisX.min.getTime()
                let currentMax = axisX.max.getTime()
                let currentRange = currentMax - currentMin

                let zoomFactor = wheel.angleDelta.y > 0 ? 0.85 : 1.15

                let maxAllowedRange = bounds[1] - bounds[0]
                let minAllowedRange = 3 * 24 * 60 * 60 * 1000

                if (zoomFactor > 1.0 && (currentRange * zoomFactor) >= maxAllowedRange) {
                    axisX.min = new Date(bounds[0])
                    axisX.max = new Date(bounds[1])
                    return
                }

                if (zoomFactor < 1.0 && (currentRange * zoomFactor) <= minAllowedRange) {
                    return
                }

                let center = currentMin + (currentRange / 2)
                let halfNewRange = (currentRange * zoomFactor) / 2

                ChartUtils.clampAxisX(axisX, center - halfNewRange, center + halfNewRange, bounds[0], bounds[1])
            }

            onDoubleClicked: root.setTimeRange(root.currentRangeFilter)
        }
    }
    
    LoadingSkeleton {
        id: chartSkeleton
        isLoading: root.isLoading
        pendingSymbol: root.pendingSymbol
    }
}