from dataclasses import dataclass, asdict
from typing import Optional

@dataclass
class Contract:
    alumno_id: str
    universidad: str
    carrera: str
    total: float
    cantidad_cuotas: int
    fecha_inicio: str
    estado: str = "ACTIVO"
    
    id: Optional[int] = None
    
    @classmethod
    def from_row(cls, row) -> "Contract":
        return cls(**dict(row))
    
    def to_dict(self) -> dict:
        return asdict(self)