import sys
from pathlib import Path
from datetime import datetime

ROOT_DIR = Path(__file__).resolve().parent.parent
if str(ROOT_DIR) not in sys.path:
    sys.path.append(str(ROOT_DIR))

from PySide6.QtCore import QObject, Slot, Signal, Property
from database.connection import DataBase
from database.entities.crypto_entity import CryptoMetricsDTO, PricePointDTO
import main as pipeline

class CryptoBridge(QObject):
    
    dataUpdated = Signal()
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
            WITH ranked_prices AS (
                SELECT c.symbol, c.name, f.price, f.market_cap, f.volume_24h, f.price_change_pct_24h, f.price_change_pct_7d, t.timestamp_utc,
                ROW_NUMBER() OVER (PARTITION BY f.coin_id ORDER BY t.timestamp_utc DESC) as rn
                FROM fact_crypto_price f
                JOIN dim_coin c ON f.coin_id = c.coin_id
                JOIN dim_time t ON f.time_id = t.time_id
            )
            SELECT symbol, name, price, market_cap, volume_24h, price_change_pct_24h, price_change_pct_7d, timestamp_utc
            FROM ranked_prices
            WHERE rn = 1
            ORDER BY price DESC
        '''
        
        conn = self.db.connection
        cursor = conn.cursor()
        cursor.execute(query)
        rows = cursor.fetchall()
        
        metrics = [
            CryptoMetricsDTO(
                symbol=row["symbol"],
                name=row["name"],
                price_raw=row["price"],
                market_cap_raw=row["market_cap"],
                volume_24h_raw=row["volume_24h"],
                change_24h_raw=row["price_change_pct_24h"],
                change_7d_raw=row["price_change_pct_7d"],
                last_updated=row["timestamp_utc"],
            ).to_dict()
            for row in rows
        ]
        
        return metrics
    
    @Slot()
    def refresh_pipeline(self):
        self._status = "Sincronizando..."
        self.statusChanged.emit(self._status)
        
        try:
            pipeline.run_pipeline()
            self._status = "Sincronización Exitosa"
            self.dataUpdated.emit()
        
        except Exception as e:
            self._status = f"Error: {str(e)}"
        
        self.statusChanged.emit(self._status)
    
    @Slot(str, result=list)
    def get_price_history(self, symbol: str):
        query = '''
            SELECT t.timestamp_utc, f.price
            FROM fact_crypto_price f
            JOIN dim_coin c ON f.coin_id = c.coin_id
            JOIN dim_time t ON f.time_id = t.time_id
            WHERE c.symbol = ?
            ORDER BY t.timestamp_utc ASC
        '''
        
        conn = self.db.connection
        cursor = conn.cursor()
        cursor.execute(query, (symbol,))
        rows = cursor.fetchall()
        
        history = []
        for row in rows:
            dt = datetime.fromisoformat(row["timestamp_utc"])
            timestamp_ms = dt.timestamp() * 1000
            
            history.append(PricePointDTO(timestamp_ms=timestamp_ms, price=row["price"]).to_dict())
        
        return history

    @Slot(str, result=list)
    def get_ohlc_history(self, symbol: str):
        query = '''
            SELECT t.timestamp_utc, o.open_price, o.high_price, o.low_price, o.close_price
            FROM fact_crypto_ohlc o
            JOIN dim_coin c ON o.coin_id = c.coin_id
            JOIN dim_time t ON o.time_id = t.time_id
            WHERE c.symbol = ?
            ORDER BY t.timestamp_utc ASC
        '''
        
        cursor = self.db.connection.cursor()
        cursor.execute(query, (symbol,))
        rows = cursor.fetchall()
        
        result = []
        
        for row in rows:
            raw_ts = row["timestamp_utc"]
            
            if isinstance(raw_ts, str):
                raw_ts = raw_ts.replace("Z", "+00:00")
                dt = datetime.fromisoformat(raw_ts)

            else:
                dt = raw_ts
            
            timestamp_ms = int(dt.timestamp() * 1000)

            result.append(
                {
                "timestamp" : timestamp_ms,
                "open" : row["open_price"],
                "high" : row["high_price"],
                "low" : row["low_price"],
                "close" : row["close_price"],
                }
            )
        
        return result
