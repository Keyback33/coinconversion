$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$workRoot = Join-Path $projectRoot 'work'
New-Item -ItemType Directory -Force -Path $workRoot | Out-Null
$testRoot = Join-Path $workRoot "release-retention-$([guid]::NewGuid().ToString('N'))"
$distributionPath = Join-Path $testRoot 'dist'

function Assert-Condition([bool]$Condition, [string]$Message) {
    if (!$Condition) { throw $Message }
}

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $distributionPath '1.0.0') | Out-Null
    New-Item -ItemType Directory -Force -Path (Join-Path $distributionPath '0.9.0') | Out-Null
    [IO.File]::WriteAllText((Join-Path $distributionPath 'coinconversion-1.0.0.apk'), 'current')
    [IO.File]::WriteAllText((Join-Path $distributionPath 'coinconversion-0.9.0.apk'), 'old')
    [IO.File]::WriteAllText((Join-Path $distributionPath 'coinconversion-0.9.0.apk.sha256'), 'old')
    [IO.File]::WriteAllText((Join-Path $distributionPath 'keep.txt'), 'unrelated')
    foreach ($report in @('signature.txt', 'apk-info.txt', 'permissions.txt')) {
        [IO.File]::WriteAllText((Join-Path $distributionPath "1.0.0/$report"), $report)
        [IO.File]::WriteAllText((Join-Path $distributionPath "0.9.0/$report"), $report)
    }
    $hash = (Get-FileHash -LiteralPath (Join-Path $distributionPath 'coinconversion-1.0.0.apk') -Algorithm SHA256).Hash
    [IO.File]::WriteAllText(
        (Join-Path $distributionPath 'coinconversion-1.0.0.apk.sha256'),
        "$hash  coinconversion-1.0.0.apk`n"
    )

    & "$PSScriptRoot/Remove-OldReleases.ps1" -CurrentVersion '1.0.0' -DistributionPath $distributionPath
    Assert-Condition (Test-Path -LiteralPath (Join-Path $distributionPath 'coinconversion-1.0.0.apk')) 'Se eliminó el APK vigente.'
    Assert-Condition (!(Test-Path -LiteralPath (Join-Path $distributionPath 'coinconversion-0.9.0.apk'))) 'No se eliminó el APK anterior.'
    Assert-Condition (!(Test-Path -LiteralPath (Join-Path $distributionPath '0.9.0'))) 'No se eliminaron los metadatos anteriores.'
    Assert-Condition (Test-Path -LiteralPath (Join-Path $distributionPath 'keep.txt')) 'Se eliminó un archivo no reconocido.'

    New-Item -ItemType Directory -Force -Path (Join-Path $distributionPath '0.8.0') | Out-Null
    [IO.File]::WriteAllText((Join-Path $distributionPath 'coinconversion-0.8.0.apk'), 'older')
    [IO.File]::WriteAllText((Join-Path $distributionPath 'coinconversion-1.0.0.apk.sha256'), 'invalid')
    $failedSafely = $false
    try {
        & "$PSScriptRoot/Remove-OldReleases.ps1" -CurrentVersion '1.0.0' -DistributionPath $distributionPath
    } catch {
        $failedSafely = $true
    }
    Assert-Condition $failedSafely 'La limpieza aceptó un checksum inválido.'
    Assert-Condition (Test-Path -LiteralPath (Join-Path $distributionPath 'coinconversion-0.8.0.apk')) 'Se eliminó una versión antes de validar el checksum.'
    Assert-Condition (Test-Path -LiteralPath (Join-Path $distributionPath '0.8.0')) 'Se eliminaron metadatos antes de validar el checksum.'

    Write-Output 'Política de retención verificada.'
} finally {
    if (Test-Path -LiteralPath $testRoot) {
        $resolvedTestRoot = (Resolve-Path -LiteralPath $testRoot).Path
        $resolvedWorkRoot = (Resolve-Path -LiteralPath $workRoot).Path
        if ([IO.Path]::GetDirectoryName($resolvedTestRoot) -ne $resolvedWorkRoot) {
            throw "Ruta temporal inválida: $resolvedTestRoot"
        }
        Remove-Item -LiteralPath $resolvedTestRoot -Recurse -Force
    }
}
