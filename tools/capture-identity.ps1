# Capture the debug design study, not the production APK.
param([string]$Device = 'emulator-5554')
$ErrorActionPreference = 'Stop'
. (Join-Path $PSScriptRoot 'dev-env.ps1')
$identityRoot = Split-Path $PSScriptRoot -Parent
adb -s $Device shell wm user-rotation lock 0
if ($LASTEXITCODE -ne 0) { throw 'Cannot lock emulator rotation.' }
$identitySizes = @(
    @{ name = 'phone'; width = 1179; height = 2556; dpi = 480; scenes = @('hub', 'results', 'map', 'floor') },
    @{ name = 'tablet-portrait'; width = 1200; height = 1920; dpi = 240; scenes = @('hub', 'map', 'floor') },
    @{ name = 'tablet-landscape'; width = 1920; height = 1200; dpi = 240; scenes = @('hub', 'map', 'floor') }
)
$identityManifest = @()
foreach ($identitySize in $identitySizes) {
    adb -s $Device shell wm size "$($identitySize.width)x$($identitySize.height)"
    if ($LASTEXITCODE -ne 0) { throw 'Cannot set emulator size.' }
    adb -s $Device shell wm density $identitySize.dpi
    if ($LASTEXITCODE -ne 0) { throw 'Cannot set emulator density.' }
    $identityDensityOutput = adb -s $Device shell wm density | Out-String
    $identityActualDensity = [int]([regex]::Matches($identityDensityOutput, 'density:\s*(\d+)') | Select-Object -Last 1).Groups[1].Value
    if ($identityActualDensity -ne $identitySize.dpi) { throw 'Emulator density does not match requested profile.' }
    Start-Sleep -Milliseconds 800
    foreach ($identityDark in @($false, $true)) {
        foreach ($identityVariant in @('a', 'b')) {
            foreach ($identityScene in $identitySize.scenes) {
                & (Join-Path $PSScriptRoot 'preview-identity.ps1') -Device $Device -Variant $identityVariant -Scene $identityScene -Dark:$identityDark | Out-Null
                $identityDeadline = [DateTime]::UtcNow.AddSeconds(30)
                $identityReady = $false
                $identityStatus = $null
                do {
                    Start-Sleep -Milliseconds 300
                    $identityStatusText = adb -s $Device shell run-as com.example.campus_navigator cat files/campus-identity-ready.json 2>$null | Out-String
                    if ($LASTEXITCODE -eq 0) {
                        try {
                            $identityStatus = $identityStatusText | ConvertFrom-Json
                            $identityExpectedWidth = $identitySize.width / ($identitySize.dpi / 160)
                            $identityReady = $identityStatus.ready -eq $true -and
                                $identityStatus.variant -eq $identityVariant -and
                                $identityStatus.scene -eq $identityScene -and
                                $identityStatus.dark -eq $identityDark -and
                                [Math]::Abs($identityStatus.widthDp - $identityExpectedWidth) -lt .1
                        } catch { $identityReady = $false }
                    }
                } while (-not $identityReady -and [DateTime]::UtcNow -lt $identityDeadline)
                if (-not $identityReady) { throw "Preview not ready: $identityVariant/$identityScene/$($identitySize.name)/dark=$identityDark. No capture accepted." }
                $identityMode = if ($identityDark) { 'dark' } else { 'light' }
                $identityRelative = "docs/ui-evidence/identity-$identityVariant/$identityScene-$($identitySize.name)-$identityMode.png"
                $identityPath = Join-Path $identityRoot $identityRelative
                New-Item -ItemType Directory -Force (Split-Path $identityPath -Parent) | Out-Null
                adb -s $Device shell screencap -p /sdcard/campus-identity-shot.png
                if ($LASTEXITCODE -ne 0) { throw 'Screenshot failed.' }
                adb -s $Device pull /sdcard/campus-identity-shot.png $identityPath *> $null
                if ($LASTEXITCODE -ne 0) { throw 'Screenshot transfer failed.' }
                $identityBytes = [System.IO.File]::ReadAllBytes($identityPath)
                $identityWidth = [int]$identityBytes[16]*16777216 + [int]$identityBytes[17]*65536 + [int]$identityBytes[18]*256 + [int]$identityBytes[19]
                $identityHeight = [int]$identityBytes[20]*16777216 + [int]$identityBytes[21]*65536 + [int]$identityBytes[22]*256 + [int]$identityBytes[23]
                if ($identityWidth -ne $identitySize.width -or $identityHeight -ne $identitySize.height) {
                    throw "Wrong screenshot size: $identityRelative ($identityWidth x $identityHeight)"
                }
                $identityManifest += [pscustomobject]@{
                    path = $identityRelative; variant = $identityVariant; scene = $identityScene;
                    dark = $identityDark; widthPx = $identityWidth; heightPx = $identityHeight;
                    densityDpi = $identityActualDensity; readiness = $identityStatus;
                    sha256 = (Get-FileHash $identityPath -Algorithm SHA256).Hash
                }
            }
        }
    }
    foreach ($identityDark in @($false, $true)) {
        foreach ($identityScene in @('floor', 'map')) {
            $identityPair = @($identityManifest | Where-Object {
                $_.scene -eq $identityScene -and $_.dark -eq $identityDark -and
                $_.widthPx -eq $identitySize.width -and $_.heightPx -eq $identitySize.height
            })
            if ($identityPair.Count -ne 2) { throw 'Missing A/B scene pair.' }
            if ($identityScene -eq 'floor' -and $identityPair[0].readiness.rasterStep -ne $identityPair[1].readiness.rasterStep) {
                throw 'A/B floor raster levels differ. Let adaptive loading finish and rerun; no manifest accepted.'
            }
            if ($identityScene -eq 'map' -and (
                $identityPair[0].readiness.latitude -ne $identityPair[1].readiness.latitude -or
                $identityPair[0].readiness.longitude -ne $identityPair[1].readiness.longitude -or
                $identityPair[0].readiness.zoom -ne $identityPair[1].readiness.zoom)) {
                throw 'A/B map cameras differ; no manifest accepted.'
            }
        }
    }
    Write-Output "Captured $($identitySize.name): dimensions verified."
}
$identityManifest | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath (Join-Path $identityRoot 'docs/ui-evidence/identity-manifest.json') -Encoding utf8
Write-Output "Saved $($identityManifest.Count) screenshots with dimensions and hashes."
