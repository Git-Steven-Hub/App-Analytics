from dataclasses import dataclass
from typing import Optional

@dataclass
class CryptoMetricsDTO:
    
    symbol: str
    name: str
    price_raw: float
    market_cap_raw: Optional[float]
    volume_24h_raw: Optional[float]
    change_24h_raw: Optional[float]
    last_updated: str
    
    @property
    def price_formatted(self) -> str:
        return f"${self.price_raw:,.2f}"

    @property
    def market_cap_formatted(self) -> str:
        return f"${self.market_cap_raw:,.0f}" if self.market_cap_raw else "N/A"
    
    @property
    def volume_24h_formatted(self) -> str:
        return f"${self.volume_24h_raw:,.0f}" if self.volume_24h_raw else "N/A"
    
    @property
    def change_24h_formatted(self) -> str:
        val = self.change_24h_raw or 0.0
        return f"{val:+.2f}%"

    @property
    def is_positive(self) -> bool:
        return (self.change_24h_raw or 0.0) >= 0.0
    
    def to_dict(self) -> dict:
        return {
            "symbol" : self.symbol,
            "name" : self.name,
            "price" : self.price_formatted,
            "market_cap" : self.market_cap_formatted,
            "volume_24h" : self.volume_24h_formatted,
            "change_24h" : self.change_24h_formatted,
            "is_positive" : self.is_positive,
            "last_updated" : self.last_updated
        }