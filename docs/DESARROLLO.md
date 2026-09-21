# Desarrollo

## Preparación y checks

Ejecutar desde la raíz del proyecto:

```powershell
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
```

Los tests usan fixtures sintéticos y backends en memoria. No dependen de Internet ni de cotizaciones reales.

## Referencias

- [Arquitectura](ARQUITECTURA.md)
- [Configuración](CONFIGURACION.md)
- [Build y distribución](BUILD.md)

Los checks anteriores también forman parte de [`Build-Release.ps1`](../scripts/Build-Release.ps1) antes de generar una nueva entrega.
