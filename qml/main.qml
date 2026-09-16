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
    property bool isInitialLoad: true

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
        cryptoList.model = cryptoBridge.get_latest_prices()
        refreshChart()
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
                enabled: cryptoBridge.status !== "Synchronizing..." && !cryptoChart.isLoading
                text: cryptoBridge.status === "Synchronizing..." ? "Procesando..." : "Actualizar datos"

                contentItem: Text {
                    text: refreshBtn.text
                    font.pixelSize: 13
                    font.bold: true
                    color: refreshBtn.enabled ? "#cdd6f4" : "#6c7086"
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                }

                background: Rectangle {
                    implicitWidth: 140
                    implicitHeight: 36
                    color: !refreshBtn.enabled ? "#11111b" : (refreshBtn.down ? "#45475a" : (refreshBtn.hovered ? "#313244" : "#181825"))
                    radius: 6
                    border.color: refreshBtn.enabled ? "#585b70" : "#313244"
                    border.width: 1
                }

                onClicked: cryptoBridge.refresh_pipeline()
            }
        }

        Text {
            text: "Estado: " + cryptoBridge.status
            font.pixelSize: 13
            color: cryptoBridge.status.indexOf("Error") !== -1 ? "#f38ba8" : "#a6adc8"
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
            isChartLoading: window.isInitialLoad ? false : cryptoChart.isLoading
            isSyncing: cryptoBridge.status === "Synchronizing..."
            chartOpacity: cryptoChart.chartOpacity
            model: []

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

    Connections {
        target: cryptoChart

        function onIsLoadingChanged() {
            if (!cryptoChart.isLoading && window.isInitialLoad) {
                window.isInitialLoad = false
            }
        }
    }
}