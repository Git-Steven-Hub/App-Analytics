import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ListView {
    id: root
    clip: true
    spacing: 10

    property string selectedSymbol: ""
    signal symbolSelected(string symbol)

    delegate: Rectangle {
        width: root.width
        height: 70
        color: modelData.symbol === selectedSymbol ? "#45475a" : "#313244"
        radius: 8
        border.color: modelData.symbol === selectedSymbol ? "#89b4fa" : "#45477a"
        border.width: modelData.symbol === selectedSymbol ? 2 : 1

        MouseArea {
            anchors.fill: parent
            onClicked: {
                root.symbolSelected(modelData.symbol)
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
}