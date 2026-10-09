import requests
import os
from typing import Optional, Any
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()

class CoinMarketCapClient:
    """
    Conector para la API de CoinMarketCap
    """
    
    BASE_URL = "https://pro-api.coinmarketcap.com/v1"
    
    def __init__(self, api_key: str):
        self.api_key = api_key
        self.headers = {
            "Accepts" : "application/json",
            "X-CMC_PRO_API_KEY" : self.api_key,
        }
        
        supabase_url = os.getenv("SUPABASE_URL")
        supabase_key = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_KEY")
        
        if not supabase_url or not supabase_key:
            raise ValueError("Credenciales de Supabase no encontradas.")
        
        self.supabase_client: Client = create_client(supabase_url, supabase_key)
        
    def fetch_latest_quotes(self, symbols: list[str], convert_currencies: list[str] = ["USD"]) -> Optional[dict[str, Any]]:
        
        endpoint = "/cryptocurrency/quotes/latest"
        url = f"{self.BASE_URL}{endpoint}"
        
        params = {
            "symbol" : ",".join(symbols),
            "convert" : ",".join(convert_currencies)
        }
        
        try:
            response = requests.get(url, headers=self.headers, params=params, timeout=10)
            response.raise_for_status()
            
            data = response.json()
            self._save_raw_response(endpoint=endpoint, payload=data)
            
            return data
        
        except requests.exceptions.RequestException as e:
            raise RuntimeError(f"Error in API: {e}")
    
    def _save_raw_response(self, endpoint: str, payload: dict[str, Any]) -> None:
        data = {
            "endpoint": endpoint,
            "payload_json": payload
        }
        
        try:
            self.supabase_client.table("raw_crypto_responses").insert(data).execute()
        
        except Exception as e:
            raise RuntimeError(f"Error in save data to Supabase: {e}")