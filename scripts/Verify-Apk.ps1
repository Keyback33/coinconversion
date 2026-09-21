param(
    [string]$AndroidSdk = "$env:LOCALAPPDATA/Android/sdk",
    [string]$JavaHome = 'C:/Program Files/Android/Android Studio/jbr'
)

$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$versionMatch = [regex]::Match(
    (Get-Content -LiteralPath (Join-Path $projectRoot 'pubspec.yaml') -Raw),
    '(?m)^version:\s*(\d+\.\d+\.\d+)\+(\d+)\s*$'
)
if (!$versionMatch.Success) { throw 'Versión de distribución inválida.' }

$version = $versionMatch.Groups[1].Value
$versionCode = $versionMatch.Groups[2].Value
$apkName = "coinconversion-$version.apk"
$apkPath = Join-Path $projectRoot "dist/$apkName"
$metadataPath = Join-Path $projectRoot "dist/$version"
if (!(Test-Path -LiteralPath $apkPath -PathType Leaf)) {
    throw "No se encontró el APK: $apkPath"
}

$buildToolsRoot = Join-Path $AndroidSdk 'build-tools'
$buildTools = Get-ChildItem -LiteralPath $buildToolsRoot -Directory | Where-Object {
    $parsedVersion = $null
    [version]::TryParse($_.Name, [ref]$parsedVersion)
} | Sort-Object { [version]$_.Name } -Descending | Select-Object -First 1
if (!$buildTools) { throw 'No se encontraron Android Build Tools.' }

$apksigner = Join-Path $buildTools.FullName 'apksigner.bat'
$aapt = Join-Path $buildTools.FullName 'aapt.exe'
if (!(Test-Path -LiteralPath $apksigner -PathType Leaf) -or !(Test-Path -LiteralPath $aapt -PathType Leaf)) {
    throw 'La versión más reciente de Android Build Tools no contiene apksigner y aapt.'
}

$env:JAVA_HOME = $JavaHome
$signature = & $apksigner verify --verbose --print-certs $apkPath 2>&1
if ($LASTEXITCODE -ne 0) { throw 'La firma del APK no es válida.' }
$signatureText = ($signature -join "`n")
if ($signatureText -match 'CN=Android Debug') { throw 'Se detectó firma de depuración.' }
if ($signatureText -notmatch '(?m)^Number of signers:\s*1\s*$') {
    throw 'El APK debe tener exactamente un signer.'
}

$badging = & $aapt dump badging $apkPath
if ($LASTEXITCODE -ne 0) { throw 'No se pudo leer la información del APK.' }
$badgingText = ($badging -join "`n")
$expectedPackage = [regex]::Escape('ar.com.coinconversion')
$expectedVersion = [regex]::Escape($version)
if ($badgingText -notmatch "package: name='$expectedPackage' versionCode='$versionCode' versionName='$expectedVersion'") {
    throw 'Package o versión inesperados.'
}
if ($badgingText -notmatch "(?m)^sdkVersion:'24'\s*$" -or $badgingText -notmatch "(?m)^targetSdkVersion:'36'\s*$") {
    throw 'SDK mínimo o target SDK inesperados.'
}

$permissions = & $aapt dump permissions $apkPath
if ($LASTEXITCODE -ne 0) { throw 'No se pudieron leer los permisos del APK.' }
$permissionsText = ($permissions -join "`n")
if ($permissionsText -notmatch "android\.permission\.INTERNET") {
    throw 'El APK no declara el permiso de Internet requerido.'
}
$forbiddenPermissions = @(
    'android.permission.ACCESS_COARSE_LOCATION',
    'android.permission.ACCESS_FINE_LOCATION',
    'android.permission.CAMERA',
    'android.permission.READ_CALL_LOG',
    'android.permission.READ_CONTACTS',
    'android.permission.READ_SMS',
    'android.permission.RECORD_AUDIO',
    'android.permission.SEND_SMS',
    'android.permission.WRITE_CALL_LOG',
    'android.permission.WRITE_CONTACTS'
)
foreach ($permission in $forbiddenPermissions) {
    if ($permissionsText -match [regex]::Escape($permission)) {
        throw "El APK declara un permiso sensible inesperado: $permission"
    }
}

New-Item -ItemType Directory -Force -Path $metadataPath | Out-Null
$utf8WithoutBom = [Text.UTF8Encoding]::new($false)
[IO.File]::WriteAllText((Join-Path $metadataPath 'signature.txt'), "$signatureText`n", $utf8WithoutBom)
[IO.File]::WriteAllText((Join-Path $metadataPath 'apk-info.txt'), "$badgingText`n", $utf8WithoutBom)
[IO.File]::WriteAllText((Join-Path $metadataPath 'permissions.txt'), "$permissionsText`n", $utf8WithoutBom)

$hash = (Get-FileHash -LiteralPath $apkPath -Algorithm SHA256).Hash.ToLowerInvariant()
[IO.File]::WriteAllText(
    (Join-Path $projectRoot "dist/$apkName.sha256"),
    "$hash  $apkName`n",
    $utf8WithoutBom
)
Write-Output "APK verificado: $apkPath"
Write-Output "SHA-256: $hash"
