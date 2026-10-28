param([string]$GodotPath = '')
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($GodotPath)) {
    $GodotPath = Join-Path (Split-Path -Parent $projectRoot) 'Godot.exe'
}
if (-not (Test-Path -LiteralPath $GodotPath -PathType Leaf)) {
    throw 'Provide -GodotPath with the path to the Godot executable used for this project.'
}
$outputDirectory = Join-Path $projectRoot 'builds/WindowsLAN'
New-Item -ItemType Directory -Path $outputDirectory -Force | Out-Null
$packPath = Join-Path $outputDirectory 'KampungLegenda.pck'
$logPath = Join-Path $outputDirectory 'pack-build.log'
$arguments = @('--headless', '--path', ('"' + $projectRoot + '"'), '--export-pack', '"Windows LAN"', ('"' + $packPath + '"'), '--log-file', ('"' + $logPath + '"'))
$build = Start-Process -FilePath $GodotPath -ArgumentList $arguments -WindowStyle Hidden -PassThru -Wait
if ($build.ExitCode -ne 0 -or -not (Test-Path -LiteralPath $packPath) -or (Select-String -LiteralPath $logPath -Pattern '^ERROR:' -Quiet)) {
    Get-Content -LiteralPath $logPath -Tail 40
    throw "Game pack export failed with exit code $($build.ExitCode)."
}
# Private test bundle: use the project's engine, avoiding export-template setup.
Copy-Item -LiteralPath $GodotPath -Destination (Join-Path $outputDirectory 'KampungLegenda.exe') -Force
$launcher = "@echo off`r`nstart `"Kampung Legenda`" `"%~dp0KampungLegenda.exe`" --main-pack `"%~dp0KampungLegenda.pck`"`r`n"
[System.IO.File]::WriteAllText((Join-Path $outputDirectory 'Play.cmd'), $launcher, [System.Text.Encoding]::ASCII)
Copy-Item -LiteralPath (Join-Path $projectRoot 'docs/WINDOWS_LAN_TEST.md') -Destination (Join-Path $outputDirectory 'READ_ME_FIRST.txt') -Force
$archive = Join-Path $projectRoot 'builds/KampungLegenda-Windows-LAN.zip'
Compress-Archive -LiteralPath (Join-Path $outputDirectory 'KampungLegenda.exe'), $packPath, (Join-Path $outputDirectory 'Play.cmd'), (Join-Path $outputDirectory 'READ_ME_FIRST.txt') -DestinationPath $archive -Force
Write-Output "Windows LAN folder: $outputDirectory"
Write-Output "Share this ZIP: $archive"
