# Providers y privacidad

## Fuentes de cotizaciones

- Tabla general principal: [ExchangeRate-API Open Access](https://www.exchangerate-api.com/docs/free), con publicación diaria.
- Tabla general alternativa: [Frankfurter v2](https://frankfurter.dev/), sin credencial y con fechas diarias que pueden diferir entre pares.
- MEP principal: [DolarAPI Bolsa](https://dolarapi.com/docs/argentina/operations/get-dolar-bolsa).
- MEP histórico alternativo: [ArgentinaDatos Bolsa](https://argentinadatos.com/docs/operations/get-cotizaciones-dolares-casa). Declara DolarAPI como origen, por lo que ambas vías pueden compartir una falla de publicación.

La aplicación usa tablas con base USD y nunca mezcla tasas de providers distintos dentro de un mismo snapshot.

## Límites y frescura

- Refresh manual: ciclos locales de una hora. Cada refresh manual aceptado inicia una espera fija de una hora; la aplicación muestra el tiempo restante y los intentos bloqueados no reinician el ciclo.
- Refresh automático: se evalúa al iniciar o volver al foreground, con un intervalo mínimo independiente de una hora.
- Fallback: como máximo un intento cada cinco minutos y 30 por día UTC en este dispositivo.
- La tabla Frankfurter se acepta completa o se conserva el cache; su fecha de frescura es la más antigua de los pares sin ARS necesarios para conversiones. En empate de día se prioriza la fuente principal con timestamp.
- MEP: cinco minutos mínimos entre intentos a cada endpoint y hasta 30 intentos históricos por día UTC. HTTP 429 respeta `Retry-After` o aplica 20 minutos. Cada request tiene límite de 10 segundos y 1 MiB.
- Cotizaciones con más de 48 horas se marcan como antiguas, pero siguen disponibles offline.
- MEP diario conserva precisión de fecha; no se le asigna hora de cotización. Se elige el dato más reciente comparable sin retroceder respecto del cache. En el mismo día, una cotización intradiaria prevalece sobre una fecha diaria.
- Cada componente muestra su fuente y fecha. Un cruce entre ARS y una tercera moneda puede combinar fechas distintas.

## Privacidad y persistencia

Los montos, favoritos, par seleccionado y tema no se envían. Los servicios externos reciben únicamente consultas HTTPS de cotizaciones a `open.er-api.com`, `api.frankfurter.dev`, `dolarapi.com` y `api.argentinadatos.com` cuando se necesita el histórico.

Los dos caches, las preferencias y las políticas de refresh se almacenan localmente. Android backup está deshabilitado para estos datos. Desinstalar la aplicación o borrar sus datos elimina caches y preferencias.

El cache previo de Open Exchange Rates conserva su atribución hasta que otra tabla más reciente lo reemplace.
