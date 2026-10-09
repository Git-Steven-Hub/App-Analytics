import time
import os
import requests
from dotenv import load_dotenv
from supabase import create_client, Client

load_dotenv()
COIN_MAPPING = {
    "bitcoin" : ("bitcoin", "BTC"),
    "ethereum" : ("ethereum", "ETH"),
    "solana" : ("solana", "SOL")
}

def get_supabase_client() -> Client:
    supabase_url = os.getenv("SUPABASE_URL")
    supabase_key = os.getenv("SUPABASE_SERVICE_KEY") or os.getenv("SUPABASE_KEY")
    
    if not supabase_url or not supabase_key:
        raise ValueError("Credenciales de Supabase no encontradas.")
    
    return create_client(supabase_url, supabase_key)

def save_raw_response(supabase: Client, endpoint: str, payload: dict) -> None:
    data = {
        "endpoint": endpoint,
        "payload_json": payload
    }
    
    try:
        supabase.table("raw_crypto_responses").insert(data).execute()
        
    except Exception as e:
        raise RuntimeError(f"Error in save data to Supabase: {e}")

def run_historical_backfill(days="365", progress_callback=None):
    """
    Descarga el historial de precios desde CoinGecko
    """
    supabase = get_supabase_client()
    
    headers = {
        "User-Agent" : "AnalyticsApp/1.0",
        "accept" : "application/json"
    }
    
    for cg_id, (coin_id, symbol) in COIN_MAPPING.items():
        url_chart = f"https://api.coingecko.com/api/v3/coins/{cg_id}/market_chart"
        
        params_chart = {
            "vs_currency" : "usd",
            "days" : days,
            "interval" : "daily"
        }
        
        response_chart = requests.get(url_chart, params=params_chart, headers=headers)
        
        if response_chart.status_code == 429:
            if progress_callback:
                progress_callback("Limit reached. Waiting 60 seconds...")
                
            time.sleep(60)
            response_chart = requests.get(url_chart, params=params_chart, headers=headers)
            
        if response_chart.status_code == 200:
            payload = response_chart.json()

            payload["_metadata"] = {
                "coin_id": coin_id, 
                "symbol": symbol, 
                "type": "market_chart"
            }
        
            save_raw_response(supabase, endpoint="/coingecko/market_chart", payload=payload)
        
        time.sleep(3)
        
        url_ohlc = f"https://api.coingecko.com/api/v3/coins/{cg_id}/ohlc"
        params_chart_ohlc = {
            "vs_currency" : "usd",
            "days" : days
        }
        
        response_ohlc = requests.get(url_ohlc, params=params_chart_ohlc, headers=headers)
        
        if response_ohlc.status_code == 429:
            if progress_callback:
                progress_callback("Limit reached. Waiting 60 seconds...")
                
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
            
            save_raw_response(supabase, endpoint="/coingecko/ohlc", payload=payload_ohlc)

        time.sleep(5)

if __name__ == "__main__":
    run_historical_backfill(days="365")