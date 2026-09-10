import pandas as pd
from datetime import datetime, timezone
from PySide6.QtCore import QObject, Signal
from database.connection import DataBase

class OhlcWorker(QObject):
    finished = Signal(list)
    
    def __init__(self, symbol: str):
        super().__init__()
        self.symbol = symbol
        
    def run(self):
        db = DataBase()
        
        query = '''
            SELECT t.timestamp_utc, o.open_price, o.high_price, o.low_price, o.close_price
            FROM fact_crypto_ohlc o
            JOIN dim_coin c ON o.coin_id = c.coin_id
            JOIN dim_time t ON o.time_id = t.time_id
            WHERE c.symbol = ?
            ORDER BY t.timestamp_utc ASC
        '''
        
        cursor = db.connection.cursor()
        cursor.execute(query, (self.symbol,))
        rows = cursor.fetchall()
        
        raw_result = []
        for row in rows:
            raw_ts = row["timestamp_utc"]
            
            if isinstance(raw_ts, str):
                raw_ts = raw_ts.replace("Z", "+00:00")
                dt = datetime.fromisoformat(raw_ts).replace(tzinfo=timezone.utc)
            
            else:
                dt = raw_ts
            
            raw_result.append(
                {
                "timestamp" : int(dt.timestamp() * 1000),
                "open" : float(row["open_price"]),
                "high" : float(row["high_price"]),
                "low" : float(row["low_price"]),
                "close" : float(row["close_price"]),
                }
            )
        
        processed_data = self.process_ohlc_resample(raw_result)
        self.finished.emit(processed_data)
    
    def process_ohlc_resample(self, raw_ohlc_list: list, freq: str = "1D") -> list:
        if not raw_ohlc_list:
            return []

        df = pd.DataFrame(raw_ohlc_list)
        df["dt"] = pd.to_datetime(df["timestamp"], unit="ms", utc=True)
        df.set_index("dt", inplace=True)
        
        df_resampled = df.resample(freq).agg(
            {
            "open" : "first",
            "high" : "max",
            "low" : "min",
            "close" : "last"
            }
        )
        
        df_resampled["close"] = df_resampled["close"].ffill()
        df_resampled["open"] = df_resampled["open"].fillna(df_resampled["close"])
        df_resampled["high"] = df_resampled["high"].fillna(df_resampled["close"])
        df_resampled["low"] = df_resampled["low"].fillna(df_resampled["close"])
        
        result = []
        for idx, (dt_idx, row) in enumerate(df_resampled.iterrows()):
            result.append(
                {
                    "index" : idx,
                    "date_str" : dt_idx.strftime("%d/%m/%Y"),
                    "timestamp" : int(dt_idx.timestamp() * 1000),
                    "open" : float(row["open"]),
                    "high" : float(row["high"]),
                    "low" : float(row["low"]),
                    "close" : float(row["close"])
                }
            )
        
        return result