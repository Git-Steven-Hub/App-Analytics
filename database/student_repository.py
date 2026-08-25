import uuid
from datetime import datetime, timedelta
from database.connection import DatabaseManager
from database.entities.student_entity import Student
from database.entities.contract_entity import Contract

class StudentService:

    def __init__(self):
        self.db = DatabaseManager()

    def registrar_alumno(self, datos_alumno: Student):
        """
        Registra un nuevo alumno recibiendo un diccionario con sus datos.
        """
        if not datos_alumno.id:
            datos_alumno.id = str(uuid.uuid4())
        
        cursor = self.db.connection.cursor()
        cursor.execute('''
        INSERT INTO alumnos (
            id, dni, nombre, apellido, telefono, colegio, año,
            telefono_madre, telefono_padre, localidad, calle, numero,
            manzana, barrio, piso, departamento, email, ingresante, recursante,
            sincronizado
        )
        VALUES (
            ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)''',
            (datos_alumno.id,
            datos_alumno.dni,
            datos_alumno.nombre,
            datos_alumno.apellido,
            datos_alumno.telefono,
            datos_alumno.colegio,
            datos_alumno.año,
            datos_alumno.telefono_madre,
            datos_alumno.telefono_padre,
            datos_alumno.localidad,
            datos_alumno.calle,
            datos_alumno.numero,
            datos_alumno.manzana,
            datos_alumno.barrio,
            datos_alumno.piso,
            datos_alumno.departamento,
            datos_alumno.email,
            datos_alumno.ingresante,
            datos_alumno.recursante
            )
        )
        
        self.db.connection.commit()
        return datos_alumno.id

    def obtener_alumnos(self, estado = "ACTIVO"):
        """
        Obtiene la lista de alumnos según su estado.
        """
        cursor = self.db.connection.cursor()
        cursor.execute('''
            SELECT * 
            FROM alumnos 
            WHERE estado = ? 
            ORDER BY apellido, nombre
            ''', (estado,))
        
        return [dict(row) for row in cursor.fetchall()]

    # --- CONTRATOS Y CUOTAS ---

    def crear_contrato_con_cuotas(self, contrato: Contract):
        """
        Crea un contrato y genera sus cuotas a 30 días de forma automática.
        """
        
        if fecha_inicio is None:
            fecha_inicio = datetime.now().date()
            
        elif isinstance(fecha_inicio, str):
            fecha_inicio = datetime.strptime(fecha_inicio, "%Y-%m-%d").date()

        conn = self.db.get_connection()
        with conn:
            cursor = conn.cursor()

            # 1. Insertar contrato
            cursor.execute(
                """
                INSERT INTO contratos (alumno_id, universidad, carrera, total, cantidad_cuotas, fecha_inicio)
                VALUES (?, ?, ?, ?, ?, ?)
            """,
                (
                    alumno_id,
                    universidad,
                    carrera,
                    total,
                    cantidad_cuotas,
                    fecha_inicio.strftime("%Y-%m-%d"),
                ),
            )

            contrato_id = cursor.lastrowid
            monto_cuota = round(total / cantidad_cuotas, 2)

            # 2. Generar cuotas (vencimientos cada 30 días)
            for i in range(1, cantidad_cuotas + 1):
                fecha_vencimiento = fecha_inicio + timedelta(days=30 * i)
                cursor.execute(
                    """
                    INSERT INTO cuotas (contrato_id, numero_cuota, monto, fecha_vencimiento)
                    VALUES (?, ?, ?, ?)
                """,
                    (
                        contrato_id,
                        i,
                        monto_cuota,
                        fecha_vencimiento.strftime("%Y-%m-%d"),
                    ),
                )

            return contrato_id

    # --- PAGOS / CAJA ---

    def obtener_cuotas_pendientes_por_dni(self, dni: str):
        """Busca a un alumno por DNI y retorna sus cuotas pendientes."""
        sql = """
            SELECT c.id AS cuota_id, c.numero_cuota, c.monto, c.fecha_vencimiento, c.estado,
                   co.universidad, co.carrera, a.nombre, a.apellido, a.dni
            FROM cuotas c
            JOIN contratos co ON c.contrato_id = co.id
            JOIN alumnos a ON co.alumno_id = a.id
            WHERE a.dni = ? AND c.estado != 'PAGADO'
            ORDER BY c.fecha_vencimiento ASC
        """
        conn = self.db.get_connection()
        cursor = conn.cursor()
        cursor.execute(sql, (dni,))
        return [dict(row) for row in cursor.fetchall()]

    def registrar_pago_cuota(
        self,
        cuota_id: int,
        monto_pagado: float,
        medio_pago: str,
        numero_boleta: str,
    ) -> int:
        """Registra el cobro de una cuota y actualiza su estado a PAGADO."""
        conn = self.db.get_connection()
        with conn:
            cursor = conn.cursor()

            cursor.execute(
                """
                INSERT INTO pagos (cuota_id, monto_pagado, medio_pago, numero_boleta)
                VALUES (?, ?, ?, ?)
            """,
                (cuota_id, monto_pagado, medio_pago, numero_boleta),
            )

            pago_id = cursor.lastrowid

            cursor.execute(
                "UPDATE cuotas SET estado = 'PAGADO' WHERE id = ?", (cuota_id,)
            )

            return pago_id