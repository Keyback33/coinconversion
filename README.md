# CoinConversion

Aplicación personal Flutter para consultar y convertir monedas fiat en Android. Descarga una tabla USD completa, calcula conversiones localmente y conserva el último snapshot para funcionar offline después de una primera descarga exitosa.

## Funcionalidad

- Cotizaciones para ARS, USD, PEN, EUR, BRL, CLP y UYU.
- Favoritos configurables, reordenables y con referencia independiente.
- Conversor local con coma o punto decimal, inversión del par y copia exacta del resultado visible.
- Búsqueda de monedas por código o nombre sin distinguir mayúsculas ni acentos.
- Cache offline con provider, fecha de extracción y fecha de cotización originales.
- Refresh automático al iniciar o volver al foreground y botón dedicado `Refrescar`.
- Tema del sistema, claro u oscuro.
- Persistencia exclusivamente local sin backup cloud de Android.

ARS representa una referencia fiat estándar del provider. No equivale a dólar blue, MEP, CCL, Banco Nación ni a un precio ejecutable. Las conversiones son orientativas y no incluyen spread, impuestos ni comisiones.

## Arquitectura

La aplicación usa una organización feature-first pequeña:

- Riverpod manual para composición y estado.
- `ExchangeRateRepository` para cache, límites, selección por frescura y fallback secuencial.
- `ExchangeRateApiClient` como fuente principal sin credencial.
- `OpenExchangeRatesApiClient` como fuente alternativa horaria con App ID.
- `SharedPreferencesAsync` para snapshot, preferencias y política de refresh versionados.
- `CurrencyConverter`, parser y formatter como lógica Dart pura.

Nunca se mezclan tasas de providers diferentes en un mismo snapshot. El provider y las fechas mostradas pertenecen a la tabla usada para calcular el resultado.

## Requisitos

- Flutter 3.41.9 stable y Dart 3.11.5, o una combinación compatible.
- Android SDK 36.
- JDK compatible con el toolchain de Flutter instalado.
- Android 7.0 / API 24 o posterior.

El proyecto genera únicamente Android y usa `ar.com.coinconversion` como `applicationId`.

## Configuración del fallback

Open Exchange Rates requiere un App ID personal. Debe proporcionarse en un JSON privado fuera de Git:

```json
{
  "OXR_APP_ID": "valor-personal"
}
```

Ejecutar o compilar con:

```powershell
flutter run --dart-define-from-file=C:\ruta-privada\coinconversion.private.json
flutter build apk --release --dart-define-from-file=C:\ruta-privada\coinconversion.private.json
```

No guardar el App ID en el repositorio, logs, fixtures ni documentación. `dart-define` evita versionarlo, pero no lo vuelve secreto dentro del APK; el build con credencial es solo para uso personal.

Sin esa configuración la app utiliza ExchangeRate-API y el cache, e informa que el fallback no está configurado.

## Desarrollo y validación

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Los tests usan fixtures sintéticos y backends en memoria. No dependen de Internet ni de cotizaciones reales.

## Firma y APK

La configuración release lee `android/key.properties`. El keystore y ese archivo están excluidos de Git. Para conservar la posibilidad de actualizar una instalación, se deben respaldar juntos y mantener su contraseña; perderlos obliga a desinstalar la app firmada anteriormente.

Formato esperado de `android/key.properties`:

```properties
storeFile=../coinconversion-release.keystore
storePassword=<contraseña-privada>
keyAlias=coinconversion
keyPassword=<contraseña-privada>
```

Generar, validar y publicar el APK universal:

```powershell
./scripts/Build-Release.ps1 -PrivateConfigPath C:\ruta-privada\coinconversion.private.json
```

El parámetro `PrivateConfigPath` es opcional. Sin él, la aplicación utiliza ExchangeRate-API y el cache, pero no dispone del fallback autenticado de Open Exchange Rates. El script nunca copia el JSON privado a `dist` ni imprime su contenido. El App ID sí queda embebido en el APK cuando se compila con esa configuración, por lo que la distribución debe mantenerse para uso personal.

El script verifica formato, analyzer y tests antes de compilar. Después comprueba firma, package, versión, SDK y permisos, y conserva únicamente la versión recién generada y validada. La entrega actual es:

```text
dist/coinconversion-1.0.0.apk
dist/coinconversion-1.0.0.apk.sha256
dist/1.0.0/apk-info.txt
dist/1.0.0/permissions.txt
dist/1.0.0/signature.txt
```

`build/` es una salida temporal ignorada; `dist/` contiene la release firmada que se publica en Git. Para otra versión se debe incrementar `version` en `pubspec.yaml` y volver a ejecutar el script. La limpieza de la entrega anterior ocurre solamente después de validar el nuevo APK y su checksum.

La entrega `1.0.0` incluida actualmente fue compilada sin un `OXR_APP_ID` personal. El provider principal y el funcionamiento offline posterior a una descarga siguen disponibles.

Repetir la verificación sin recompilar:

```powershell
./scripts/Verify-Apk.ps1
```

Instalar en un dispositivo autorizado:

```powershell
adb install -r dist/coinconversion-1.0.0.apk
```

## Providers, límites y privacidad

- Principal: [ExchangeRate-API Open Access](https://www.exchangerate-api.com/docs/free), publicación diaria.
- Alternativo: [Open Exchange Rates Free](https://openexchangerates.org/signup/free), publicación horaria y cuota del plan personal.
- Refresh manual: debounce local de 60 segundos.
- Fallback: como máximo un intento cada cinco minutos y 30 por día UTC en este dispositivo.
- Cotizaciones con más de 48 horas se marcan como antiguas, pero siguen disponibles offline.

Los montos, favoritos, par y tema no se envían. Los servicios externos reciben la consulta HTTPS necesaria para descargar la tabla USD. Desinstalar o borrar datos elimina el cache y las preferencias.
