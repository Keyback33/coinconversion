# Build y distribución

## Firma local

La configuración release lee `android/key.properties`. El keystore y ese archivo están excluidos de Git. Para conservar la posibilidad de actualizar una instalación, se deben respaldar juntos y mantener su contraseña; perderlos obliga a desinstalar la app firmada anteriormente.

Formato esperado de `android/key.properties`:

```properties
storeFile=../coinconversion-release.keystore
storePassword=<contraseña-privada>
keyAlias=coinconversion
keyPassword=<contraseña-privada>
```

El keystore, sus contraseñas y cualquier configuración privada deben permanecer fuera de `dist/` y del control de versiones.

## Generar una release

Ejecutar desde la raíz del proyecto:

```powershell
./scripts/Build-Release.ps1 -PrivateConfigPath C:\ruta-privada\coinconversion.private.json
```

`PrivateConfigPath` es opcional. Sin ese parámetro, la aplicación utiliza ExchangeRate-API y el cache, pero no dispone del fallback autenticado de Open Exchange Rates.

El script nunca copia el JSON privado a `dist` ni imprime su contenido. El App ID sí queda embebido en el APK cuando se compila con esa configuración, por lo que la distribución debe mantenerse para uso personal.

## Validación y retención

[`Build-Release.ps1`](../scripts/Build-Release.ps1) verifica formato, analyzer y tests antes de compilar. Después comprueba firma, package, versión, SDK y permisos mediante [`Verify-Apk.ps1`](../scripts/Verify-Apk.ps1).

[`Remove-OldReleases.ps1`](../scripts/Remove-OldReleases.ps1) conserva únicamente la versión recién generada y validada. La limpieza de la entrega anterior ocurre sólo después de comprobar el APK nuevo, su checksum y los informes requeridos. La política se valida de forma aislada con [`Test-ReleaseRetention.ps1`](../scripts/Test-ReleaseRetention.ps1).

Repetir la verificación sin recompilar:

```powershell
./scripts/Verify-Apk.ps1
```

## Distribución publicada

`build/` es una salida temporal ignorada. `dist/` contiene la única release firmada publicada en Git:

```text
dist/
├── coinconversion-1.0.0.apk
├── coinconversion-1.0.0.apk.sha256
└── 1.0.0/
    ├── apk-info.txt
    ├── permissions.txt
    └── signature.txt
```

- [Descargar APK firmado 1.0.0](../dist/coinconversion-1.0.0.apk)
- [Consultar checksum SHA-256](../dist/coinconversion-1.0.0.apk.sha256)
- [Consultar firma pública](../dist/1.0.0/signature.txt)
- [Consultar información del APK](../dist/1.0.0/apk-info.txt)
- [Consultar permisos](../dist/1.0.0/permissions.txt)

Para otra versión se debe incrementar `version` en `pubspec.yaml` y volver a ejecutar el script. Al preparar el commit se deben incluir tanto la nueva entrega como las eliminaciones de la versión anterior.

La entrega `1.0.0` incluida actualmente fue compilada sin un `OXR_APP_ID` personal. El provider principal y el funcionamiento offline posterior a una descarga siguen disponibles.

## Instalación

Instalar en un dispositivo autorizado:

```powershell
adb install -r dist/coinconversion-1.0.0.apk
```
