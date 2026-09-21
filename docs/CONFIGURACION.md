# Configuración

## Requisitos

- Flutter 3.41.9 stable y Dart 3.11.5, o una combinación compatible.
- Android SDK 36.
- JDK compatible con el toolchain de Flutter instalado.
- Android 7.0 / API 24 o posterior en el dispositivo objetivo.

El proyecto genera únicamente Android y usa `ar.com.coinconversion` como `applicationId`.

## Configuración del fallback

Open Exchange Rates requiere un App ID personal. Debe proporcionarse mediante un JSON privado ubicado fuera del repositorio:

```json
{
  "OXR_APP_ID": "valor-personal"
}
```

Ejecutar la aplicación con esa configuración desde la raíz del proyecto:

```powershell
flutter run --dart-define-from-file=C:\ruta-privada\coinconversion.private.json
```

Para generar la distribución firmada, consultar [Build y distribución](BUILD.md).

## Seguridad de la configuración

No guardar el App ID en el repositorio, logs, fixtures ni documentación. Los archivos `*.private.json` están excluidos de Git.

`dart-define` evita versionar el valor como archivo de configuración, pero no lo vuelve secreto dentro del APK: la credencial puede extraerse del binario. Un build con App ID debe mantenerse para uso personal.

Sin esa configuración, la aplicación utiliza ExchangeRate-API y el cache, e informa que el fallback no está configurado. La release `1.0.0` publicada actualmente fue compilada sin un `OXR_APP_ID` personal.
