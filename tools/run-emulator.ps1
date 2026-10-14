# Run from PowerShell: .\tools\run-emulator.ps1
param([switch]$HotReload)

$ErrorActionPreference = 'Stop'
. "$PSScriptRoot\dev-env.ps1"
$projectRoot = Split-Path $PSScriptRoot -Parent
$serial = 'emulator-5554'
$avdName = 'campus_api34'
$apk = Join-Path $projectRoot 'build\app\outputs\flutter-apk\app-debug.apk'
if (-not $HotReload -and -not (Test-Path -LiteralPath $apk)) {
    throw 'APK missing. Run flutter build apk --debug first.'
}
if (-not (Test-Path -LiteralPath "$env:ANDROID_AVD_HOME\$avdName.avd")) {
    throw "Emulator $avdName has not been created."
}
adb start-server
$deviceList = adb devices
if ($deviceList -notmatch "$serial\s+device") {
    if ($deviceList -match "$serial\s+offline") {
        throw "$serial is offline. Close that emulator and try again."
    }
    Start-Process -FilePath "$env:ANDROID_HOME\emulator\emulator.exe" `
        -ArgumentList @('-avd', $avdName, '-port', '5554', '-gpu', 'auto', '-scale', '0.5') `
        -WindowStyle Normal | Out-Null
}
Write-Host 'Waiting for Android to boot...'
$booted = $false
for ($attempt = 0; $attempt -lt 180; $attempt++) {
    $bootState = adb -s $serial shell getprop sys.boot_completed 2>$null
    if ($bootState -eq '1') { $booted = $true; break }
    Start-Sleep -Seconds 1
}
if (-not $booted) { throw 'Android did not finish booting within three minutes.' }
adb -s $serial shell input keyevent 82
if ($HotReload) {
    Push-Location $projectRoot
    try { flutter run -d $serial } finally { Pop-Location }
} else {
    adb -s $serial install -r $apk
    if ($LASTEXITCODE -ne 0) { throw 'APK installation failed.' }
    adb -s $serial shell am start -n com.example.campus_navigator/.MainActivity
    if ($LASTEXITCODE -ne 0) { throw 'App launch failed.' }
}
