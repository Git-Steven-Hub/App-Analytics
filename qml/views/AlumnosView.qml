import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: "Registro y Alta de Alumnos"
            font.pixelSize: 20
            font.bold: true
        }

        GridLayout {
            columns: 4
            rowSpacing: 10
            columnSpacing: 10
            Layout.fillWidth: true

            TextField { id: inDni; placeholderText: "DNI (*)"; Layout.fillWidth: true }
            TextField { id: inNombre; placeholderText: "Nombre (*)"; Layout.fillWidth: true }
            TextField { id: inApellido; placeholderText: "Apellido (*)"; Layout.fillWidth: true }
            TextField { id: inEmail; placeholderText: "Email"; Layout.fillWidth: true }

            TextField { id: inTelefono; placeholderText: "Teléfono"; Layout.fillWidth: true }
            TextField { id: inLocalidad; placeholderText: "Localidad"; Layout.fillWidth: true }
            TextField { id: inCalle; placeholderText: "Calle"; Layout.fillWidth: true }
            TextField { id: inNumero; placeholderText: "Número"; Layout.fillWidth: true }

            TextField { id: inColegio; placeholderText: "Colegio"; Layout.fillWidth: true }
            TextField { id: inAnio; placeholderText: "Año"; Layout.fillWidth: true }

            ComboBox {
                id: inIngresante
                model: ["SI", "NO"]
                Layout.fillWidth: true
            }

            Button {
                text: "Guardar Alumno"
                highlighted: true
                Layout.fillWidth: true
                onClicked: {
                    if (inDni.text !== "" && inNombre.text !== "" && inApellido.text !== "") {
                        backend.agregar_alumno({
                            "dni": inDni.text,
                            "nombre": inNombre.text,
                            "apellido": inApellido.text,
                            "email": inEmail.text,
                            "telefono": inTelefono.text,
                            "localidad": inLocalidad.text,
                            "calle": inCalle.text,
                            "numero": inNumero.text,
                            "colegio": inColegio.text,
                            "año": inAnio.text,
                            "ingresante": inIngresante.currentText,
                            "recursante": "NO"
                        })
                        inDni.text = ""; inNombre.text = ""; inApellido.text = ""
                    }
                }
            }
        }

        Label {
            text: "Listado de Alumnos Registrados"
            font.pixelSize: 16
            font.bold: true
            Layout.topMargin: 10
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: backend.alumnos

            delegate: Rectangle {
                width: ListView.view.width
                height: 45
                color: index % 2 === 0 ? "#f9f9f9" : "#ffffff"
                border.color: "#e0e0e0"
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Label {
                        text: modelData.apellido + ", " + modelData.nombre
                        font.bold: true
                        Layout.preferredWidth: 200
                    }

                    Label {
                        text: "DNI: " + modelData.dni
                        Layout.preferredWidth: 150
                    }

                    Label {
                        text: modelData.email ? modelData.email : "-"
                        Layout.fillWidth: true
                    }

                    Label {
                        text: modelData.sincronizado ? "● Sincronizado" : "○ Pendiente"
                        color: modelData.sincronizado ? "#2E7D32" : "#EF6C00"
                        font.bold: true
                    }
                }
            }
        }
    }
}