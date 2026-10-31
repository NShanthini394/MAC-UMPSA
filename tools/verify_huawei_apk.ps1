param(
    [Parameter(Mandatory=$true)][string]$Apk,
    [string]$AndroidSdk = "$env:LOCALAPPDATA/Android/Sdk"
)
$ErrorActionPreference = 'Stop'
$apkPath = (Resolve-Path -LiteralPath $Apk).Path
$aapt = Get-ChildItem -LiteralPath "$AndroidSdk/build-tools" -Directory |
    Sort-Object Name -Descending | ForEach-Object { Join-Path $_.FullName 'aapt.exe' } |
    Where-Object { Test-Path -LiteralPath $_ } | Select-Object -First 1
if (-not $aapt) { throw 'Android aapt was not found.' }
$manifest = (& $aapt dump xmltree $apkPath AndroidManifest.xml) -join "`n"
if ($LASTEXITCODE -ne 0) { throw 'APK manifest could not be read.' }
foreach ($module in @('KampungHuaweiAccount','KampungHuaweiScan','KampungHuaweiTranslate')) {
    if (-not $manifest.Contains("org.godotengine.plugin.v2.$module")) { throw "APK is missing $module." }
}
if (-not $manifest.Contains('com.huawei.hms.client.appid')) { throw 'APK is missing the Huawei App ID metadata.' }
Add-Type -AssemblyName System.IO.Compression.FileSystem
$zip = [System.IO.Compression.ZipFile]::OpenRead($apkPath)
try {
    if ($zip.GetEntry('assets/config/agconnect-services.json')) { throw 'Raw Huawei configuration must not be bundled.' }
    $public = $zip.GetEntry('assets/config/huawei-public.json')
    if (-not $public) { throw 'APK is missing public Huawei SDK configuration.' }
    $reader = [System.IO.StreamReader]::new($public.Open())
    try { $configuration = $reader.ReadToEnd() | ConvertFrom-Json } finally { $reader.Dispose() }
    if ($configuration.client.package_name -ne 'org.godotengine.nenekkebayan') { throw 'Huawei package name does not match the game.' }
    if ([string]::IsNullOrWhiteSpace($configuration.client.api_key)) { throw 'Public Huawei API key is missing.' }
    if ($configuration.client.PSObject.Properties.Name -contains 'client_secret') { throw 'Client secrets must not be bundled.' }
    if (-not $zip.GetEntry('assets/localization/sources.json')) { throw 'App language catalogue is missing.' }
    $classes = ''
    foreach ($dex in $zip.Entries | Where-Object { $_.FullName -match '^classes\d*\.dex$' }) {
        $stream = $dex.Open()
        $memory = [System.IO.MemoryStream]::new()
        try { $stream.CopyTo($memory); $classes += [System.Text.Encoding]::ASCII.GetString($memory.ToArray()) }
        finally { $stream.Dispose(); $memory.Dispose() }
    }
    foreach ($module in @('KampungHuaweiAccount','KampungHuaweiScan','KampungHuaweiTranslate')) {
        if (-not $classes.Contains("Lorg/kampung/huawei/$module;")) { throw "Native class $module is missing." }
    }
    Write-Output 'APK verified: all three Huawei modules, App ID, public configuration and app language catalogue are present; raw configuration is excluded.'
} finally { $zip.Dispose() }
