import pandas as pd
from PySide6.QtCore import QObject, Signal
from database.readers.supabase_reader import SupabaseReader

class OhlcWorker(QObject):
    finished = Signal(list)
    error = Signal(str)
    
    def __init__(self, symbol: str, days: int = 365):
        super().__init__()
        self.symbol = symbol
        self.days = days
        self.reader = None
        
    def run(self):
        try:
            if self.reader is None:
                self.reader = SupabaseReader()
            
            records = self.reader.get_fct_ohlc_indicators(self.symbol, self.days)
            
            raw_result = []
            for row in records:
                raw_result.append(
                    {
                    "timestamp" : int(row["timestamp_ms"]),
                    "open" : float(row["open"]),
                    "high" : float(row["high"]),
                    "low" : float(row["low"]),
                    "close" : float(row["close"]),
                    "sma_20": float(row["sma_20"]) if row.get("sma_20") is not None else None,
                    "sma_50": float(row["sma_50"]) if row.get("sma_50") is not None else None,
                    "pct_daily_change": float(row["pct_daily_change"]) if row.get("pct_daily_change") is not None else 0.0
                    }
                )
            
            processed_data = self.process_ohlc_resample(raw_result)
            self.finished.emit(processed_data)

        except Exception as e:
            self.error.emit(f"Error in Ohlc: {str(e)}")
    
    def process_ohlc_resample(self, raw_ohlc_list: list, freq: str = "1D") -> list:
        if not raw_ohlc_list:
            return []

        df = pd.DataFrame(raw_ohlc_list)
        df["dt"] = pd.to_datetime(df["timestamp"], unit="ms", utc=True)
        df.set_index("dt", inplace=True)
        
        df.sort_index(inplace=True)
        
        df_resampled = df.resample(freq).agg(
            {
            "open" : "first",
            "high" : "max",
            "low" : "min",
            "close" : "last",
            "sma_20" : "last",
            "sma_50" : "last",
            "pct_daily_change": "last"
            }
        )
        
        df_resampled["close"] = df_resampled["close"].ffill()
        df_resampled["open"] = df_resampled["open"].fillna(df_resampled["close"])
        df_resampled["high"] = df_resampled["high"].fillna(df_resampled["close"])
        df_resampled["low"] = df_resampled["low"].fillna(df_resampled["close"])
        
        df_resampled.dropna(subset=["close"], inplace=True)
        
        result = []
        for idx, (dt_idx, row) in enumerate(df_resampled.iterrows()):
            sma_20_val = round(float(row["sma_20"]), 2) if pd.notnull(row["sma_20"]) else None
            sma_50_val = round(float(row["sma_50"]), 2) if pd.notnull(row["sma_50"]) else None
            
            result.append(
                {
                    "index" : idx,
                    "date_str" : dt_idx.strftime("%d/%m/%Y"),
                    "timestamp" : int(dt_idx.timestamp() * 1000),
                    "open" : round(float(row["open"]), 2),
                    "high" : round(float(row["high"]), 2),
                    "low" : round(float(row["low"]), 2),
                    "close" : round(float(row["close"]), 2),
                    "sma_20": sma_20_val,
                    "sma_50": sma_50_val,
                    "pct_daily_change": round(float(row["pct_daily_change"]), 2) if pd.notnull(row["pct_daily_change"]) and not pd.isna(row["pct_daily_change"]) else 0.0
                }
            )
        
        return result