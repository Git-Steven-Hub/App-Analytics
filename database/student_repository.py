import uuid
from datetime import datetime, timedelta
from typing import Optional
from database.connection import DatabaseManager
from database.entities.student_entity import Student
from database.entities.contract_entity import Contract
from database.entities.payment_entity import Payment

class StudentService:

    def __init__(self):
        self.db = DatabaseManager()

    def registrar_alumno(self, datos_alumno: Student) -> str:
        '''
        Registra un nuevo alumno recibiendo un diccionario con sus datos.
        '''
        if not datos_alumno.id:
            datos_alumno.id = str(uuid.uuid4())
        
        conn = self.db.connection
        with conn:
            cursor = conn.cursor()
            cursor.execute('''
            INSERT INTO alumnos (
                id, dni, nombre, apellido, telefono, colegio, año,
                telefono_madre, telefono_padre, localidad, calle, numero,
                manzana, barrio, piso, departamento, email, ingresante, recursante,
                estado, sincronizado
                )
            VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, 0)
            ON CONFLICT (dni)
            DO UPDATE SET
                nombre=excluded.nombre,
                apellido=excluded.apellido,
                telefono=excluded.telefono,
                colegio=excluded.colegio,
                año=excluded.año,
                telefono_madre=excluded.telefono_madre,
                telefono_padre=excluded.telefono_padre,
                localidad=excluded.localidad,
                calle=excluded.calle,
                numero=excluded.numero,
                manzana=excluded.manzana,
                barrio=excluded.barrio,
                piso=excluded.piso,
                departamento=excluded.departamento,
                email=excluded.email,
                ingresante=excluded.ingresante,
                recursante=excluded.recursante,
                estado=excluded.estado,
                sincronizado=0''',
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
                datos_alumno.recursante,
                datos_alumno.estado
                )
            )
        
        self.db.connection.commit()
        return datos_alumno.id

    def obtener_alumnos(self, estado: str = "ACTIVO") -> list[Student]:
        '''
        Obtiene la lista de alumnos según su estado.
        '''
        cursor = self.db.connection.cursor()
        cursor.execute('''
            SELECT * 
            FROM alumnos 
            WHERE estado = ? 
            ORDER BY apellido, nombre
            ''',
            (estado,)
        )
        
        return [Student.from_row(row) for row in cursor.fetchall()]
    
    def obtener_alumno_por_id(self, alumno_id: str) -> Optional[Student]:
        cursor = self.db.connection.cursor()
        cursor.execute('''
            SELECT *
            FROM alumnos
            WHERE id = ?
            ''',
            (alumno_id,)
        )
        
        row = cursor.fetchone()
        return Student.from_row(row) if row else None

    def crear_contrato_con_cuotas(self, contrato: Contract) -> int:
        '''
        Crea un contrato y genera sus cuotas a 30 días de forma automática.
        '''
        cursor = self.db.connection.cursor()
        
        if isinstance(contrato.fecha_inicio, str):
            fecha_inicio = datetime.strptime(contrato.fecha_inicio, "%Y-%m-%d").date()
        
        else:
            fecha_inicio = contrato.fecha_inicio or datetime.now().date()

        conn = self.db.connection
        
        with conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO contratos (alumno_id, universidad, carrera, total, cantidad_cuotas, fecha_inicio, estado, sincronizado)
                VALUES (?, ?, ?, ?, ?, ?, ?, 0)''',
                (contrato.alumno_id,
                contrato.universidad,
                contrato.carrera,
                contrato.total,
                contrato.cantidad_cuotas,
                fecha_inicio.strftime("%Y-%m-%d"),
                contrato.estado
                ),
            )
            
            contrato_id = cursor.lastrowid
            monto_cuota = round(contrato.total / contrato.cantidad_cuotas, 2)
            
            for i in range(1, contrato.cantidad_cuotas + 1):
                fecha_vencimiento = fecha_inicio + timedelta(days=30 * i)
                cursor.execute('''
                    INSERT INTO cuotas (contrato_id, numero_cuota, monto, fecha_vencimiento, estado, sincronizado)
                    VALUES (?, ?, ?, ?, "PENDIENTE", 0)''',
                    (contrato_id,
                    i,
                    monto_cuota,
                    fecha_vencimiento.strftime("%Y-%m-%d"),
                    ),
                )

        return contrato_id
    
    def actualizar_estados_cuotas_vencidas(self) -> int:
        hoy = datetime.now().strftime("%Y-%m-%d")
        
        conn = self.db.connection
        with conn:
            cursor = conn.cursor()
            cursor.execute('''
                UPDATE cuotas
                SET estado = "VENCIDO", sincronizado = 0
                WHERE estado = "PENDIENTE" AND fecha_vencimiento < ?
            ''',
            (hoy,)
            )
            
            return cursor.rowcount
        
    def obtener_cuotas_pendientes_por_dni(self, dni: str) -> list[dict]:
        '''
        Busca a un alumno por DNI y retorna sus cuotas pendientes.
        '''
        self.actualizar_estados_cuotas_vencidas()
        
        cursor = self.db.connection.cursor()
        
        cursor.execute('''
            SELECT c.id AS cuota_id, c.numero_cuota, c.monto, c.fecha_vencimiento, c.estado,
                   co.universidad, co.carrera, a.nombre, a.apellido, a.dni
            FROM cuotas c
            JOIN contratos co ON c.contrato_id = co.id
            JOIN alumnos a ON co.alumno_id = a.id
            WHERE a.dni = ? AND c.estado != 'PAGADO'
            ORDER BY c.fecha_vencimiento ASC
            ''',
            (dni,)
        )
        
        return [dict(row) for row in cursor.fetchall()]

    def registrar_pago_cuota(self, pago: Payment) -> int:
        '''
        Registra el cobro de una cuota y actualiza su estado a PAGADO.
        '''
        conn = self.db.connection

        with conn:
            cursor = conn.cursor()
            cursor.execute('''
                INSERT INTO pagos (cuota_id, monto_pagado, medio_pago, numero_boleta, sincronizado)
                VALUES (?, ?, ?, ?, 0)''',
                (pago.cuota_id,
                pago.monto_pagado,
                pago.medio_pago,
                pago.numero_boleta
                ),
            )

            pago_id = cursor.lastrowid

            cursor.execute('''
                UPDATE cuotas 
                SET estado = 'PAGADO' 
                WHERE id = ?''', 
                (pago.cuota_id,)
            )
            
            cursor.execute('''
                SELECT contrato_id
                FROM cuotas
                WHERE id = ?
                ''',
                (pago.cuota_id,)
            )
            
            row = cursor.fetchone()
            
            if row:
                contrato_id = row["contrato_id"]
                
                cursor.execute('''
                    SELECT COUNT (*) as pendientes
                    FROM cuotas
                    WHERE contrato_id = ? AND estado != "PAGADO
                    ''',
                    (contrato_id,)
                )
                
                res = cursor.fetchone()
                
                if res and res["pendientes"] == 0:
                    cursor.execute('''
                        UPDATE contratos
                        SET estado = "FINALIZADO", sincronizado = 0
                        WHERE id = ?
                        ''',
                        (contrato_id,)
                    )

        return pago_id
    
    def obtener_historial_pagos(self, dni: str) -> list[dict]:
        cursor = self.db.connection.cursor()
        
        cursor.execute('''
            SELECT p.id AS pago_id, p.fecha_pago, p.monto_pagado, p.medio_pago, p.numero_boleta,
                   c.numero_cuota, co.carrera, co.universidad
            FROM pagos p
            JOIN cuotas c ON p.cuota_id = c.id
            JOIN contratos co ON c.contrato_id = co.id
            JOIN alumnos a ON co.alumno_id = a.id
            WHERE a.dni = ?
            ORDER BY p.fecha_pago DESC
            ''',
            (dni,)
        )
        
        return [dict(row) for row in cursor.fetchall()]