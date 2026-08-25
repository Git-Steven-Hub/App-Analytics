from dataclasses import dataclass, asdict
from typing import Optional

@dataclass
class Payment:
    cuota_id: int
    monto_pagado: float
    medio_pago: str
    numero_boleta: str
    fecha_pago: Optional[str] = None
    id: Optional[int] = None
    
    @classmethod
    def from_row(cls, row) -> "Payment":
        return cls(**dict(row))
    
    def to_dict(self) -> dict:
        return asdict(self)