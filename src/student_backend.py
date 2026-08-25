import asyncio
from PySide6.QtCore import QObject, Slot, Signal, Property
from database.student_repository import StudentService
from database.sync_service import SyncService
from database.entities.student_entity import Student

class StudentBackend(QObject):
    alumnosChanged = Signal()
    
    def __init__(self):
        super().__init__()
        self.service = StudentService()
        self.sync_service = SyncService()
        self._alumnos = []
        self.cargar_alumnos()
        
    @Property(list, notify=alumnosChanged)
    def alumnos(self):
        return self._alumnos

    def cargar_alumnos(self):
        self._alumnos = self.service.obtener_alumnos("ACTIVO")
        self.alumnosChanged.emit()
    
    @Slot(str, str, str, str)
    def agregar_alumno(self, dni, nombre, apellido, email):
        nuevo_alumno = Student(
            dni=dni,
            nombre=nombre,
            apellido=apellido,
            email=email,
            ingresante="SI",
            recursante="NO",
            telefono="",
            localidad="",
            calle="",
            numero=""
        )
        
        self.service.registrar_alumno(nuevo_alumno)
        self.cargar_alumnos()
        asyncio.create_task(self.sincronizar_con_servidor())
        
    @Slot()
    def sincronizar_manual(self):
        asyncio.create_task(self.sincronizar_con_servidor())
    
    async def sincronizar_con_servidor(self):
        await self.sync_service.sync_all()
        self.cargar_alumnos()