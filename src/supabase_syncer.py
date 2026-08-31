import os
from dotenv import load_dotenv
from supabase import create_client, Client
from database.connection import DataBase
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
            SELECT coin_id, currency_code, symbol
            FROM dim_coin
        ''')
        
        if records:
            self.supabase.table("dim_coin").upsert(records, on_conflict="currency_code").execute()
            