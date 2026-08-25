from dataclasses import dataclass, asdict
from typing import Optional

@dataclass
class Student:
    dni: str
    nombre: str
    apellido: str
    ingresante: str
    recursante: str
    telefono: str
    localidad: str
    calle: str
    numero: str
    email: str
    
    barrio: str = ""
    manzana: str = ""
    estado: str = "ACTIVO"
    
    id: Optional[int] = None
    colegio: Optional[str] = None
    año: Optional[str] = None
    telefono_madre: Optional[str] = None
    telefono_padre: Optional[str] = None
    piso: Optional[str] = None
    departamento: Optional[str] = None
    fecha_registro: Optional[str] = None

    @property
    def complete_name(self) -> str:
        return f"{self.apellido}, {self.nombre}"
    
    @classmethod
    def from_row(cls, row) -> "Student":
        return cls(**dict(row))
    
    def to_dict(self) -> dict:
        return asdict(self)