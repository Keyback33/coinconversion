# Configuración

## Requisitos

- Flutter 3.41.9 stable y Dart 3.11.5, o una combinación compatible.
- Android SDK 36.
- JDK compatible con el toolchain de Flutter instalado.
- Android 7.0 / API 24 o posterior en el dispositivo objetivo.

El proyecto genera únicamente Android y usa `ar.com.coinconversion` como `applicationId`.

## Fuentes de cotizaciones

ExchangeRate-API es la tabla general principal. Frankfurter funciona como alternativa automática sin credenciales. Ejecutar la aplicación desde la raíz del proyecto:

```powershell
flutter run
```

Para generar la distribución firmada, consultar [Build y distribución](BUILD.md).

MEP usa DolarAPI, ArgentinaDatos y un cache propio. La release publicada puede no incluir estos cambios del código fuente hasta generar una nueva versión.
