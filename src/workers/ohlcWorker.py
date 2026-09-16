import pandas as pd
from PySide6.QtCore import QObject, Signal
from database.readers.supabase_reader import SupabaseReader

class OhlcWorker(QObject):
    finished = Signal(list)
    
    def __init__(self, symbol: str):
        super().__init__()
        self.symbol = symbol
        self.reader = SupabaseReader()
        
    def run(self):
        records = self.reader.get_fct_ohlc_chart(self.symbol)
        
        raw_result = []
        for row in records:
            raw_result.append(
                {
                "timestamp" : int(row["timestamp_ms"]),
                "open" : float(row["open"]),
                "high" : float(row["high"]),
                "low" : float(row["low"]),
                "close" : float(row["close"]),
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