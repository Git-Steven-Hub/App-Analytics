from datetime import datetime
from typing import Any
from .database.connection import DataBase

class CryptoDataTransformer:
    """
    Se encarga de transformar el JSON crudo de la API
    y poblar el Modelo Dimensional en SQLite3
    """
    
    def __init__(self):
        self.db = DataBase()
    
    def process_raw_payload(self, payload: dict[str, Any], currency_code: str = "USD") -> None:
        """
        Lee el payload de CoinMarketCap y distribuye los datos
        en dim_currency, dim_coin, dim_time y fact_crypto_price
        """
        
        if not payload or "data" not in payload:
            print("[WARN] Payload vacío o inválido")
            return
        
        conn = self.db.connection
        
        with conn:
            # Asegurar la Dimensión Moneda Fiat
            currency_id = self._get_or_create_currency(conn, currency_code=currency_code, symbol="$")
            
            for symbol, coin_data in payload["data"].items():
                # En CoinMarketCap el valor puede ser un dict directo
                coin_info = coin_data[0] if isinstance(coin_data, list) else coin_data
                
                # Asegurar la Dimensión Cripto
                coin_id = coin_info["slug"] # Usamos el slug como id único
                self._get_or_create_coin(
                    conn,
                    coin_id=coin_id,
                    symbol=coin_info["symbol"],
                    name=coin_info["name"]
                )

                # Extraer datos financieros
                quote = coin_info["quote"].get(currency_code, {})
                price = quote.get("price", 0.0)
                market_cap = quote.get("market_cap")
                volume_24h = quote.get("volume_24h")
                pct_change_24h = quote.get("percent_change_24h")
                pct_change_7d = quote.get("percent_change_7d")
                
                # Parsear el timestamp de la cotización
                last_updated_str = quote.get("last_updated")
                
                if last_updated_str:
                    clean_ts = last_updated_str.replace("Z", "+00:00")
                    dt_utc = datetime.fromisoformat(clean_ts)
                
                else:
                    dt_utc = datetime.utcnow()
                
                # Asegurar la Dimensión Tiempo
                time_id = self._get_or_create_time(conn, dt_utc)
                
                # Insertar en tabla de Hechos
                self._insert_fact_price(
                    conn, 
                    coin_id=coin_id, 
                    time_id=time_id, 
                    currency_id=currency_id, 
                    price=price, 
                    market_cap=market_cap,
                    volume_24h=volume_24h,
                    pct_change_24h=pct_change_24h,
                    pct_change_7d=pct_change_7d
                )
                
        print("[OK] Datos transformados y cargados exitosamente en el Model Dimensional")
    
    def _get_or_create_currency(self, conn, currency_code: str, symbol: str) -> int:
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT currency_id
            FROM dim_currency
            WHERE currency_code = ?
            ''',
            (currency_code.upper(),)
        )
        
        row = cursor.fetchone()
        
        if row:
            return row["currency_id"]
        
        cursor.execute('''
            INSERT INTO dim_currency (currency_code, symbol)
            VALUES (?, ?)
            ''',
            (currency_code.upper(), 
            symbol
            )
        )
        
        return cursor.lastrowid
    
    def _get_or_create_coin(self, conn, coin_id: str, symbol: str, name: str) -> None:
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT OR IGNORE INTO dim_coin (coin_id, symbol, name)
            VALUES (?, ?, ?)
            ''',
            (coin_id,
            symbol.upper(),
            name
            )
        )
    
    def _get_or_create_time(self, conn, dt: datetime) -> int:
        timestamp_iso = dt.strftime("%Y-%m-%d %H:%M:00")
        
        cursor = conn.cursor()
        
        cursor.execute('''
            SELECT time_id
            FROM dim_time
            WHERE timestamp_utc = ?
            ''',
            (timestamp_iso,)
        )
        
        row = cursor.fetchone()
        
        if row:
            return row["time_id"]

        cursor.execute('''
            INSERT INTO dim_time (timestamp_utc, date_day, hour, day_of_week, month, year)
            VALUES (?, ?, ?, ?, ?, ?)
            ''',
            (timestamp_iso,
            dt.strftime("%Y-%m-%d"),
            dt.hour,
            dt.weekday(),
            dt.month,
            dt.year
            )
        )
        
        return cursor.lastrowid
    
    def _insert_fact_price(self, conn, coin_id: str, time_id: int, currency_id: int, price: float, market_cap: float, volume_24h: float, pct_change_24h: float, pct_change_7d: float) -> None:
        cursor = conn.cursor()
        
        cursor.execute('''
            INSERT OR IGNORE INTO fact_crypto_price
            (coin_id, time_id, currency_id, price, market_cap, volume_24h, price_change_pct_24h, price_change_pct_7d)
            VALUES (?, ?, ?, ?, ?, ?, ?, ?)
            ''',
            (coin_id,
            time_id,
            currency_id,
            price,
            market_cap,
            volume_24h,
            pct_change_24h,
            pct_change_7d)
        )