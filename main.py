import sys
import os
from pathlib import Path

sys.path.append(str(Path(__file__).resolve().parent / "src"))

from src.api_connector import CoinMarketCapClient
from src.supabase_syncer import SupabaseSyncer

def run_pipeline():
    """
    Ejecuta extract & load (EL)
    """
    
    print("=" * 60)
    print("INICIANDO PIPELINE ANALYTICS ENGINEERING")
    print("=" * 60)
    
    # Carga credenciales
    api_key = os.getenv("CMC_API_KEY", "2bf11b4fb6964f8bb5094eb85a119b5d")
    
    # Inicializa módulos
    client = CoinMarketCapClient(api_key=api_key)
    syncer = SupabaseSyncer()
    
    crypto_symbols = ["BTC", "ETH", "SOL"]
    print(f"\n[PASO 1/2] Extrayendo datos de CoinMarketCap...")
    raw_payload = client.fetch_latest_quotes(symbols=crypto_symbols)
    
    if raw_payload:
        print("\n[PASO 2/2] Cargando datos crudos a Supabase...")
        syncer.sync_all()
        print("\nPipeline completado")

if __name__ == "__main__":
    run_pipeline()