import asyncio
from database.connection import DatabaseManager
from supabase import create_client, Client

SUPABASE_URL = "https://crenicvzyozzvkyfakma.supabase.co"
SUPABASE_KEY = "sb_publishable_24f_iTAKZu6r0Chd3q0f8Q_zetAC0_J"

class SyncService:
    
    def __init__(self):
        self.db = DatabaseManager()
        self.supabase: Client = create_client(SUPABASE_URL, SUPABASE_KEY)
        
    async def sync_all(self):
        loop = asyncio.get_event_loop()
        await loop.run_in_executor(None, self._sync_alumnos)
        await loop.run_in_executor(None, self._sync_contratos)
        await loop.run_in_executor(None, self._sync_cuotas)
        await loop.run_in_executor(None, self._sync_pagos)
        
    def _sync_alumnos(self):
        conn = self.db.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT *
            FROM alumnos
            WHERE sincronizado = 0
        ''')
        
        pendientes = cursor.fetchall()
        
        for row in pendientes:
            data = dict(row)
            data.pop("sincronizado", None)
            
            try:
                res = self.supabase.table("alumnos").upsert(data).execute()
                
                if res.data:
                    cursor.execute('''
                        UPDATE alumnos
                        SET sincronizado = 1
                        WHERE id = ?
                        ''',
                        (data["id"],)
                    )
                    
                    conn.commit()
            
            except Exception as e:
                print(f"Error sincronizando alumno {data['id']}: {e}")
    
    def _sync_contratos(self):
        conn = self.db.get_connection()
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT *
            FROM contratos
            WHERE sincronizado = 0
        ''')
        
        pendientes = cursor.fetchall()
        
        for row in pendientes:
            data = dict(row)
            data.pop("sincronizado", None)
            
            try:
                res = self.supabase.table("contratos").upsert(data).execute()
                
                if res.data:
                    cursor.execute('''
                        UPDATE contratos
                        SET sincronizado = 1
                        WHERE id = ?
                        ''',
                        (data["id"],)
                    )
                    
                    conn.commit()
            
            except Exception as e:
                print(f"Error sincronizando contrato {data['id']}: {e}")
    
    def _sync_cuotas(self):
        conn = self.db.get_connection()
        cursor = conn.cursor()
                
        cursor.execute('''
            SELECT *
            FROM cuotas
            WHERE sincronizado = 0
        ''')
        
        pendientes = cursor.fetchall()
        
        for row in pendientes:
            data = dict(row)
            data.pop("sincronizado", None)
            
            try:
                res = self.supabase.table("cuotas").upsert(data).execute()
                
                if res.data:
                    cursor.execute('''
                        UPDATE cuotas
                        SET sincronizado = 1
                        WHERE id = ?
                        ''',
                        (data["id"],)
                    )
                    
                    conn.commit()
            
            except Exception as e:
                print(f"Error sincronizando cuota {data['id']}: {e}")
    
    def _sync_pagos(self):
        conn = self.db.get_connection()
        cursor = conn.cursor()
                
        cursor.execute('''
            SELECT *
            FROM pagos
            WHERE sincronizado = 0
        ''')
        
        pendientes = cursor.fetchall()
        
        for row in pendientes:
            data = dict(row)
            data.pop("sincronizado", None)
            
            try:
                res = self.supabase.table("pagos").upsert(data).execute()
                
                if res.data:
                    cursor.execute('''
                        UPDATE pagos
                        SET sincronizado = 1
                        WHERE id = ?
                        ''',
                        (data["id"],)
                    )
                    
                    conn.commit()
            
            except Exception as e:
                print(f"Error sincronizando pago {data['id']}: {e}")