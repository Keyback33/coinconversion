# Funcionalidad

CoinConversion permite consultar y convertir monedas fiat en Android. Descarga una tabla USD completa, realiza los cálculos localmente y conserva el último snapshot para seguir operando offline después de una primera descarga exitosa.

## Capacidades

- Cotizaciones para ARS, USD, PEN, EUR, BRL, CLP y UYU.
- Favoritos configurables y reordenables; la moneda de referencia se destaca y no se repite entre sus propias cotizaciones.
- Conversor local con coma o punto decimal.
- Inversión rápida del par de conversión.
- Copia exacta del resultado visible.
- Búsqueda de monedas por código o nombre sin distinguir mayúsculas ni acentos.
- Cache offline con provider, fecha de extracción y fecha de cotización originales.
- Refresh automático al iniciar o volver al foreground.
- Botón dedicado `Refrescar`, con ciclos manuales de una hora y cuenta regresiva hasta su próxima disponibilidad.
- Tema del sistema, claro u oscuro.
- Persistencia exclusivamente local sin backup cloud de Android.

## Referencias y limitaciones

ARS representa una referencia fiat estándar del provider. No equivale a dólar blue, MEP, CCL, Banco Nación ni a un precio ejecutable.

Las conversiones son orientativas y no incluyen spread, impuestos ni comisiones. La disponibilidad y antigüedad de las cotizaciones dependen del provider efectivo y del último snapshot almacenado.

Consultar [Providers y privacidad](PROVIDERS_Y_PRIVACIDAD.md) para conocer las fuentes, límites y reglas de frescura.
