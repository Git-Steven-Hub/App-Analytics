import sys
import os
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent / "src"))

from src.api_connector import CoinMarketCapClient
from src.transformer import CryptoDataTransformer
from src.supabase_syncer import SupabaseSyncer

def run_pipeline():
    """
    Ejecuta el pipeline ETL completo: 
    Extracción de API, transformación de datos y sincronización a la nube
    """
    
    print("=" * 60)
    print("INICIANDO PIPELINE ANALYTICS ENGINEERING")
    print("=" * 60)
    
    # Carga credenciales
    api_key = os.getenv("CMC_API_KEY", "2bf11b4fb6964f8bb5094eb85a119b5d")
    
    # Inicializa módulos
    client = CoinMarketCapClient(api_key=api_key)
    transformer = CryptoDataTransformer()
    syncer = SupabaseSyncer()
    
    crypto_symbols = ["BTC", "ETH", "SOL"]
    print(f"\n[PASO 1/3] Extrayendo datos de CoinMarketCap para: {", ".join(crypto_symbols)}...")
    raw_payload = client.fetch_latest_quotes(symbols=crypto_symbols, convert_currencies=["USD"])
    
    if not raw_payload:
        print("[ERROR] No se pudieron obtener datos de CoinMarketCap. Abortando pipeline")
        return
    
    print("\n[PASO 2/3] Transformado payload y poblado el Model Dimensional local...")
    transformer.process_raw_payload(payload=raw_payload, currency_code="USD")
    
    print("\n[PASO 3/3] Sincronizado modelo dimensional con la nube...")
    syncer.sync_all()
    
    print("\n" + "=" * 60)
    print("PIPELINE EJECUTADO CON ÉXITO")
    print("=" * 60)

if __name__ == "__main__":
    run_pipeline()