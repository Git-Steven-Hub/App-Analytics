import psycopg2
from psycopg2.extras import RealDictCursor
from database.readers.supabase_reader import SupabaseReader
from database.entities.crypto_entity import CryptoMetricsDTO

class CryptoRepository:
    
    def __init__(self, reader: SupabaseReader):
        self.reader = reader
        
    def get_ohlc_data(self, symbol: str) -> list[dict]:
        return self.reader.get_fct_ohlc_chart(symbol)
    
    def get_lastest_quotes(self) -> list[dict]:
        try:
            response = (
                self.reader.client.schema("analytics")
                .table("fct_crypto_quotes")
                .select("*")
                .order("market_cap_usd", desc=True)
                .execute()
            )
            
            raw_data = response.data
            metrics = []
            
            for row in raw_data:
                coin_name = row.get("coin_name") or row.get("name") or row.get("symbol", "")
                
                c_24h = row.get("pct_change_24h")
                c_7d = row.get("pct_change_7d")
                
                dto = CryptoMetricsDTO(
                    symbol=row.get("symbol", ""),
                    name=coin_name,
                    price_raw=float(row.get("price_usd") or 0.0),
                    market_cap_raw=float(row.get("market_cap_usd")) if row.get("market_cap_usd") is not None else None,
                    volume_24h_raw=float(row.get("volume_24h_usd")) if row.get("volume_24h_usd") is not None else None,
                    change_24h_raw=float(c_24h) if c_24h is not None else 0.0,
                    change_7d_raw=float(c_7d) if c_7d is not None else 0.0,
                    last_updated=str(row.get("updated_at") or row.get("ingested_at_utc") or "")
                )
                    
                metrics.append(dto.to_dict())
            
            return metrics

        except Exception as e:
            print(f"[ERROR CryptoRepository] Error al obtener quotes: {e}")
            return []