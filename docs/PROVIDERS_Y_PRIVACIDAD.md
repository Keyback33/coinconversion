# Providers y privacidad

## Fuentes de cotizaciones

- Principal: [ExchangeRate-API Open Access](https://www.exchangerate-api.com/docs/free), con publicación diaria.
- Alternativo: [Open Exchange Rates Free](https://openexchangerates.org/signup/free), con publicación horaria y cuota del plan personal.

La aplicación usa tablas con base USD y nunca mezcla tasas de providers distintos dentro de un mismo snapshot.

## Límites y frescura

- Refresh manual: ciclos locales de una hora. Cada refresh manual aceptado inicia una espera fija de una hora; la aplicación muestra el tiempo restante y los intentos bloqueados no reinician el ciclo.
- Refresh automático: se evalúa al iniciar o volver al foreground, con un intervalo mínimo independiente de una hora.
- Fallback: como máximo un intento cada cinco minutos y 30 por día UTC en este dispositivo.
- Cotizaciones con más de 48 horas se marcan como antiguas, pero siguen disponibles offline.
- La fuente y las fechas visibles corresponden al snapshot efectivo utilizado para calcular la conversión.

## Privacidad y persistencia

Los montos, favoritos, par seleccionado y tema no se envían. Los servicios externos reciben únicamente la consulta HTTPS necesaria para descargar la tabla USD.

El snapshot, las preferencias y la política de refresh se almacenan localmente. Android backup está deshabilitado para estos datos. Desinstalar la aplicación o borrar sus datos elimina el cache y las preferencias.

Open Exchange Rates requiere una credencial personal opcional. Consultar [Configuración](CONFIGURACION.md) para conocer cómo se proporciona y por qué no debe considerarse secreta dentro de un APK distribuido.
