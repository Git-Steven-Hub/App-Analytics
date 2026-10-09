import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import "../theme"

Rectangle {
    id: badge

    property bool isLoading: true
    property string pendingSymbol: ""

    property bool isVisible: badge.isLoading && (!window || !window.isAppLoading)

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 10
    implicitWidth: loadingRow.implicitWidth + 24
    implicitHeight: 28
    radius: 14
    color: Style.bgCard
    border.color: Style.primary
    border.width: 1
    visible: opacity > 0
    opacity: isVisible ? 1.0 : 0.0
    scale: isVisible ? 1.0 : 0.0
    z: 25

    Behavior on scale {
        NumberAnimation {
            duration: 250
            easing.type: badge.isVisible ? Easing.OutCubic : Easing.InQuad
            easing.overshoot: 1.3
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 180
            easing.type: Easing.InOutQuad
        }
    }

    RowLayout {
        id: loadingRow
        
        anchors.centerIn: parent
        spacing: 8

        Item {
            implicitWidth: 14
            implicitHeight: 14

            Rectangle {
                anchors.fill: parent
                radius: width / 2
                color: "transparent"
                border.color: Style.primary
                border.width: 2

                Rectangle {
                    width: 6
                    height: 6
                    color: Style.bgCard
                    anchors.top: parent.top
                    anchors.right: parent.right
                }

                RotationAnimation on rotation {
                    running: badge.visible
                    from: 0
                    to: 360
                    duration: 800
                    loops: Animation.Infinite
                }
            }
        }

        Text {
            text: badge.pendingSymbol !== "" ? "Loading " + badge.pendingSymbol + "..." : "Loading..."
            color: Style.textMain
            font.pixelSize: 11
            font.bold: true
        }
    }
}