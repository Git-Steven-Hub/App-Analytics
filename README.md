# Crypto Analytics Dashboard

Dashboard de escritorio para el seguimiento y análisis técnico de cripto monedas en tiempo real e histórico (BTC, ETH, SOL).

El proyecto implementa arquitectura moderna de **Analytics Engineering (ETL)** combinada con una interfaz gráfica nativa reactiva y asíncrona.

---

## Arquitectura del Sistema

**[APIs Externas] (CoinMarketCap / CoinGecko)**

|
▼

**[Python Pipeline] (Extract & Load)**

|
▼

**[Supabase PostgreSQL] (Landing: public.raw_crypto_responses)**

|
▼

**[dbt Transformations] (Staging Views ──> Fact Tables en esquema analytics)**

|
▼

**[PySide6 / QML UI] (Async Workers + Reader Services)**

1. **Ingesta (Extract & Load):** Python consume las APIs de CoinMarketCap y CoinGecko y guarda la respuesta JSON cruda en Supabase (`raw_crypto_responses`) utilizando permisos de servidor (`service_role`).

2. **Transformación (Transform):** **dbt** procesa los JSONs crudos, aplica deduplicación, construye los modelos analíticos (`fct_ohlc_chart`, `fct_crypto_quotes`, `fct_ohlc_indicators`) y calcula indicadores técnicos (`SMA 20`, `SMA 50`).

3. **Presentación (UI/UX):** Una aplicación en **PySide6 / QML** consume las tablas analíticas en hilos secundarios (`QThread`), aplicando *resampling* dinámico con Pandas e interpolación para renders de velas japonesas continuas.

---

## Tech Stack

* **Frontend / UI:** PySide6 (Qt for Python), QML (Qt Quick).
* **Data Processing & Analytics:** Python, Pandas, dbt Core (`dbt-postgres`).
* **Database & Cloud:** Supabase (PostgreSQL), Row Level Security (RLS).
* **APIs:** CoinMarketCap API, CoinGecko Public API.

---

### Consideraciones de la fuente de los Datos (Data Trade-off)

* **Proveedor:** API Pública de CoinGecko & CoinMarketCap API.
* **Granularidad:**
    * **Consultas anuales (`days=365`):** Agregación en intervalos de 96 horas (4 días) por limitaciones de la API pública.

* **Transformación:** Se aplicaron técnicas de *resampling* (Pandas) e interpolación previa (*Forward Fill*) para adaptar los intervalos a las necesidades visuales.
* **Seguridad en Capa de Datos:** Implementación estricta de **Row Level Security (RLS)** en Supabase. Las tablas y vistas finales cuentan con políticas `SELECT` públicas para la app cliente, mientras que la tabla cruda `raw_crypto_responses` está restringida a escrituras del pipeline backend.

---

## Instalación y Configuración

### 1. Clonar el repositorio e instalar dependencias
```bash
git clone [https://github.com/tu-usuario/App_analytics.git](https://github.com/tu-usuario/App_analytics.git)

cd App_analytics
python -m venv .venv
source .venv/bin/activate # En Windows: .venv\Scripts\activate
pip install -r requirements.txt

```

### 2.Variables de Entorno

Copia el archivo de ejemplo `.env.example` y renómbralo a `.env`:
```bash

cp .env.example .env

```

---

### Resumen de Seguridad

* **`.env` (Real):** Se queda **solo en tu computadora** (ignorado por `.gitignore`).
* **`.env.example` (Plantilla):** Se sube a **Github** para mostrar la estructura sin exponer contraseñas.
* **`README.md`:** Muestra la documentación de cómo configurar el `.env` partiendo de la plantilla.
