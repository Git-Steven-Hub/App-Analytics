import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme"

Button {
    id: root

    property bool isSelected: false
    property bool isProcessing: false
    property color activeColor: Style.primary

    implicitWidth: contentItem.implicitWidth + leftPadding + rightPadding
    implicitHeight: 32

    leftPadding: 14
    rightPadding: 14

    contentItem: RowLayout {
        spacing: root.isProcessing ? 6 : 0

        Item {
            implicitWidth: 12
            implicitHeight: 12
            visible: root.isProcessing
            Layout.preferredWidth: root.isProcessing ? 12 : 0

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: Style.primary
                border.width: 2

                Rectangle {
                    width: 4
                    height: 4
                    color: Style.bgSurface
                    anchors.top: parent.top
                    anchors.right: parent.right
                }

                RotationAnimation on rotation {
                    running: root.isProcessing
                    from: 0
                    to: 360
                    duration: 800
                    loops: Animation.Infinite
                }
            }
        }

        Text {
            text: root.text
            font.pixelSize: Style.fontMd
            font.bold: true
            font.family: Style.fontFamily
            color: !root.enabled ? Style.textSubtle : (root.isSelected ? Style.bgSurface : Style.textMain)
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

    background: Rectangle {
        color: {
            if (!root.enabled) return Style.textDark
            if (root.isSelected) return root.activeColor
            if (root.down) return Style.bgCardSelected
            if (root.hovered) return Style.bgCard

            return Style.bgSurface
        }
        
        radius: Style.radiusSm
        border.color: root.isSelected ? root.activeColor : (root.enabled ? Style.borderActive : Style.bgCard)
        border.width: 1

        Behavior on color {
            ColorAnimation { 
                duration: 150 
            }
        }
    }
}