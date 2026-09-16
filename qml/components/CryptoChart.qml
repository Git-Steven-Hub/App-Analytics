import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Rectangle {
    id: root
    color: "#181825"
    radius: 8
    border.color: "#313244"

    property var rawDataMap: []
    property string currentRangeFilter: "1Y"
    property string pendingSymbol: ""
    property bool isLoading: false
    property alias chartOpacity: chartView.opacity

    function setAxisXRange(newMinMs, newMaxMs) {
        if (isNaN(newMinMs) || isNaN(newMaxMs) || newMinMs >= newMaxMs) return

        let oldMin = axisX.min.getTime()
        let oldMax = axisX.max.getTime()

        if (isNaN(oldMin) || isNaN(oldMax) || oldMin >= oldMax) {
            axisX.min = new Date(0)
            axisX.max = new Date(newMaxMs)
            axisX.min = new Date(newMinMs)
            
            return
        }

        if (newMaxMs > oldMax) {
            axisX.max = new Date(newMaxMs)
            axisX.min = new Date(newMinMs)
        }
        else {
            axisX.min = new Date(newMinMs)
            axisX.max = new Date(newMaxMs)
        }
    }

    function loadSymbolChart(symbol) {
        if (!symbol || isLoading) return

        isLoading = true
        pendingSymbol = symbol

        if (chartView.opacity === 0.0) {
            cryptoBridge.load_ohlc_async(pendingSymbol)
            pendingSymbol = ""
        }
        else {
            fadeOutAnimation.restart()
        }

        fadeOutAnimation.start()
    }

    NumberAnimation {
        id: fadeOutAnimation
        target: chartView
        property: "opacity"
        to: 0.0
        duration: 150
        easing.type: Easing.OutQuad

        onStarted: {
            root.isLoading = true
        }

        onFinished: {
            if (root.pendingSymbol !== "") {
                cryptoBridge.load_ohlc_async(root.pendingSymbol)
                root.pendingSymbol = ""
            }
        }
    }

    NumberAnimation {
        id: fadeInAnimation
        target: chartView
        property: "opacity"
        to: 1.0
        duration: 150
        easing.type: Easing.OutQuad

        onFinished: {
            root.isLoading = false
        }
    }

    function setTimeRange(rangeKey) {
        if (!rawDataMap || rawDataMap.length === 0) return

        currentRangeFilter = rangeKey

        let totalCount = rawDataMap.length
        let lastIdx = totalCount - 1

        let getTs = (item) => Number(item.timestamp_ms ?? item.timestamp ?? 0)

        let maxTs = getTs(rawDataMap[lastIdx])
        let minTs = getTs(rawDataMap[0])

        let dayMs = 24 * 60 * 60 * 1000
        let halfDayMs = 12 * 60 * 60 * 1000
        let targetMinTs = minTs

        switch (rangeKey) {
            case "7D":
                targetMinTs = Math.max(minTs, maxTs - (7 * dayMs))
                break
            
            case "30D":
                targetMinTs = Math.max(minTs, maxTs - (30 * dayMs))
                break

            case "90D":
                targetMinTs = Math.max(minTs, maxTs - (90 * dayMs))
                break
            
            case "1Y":
            default:
                targetMinTs = minTs
                break
        }

        setAxisXRange(targetMinTs - halfDayMs, maxTs + halfDayMs)

        let visibleItems = rawDataMap.filter(item => {
            let ts = getTs(item)
            return ts >= targetMinTs && ts <= maxTs
            }
        )

        if (visibleItems.length > 0) {
            let minPrice = Number(visibleItems[0].low)
            let maxPrice = Number(visibleItems[0].high)

            for (let i = 0;i < visibleItems.length;i ++) {
                let item = visibleItems[i]
                let low = Number(item.low)
                let high = Number(item.high)

                if (!isNaN(low) && low < minPrice) minPrice = low
                
                if (!isNaN(high) && high > maxPrice) maxPrice = high
            }

            let range = maxPrice - minPrice
            let margin = range === 0 ? maxPrice * 0.1 : range * 0.12

            axisY.min = Math.max(0, minPrice - margin)
            axisY.max = maxPrice + margin
        }
    }

    Connections {
        target: cryptoBridge

        function onOhlcDataReady(ohlcData) {
            if (!ohlcData || ohlcData.length === 0) {
                fadeInAnimation.start()
                return
            }

            root.rawDataMap = ohlcData
            candlestickSeries.clear()

            for (let i = 0;i < ohlcData.length; i++) {
                let item = ohlcData[i]
                let ts = Number(item.timestamp_ms ?? item.timestamp)
                let o = Number(item.open)
                let h = Number(item.high)
                let l = Number(item.low)
                let c = Number(item.close)

                if (isNaN(ts) || isNaN(o) || isNaN(h) || isNaN(l) || isNaN(c)) continue

                let setObj = Qt.createQmlObject(
                    `import QtCharts; CandlestickSet { timestamp: ${ts}; open: ${o}; high: ${h}; low: ${l}; close: ${c} }`,
                    candlestickSeries
                )

                candlestickSeries.append(setObj)
            }

            console.log("[CryptoChart] Velas construidas de forma segura en GUI Thread:", ohlcData.length)

            root.setTimeRange(root.currentRangeFilter)

            let lastIdx = ohlcData.length - 1
            txtDate.text = ohlcData[lastIdx].date_str ?? "---"
            txtOpen.text = "O: $" + Number(ohlcData[lastIdx].open).toFixed(2)
            txtHigh.text = "H: $" + Number(ohlcData[lastIdx].high).toFixed(2)
            txtLow.text = "L: $" + Number(ohlcData[lastIdx].low).toFixed(2)
            txtClose.text = "C: $" + Number(ohlcData[lastIdx].close).toFixed(2)

            renderDelayTimer.start()
        }
    }

    Timer {
        id: renderDelayTimer
        interval: 30
        repeat: false
        onTriggered: fadeInAnimation.start()
    }

    ChartView {
        id: chartView
        anchors.fill: parent
        anchors.margins: 5
        backgroundColor: "transparent"
        legend.visible: false
        antialiasing: true
        opacity: 0.0

        DateTimeAxis {
            id: axisX
            format: "dd/MM"
            labelsColor: "#9399b2"
            gridLineColor: "#212234"
            labelsFont.pixelSize: 10
            lineVisible: false
            tickCount: 6
        }

        ValueAxis {
            id: axisY
            labelsColor: "#9399b2"
            gridLineColor: "#212234"
            labelFormat: "$%.2f"
            labelsFont.pixelSize: 10
            lineVisible: false
        }

        CandlestickSeries {
            id: candlestickSeries
            axisX: axisX
            axisY: axisY
            increasingColor: "#26a69a"
            decreasingColor: "#ef5350"
            bodyOutlineVisible: false
            capsVisible: false
            maximumColumnWidth: 28
            minimumColumnWidth: 6

            onHovered: (status, candlestickSet) => {
                if (status) {
                    let setTs = candlestickSet.timestamp
                    let found = root.rawDataMap.find(item => Number(item.timestamp) === Number(setTs))

                    if (found) {txtDate.text = found.date_str}
                    
                    txtOpen.text = "O: $" + candlestickSet.open.toFixed(2)
                    txtHigh.text = "H: $" + candlestickSet.high.toFixed(2)
                    txtLow.text = "L: $" + candlestickSet.low.toFixed(2)
                    txtClose.text = "C: $" + candlestickSet.close.toFixed(2)
                    ohlcHeader.visible = true
                }
            }
        }

        MouseArea {
            anchors.fill: parent
            acceptedButtons: Qt.LeftButton | Qt.RightButton
            property point lastMousePos: Qt.point(0, 0)

            function getTs(item) {
                if (!item) return 0
                return Number(item.timestamp_ms ?? item.timestamp ?? 0)
            }

            function getAbsoluteBounds() {
                if (!root.rawDataMap || root.rawDataMap.length === 0) return [0, 0]

                let halfDaysMs = 12 * 60 * 60 * 1000
                let firstTs = getTs(root.rawDataMap[0])
                let lastTs = getTs(root.rawDataMap[root.rawDataMap.length - 1])

                return [
                    firstTs - halfDaysMs,
                    lastTs + halfDaysMs
                ]
            }

            function clampAxisX(newMinMs, newMaxMs, absoluteMin, absoluteMax) {
                let currentRange = newMaxMs - newMinMs
                let fullRange = absoluteMax - absoluteMin

                if (currentRange >= fullRange) {
                    axisX.min = new Date(absoluteMin)
                    axisX.max = new Date(absoluteMax)
                    return
                }

                if (newMinMs < absoluteMin) {
                    newMinMs = absoluteMin
                    newMaxMs = absoluteMin + currentRange
                }

                if (newMaxMs > absoluteMax) {
                    newMaxMs = absoluteMax
                    newMinMs = absoluteMax - currentRange

                    if (newMinMs < absoluteMin) {
                        newMinMs = absoluteMin
                    }
                }

                axisX.min = new Date(newMinMs)
                axisX.max = new Date(newMaxMs)
            }            

            onPressed: (mouse) => lastMousePos = Qt.point(mouse.x, mouse.y)
            
            onPositionChanged: (mouse) => {
                if (mouse.buttons & Qt.LeftButton) {
                    if (!root.rawDataMap || root.rawDataMap.length === 0) return

                    let dx = mouse.x - lastMousePos.x
                    lastMousePos = Qt.point(mouse.x, mouse.y)

                    if (dx === 0) return

                    let bounds = getAbsoluteBounds()

                    let absoluteMin = bounds[0]
                    let absoluteMax = bounds[1]

                    let currentMin = axisX.min.getTime()
                    let currentMax = axisX.max.getTime()
                    let currentRange = currentMax - currentMin

                    let msPerPixel = currentRange / chartView.width
                    let deltaMs = dx * msPerPixel

                    let newMin = currentMin - deltaMs
                    let newMax = currentMax - deltaMs

                    clampAxisX(newMin, newMax, absoluteMin, absoluteMax)
                }
            }
            
            onWheel: (wheel) => {
                if (!root.rawDataMap || root.rawDataMap.length === 0) return

                let bounds = getAbsoluteBounds()

                let absoluteMin = bounds[0]
                let absoluteMax = bounds[1]

                if (absoluteMin === 0 && absoluteMax === 0) return

                let currentMin = axisX.min.getTime()
                let currentMax = axisX.max.getTime()
                let currentRange = currentMax - currentMin

                let zoomFactor = wheel.angleDelta.y > 0 ? 0.9 : 1.1

                if (zoomFactor > 1.0) {
                    let proposedRange = currentRange * zoomFactor
                    let fullRange = absoluteMax - absoluteMin

                    if (proposedRange >= fullRange) {
                        axisX.min = new Date(absoluteMin)
                        axisX.max = new Date(absoluteMax)
                        return
                    }
                }

                let center = currentMin + (currentRange / 2)
                let halfNewRange = (currentRange * zoomFactor) / 2

                let newMin = center - halfNewRange
                let newMax = center + halfNewRange

                clampAxisX(newMin, newMax, absoluteMin, absoluteMax)
            }

            onDoubleClicked: {
                root.setTimeRange(root.currentRangeFilter)
            }
        }
    }


    RowLayout {
        id: ohlcHeader
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 80
        anchors.topMargin: 12
        spacing: 16
        z: 10

        Text {
            id: txtDate
            text: "---"
            color: "#cdd6f4"
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            id: txtOpen
            text: "O: ---"
            color: "#a6adc8"
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            id: txtHigh
            text: "H: ---"
            color: "#26a69a"
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            id: txtLow
            text: "L: ---"
            color: "#ef5350"
            font.pixelSize: 11
            font.bold: true
        }

        Text {
            id: txtClose
            text: "C: ---"
            color: "#cdd6f4"
            font.pixelSize: 11
            font.bold: true
        }
    }

    RowLayout {
        id: timeFilterBar
        anchors.right: parent.right
        anchors.top: parent.top
        anchors.rightMargin: 16
        anchors.topMargin: 12
        spacing: 6
        z: 10

        Repeater {
            model: ["7D", "30D", "90D", "1Y"]

            delegate: Button {
                id: filterBtn
                required property string modelData
                text: modelData

                implicitWidth: 42
                implicitHeight: 26

                contentItem: Text {
                    text: filterBtn.text
                    font.pixelSize: 11
                    font.bold: true
                    color: root.currentRangeFilter === filterBtn.modelData ? "#181825" : "#a6adc8"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    color: root.currentRangeFilter === filterBtn.modelData ? "#89b4fa" : (filterBtn.hovered ? "#313244" : "#1e1e2e")
                    radius: 4
                    border.color: root.currentRangeFilter === filterBtn.modelData ? "#89b4fa" : "#45475a"
                    border.width: 1
                }

                onClicked: root.setTimeRange(filterBtn.modelData)
            }
        }
    }
}