from dataclasses import dataclass, asdict
from typing import Optional

@dataclass
class Installment:
    contrato_id: int
    numero_cuota: int
    monto: float
    fecha_vencimiento: str
    estado: str = "PENDIENTE"
    id: Optional[int] = None
    
    @classmethod
    def from_row(cls, row) -> "Installment":
        return cls(**dict(row))

    def to_dict(self) -> dict:
        return asdict(self)