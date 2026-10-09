import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
import "components"

ApplicationWindow {
    id: window
    visible: true
    width: Math.min(Screen.desktopAvailableWidth * 0.85, 1400)
    height: Math.min(Screen.desktopAvailableHeight * 0.85, 800)
    minimumWidth: 1024
    minimumHeight: 650
    title: "Crypto Analytics Dashboard"
    color: "#1e1e2e"
    opacity: 0.0

    property string selectedSymbol: "BTC"

    property bool quotesLoaded: false
    property bool chartLoaded: !cryptoChart.isLoading
    property bool isAppLoading: !quotesLoaded || !chartLoaded

    Notification {
        id: toast
        z: 9999
    }

    Timer {
        interval: 300000
        running: true
        repeat: true
        
        onTriggered: {
            cryptoBridge.refresh_pipeline()
        }
    }

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
        window.chartLoaded = false
        window.quotesLoaded = false

        refreshChart()
        cryptoBridge.load_initial_quotes()
    }

    Item {
        id: main
        anchors.fill: parent
        visible: true
        opacity: window.isAppLoading ? 0.0 : 1.0
        scale: window.isAppLoading ? 0.98 : 1.0

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        Behavior on scale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
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

                AppButton {
                    id: refreshBtn

                    text: isProcessing ? "Syncing..." : "Update data"
                    isProcessing: cryptoBridge.status === "Synchronizing..."
                    enabled: !isProcessing && !cryptoChart.isLoading && !window.isAppLoading

                    onClicked: {
                        cryptoBridge.refresh_pipeline()
                    }
                }
            }

            CryptoChart {
                id: cryptoChart
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 320
                Layout.verticalStretchFactor: 3
            }

            CryptoListView {
                id: cryptoList
                Layout.fillWidth: true
                Layout.fillHeight: true
                Layout.minimumHeight: 180
                Layout.verticalStretchFactor: 2
                selectedSymbol: window.selectedSymbol
                isChartLoading: window.isAppLoading
                isSyncing: cryptoBridge.status === "Synchronizing..."
                chartOpacity: cryptoChart.chartOpacity
                model: []

                onSymbolSelected: (symbol) => {
                    window.selectedSymbol = symbol
                    window.refreshChart()
                }
            }
        }
    }

    MultiEffect {
        anchors.fill: main
        source: main
        blurEnabled: window.isAppLoading
        blur: window.isAppLoading ? 0.7 : 0.0
        blurMax: 16
        visible: window.isAppLoading
        z: 100

        Behavior on blur {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutCubic
            }
        }
    }

    Rectangle {
        id: loadingOverlay

        anchors.fill: parent
        color: "#1e1e2e"
        visible: opacity > 0
        opacity: window.isAppLoading ? 1.0 : 0.0
        z: 101

        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        MouseArea {
            anchors.fill: parent
            enabled: window.isAppLoading
        }

        ColumnLayout {
            anchors.centerIn: parent
            spacing: 15

            BusyIndicator {
                running: window.isAppLoading
                Layout.alignment: Qt.AlignHCenter
                implicitWidth: 48
                implicitHeight: 48
            }

            Text {
                text: "Initializing Dashboard..."
                color: "#cdd6f4"
                font.pixelSize: 16
                font.bold: true
                Layout.alignment: Qt.AlignHCenter
            }
        }
    }

    Connections {
        target: cryptoBridge
        
        function onDataUpdated() {
            cryptoBridge.load_initial_quotes()
            cryptoChart.loadSymbolChart(window.selectedSymbol)
            window.refreshChart()
        }

        function onQuotesReady(data) {
            cryptoList.model = data
            window.quotesLoaded = true
        }

        function onErrorMessage(msg) {
            toast.showNotification(msg, true)
        }

        function onSuccessMessage(msg) {
            toast.showNotification(msg, false)
        }
    }

    Connections {
        target: cryptoChart

        function onIsLoadingChanged() {
            if (!cryptoChart.isLoading) {
                window.chartLoaded = true
            }
        }
    }
}