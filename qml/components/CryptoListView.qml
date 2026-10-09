import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Item {
    id: wrapper

    property alias model: root.model
    property alias count: root.count
    property string selectedSymbol: ""
    property bool isChartLoading: false
    property bool isSyncing: false
    property real chartOpacity: 1.0

    signal symbolSelected(string symbol)

    ColumnLayout {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.top: parent.top
        spacing: 10
        visible: root.count === 0

        Repeater {
            model: 3

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 70
                radius: 8
                color: Style.bgCard

                SequentialAnimation on color {
                    running: root.count === 0
                    loops: Animation.Infinite

                    ColorAnimation {
                        from: Style.gridLine
                        to: Style.borderBase
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }

                    ColorAnimation { 
                        from: Style.borderBase
                        to: Style.gridLine
                        duration: 800
                        easing.type: Easing.InOutQuad
                    }
                }
            }
        }
    }

    ListView {
        id: root

        clip: true
        anchors.fill: parent
        spacing: 10
        visible: root.count > 0

        delegate: Rectangle {
            id: cardItem

            property bool isSelected: modelData.symbol === wrapper.selectedSymbol
            property bool isHovered: mouseArea.containsMouse

            width: root.width
            height: 70
            color: isSelected ? Style.borderBase: (isHovered ? Style.bgCardHover : Style.bgCard)
            radius: 8
            border.color: isSelected ? Style.primary : (isHovered ? Style.borderActive : Style.borderBase)
            border.width: isSelected ? 2 : 1
            opacity: wrapper.isSyncing ? 0.6 : (0.6 + (wrapper.chartOpacity * 0.4))

            Behavior on color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            Behavior on border.color {
                ColorAnimation {
                    duration: 180
                    easing.type: Easing.OutCubic
                }
            }

            MouseArea {
                id: mouseArea

                anchors.fill: parent
                hoverEnabled: true
                enabled: !wrapper.isChartLoading && !wrapper.isSyncing
                cursorShape: enabled ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                onClicked: {
                    if (modelData.symbol !== wrapper.selectedSymbol) {
                        wrapper.symbolSelected(modelData.symbol)
                    }
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
                        color: Style.textMain
                    }

                    Text {
                        text: "Vol 24h: " + (modelData.volume_24h_usd ?? "0")
                        font.pixelSize: 12
                        color: Style.textMain
                    }
                }

                Item { Layout.fillWidth: true }

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignRight

                    Text {
                        text: "Market Cap"
                        font.pixelSize: 11
                        color: Style.textSubtle
                        Layout.alignment: Qt.AlignRight
                    }

                    Text {
                        text: modelData.market_cap_usd ?? "0"
                        font.pixelSize: 13
                        color: Style.textMuted
                        Layout.alignment: Qt.AlignRight
                    }
                }

                Item { implicitWidth: 20 }

                ColumnLayout {
                    spacing: 4
                    Layout.alignment: Qt.AlignRight

                    Text {
                        text: modelData.price ?? "0"
                        font.pixelSize: 16
                        font.bold: true
                        color: Style.textMain
                        Layout.alignment: Qt.AlignRight
                    }

                    RowLayout {
                        spacing: 6
                        Layout.alignment: Qt.AlignRight

                        Text {
                            text: "24h: " + modelData.change_24h
                            font.pixelSize: 12
                            font.bold: true
                            color: modelData.is_positive ? Style.success : Style.danger
                        }

                        Text {
                            text: "7d: " + modelData.change_7d
                            font.pixelSize: 12
                            font.bold: true
                            color: Style.textMuted
                        }
                    }
                }
            }
        }
    }
}