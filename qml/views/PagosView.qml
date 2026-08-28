import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

Item {
    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 20
        spacing: 15

        Label {
            text: "Caja - Cobro de Cuotas e Historial"
            font.pixelSize: 20
            font.bold: true
        }

        RowLayout {
            spacing: 10
            Layout.fillWidth: true

            TextField {
                id: inBuscarDni
                placeholderText: "Ingrese DNI del Alumno"
                Layout.fillWidth: true
            }

            Button {
                text: "Buscar Cuotas"
                highlighted: true
                onClicked: {
                    if (inBuscarDni.text !== "") {
                        backend.buscar_cuotas_pendientes(inBuscarDni.text)
                        backend.cargar_historial_pagos(inBuscarDni.text)
                    }
                }
            }
        }

        Label {
            text: "Cuotas Pendientes / Vencidas"
            font.pixelSize: 16
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.preferredHeight: 200
            clip: true
            model: backend.cuotasPendientes

            delegate: Rectangle {
                width: ListView.view.width
                height: 50
                color: modelData.estado === "VENCIDO" ? "#FFEBEE" : "#FFFFFF"
                border.color: "#E0E0E0"
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Label {
                        text: "Cuota #" + modelData.numero_cuota + " (" + modelData.carrera + ")"
                        font.bold: true
                        Layout.preferredWidth: 220
                    }

                    Label {
                        text: "Vencimiento: " + modelData.fecha_vencimiento
                        Layout.preferredWidth: 180
                    }

                    Label {
                        text: "$" + modelData.monto
                        font.bold: true
                        Layout.preferredWidth: 100
                    }

                    Label {
                        text: modelData.estado
                        color: modelData.estado === "VENCIDO" ? "red" : "orange"
                        font.bold: true
                        Layout.fillWidth: true
                    }

                    Button {
                        text: "Cobrar"
                        onClicked: {
                            dialogoPago.cuotaId = modelData.cuota_id
                            dialogoPago.monto = modelData.monto
                            dialogoPago.open()
                        }
                    }
                }
            }
        }

        Label {
            text: "Historial de Pagos"
            font.pixelSize: 16
            font.bold: true
        }

        ListView {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            model: backend.historialPagos

            delegate: Rectangle {
                width: ListView.view.width
                height: 40
                color: "#F5F5F5"
                border.color: "#E0E0E0"
                radius: 4

                RowLayout {
                    anchors.fill: parent
                    anchors.margins: 10

                    Label {
                        text: "Cuota #" + modelData.numero_cuota + " - " + modelData.fecha_pago
                        Layout.fillWidth: true
                    }

                    Label {
                        text: "$" + modelData.monto_pagado + " (" + modelData.medio_pago + ")"
                        font.bold: true
                        Layout.preferredWidth: 180
                    }

                    Label {
                        text: "Boleta: " + modelData.numero_boleta
                        Layout.preferredWidth: 150
                    }
                }
            }
        }
    }

    Dialog {
        id: dialogoPago
        property int cuotaId: 0
        property real monto: 0.0

        title: "Registrar Pago de Cuota"
        standardButtons: Dialog.Ok | Dialog.Cancel
        x: (parent.width - width) / 2
        y: (parent.height - height) / 2

        ColumnLayout {
            spacing: 10

            Label { text: "Monto a Pagar: $" + dialogoPago.monto; font.bold: true }

            ComboBox {
                id: cbMedioPago
                model: ["EFECTIVO", "TRANSFERENCIA"]
                Layout.fillWidth: true
            }

            TextField {
                id: inBoleta
                placeholderText: "Número de Boleta / Recibo"
                Layout.fillWidth: true
            }
        }

        onAccepted: {
            backend.pagar_cuota({
                "cuota_id": dialogoPago.cuotaId,
                "monto_pagado": dialogoPago.monto,
                "medio_pago": cbMedioPago.currentText,
                "numero_boleta": inBoleta.text,
                "dni_alumno": inBuscarDni.text
            })
            inBoleta.text = ""
        }
    }
}