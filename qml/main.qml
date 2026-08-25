import QtQuick
import QtQuick.Controls

Window {
    id: root
    visible: true
    width: 800
    height: 600
    title: "Demo Offline-First"
    color: "#2b2b2b"
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

    Column {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Text {
            text: "Registro de Alumnos"
            color: "black"
            font.pixelSize: 24
            font.bold: true
        }

        Row {
            spacing: 10
            width: parent.width

            TextField {
                id:inputDni
                placeholderText: "DNI"
                width: 120
            }

            TextField {
                id: inputNombre
                placeholderText: "Nombre del alumno"
                width: parent.width - 240
            }
        
            Button {
                text: "Guardar"
                width: 100
                onClicked: {
                    if (inputNombre.text !== "" && inputDni.text !== "") {
                        backend.agregar_alumno(inputDni.text, inputNombre.text, "Perez", "correo@ejemplo.com")
                        inputNombre.text = ""
                        inputDni.text = ""
                    }
                }
            }
        }

        Button {
            text: "Sincronizar Manualmente"
            width: parent.width
            onClicked: backend.sincronizar_manual()
        }

        Text {
            text: "Estado en SQLite Local:"
            font.bold: true
        }

        ListView {
            width: parent.width
            height: 250
            clip: true
            model: backend.alumnos

            delegate: Rectangle {
                width: ListView.view.width
                height: 40
                color: "#f4f4f4"
                border.color: "#ccc"
                radius: 4

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Text {
                        text: modelData.nombre
                        font.pixelSize: 14
                        width: parent.width - 110
                    }

                    Text {
                        text: modelData.sincronizado ? "Sincronizado" : "Pendiente"
                        color: modelData.sincronizado ? "green" : "orange"
                        font.bold: true
                    }
                }
            }
        }
    }
}