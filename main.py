import sys
import os
import subprocess
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
        run_dbt_transformations()

def run_dbt_transformations():
    print("\n[PASO 3/3] Ejecutando transformaciones y pruebas dbt...")

    dbt_project = Path(__file__).resolve().parent / "crypto_dbt"

    run_result = subprocess.run(
        ["dbt", "run"],
        cwd=str(dbt_project),
        capture_output=True,
        text=True,
    )
    
    if run_result.returncode != 0:
        print(f"[ERROR DBT RUN]:\n{run_result.stderr}")
        raise RuntimeError(f"Fallo en dbt run: {run_result.stderr}")
    
    print("[OK] dbt run completado exitosamente:")
    
    print("\nEjecutando 'dbt test'...")
    test_result = subprocess.run(
        ["dbt", "test"],
        cwd=str(dbt_project),
        capture_output=True,
        text=True
    )

    if test_result.returncode != 0:
        print(f"[ERROR DBT TEST]:\n{test_result.stdout}")
        raise RuntimeError("Fallo en dbt test")
    
    print("[OK] dbt test completado")


if __name__ == "__main__":
    run_pipeline()