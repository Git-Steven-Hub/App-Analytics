import QtQuick
import QtQuick.Layouts
import "../theme"

Item {
    id: root
    anchors.fill: parent
    z: 20

    property bool active: false
    property string dateVal: ""
    property string priceVal: ""

    function updateCrosshair(candlePos, rawMouseY, plotArea) {
        let clampedX = Math.max(plotArea.x, Math.min(candlePos.x, plotArea.x + plotArea.width))
        let clampedY = Math.max(plotArea.y, Math.min(rawMouseY, plotArea.y + plotArea.height))

        crosshairX.x = clampedX
        crosshairX.y = plotArea.y
        crosshairX.height = plotArea.height

        crosshairY.x = plotArea.x
        crosshairY.y = clampedY
        crosshairY.width = plotArea.width

        let offsetX = clampedX + 15
        let offsetY = clampedY - 45

        if (offsetX + tooltipBox.width > plotArea.x + plotArea.width - 10) {
            offsetX = clampedX - tooltipBox.width - 15
        }

        if (offsetY < plotArea.y + 10) {
            offsetY = clampedY + 15
        }

        tooltipBox.x = offsetX
        tooltipBox.y = offsetY
    }

    Rectangle {
        id: crosshairX
        width: 1
        color: Style.borderActive
        visible: root.active && root.dateVal !== ""
        z: 15
        opacity: 0.6
    }

    Rectangle {
        id: crosshairY
        height: 1
        color: Style.borderActive
        visible: root.active && root.dateVal !== ""
        z: 15
        opacity: 0.6
    }

    Rectangle {
        id: tooltipBox
        width: tooltipLayout.implicitWidth + 16
        height: 38
        radius: Style.radiusSm
        color: Style.bgBase
        border.color: Style.primary
        border.width: 1
        visible: root.active && root.dateVal !== ""
        z: 20
        opacity: 0.95

        ColumnLayout {
            id: tooltipLayout
            anchors.centerIn: parent
            spacing: 2

            Text {
                text: root.dateVal
                color: Style.textMuted
                font.pixelSize: 10
                font.bold: true
            }

            Text {
                text: root.priceVal
                color: Style.success
                font.pixelSize: 11
                font.bold: true
            }
        }
    }
}