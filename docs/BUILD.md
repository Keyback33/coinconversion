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
./scripts/Build-Release.ps1
```

El build incluye ExchangeRate-API y Frankfurter como fallback automático sin configuración privada. La opción anterior `PrivateConfigPath` ya no forma parte del script.

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
├── coinconversion-1.0.2.apk
├── coinconversion-1.0.2.apk.sha256
└── 1.0.2/
    ├── apk-info.txt
    ├── permissions.txt
    └── signature.txt
```

- [Descargar APK firmado 1.0.2](../dist/coinconversion-1.0.2.apk)
- [Consultar checksum SHA-256](../dist/coinconversion-1.0.2.apk.sha256)
- [Consultar firma pública](../dist/1.0.2/signature.txt)
- [Consultar información del APK](../dist/1.0.2/apk-info.txt)
- [Consultar permisos](../dist/1.0.2/permissions.txt)

Para otra versión se debe incrementar `version` en `pubspec.yaml`, sincronizar la versión visible en Ajustes y volver a ejecutar el script. Al preparar el commit se deben incluir tanto la nueva entrega como las eliminaciones de la versión anterior.

La entrega `1.0.2` incluye ExchangeRate-API, Frankfurter, las fuentes MEP y cache offline independiente para ambas ramas. No requiere credenciales de providers.

## Instalación

Instalar en un dispositivo autorizado:

```powershell
adb install -r dist/coinconversion-1.0.2.apk
```
