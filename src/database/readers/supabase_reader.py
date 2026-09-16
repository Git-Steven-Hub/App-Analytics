import os
from typing import Any
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
    
    def get_fct_ohlc_chart(self, symbol: str) -> list[dict[str, Any]]:
        try:
            response = (
                self.client.schema("analytics")
                .table("fct_ohlc_chart")
                .select("*")
                .eq("symbol", symbol)
                .execute()
            )
            return response.data
        except Exception as e:
            print(f"[ERROR SupabaseReader] Error al consultar fct_ohlc_chart: {e}")
            return []
    
    def get_fct_crypto_quotes(self):
        response = self.client.table("fct_crypto_quotes").select("*").execute()
        return response.data