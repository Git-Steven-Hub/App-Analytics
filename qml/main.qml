import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Effects
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

    property bool quotesLoaded: false
    property bool chartLoaded: !cryptoChart.isLoading
    property bool isAppLoading: !quotesLoaded || !chartLoaded

    Notification {
        id: toast
        z: 999
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

                    property bool isProcessing: cryptoBridge.status === "Synchronizing..."

                    enabled: !isProcessing && !cryptoChart.isAppLoading
                    implicitWidth: 140
                    implicitHeight: 36

                    contentItem: RowLayout {
                        spacing: 8
                        anchors.centerIn: parent

                        Item {
                            implicitWidth: 14
                            implicitHeight: 14
                            visible: refreshBtn.isProcessing

                            Rectangle {
                                anchors.fill: parent
                                radius: width / 2
                                color: "transparent"
                                border.color: "#89b4fa"
                                border.width: 2

                                Rectangle {
                                    width: 5
                                    height: 5
                                    color: "#181825"
                                    anchors.top: parent.top
                                    anchors.right: parent.right
                                }

                                RotationAnimation on rotation {
                                    running: refreshBtn.isProcessing
                                    from: 0
                                    to: 360
                                    duration: 800
                                    loops: Animation.Infinite
                                }
                            }
                        }

                        Text {
                            text: refreshBtn.isProcessing ? "Syncing..." : "Update data"
                            font.pixelSize: 13
                            font.bold: true
                            color: refreshBtn.enabled ? "#cdd6f4" : "#a6adc8"
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                    }

                    background: Rectangle {
                        color: !refreshBtn.enabled ? "#11111b" : (refreshBtn.down ? "#45475a" : (refreshBtn.hovered ? "#313244" : "#181825"))
                        radius: 6
                        border.color: refreshBtn.enabled ? "#585b70" : "#313244"
                        border.width: 1

                        Behavior on color {
                            ColorAnimation { 
                                duration: 150 
                            }
                        }
                    }

                    onClicked: {
                        toast.showNotification("Stating data synchronization...", false)
                        cryptoBridge.refresh_pipeline()
                    }
                }
            }

            Text {
                text: "State: " + cryptoBridge.status
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