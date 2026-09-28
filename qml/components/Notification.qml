import QtQuick
import QtQuick.Controls

Rectangle {
    id: root

    property string message: ""
    property bool isError: false
    property int duration: 4000

    visible: false
    width: Math.min(parent.width * 0.8, 400)
    height: 45
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.top: parent.top
    anchors.topMargin: visible ? 20 : -height

    radius: 8
    color: isError ? "#DC2626" : "#059669"
    opacity: visible ? 0.95 : 0.0

    Behavior on anchors.topMargin {
        NumberAnimation {
            duration: 300
            easing.type: Easing.OutCubic
        }
    }

    Behavior on opacity {
        NumberAnimation {
            duration: 300
        }
    }

    Row {
        anchors.centerIn: parent
        spacing: 10

        Text {
            text: root.isError ? "⚠️" : "✓"
            color: "white"
            font.pixelSize: 16
        }

        Text {
            text: root.message
            color: "white"
            font.pixelSize: 13
            font.bold: true
        }
    }

    Timer {
        id: timer
        interval: root.duration
        onTriggered: root.visible = false
    }

    function showNotification(msg, error = false) {
        root.message = msg
        root.isError = error
        root.visible = true
        timer.restart()
    }
}