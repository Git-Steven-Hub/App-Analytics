import sys
from pathlib import Path
from PySide6.QtCore import QObject, Slot, Signal, Property
from database.connection import DataBase
import main as pipeline

class CryptoBridge(QObject):
    
    dataUpadated = Signal()
    statusChanged = Signal(str)
    
    def __init__(self):
        super().__init__()
        self.db = DataBase()
        self._status = "Listo"
    
    @Property(str, notify=statusChanged)
    def status(self):
        return self._status
    
    @Slot(result=list)
    def get_latest_prices(self):
        query = '''
            SELECT c.symbol, c.name, f.price, f.market_cap, f.volume_24h, f.price_change_pct_24h, t.timestamp_utc
            FROM fact_crypto_price f
            JOIN dim_coin c ON f.coin_id = c.coin_id
            JOIN dim_time t ON f.time_id = t.time_id
            WHERE t.timestamp_utc = (SELECT MAX(timestamp_utc) FROM dim_time)
            ORDER BY f.price DESC
        '''
        
        conn =