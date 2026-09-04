import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtCharts

ApplicationWindow {
    id: window
    visible: true
    width: 1920
    height: 1080
    title: "Crypto Analytics Dashboard"
    color: "#1e1e2e"
    opacity: 0.0

    property string selectedSymbol: "BTC"

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        opacity = 1.0
        initTimer.start()
    }

    Timer {
        id: initTimer
        interval: 50
        repeat: false
        onTriggered: {
            updateChart()
        }
    }

    function updateChart() {
        lineSeries.clear()
        let points = cryptoBridge.get_price_history(selectedSymbol)
        
        if (points.length === 0) return

        let minPrice = points[0].y
        let maxPrice = points[0].y

        for (let i = 0; i < points.length; i++) {
            lineSeries.append(points[i].x, points[i].y)
            if (points[i].y < minPrice) minPrice = points[i].y
            if (points[i].y > maxPrice) maxPrice = points[i].y
        }

        let margin = (maxPrice - minPrice) * 0.1
        axisY.min = Math.max(0, minPrice - margin)
        axisY.max = maxPrice + margin
        
        if (points.length > 0) {
            axisX.min = new Date(points[0].x)
            axisX.max = new Date(points[points.length - 1].x)
        }
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        RowLayout {
            Layout.fillWidth: true

            Text {
                text: "Analytics Dashboard"
                font.pixelSize: 24
                font.bold: true
                color: "#cdd6f4"
            }

            Item { Layout.fillWidth: true }

            Button {
                id: refreshBtn
                text: "Actualizar datos"

                contentItem: Text {
                    text: refreshBtn.text
                    font.pixelSize: 13
                    font.bold: true
                    color: "#cdd6f4"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: 140
                    implicitHeight: 36
                    color: refreshBtn.down ? "#45475a" : (refreshBtn.hovered ? "#313244" : "#181825")
                    radius: 6
                    border.color: "#585b70"
                    border.width: 1
                }

                onClicked: cryptoBridge.refresh_pipeline()
            }
        }

        Text {
            text: "Estado: " + cryptoBridge.status
            font.pixelSize: 13
            color: "#a6adc8"
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 500
            color: "#181825"
            radius: 8
            border.color: "#313244"

            ChartView {
                id: chartView
                anchors.fill: parent
                anchors.margins: 5
                backgroundColor: "transparent"
                legend.visible: false
                antialiasing: true

                DateTimeAxis {
                    id: axisX
                    format: "dd MMM yyyy"
                    tickCount: 6
                    labelsColor: "#a6adc8"
                    gridLineColor: "#313244"
                }

                ValueAxis {
                    id: axisY
                    labelsColor: "#a6adc8"
                    gridLineColor: "#313244"
                    labelFormat: "$%.2f"
                }

                LineSeries {
                    id: lineSeries
                    name: selectedSymbol
                    axisX: axisX
                    axisY: axisY
                    color: "#89b4fa"
                    width: 2.5

                    onHovered: (point, state) => {
                        if (state) {
                            let dateStr = Qt.formatDateTime(new Date(point.x), "dd/MM/yyyy")
                            let priceStr = "$" + point.y.toFixed(2)
                            tooltipText.text = dateStr + " \n " + priceStr

                            let pos = chartView.mapToPosition(point, lineSeries)
                            tooltipRect.x = Math.min(pos.x + 10, chartView.width - tooltipRect.width - 10)
                            tooltipRect.y = Math.max(10, pos.y - tooltipRect.height - 10)
                            tooltipRect.visible = true
                        } 
                        else {
                            tooltipRect.visible = false
                        }
                    }
                }

                MouseArea {
                    id: chartMouseArea
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    hoverEnabled: false

                    property point lastMousePos: Qt.point(0, 0)

                    onPressed: (mouse) => {
                        lastMousePos = Qt.point(mouse.x, mouse.y)
                    }

                    onPositionChanged: (mouse) => {
                        if (mouse.buttons & Qt.LeftButton) {
                            let dx = mouse.x - lastMousePos.x
                            let dy = mouse.y - lastMousePos.y

                            if (dx !== 0) chartView.scrollLeft(dx)
                            if (dy !== 0) chartView.scrollUp(dy)

                            lastMousePos = Qt.point(mouse.x, mouse.y)
                        }
                    }

                    onWheel: (wheel) => {
                        if (wheel.angleDelta.y > 0) {
                            chartView.zoom(1.05)
                        }
                        else {
                            chartView.zoom(0.950)
                        }
                    }

                    onDoubleClicked: {
                        chartView.zoomReset()
                    }
                }
            }
            
            Rectangle {
                id: tooltipRect
                visible: false
                width: tooltipText.implicitWidth + 16
                height: tooltipText.implicitHeight + 10
                color: "#313244"
                radius: 6
                border.color: "#89b4fa"
                border.width: 1
                z: 10

                Text {
                    id: tooltipText
                    anchors.centerIn: parent
                    color: "#cdd6f4"
                    font.pixelSize: 11
                    font.bold: true
                    horizontalAlignment: Text.AlignHCenter
                }
            }
        }

        ListView {
            id: listView
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: cryptoBridge.get_latest_prices()

            delegate: Rectangle {
                width: listView.width
                height: 70
                color: modelData.symbol === selectedSymbol ? "#45475a" : "#313244"
                radius: 8
                border.color: modelData.symbol === selectedSymbol ? "#89b4fa" : "#45477a"
                border.width: modelData.symbol === selectedSymbol ? 2 : 1

                MouseArea {
                    anchors.fill: parent
                    onClicked: {
                        selectedSymbol = modelData.symbol
                        updateChart()
                    }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 15

                    ColumnLayout {
                        spacing: 4
                        
                        Text {
                            text: modelData.name + " (" + modelData.symbol + ")"
                            font.pixelSize: 16
                            font.bold: true
                            color: "#cdd6f4"
                        }

                        Text {
                            text: "Vol 24h: " + modelData.volume_24h
                            font.pixelSize: 12
                            color: "#a6adc8"
                        }
                    }

                    Item { Layout.fillWidth: true }

                    ColumnLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight

                        Text {
                            text: "Market Cap"
                            font.pixelSize: 11
                            color: "#6c7086"
                            Layout.alignment: Qt.AlignRight
                        }

                        Text {
                            text: modelData.market_cap
                            font.pixelSize: 13
                            color: "#bac2de"
                            Layout.alignment: Qt.AlignRight
                        }
                    }

                    Item { implicitWidth: 20 }

                    ColumnLayout {
                        spacing: 4
                        Layout.alignment: Qt.AlignRight

                        Text {
                            text: modelData.price
                            font.pixelSize: 16
                            font.bold: true
                            color: "#cdd6f4"
                            Layout.alignment: Qt.AlignRight
                        }

                        RowLayout {
                            spacing: 6
                            Layout.alignment: Qt.AlignRight

                            Text {
                                text: "24h: " + modelData.change_24h
                                font.pixelSize: 12
                                font.bold: true
                                color: modelData.is_positive ? "#a6e3a1" : "#f38ba8"
                            }

                            Text {
                                text: "7d: " + modelData.change_7d
                                font.pixelSize: 12
                                font.bold: true
                                color: "#bac2de"
                            }
                        }
                    }
                }
            }
            
            spacing: 10
        }
    }

    Connections {
        target: cryptoBridge
        function onDataUpdated() {
            listView.model = cryptoBridge.get_latest_prices()
        }
    }
}