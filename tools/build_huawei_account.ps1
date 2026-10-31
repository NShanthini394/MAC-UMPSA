param(
    [Parameter(Mandatory=$true)][string]$GradlePath,
    [string]$GodotAar = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$nativeProject = Join-Path $projectRoot 'native/huawei_account'
$buildArgs = @('-p', $nativeProject, '--no-daemon', 'assembleRelease')
if ($GodotAar) {
    if (-not (Test-Path -LiteralPath $GodotAar -PathType Leaf)) { throw 'GodotAar must point to the Godot Android AAR.' }
    $buildArgs += "-PgodotAar=$GodotAar"
}
& $GradlePath @buildArgs
if ($LASTEXITCODE -ne 0) { throw 'Huawei Account Kit native build failed.' }
$source = Join-Path $nativeProject 'build/outputs/aar/KampungHuaweiAccount-release.aar'
$destination = Join-Path $projectRoot 'addons/kampung_huawei/bin'
New-Item -ItemType Directory -Path $destination -Force | Out-Null
Copy-Item -LiteralPath $source -Destination (Join-Path $destination 'KampungHuaweiAccount.aar') -Force
Write-Output "Huawei Account Kit plugin built: $destination/KampungHuaweiAccount.aar"
