# Funcionalidad

CoinConversion permite consultar y convertir monedas fiat en Android. Descarga una tabla USD general y una cotización de dólar MEP independiente. Realiza los cálculos localmente y conserva los últimos datos válidos para uso offline.

## Capacidades

- Cotizaciones para ARS, USD, PEN, EUR, BRL, CLP y UYU.
- Favoritos configurables y reordenables; la moneda de referencia se destaca y no se repite entre sus propias cotizaciones.
- Conversor local con coma o punto decimal.
- Inversión rápida del par de conversión.
- Copia exacta del resultado visible.
- Búsqueda de monedas por código o nombre sin distinguir mayúsculas ni acentos.
- Cache offline independiente para tabla general y MEP, con provider y fechas originales.
- Refresh automático al iniciar o volver al foreground.
- Botón dedicado `Refrescar`, con ciclos manuales de una hora y cuenta regresiva hasta su próxima disponibilidad.
- Tema del sistema, claro u oscuro.
- Persistencia exclusivamente local sin backup cloud de Android.
- Fuente y estado y Cotizaciones comienzan cerradas y se expanden de forma independiente. Conversor permanece visible.

## Referencias y limitaciones

Toda conversión entre monedas diferentes que incluye ARS usa dólar MEP venta como referencia en ambos sentidos. USD ↔ ARS requiere sólo MEP; los cruces entre ARS y otra moneda requieren MEP y tabla general. Los pares sin ARS usan sólo la tabla general. La identidad funciona sin datos.

Si falta MEP, los pares con ARS muestran indisponibilidad sin usar el ARS fiat de la tabla general. Si falta la tabla general, USD ↔ ARS continúa disponible. Las fechas de MEP y tabla general pueden diferir; el histórico MEP muestra únicamente la fecha publicada, sin hora inventada.

Frankfurter puede publicar fechas distintas por par. La app conserva cada fecha y muestra sólo el día publicado, sin atribuirle una hora de mercado.

Las conversiones son orientativas y no incluyen spread, impuestos ni comisiones. MEP no es un precio ejecutable. Los datos con más de 48 horas siguen disponibles con aviso de antigüedad.

Consultar [Providers y privacidad](PROVIDERS_Y_PRIVACIDAD.md) para conocer las fuentes, límites y reglas de frescura.
