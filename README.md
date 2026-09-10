
### Consideraciones de la fuente de los Datos (Data Trade-off)

**Provedor:** API Pública de CoinGecko.
**Granularidad:**
    - Consultas anuales ("days=365"): Agregación en intervalos de 96 horas por limitaciones de la API pública.
    - Consultas diarias ("days=1"): Precisión con intervalos de 30 minutos.

**Transformación:** Se aplicaron técnicas de resampling ("Pandas") e interpolación previa para adaptar los intervalos a las necesidades visuales

# En proceso