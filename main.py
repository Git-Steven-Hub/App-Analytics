import sys
import os
import subprocess
from pathlib import Path
from dotenv import load_dotenv

load_dotenv()

sys.path.append(str(Path(__file__).resolve().parent / "src"))

from src.api_connector import CoinMarketCapClient
from historical_backfill import run_historical_backfill

def run_pipeline(progress_callback=None):
    """
    Ejecuta el pipeline completo: Ingesta directa (EL) + Trasnformacion dbt (T)
    """
    
    # Carga credenciales
    api_key = os.getenv("CMC_API_KEY")
    
    if not api_key:
        raise ValueError("[ERROR] La variable CMC_API_KEY no está definida")
    
    # Inicializa módulos
    client = CoinMarketCapClient(api_key=api_key)
    crypto_symbols = ["BTC", "ETH", "SOL"]
    client.fetch_latest_quotes(symbols=crypto_symbols)
    
    run_historical_backfill(days="365", progress_callback=progress_callback)
    run_dbt_transformations()

def run_dbt_transformations():
    dbt_project = Path(__file__).resolve().parent / "crypto_dbt"

    run_result = subprocess.run(
        ["dbt", "run"],
        cwd=str(dbt_project),
        capture_output=True,
        text=True,
    )
    
    if run_result.returncode != 0:
        raise RuntimeError(f"Fallo en dbt run: {run_result.stderr}")
    
    test_result = subprocess.run(
        ["dbt", "test"],
        cwd=str(dbt_project),
        capture_output=True,
        text=True
    )

    if test_result.returncode != 0:
        raise RuntimeError("Fallo en dbt test")

if __name__ == "__main__":
    run_pipeline()