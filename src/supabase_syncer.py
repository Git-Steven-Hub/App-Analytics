import os
from dotenv import load_dotenv
from supabase import create_client, Client
from .database.connection import DataBase
from typing import Any

load_dotenv()

SUPABASE_URL = os.getenv("SUPABASE_URL")
SUPABASE_KEY = os.getenv("SUPABASE_KEY")

class SupabaseSyncer:
    
    def __init__(self, url: str = SUPABASE_URL, key: str = SUPABASE_KEY):
        if not url or not key:
            raise ValueError("Las credenciales de Supabase no están configuradas en el archivo .env")
        
        self.supabase: Client = create_client(url, key)
        self.db = DataBase()
    
    def sync_all(self) -> None:
        """
        Sincroniza todas las dimensiones y la tabla de hechos en orden racional
        """
        
        print("[INFO] Iniciando sincronización con Supabe...")
        
        try:
            self._sync_dim_coin()
            self._sync_dim_currency()
            self._sync_dim_time()
            self._sync_fact_crypto_price()
            
            print("[OK] Sincronización completa con Supabase finalizada con éxito")
        
        except Exception as e:
            print(f"[ERROR] Falló la sincronización con Supabase: {e}")
        
    def _fetch_local_data(self, query: str) -> list[dict[str, Any]]:
        conn = self.db.connection
        
        cursor = conn.cursor()
        cursor.execute(query)
        rows = cursor.fetchall()
        
        return [dict(row) for row in rows]
    
    def _sync_dim_coin(self) -> None:
        records = self._fetch_local_data('''
            SELECT coin_id, symbol, name
            FROM dim_coin
        ''')
        
        if records:
            self.supabase.table("dim_coin").upsert(records, on_conflict="coin_id").execute()
            print(f"  └─ dim_coin: {len(records)} registros sincronizados")
        
    def _sync_dim_currency(self) -> None:
        records = self._fetch_local_data('''
            SELECT currency_id, currency_code, symbol
            FROM dim_currency
        ''')
        
        if records:
            self.supabase.table("dim_currency").upsert(records, on_conflict="currency_code").execute()
            print(f"  └─ dim_currency: {len(records)} registros sincronizados")
    
    def _sync_dim_time(self) -> None:
        records = self._fetch_local_data('''
            SELECT time_id, timestamp_utc, date_day, hour, day_of_week, month, year
            FROM dim_time
        ''')
        
        if records:
            self.supabase.table("dim_time").upsert(records, on_conflict="timestamp_utc").execute()
            print(f"  └─ dim_time: {len(records)} registros sincronizados")
            
    def _sync_fact_crypto_price(self) -> None:
        records = self._fetch_local_data('''
            SELECT coin_id, time_id, currency_id, price, market_cap, volume_24h, price_change_pct_24h, price_change_pct_7d
            FROM fact_crypto_price
        ''')
        
        if records:
            self.supabase.table("fact_crypto_price").upsert(records, on_conflict="coin_id, time_id, currency_id").execute()
            print(f"  └─ fact_crypto_price: {len(records)} registros sincronizados")
    
if __name__ == "__main__":
    syncer = SupabaseSyncer()
    syncer.sync_all()