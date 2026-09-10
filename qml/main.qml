import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "components"

ApplicationWindow {
    id: window
    visible: true
    width: 1920
    height: 1080
    title: "Crypto Analytics Dashboard"
    color: "#1e1e2e"
    opacity: 0.0

    property string selectedSymbol: "BTC"

    function refreshChart() {
        cryptoChart.loadSymbolChart(selectedSymbol)
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        opacity = 1.0
        Qt.callLater(refreshChart)
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

        CryptoChart {
            id: cryptoChart
            Layout.fillWidth: true
            Layout.preferredHeight: 500
        }

        CryptoListView {
            id: cryptoList
            Layout.fillWidth: true
            Layout.fillHeight: true
            selectedSymbol: window.selectedSymbol
            model: cryptoBridge.get_latest_prices()

            onSymbolSelected: (symbol) => {
                window.selectedSymbol = symbol
                window.refreshChart()
            }
        }
    }

    Connections {
        target: cryptoBridge
        function onDataUpdated() {
            cryptoList.model = cryptoBridge.get_latest_prices()
            window.refreshChart()
        }
    }
}