import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "views/"

ApplicationWindow {
    id: window
    visible: true
    width: 1000
    height: 700
    title: "Gestión de Alumnos - v" + (backend ? "0.9.9" : "Demo")
    opacity: 0.0

    Behavior on opacity {
        NumberAnimation {
            duration: 250
            easing.type: Easing.OutCubic
        }
    }

    Component.onCompleted: {
        opacity = 1.0
    }

    Connections {
        target: backend

        function onOperacionCompletada(categoría, mensaje) {
            notificacionTexto.text = "[" + categoría + "]" + mensaje
            notificacion.open
        }

        function onErrorOcurrido(mensaje) {
            notificacionTexto.text = "ERROR: " + mensaje
            notificacion.open
        }
    }

    header: ToolBar {
        RowLayout {
            anchors.fill: parent

            ToolButton {
                text: "☰"
                font.pixelSize: 20
                onClicked: drawer.open()
            }

            Label {
                text: "Gestión Administrativa"
                font.pixelSize: 16
                font.bold: true
                Layout.fillWidth: true
            }

            Button {
                text: "☁ Sincronizar"
                onClicked: backend.sincronizar_manual()
            }
        }
    }

    Drawer {
        id: drawer
        width: 240
        height: window.height

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 100
                color: "#1E88E5"

                ColumnLayout {
                    anchors.centerIn: parent
                    spacing: 5

                    Label {
                        text: "Panel de Control"
                        color: "white"
                        font.pixelSize: 18
                        font.bold: true
                    }

                    Label {
                        text: "Offline-First Mode"
                        color: "#BBDEFB"
                        font.pixelSize: 12
                    }
                }
            }

            ItemDelegate {
                text: "Alumnos"
                Layout.fillWidth: true

                onClicked: {
                    stackView.replace("views/AlumnosView.qml")
                    drawer.close()
                }
            }

            ItemDelegate {
                text: "Contratos"
                Layout.fillWidth: true
                onClicked: {
                    stackView.replace("views/ContratosView.qml")
                    drawer.close()
                }
            }

            ItemDelegate {
                text: "Pagos"
                Layout.fillWidth: true
                onClicked: {
                    stackView.replace("views/PagosView.qml")
                    drawer.close()
                }
            }

            Item {
                Layout.fillHeight: true
            }
        }
    }

    StackView {
        id: stackView
        anchors.fill: parent
        initialItem: "views/AlumnosView.qml"
    }

    Popup {
        id: notificacion
        x: (parent.width - width) / 2
        y: parent.height - height - 20
        width: 350
        height: 50
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        Label {
            id: notificacionTexto
            anchors.centerIn: parent
            font.pixelSize: 13
        }
    }
}