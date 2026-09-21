param(
    [Parameter(Mandatory)][string]$CurrentVersion,
    [string]$DistributionPath = (Join-Path (Split-Path $PSScriptRoot -Parent) 'dist')
)

$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Split-Path $PSScriptRoot -Parent))
$distRoot = (Resolve-Path -LiteralPath $DistributionPath).Path
if (!$distRoot.StartsWith($projectRoot + [IO.Path]::DirectorySeparatorChar, [StringComparison]::OrdinalIgnoreCase)) {
    throw 'La distribución debe estar dentro del proyecto.'
}
if ((Get-Item -LiteralPath $distRoot).Attributes -band [IO.FileAttributes]::ReparsePoint) {
    throw 'La distribución no puede ser un enlace.'
}
if ($CurrentVersion -notmatch '^\d+\.\d+\.\d+$') { throw 'Versión inválida.' }

$currentApk = Join-Path $distRoot "coinconversion-$CurrentVersion.apk"
$checksum = "$currentApk.sha256"
if (!(Test-Path -LiteralPath $currentApk -PathType Leaf) -or !(Test-Path -LiteralPath $checksum -PathType Leaf)) {
    throw 'Falta el APK nuevo o su checksum; no se eliminó ninguna versión.'
}
$actualHash = (Get-FileHash -LiteralPath $currentApk -Algorithm SHA256).Hash
$expectedHash = ((Get-Content -LiteralPath $checksum -Raw).Trim() -split '\s+')[0]
if ($actualHash -ne $expectedHash) { throw 'Checksum inválido; no se eliminó ninguna versión.' }

foreach ($report in @('signature.txt', 'apk-info.txt', 'permissions.txt')) {
    if (!(Test-Path -LiteralPath (Join-Path $distRoot "$CurrentVersion/$report") -PathType Leaf)) {
        throw 'Faltan informes de verificación; no se eliminó ninguna versión.'
    }
}

$remove = @(Get-ChildItem -LiteralPath $distRoot | Where-Object {
    $artifactVersion = $null
    if ($_.PSIsContainer -and $_.Name -match '^(\d+\.\d+\.\d+)$') {
        $artifactVersion = $Matches[1]
    } elseif (!$_.PSIsContainer -and $_.Name -match '^coinconversion-(\d+\.\d+\.\d+)\.apk(?:\.sha256)?$') {
        $artifactVersion = $Matches[1]
    }
    $artifactVersion -and $artifactVersion -ne $CurrentVersion
})

foreach ($item in $remove) {
    $target = (Resolve-Path -LiteralPath $item.FullName).Path
    if ([IO.Path]::GetDirectoryName($target) -ne $distRoot -or
        ($item.Attributes -band [IO.FileAttributes]::ReparsePoint)) {
        throw "Ruta de eliminación inválida: $target"
    }
    if ($item.PSIsContainer -and @(Get-ChildItem -LiteralPath $target -Recurse -Force | Where-Object {
        $_.Attributes -band [IO.FileAttributes]::ReparsePoint
    }).Count -gt 0) {
        throw "La carpeta contiene enlaces: $target"
    }
}

foreach ($item in $remove) {
    Remove-Item -LiteralPath $item.FullName -Recurse -Force
}
Write-Output "Versión conservada: $CurrentVersion"
