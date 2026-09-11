import time
import json
import requests
from src.database.connection import DataBase
from src.supabase_syncer import SupabaseSyncer

COIN_MAPPING = {
    "bitcoin" : ("bitcoin", "BTC"),
    "ethereum" : ("ethereum", "ETH"),
    "solana" : ("solana", "SOL")
}

def save_raw_response(conn, endpoint: str, payload: dict) -> None:
    """
    Guarda JSON en base de datos local
    """
    
    query = '''
        INSERT INTO raw_crypto_responses (endpoint, payload_json)
        VALUES (?, ?)
    '''
    
    with conn:
        conn.execute(query, (endpoint, json.dumps(payload)))

def run_historical_backfill(days="180"):
    """
    Descarga el historial de precios desde CoinGecko
    """
    print("--- INICIANDO BACKFILL HISTÓRICO ---")
    db = DataBase()
    conn = db.get_connection()
    
    headers = {
        "User-Agent" : "AnalyticsApp/1.0",
        "accept" : "application/json"
    }
    
    for cg_id, (coin_id, symbol) in COIN_MAPPING.items():
        print(f"\n[1/2] Obteniendo historial para ({symbol})...")
        
        url_chart = f"https://api.coingecko.com/api/v3/coins/{cg_id}/market_chart"
        
        params_chart = {
            "vs_currency" : "usd",
            "days" : days,
            "interval" : "daily"
        }
        
        response_chart = requests.get(url_chart, params=params_chart, headers=headers)
        
        if response_chart.status_code == 429:
            print("Límite alcanzado. Esperando 60 segundos...")
            time.sleep(60)
            response_chart = requests.get(url_chart, params=params_chart, headers=headers)
            
        if response_chart.status_code == 200:
            payload = response_chart.json()

            payload["_metadata"] = {
                "coin_id": coin_id, 
                "symbol": symbol, 
                "type": "market_chart"
            }
        
            save_raw_response(conn, endpoint="/coingecko/market_chart", payload=payload)
            print(f"[OK] Payload market_chart guardado para {symbol}")
            
        else:
            print(f"[ERROR] HTTP {response_chart.status_code} al consultar market_chart para {symbol}")
        
        time.sleep(3)
        
        print(f"[2/2] Obteniendo OHLC histórico para ({symbol})...")
        url_ohlc = f"https://api.coingecko.com/api/v3/coins/{cg_id}/ohlc"
        
        params_chart_ohlc = {
            "vs_currency" : "usd",
            "days" : days
        }
        
        response_ohlc = requests.get(url_ohlc, params=params_chart_ohlc, headers=headers)
        
        if response_ohlc.status_code == 429:
            print("Límite de peticiones alcanzado. Esperando 60 segundos...")
            time.sleep(60)
            response_ohlc = requests.get(url_ohlc, params=params_chart_ohlc, headers=headers)
            
        if response_ohlc.status_code == 200:
            ohlc_data = response_ohlc.json()
            
            payload_ohlc = {
                "ohlc_data" : ohlc_data,
                "_metadata" : {
                    "coin_id": coin_id,
                    "symbol" : symbol,
                    "type" : "ohlc"
                }
            }
            
            save_raw_response(conn,  endpoint="/coingecko/ohlc", payload=payload_ohlc)
            print(f"[OK] Payload OHLC guardado para {symbol}")
        
        else:
            print(f"[ERROR] HTTP {response_ohlc.status_code} al consultar OHLC para {symbol}")

        time.sleep(5)

    
    print("\nIniciando sincronización masiva con Supabase...")
    syncer = SupabaseSyncer()
    syncer.sync_all()
    print("--- BACKFILL COMPLETADO ---")

if __name__ == "__main__":
    run_historical_backfill(days="180")