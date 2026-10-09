import QtQuick
import QtQuick.Layouts
import "../theme"

RowLayout {
    id: timeFilterBar
    spacing: 6

    property string currentFilter: "1Y"
    signal filterSelected(string rangeKey)

    Repeater {
        model: ["7D", "30D", "90D", "1Y"]

        delegate: AppButton {
            required property string modelData

            text: modelData
            isSelected: timeFilterBar.currentFilter === modelData
            implicitWidth: 42
            implicitHeight: 26

            onClicked: timeFilterBar.filterSelected(modelData)
        }
    }
}