import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: toggleRoot
    spacing: 6

    property bool showSma20: true
    property bool showSma50: true

    Rectangle {
        implicitWidth: 62
        implicitHeight: 26
        radius: 4
        color: toggleRoot.showSma20 ? Style.bgCard : Style.bgSurface
        border.color: toggleRoot.showSma20 ? Style.warning : Style.borderBase
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "SMA 20"
            font.pixelSize: 11
            font.bold: true
            color: toggleRoot.showSma20 ? Style.warning : Style.textSubtle
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor

            onClicked: toggleRoot.showSma20 = !toggleRoot.showSma20
        }

        Behavior on color {
            ColorAnimation { 
                duration: 150 
            }
        }
    }

    Rectangle {
        implicitWidth: 62
        implicitHeight: 26
        radius: 4
        color: toggleRoot.showSma50 ? Style.bgCard : Style.bgSurface
        border.color: toggleRoot.showSma50 ? Style.primary : Style.borderBase
        border.width: 1

        Text {
            anchors.centerIn: parent
            text: "SMA 50"
            font.pixelSize: 11
            font.bold: true
            color: toggleRoot.showSma50 ? Style.primary : Style.textSubtle
        }

        MouseArea {
            anchors.fill: parent
            cursorShape: Qt.PointingHandCursor
            onClicked: toggleRoot.showSma50 = !toggleRoot.showSma50
        }

        Behavior on color {
            ColorAnimation { 
                duration: 150 
            }
        }
    }
}