import time
import requests
from datetime import datetime, timezone
from src.database.connection import DataBase
from src.transformer import CryptoDataTransformer
from src.supabase_syncer import SupabaseSyncer

COIN_MAPPING = {
    "bitcoin" : ("bitcoin", "BTC", "Bitcoin"),
    "ethereum" : ("ethereum", "ETH", "Ethereum"),
    "solana" : ("solana", "SOL", "Solana")
}

def run_historical_backfill(days="365"):
    """
    Descarga el historial de precios desde CoinGecko
    """
    print("--- INICIANDO BACKFILL HISTÓRICO ---")
    db = DataBase()
    transformer = CryptoDataTransformer()
    conn = db.get_connection()
    
    currency_id = transformer._get_or_create_currency(conn, currency_code="USD", symbol="$")
    
    headers = {
        "User-Agent" : "AnalyticsApp/1.0",
        "accept" : "application/json"
    }
    
    for cg_id, (coin_id, symbol, name) in COIN_MAPPING.items():
        print(f"\nObteniendo historial para {name} ({symbol})...")
        
        transformer._get_or_create_coin(conn, coin_id=coin_id, symbol=symbol, name=name)
        conn.commit()
        
        url_chart = f"https://api.coingecko.com/api/v3/coins/{cg_id}/market_chart"
        
        params = {
            "vs_currency" : "usd",
            "days" : days,
            "interval" : "daily"
        }
        
        response_chart = requests.get(url_chart, params=params, headers=headers)
        
        if response_chart.status_code == 429:
            print("Límite de peticiones de CoinGecko alcanzado. Esperando 60 segundos...")
            time.sleep(60)
            response_chart = requests.get(url_chart, params=params, headers=headers)
            
        if response_chart.status_code == 200:
            data = response_chart.json()
            prices = data.get("prices", [])
            market_caps = dict(data.get("market_caps", []))
            total_volumes = dict(data.get("total_volumes", []))
        
            inserted_count = 0
        
            for item in prices:
                timestamp_ms = item[0]
                price = item[1]
                
                mcap = market_caps.get(timestamp_ms)
                vol = total_volumes.get(timestamp_ms)
                
                dt_utc = datetime.fromtimestamp(timestamp_ms / 1000.0, tz=timezone.utc)
                
                time_id = transformer._get_or_create_time(conn, dt_utc)
                conn.commit()
                
                cursor = conn.cursor()
                cursor.execute('''
                    INSERT OR IGNORE INTO fact_crypto_price (coin_id, time_id, currency_id, price, market_cap, volume_24h, price_change_pct_24h, price_change_pct_7d)
                    VALUES (?, ?, ?, ?, ?, ?, ?, ?)
                    ''',
                    (coin_id,
                    time_id,
                    currency_id,
                    price,
                    mcap,
                    vol,
                    None,
                    None
                    )
                )
                
                if cursor.rowcount > 0:
                    inserted_count += 1
            
            conn.commit()
            print(f"Finalizado {symbol}: {inserted_count} nuevos registros insertados.")
        
        time.sleep(3)
        
        print(f"Obteniendo datos OHLC para {name} ({symbol})...")
        url_ohlc = f"https://api.coingecko.com/api/v3/coins/{cg_id}/ohlc"
        params_ohlc = {
            "vs_currency" : "usd",
            "days" : days
        }
        
        response_ohlc = requests.get(url_ohlc, params=params_ohlc, headers=headers)
        
        if response_ohlc.status_code == 429:
            print("Límite de peticiones alcanzado. Esperando 60 segundos...")
            time.sleep(60)
            response_ohlc = requests.get(url_ohlc, params=params_ohlc, headers=headers)
            
        if response_ohlc.status_code == 200:
            ohlc_data = response_ohlc.json()
            inserted_ohlc_count = 0
            
            for item in ohlc_data:
                timestamp_ms, open_p, high_p, low_p, close_p = item
                dt_utc = datetime.fromtimestamp(timestamp_ms / 1000.0, tz=timezone.utc)
                
                time_id = transformer._get_or_create_time(conn, dt_utc)
                
                cursor = conn.cursor()
                cursor.execute('''
                    INSERT OR IGNORE INTO fact_crypto_ohlc (coin_id, time_id, currency_id, open_price, high_price, low_price, close_price)
                    VALUES (?, ?, ?, ?, ?, ?, ?)
                    ''',
                    (coin_id,
                    time_id,
                    currency_id,
                    open_p,
                    high_p,
                    low_p,
                    close_p
                    )
                )
                
                if cursor.rowcount > 0:
                    inserted_ohlc_count += 1
            
            conn.commit()
            print(f"Finalizado OHLC {symbol} : {inserted_ohlc_count} registros insertados")
        
        else:
            print(f"Error al consultar OHLC para {symbol} : {response_ohlc.status_code}")
        
        time.sleep(5)

    
    print("\nIniciando sincronización masiva con Supabase...")
    syncer = SupabaseSyncer()
    syncer.sync_all()
    print("--- BACKFILL COMPLETADO ---")

if __name__ == "__main__":
    run_historical_backfill(days="365")