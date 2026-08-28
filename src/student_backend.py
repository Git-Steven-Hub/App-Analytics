import asyncio
from PySide6.QtCore import QObject, Slot, Signal, Property
from database.student_repository import StudentService
from database.sync_service import SyncService
from database.entities.student_entity import Student
from database.entities.contract_entity import Contract
from database.entities.payment_entity import Payment

class StudentBackend(QObject):
    alumnosChanged = Signal()
    cuotasPendientesChanged = Signal()
    historialPagosChanged = Signal()
    operacionCompletada = Signal(str, str)
    errorOcurrido = Signal(str)
    
    def __init__(self):
        super().__init__()
        self.service = StudentService()
        self.sync_service = SyncService()
        
        self._alumnos = []
        self._cuotas_pendientes = []
        self._historial_pagos = []
        self.cargar_alumnos()

    @Property(list, notify=alumnosChanged)
    def alumnos(self):
        return [alumno.to_dict() for alumno in self._alumnos]

    @Property(list, notify=cuotasPendientesChanged)
    def cuotasPendientes(self):
        return self._cuotas_pendientes
    
    @Property(list, notify=historialPagosChanged)
    def historialPagos(self):
        return self._historial_pagos

    def cargar_alumnos(self):
        self._alumnos = self.service.obtener_alumnos("ACTIVO")
        self.alumnosChanged.emit()
    
    @Slot(dict)
    def agregar_alumno(self, datos: dict):
        try:
            nuevo_alumno = Student(
                dni=str(datos.get("dni", "")),
                nombre=datos.get("nombre", ""),
                apellido=datos.get("apellido", ""),
                email=datos.get("email", ""),
                telefono=datos.get("telefono", ""),
                localidad=datos.get("localidad", ""),
                calle=datos.get("calle", ""),
                numero=datos.get("numero", ""),
                colegio=datos.get("colegio", ""),
                año=datos.get("año", ""),
                ingresante=datos.get("ingresante", "SI"),
                recursante=datos.get("recursante", "NO"),
            )
            
            self.service.registrar_alumno(nuevo_alumno)
            self.cargar_alumnos()
            asyncio.create_task(self.sincronizar_con_servidor())
            
            self.operacionCompletada.emit("ALUMNO", "Alumno guardado correctamente")

        except Exception as e:
            self.errorOcurrido.emit(f"Error al registrar alumno: {str(e)}")
    
    @Slot(dict)
    def crear_contrato(self, datos: dict):
        try:
            nuevo_contrato = Contract(
                alumno_id=str(datos.get("alumno_id", "")),
                universidad=datos.get("universidad", ""),
                carrera=datos.get("carrera", ""),
                total=float(datos.get("total", 0.0)),
                cantidad_cuotas=int(datos.get("cantidad_cuotas", 1)),
                fecha_inicio=datos.get("fecha_inicio", "")
            )
            
            self.service.crear_contrato_con_cuotas(nuevo_contrato)
            asyncio.create_task(self.sincronizar_con_servidor())
            
            self.operacionCompletada.emit("CONTRATO", "Contrato y cuotas generadas correctamente")
        
        except Exception as e:
            self.errorOcurrido.emit(f"Error al crear contrato: {str(e)}")
    
    @Slot(str)
    def buscar_cuotas_pendientes(self, dni: str):
        try:
            self._cuotas_pendientes = self.service.obtener_cuotas_pendientes_por_dni(dni)
            self.cuotasPendientesChanged.emit()
        
        except Exception as e:
            self.errorOcurrido.emit(f"Error al buscar cuotas: {str(e)}")
    
    @Slot(str)
    def cargar_historial_pagos(self, dni: str):
        try:
            self._historial_pagos = self.service.obtener_historial_pagos(dni)
            self.historialPagosChanged.emit()
            
        except Exception as e:
            self.errorOcurrido.emit(f"Error al obtener historial: {str(e)}")
    
    @Slot(dict)
    def pagar_cuota(self, datos: dict):
        try:
            nuevo_pago = Payment(
                cuota_id=int(datos.get("cuota_id", 0)),
                monto_pagado=float(datos.get("monto_pagado", 0.0)),
                medio_pago=datos.get("medio_pago", "EFECTIVO"),
                numero_boleta=str(datos.get("numero_boleta", ""))
            )
            
            dni_alumno = str(datos.get("dni_alumno", ""))
            
            self.service.registrar_pago_cuota(nuevo_pago)
            
            if dni_alumno:
                self.buscar_cuotas_pendientes(dni_alumno)
                self.cargar_historial_pagos(dni_alumno)
                
            asyncio.create_task(self.sincronizar_con_servidor())
            
            self.operacionCompletada.emit("PAGO", "Pago registrado con éxito")
        
        except Exception as e:
            self.errorOcurrido.emit(f"Error al procesar pago: {str(e)}")

    @Slot()
    def sincronizar_manual(self):
        asyncio.create_task(self.sincronizar_con_servidor())
    
    async def sincronizar_con_servidor(self):
        await self.sync_service.sync_all()
        self.cargar_alumnos()