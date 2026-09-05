import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

Rectangle {
    id: root
    color: "#181825"
    radius: 8
    border.color: "#313244"

    function loadOhlcData(ohlcData) {
        candlestickSeries.clear()
        if (!ohlcData || ohlcData.length === 0) return

        let minPrice = ohlcData[0].low
        let maxPrice = ohlcData[0].high

        for (let i = 0; i < ohlcData.length; i++) {
            let item = ohlcData[i]

            let setObj = Qt.createQmlObject(
                'import QtCharts; CandlestickSet { timestamp: ' + item.timestamp +
                '; open: ' + item.open +
                '; high: ' + item.high +
                '; low: ' + item.low +
                '; close: ' + item.close + ' }',
                candlestickSeries
            )

            candlestickSeries.append(setObj)

            if (item.low < minPrice) minPrice = item.low
            if (item.high > maxPrice) maxPrice = item.high
        }

        let range = maxPrice - minPrice
        let margin = range === 0 ? maxPrice * 0.1 : range * 0.12

        axisY.min = Math.max(0, minPrice - margin)
        axisY.max = maxPrice + margin

        if (ohlcData.length > 0) {
            let dayInMs = 86400000
            axisX.min = new Date(ohlcData[0].timestamp - dayInMs)
            axisX.max = new Date(ohlcData[ohlcData.length - 1].timestamp + dayInMs)
        }
    }

    ChartView {
        id: chartView
        anchors.fill: parent
        anchors.margins: 5
        backgroundColor: "black"
        legend.visible: false
        antialiasing: true

        DateTimeAxis {
            id: axisX
            format: "MMM yyyy"
            tickCount: 6
            labelsColor: "#9399b2"
            gridLineColor: "#212234"
            labelsFont.pixelSize: 11
            lineVisible: false
        }

        ValueAxis {
            id: axisY
            labelsColor: "#9399b2"
            gridLineColor: "#212234"
            labelFormat: "$%.2f"
            labelsFont.pixelSize: 11
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
            maximumColumnWidth: 4
            minimumColumnWidth: 16

            onHovered: (status, candlestickSet) => {
                if (status) {
                    txtDate.text = Qt.formatDateTime(new Date(candlestickSet.timestamp), "dd/MM/yyyy")
                    
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

            onPressed: (mouse) => lastMousePos = Qt.point(mouse.x, mouse.y)
            onPositionChanged: (mouse) => {
                if (mouse.buttons & Qt.LeftButton) {
                    let dx = mouse.x - lastMousePos.x
                    let dy = mouse.y - lastMousePos.y
                    if (dx !== 0) chartView.scrollLeft(dx)
                    if (dy !== 0) chartView.scrollUp(dy)
                    lastMousePos = Qt.point(mouse.x, mouse.y)
                }
            }
            
            onWheel: (wheel) => wheel.angleDelta.y > 0 ? chartView.zoom(1.05) : chartView.zoom(0.95)
            onDoubleClicked: chartView.zoomReset()
        }
    }


    RowLayout {
        id: ohlcHeader
        anchors.left: parent.left
        anchors.top: parent.top
        anchors.leftMargin: 65
        anchors.topMargin: 15
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
            font.pixelSize: 1
            font.bold: true1
        }

        Text {
            id: txtClose
            text: "C: ---"
            color: "#cdd6f4"
            font.pixelSize: 11
            font.bold: true
        }
    }
}