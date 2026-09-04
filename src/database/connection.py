import sqlite3
import threading
from pathlib import Path

class DataBase:
    
    _instance = None
    _lock = threading.Lock()
    _local = threading.local()
    _initialized = False
    
    def __new__(cls):
        if cls._instance is None:
            with cls._lock:
                if cls._instance is None:
                    cls._instance = super().__new__(cls)
                    
        return cls._instance
    
    def __init__(self):
        if DataBase._initialized:
            return
        
        with DataBase._lock:
            if DataBase._initialized:
                return
            
            base_dir = Path(__file__).resolve().parent
            self.db_path = base_dir / "base.db"
            
            with sqlite3.connect(str(self.db_path)) as temp_conn:
                temp_conn.execute("PRAGMA journal_mode=WAL")

            self.create_tables()
            DataBase._initialized = True
            
    def get_connection(self):
        if not hasattr(DataBase._local, "connection") or DataBase._local.connection is None:
            connection = sqlite3.connect(str(self.db_path))
            
            connection.row_factory = sqlite3.Row
            connection.execute("PRAGMA foreign_keys=ON")
            connection.execute("PRAGMA busy_timeout=5000")
            
            DataBase._local.connection = connection
        
        return DataBase._local.connection
    
    @property
    def connection(self):
        return self.get_connection()
    
    def create_tables(self):
        
        try:
            with sqlite3.connect(str(self.db_path)) as connection:
                connection.row_factory = sqlite3.Row
                connection.execute("PRAGMA foreign_keys = ON")
                cursor = connection.cursor()
            
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS raw_crypto_responses (
                        raw_id INTEGER PRIMARY KEY AUTOINCREMENT,
                        endpoint VARCHAR(100) NOT NULL,
                        payload_json TEXT NOT NULL,
                        ingested_at_utc TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS dim_coin (
                        coin_id VARCHAR(50) PRIMARY KEY,
                        symbol VARCHAR(10) NOT NULL,
                        name VARCHAR(100) NOT NULL,
                        created_at_utc TIMESTAMP DEFAULT CURRENT_TIMESTAMP
                    )
                ''')
                
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS dim_currency (
                        currency_id INTEGER PRIMARY KEY AUTOINCREMENT,
                        currency_code VARCHAR(10) UNIQUE NOT NULL,
                        symbol VARCHAR(5) NOT NULL
                    )
                ''')
                
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS dim_time (
                        time_id INTEGER PRIMARY KEY AUTOINCREMENT,
                        timestamp_utc TIMESTAMP UNIQUE NOT NULL,
                        date_day DATE NOT NULL,
                        hour INTEGER NOT NULL CHECK (hour BETWEEN 0 AND 23),
                        day_of_week INTEGER NOT NULL CHECK (day_of_week BETWEEN 0 AND 6),
                        month INTEGER NOT NULL CHECK (month BETWEEN 1 AND 12),
                        year INTEGER NOT NULL
                    )
                ''')
                
                cursor.execute('''
                    CREATE TABLE IF NOT EXISTS fact_crypto_price (
                        price_fact_id INTEGER PRIMARY KEY AUTOINCREMENT,
                        coin_id VARCHAR(50) NOT NULL,
                        time_id INTEGER NOT NULL,
                        currency_id INTEGER NOT NULL,
                        price REAL NOT NULL CHECK (price >= 0),
                        market_cap REAL,
                        volume_24h REAL,
                        price_change_pct_24h REAL,
                        created_at_utc TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
                        
                        FOREIGN KEY (coin_id) REFERENCES dim_coin (coin_id),
                        FOREIGN KEY (time_id) REFERENCES dim_time (time_id),
                        FOREIGN KEY (currency_id) REFERENCES dim_currency (currency_id),
                        
                        UNIQUE (coin_id, time_id, currency_id)
                    )
                ''')
                
                try:
                    cursor.execute('''
                        ALTER TABLE fact_crypto_price ADD COLUMN price_change_pct_7d REAL
                    ''')
                
                except sqlite3.OperationalError:
                    pass
                
                cursor.execute('''
                    CREATE INDEX IF NOT EXISTS idx_fact_coin_time 
                    ON fact_crypto_price (coin_id, time_id)
                ''')
                
                connection.commit()
        
        except Exception as e:
            print(f"Error al crear las tablas: {e}")