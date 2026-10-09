import QtQuick
import QtQuick.Layouts
import "../theme"

Flow {
    id: header
    spacing: 12
    width: parent.width - 300

    property string dateText: "---"
    property string openText: "O: ---"
    property string highText: "H: ---"
    property string lowText: "L: ---"
    property string closeText: "C: ---"
    property string sma20Text: "SMA20: ---"
    property string sma50Text: "SMA50: ---"

    property bool showSma20: true
    property bool showSma50: true

    Text {
        text: header.dateText
        color: Style.textMain
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        text: header.openText
        color: Style.textMuted
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        text: header.highText
        color: Style.teal
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        text: header.lowText
        color: Style.danger
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        text: header.closeText
        color: Style.textMain
        font.pixelSize: 11
        font.bold: true
    }

    Text {
        text: header.sma20Text
        color: Style.warning
        font.pixelSize: 11
        font.bold: true
        visible: opacity > 0
        opacity: header.showSma20 ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }
    }

    Text {
        text: header.sma50Text
        color: Style.primary
        font.pixelSize: 11
        font.bold: true
        visible: opacity > 0
        opacity: header.showSma50 ? 1.0 : 0.0

        Behavior on opacity {
            NumberAnimation {
                duration: 180
            }
        }
    }
}