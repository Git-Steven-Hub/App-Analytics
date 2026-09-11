import os
import json
from dotenv import load_dotenv
from supabase import create_client, Client
from .database.connection import DataBase

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
        Sincronizca únicamente la tabla con Supabase
        """
        
        conn = self.db.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT raw_id, endpoint, payload_json, ingested_at_utc
            FROM raw_crypto_responses
        ''')

        rows = cursor.fetchall()
        
        records = []
        for row in rows:
            records.append(
                {
                "endpoint" : row["endpoint"],
                "payload_json" : json.loads(row["payload_json"]),
                "ingested_at_utc" : row["ingested_at_utc"]
                }
            )
        
        if records:
            self.supabase.table("raw_crypto_responses").insert(records).execute()
            print(f"[OK] {len(records)} payloads crudos subidos a Supabase.")