import os
from datetime import datetime, timedelta, timezone
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

class SupabaseReader:
    """
    Clase encargada de consultar tablas analíticas de Supabase
    """
    def __init__(self):
        url = os.getenv("SUPABASE_URL")
        key = os.getenv("SUPABASE_KEY")
        
        if not url or not key:
            raise ValueError("Las credenciales de Supabase no están configuradas")

        self.client: Client = create_client(url, key)
    
    def get_fct_ohlc_indicators(self, symbol: str, days: int = 365) -> list:
        try:
            start_of_day = (datetime.now(timezone.utc) - timedelta(days=days)).replace(hour=0, minute=0, second=0, microsecond=0)
            
            cutoff_date = start_of_day.isoformat()
            
            response = (
                self.client.schema("analytics")
                .table("fct_ohlc_indicators")
                .select("*")
                .eq("symbol", symbol.upper())
                .gte("price_timestamp", cutoff_date)
                .order("timestamp_ms", desc=False)
                .execute()
            )
            return response.data
        except Exception as e:
            raise RuntimeError(f"Error fetching OHLC indicators: {e}")
    
    def get_fct_crypto_quotes(self):
        response = self.client.table("fct_crypto_quotes").select("*").execute()
        return response.data