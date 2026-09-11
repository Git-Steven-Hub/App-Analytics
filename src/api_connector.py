import json
import requests
from typing import Optional, Any
from database.connection import DataBase

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
        
        self.db = DataBase()
        
    def fetch_latest_quotes(self, symbols: list[str], convert_currencies: list[str] = ["USD"]) -> Optional[dict[str, Any]]:
        """
        Consulta las últimas cotizacion para una lista de símbolos ['BTC', 'ETH']
        Guarda automáticamente la respuesta cruda en SQLite3
        """ 
        
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
            print(f"[ERROR] Falló la petición a CoinMarketCap: {e}")
            return None
    
    def _save_raw_response(self, endpoint: str, payload: dict[str, Any]) -> None:
        """
        Guarda la respuesta JSON original en la tabla raw_crypto_responses
        """
        
        query = '''
            INSERT INTO raw_crypto_responses (endpoint, payload_json)
            VALUES (?, ?)
        '''
        
        try:
            conn = self.db.connection
            with conn:
                conn.execute(query, (endpoint, json.dumps(payload)))
            
            print(f"[OK] Payload crudo guardado en SQLite.")
        
        except Exception as e:
            print(f"[ERROR] Error al guardar datos localmente: {e}")