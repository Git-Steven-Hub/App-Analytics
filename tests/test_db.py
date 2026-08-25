import os
from database.connection import DatabaseManager


def probar_base_de_datos():
    # Eliminar BD previa de pruebas si existe
    if os.path.exists("database/alumnos.db"):
        os.remove("database/alumnos.db")

    db = DatabaseManager()
    print("✅ Base de datos e historia de tablas creadas exitosamente.")

    # 1. Probar alta de alumno
    alumno_id = db.registrar_alumno(
        dni="40123456",
        nombre="Juan",
        apellido="Pérez",
        telefono="2644123456",
        email="juan.perez@email.com",
    )
    print(f"✅ Alumno registrado con ID: {alumno_id}")

    # 2. Probar creación de contrato y generación de cuotas
    # Ejemplo: $120.000 total en 6 cuotas de $20.000
    contrato_id = db.crear_contrato_y_cuotas(
        alumno_id=alumno_id,
        universidad="UNSJ",
        carrera="Ingeniería en Sistemas",
        total=120000.0,
        cantidad_cuotas=6,
    )
    print(f"✅ Contrato creado con ID: {contrato_id} y 6 cuotas generadas a 30 días.")

    # 3. Consultar y verificar cuotas generadas
    with db.get_connection() as conn:
        cursor = conn.cursor()
        cuotas = cursor.execute(
            "SELECT * FROM cuotas WHERE contrato_id = ?", (contrato_id,)
        ).fetchall()

        print("\n--- 📋 Cuotas Generadas ---")
        for c in cuotas:
            print(
                f"Cuota N°{c['numero_cuota']} | Monto: ${c['monto']} | Vence: {c['fecha_vencimiento']} | Estado: {c['estado']}"
            )

        # 4. Simular cobro de la Cuota N°1
        primera_cuota_id = cuotas[0]["id"]
        pago_id = db.registrar_pago(
            cuota_id=primera_cuota_id,
            monto_pagado=20000.0,
            medio_pago="TRANSFERENCIA",
            nro_boleta="BOL-0001928",
        )
        print(f"\n✅ Pago cobrado exitosamente (ID Pago: {pago_id}).")

        # Verificar cambio de estado en la cuota 1
        cuota_actualizada = cursor.execute(
            "SELECT * FROM cuotas WHERE id = ?", (primera_cuota_id,)
        ).fetchone()
        print(
            f"🔄 Nuevo estado de Cuota N°1: {cuota_actualizada['estado']}"
        )


if __name__ == "__main__":
    probar_base_de_datos()