# Arquitectura

La aplicación usa una organización feature-first pequeña, con responsabilidades separadas para integración, selección de tasas, persistencia, estado y presentación.

## Componentes principales

- Riverpod manual para composición y estado.
- `RatesRefreshCoordinator` para cooldown global, deduplicación y actualización independiente de ambas ramas.
- `ExchangeRateRepository` para cache, límites por provider, selección por frescura y fallback de la tabla general.
- `MepRateRepository` para selección temporal, cache y política MEP independientes.
- `ExchangeRateApiClient` como fuente principal sin credencial.
- `FrankfurterApiClient` como fuente alternativa diaria sin credencial y con fecha por par.
- `DolarApiClient` y `ArgentinaDatosMepClient` como fuentes MEP principal e histórica.
- `SharedPreferencesAsync` para snapshot, preferencias y política de refresh versionados.
- `CurrencyConverter`, parser y formatter como lógica Dart pura.

## Reglas de datos

Nunca se mezclan tasas de providers diferentes en un mismo `RateSnapshot`. `ConversionRates` compone explícitamente el snapshot general y `MepQuote`, con procedencia y fecha propias. Todo par con ARS distinto de identidad usa MEP venta; `CurrencyConverter` no toma ARS fiat del snapshot.

`rates_snapshot_v1` permanece compatible y `mep_quote_v1` guarda sólo el MEP elegido. `refresh_policy_v1` conserva el cooldown global y la política general; `mep_refresh_policy_v1` registra límites de ambas fuentes MEP. La falta o corrupción de un cache no impide leer el otro.

Al reemplazar Open Exchange Rates, la política general reinicia sólo los límites del fallback. El cache anterior conserva su provider. Frankfurter se compara por la fecha mínima de los pares sin ARS; una tabla incompleta no se almacena.

## Organización relevante

```text
lib/
├── features/
│   ├── converter/
│   ├── currencies/
│   ├── home/
│   ├── rates/
│   └── settings/
├── shared/
├── app.dart
├── main.dart
└── providers.dart
```

Consultar [Configuración](CONFIGURACION.md) para preparar el entorno y [Desarrollo](DESARROLLO.md) para ejecutar los checks del proyecto.
