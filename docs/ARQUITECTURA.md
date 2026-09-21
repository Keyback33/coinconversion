# Arquitectura

La aplicación usa una organización feature-first pequeña, con responsabilidades separadas para integración, selección de tasas, persistencia, estado y presentación.

## Componentes principales

- Riverpod manual para composición y estado.
- `ExchangeRateRepository` para cache, límites, selección por frescura y fallback secuencial.
- `ExchangeRateApiClient` como fuente principal sin credencial.
- `OpenExchangeRatesApiClient` como fuente alternativa horaria con App ID.
- `SharedPreferencesAsync` para snapshot, preferencias y política de refresh versionados.
- `CurrencyConverter`, parser y formatter como lógica Dart pura.

## Reglas de datos

Nunca se mezclan tasas de providers diferentes en un mismo snapshot. El provider, la fecha de extracción y la fecha de cotización mostrados pertenecen a la tabla usada para calcular el resultado.

El cache permite conservar la última tabla válida y continuar convirtiendo sin conexión. Los límites de refresh y fallback se aplican desde el repository y se persisten localmente cuando corresponde.

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
