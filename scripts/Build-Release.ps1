param(
    [string]$PrivateConfigPath,
    [string]$AndroidSdk = "$env:LOCALAPPDATA/Android/sdk",
    [string]$JavaHome = 'C:/Program Files/Android/Android Studio/jbr'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
Push-Location $projectRoot
try {
    $env:JAVA_HOME = $JavaHome
    if (!(Test-Path -LiteralPath 'android/key.properties' -PathType Leaf)) {
        throw 'Falta android/key.properties para firmar el APK release.'
    }

    & dart format --output=none --set-exit-if-changed lib test
    if ($LASTEXITCODE -ne 0) { throw 'Falló la verificación de formato.' }

    & flutter analyze
    if ($LASTEXITCODE -ne 0) { throw 'Falló el análisis.' }

    & flutter test
    if ($LASTEXITCODE -ne 0) { throw 'Fallaron las pruebas.' }

    $buildArguments = @('build', 'apk', '--release')
    if ($PrivateConfigPath) {
        $resolvedPrivateConfig = (Resolve-Path -LiteralPath $PrivateConfigPath -ErrorAction Stop).Path
        if (!(Test-Path -LiteralPath $resolvedPrivateConfig -PathType Leaf)) {
            throw 'La configuración privada debe ser un archivo.'
        }
        $buildArguments += "--dart-define-from-file=$resolvedPrivateConfig"
    }

    & flutter @buildArguments
    if ($LASTEXITCODE -ne 0) { throw 'Falló la compilación.' }

    $versionMatch = [regex]::Match(
        (Get-Content -LiteralPath 'pubspec.yaml' -Raw),
        '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$'
    )
    if (!$versionMatch.Success) { throw 'Versión de distribución inválida.' }

    $version = $versionMatch.Groups[1].Value
    $sourceApk = 'build/app/outputs/flutter-apk/app-release.apk'
    $destinationApk = "dist/coinconversion-$version.apk"
    if (!(Test-Path -LiteralPath $sourceApk -PathType Leaf)) {
        throw 'No se encontró el APK release generado.'
    }

    New-Item -ItemType Directory -Force -Path 'dist' | Out-Null
    Copy-Item -LiteralPath $sourceApk -Destination $destinationApk -Force
    & "$PSScriptRoot/Verify-Apk.ps1" -AndroidSdk $AndroidSdk -JavaHome $JavaHome
    & "$PSScriptRoot/Remove-OldReleases.ps1" -CurrentVersion $version
} finally {
    Pop-Location
}
