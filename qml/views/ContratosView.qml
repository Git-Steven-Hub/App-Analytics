import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: "Emisión de Contrato"
            font.pixelSize: 20
            font.bold: true
        }

        GridLayout {
            columns: 2
            rowSpacing: 10
            columnSpacing: 10
            Layout.fillWidth: true

            Label { text: "Seleccionar Alumno:" }
            ComboBox {
                id: cbAlumnos
                Layout.fillWidth: true
                textRole: "complete_name"
                valueRole: "id"
                model: backend.alumnos
            }

            Label { text: "Universidad:" }
            TextField { id: inUniversidad; placeholderText: "Ej: UNJ"; Layout.fillWidth: true }

            Label { text: "Carrera:" }
            TextField { id: inCarrera; placeholderText: "Ej: Medicina"; Layout.fillWidth: true }

            Label { text: "Monto Total ($):" }
            TextField { id: inTotal; placeholderText: "0.00"; inputMethodHints: Qt.ImhFormattedNumbersOnly; Layout.fillWidth: true }

            Label { text: "Cantidad de Cuotas:" }
            SpinBox { id: inCuotas; from: 1; to: 36; value: 12; Layout.fillWidth: true }

            Label { text: "Fecha Inicio (YYYY-MM-DD):" }
            TextField { id: inFechaInicio; placeholderText: "2026-03-01"; Layout.fillWidth: true }

            Item { Layout.fillWidth: true }
            Button {
                text: "Generar Contrato y Cuotas"
                highlighted: true
                Layout.fillWidth: true
                onClicked: {
                    if (cbAlumnos.currentIndex >= 0 && inTotal.text !== "") {
                        backend.crear_contrato({
                            "alumno_id": cbAlumnos.model[cbAlumnos.currentIndex].id,
                            "universidad": inUniversidad.text,
                            "carrera": inCarrera.text,
                            "total": parseFloat(inTotal.text),
                            "cantidad_cuotas": inCuotas.value,
                            "fecha_inicio": inFechaInicio.text
                        })
                        inUniversidad.text = ""; inCarrera.text = ""; inTotal.text = ""
                    }
                }
            }
        }

        Item { Layout.fillHeight: true }
    }
}