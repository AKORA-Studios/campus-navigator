# Debug-only presentation config, separate from production settings/storage.
param(
    [ValidateSet('a', 'b')][string]$Variant = 'a',
    [ValidateSet('hub', 'results', 'map', 'floor')][string]$Scene = 'hub',
    [switch]$Dark,
    [string]$Device = 'emulator-5554'
)
. (Join-Path $PSScriptRoot 'dev-env.ps1')
$previewConfig = @{ variant = $Variant; scene = $Scene; dark = [bool]$Dark }
$previewJson = $previewConfig | ConvertTo-Json -Compress
adb -s $Device shell run-as com.example.campus_navigator mkdir -p files
if ($LASTEXITCODE -ne 0) { throw 'Debug app is not installed or run-as unavailable.' }
$previewJson | adb -s $Device shell run-as com.example.campus_navigator tee files/campus-identity-preview.json
if ($LASTEXITCODE -ne 0) { throw 'Could not update preview configuration.' }
