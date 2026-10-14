param([string]$Serial = 'emulator-5554')
. (Join-Path $PSScriptRoot 'dev-env.ps1')
$script:CampusSerial = $Serial
function Get-CampusUi {
    for ($attempt=0; $attempt -lt 3; $attempt++) {
    adb -s $script:CampusSerial shell uiautomator dump /sdcard/campus-product-ui.xml | Out-Null
    [xml]$tree = (adb -s $script:CampusSerial shell cat /sdcard/campus-product-ui.xml | Out-String)
    $nodes = $tree.SelectNodes('//node')
    if (@($nodes | Where-Object { $_.'content-desc' -or $_.text }).Count -ge 3) { return $nodes }
    Start-Sleep -Milliseconds 700
    }
    throw 'Android accessibility tree has not become ready.'
}
function Tap-CampusNode($Node) {
    if ($null -eq $Node) { throw 'UI node not found' }
    $numbers = [regex]::Matches($Node.bounds, '\d+') | ForEach-Object { [int]$_.Value }
    if ($numbers[2] -le $numbers[0] -or $numbers[3] -le $numbers[1]) { throw 'UI node has no visible bounds.' }
    $x = [int](($numbers[0]+$numbers[2])/2)
    $y = [int](($numbers[1]+$numbers[3])/2)
    Write-Host "Tap $x,$y $($Node.'content-desc')"
    adb -s $script:CampusSerial shell input tap $x $y
    Start-Sleep -Milliseconds 500
}
function Tap-CampusLabel([string]$Pattern) {
    for ($try=0; $try -lt 3; $try++) {
    $nodes = @(Get-CampusUi | Where-Object { ($_.bounds -ne '[0,0][0,0]') -and ($_.'content-desc' -match $Pattern -or $_.text -match $Pattern) })
    if ($nodes.Count -eq 1) { Tap-CampusNode $nodes[0]; return }
    Start-Sleep -Milliseconds 800
    }
    throw "Expected one UI match for $Pattern, got $($nodes.Count)"
}
function Show-CampusUi {
    Get-CampusUi | Where-Object { $_.'content-desc' -or $_.text -or $_.clickable -eq 'true' } |
        Select-Object class, text, 'content-desc', bounds, clickable | Format-Table -Wrap
}
function Save-CampusShot([string]$Name, [string]$Expected = '') {
    $nodes = @(Get-CampusUi)
    if ($Expected -and !($nodes | Where-Object { $_.'content-desc' -match $Expected -or $_.text -match $Expected })) {
        throw "Screenshot state does not match $Expected"
    }
    Start-Sleep -Milliseconds 600
    $outputFolder = Join-Path (Split-Path $PSScriptRoot -Parent) 'docs/ui-evidence/product'
    New-Item -ItemType Directory -Force -Path $outputFolder | Out-Null
    adb -s $script:CampusSerial shell screencap -p /sdcard/campus-product.png | Out-Null
    adb -s $script:CampusSerial pull /sdcard/campus-product.png (Join-Path $outputFolder "$Name.png") | Out-Null
    Add-Type -AssemblyName System.Drawing
    $picture = [Drawing.Image]::FromFile((Join-Path $outputFolder "$Name.png"))
    try { Write-Output "$Name $($picture.Width)x$($picture.Height)" } finally { $picture.Dispose() }
}
function Set-CampusDevice([string]$Size, [int]$Density) {
    adb -s $script:CampusSerial shell wm user-rotation lock 0
    adb -s $script:CampusSerial shell wm size $Size
    adb -s $script:CampusSerial shell wm density $Density
    Start-Sleep -Seconds 2
}

function Start-CampusProduct {
    adb -s $script:CampusSerial shell am force-stop com.example.campus_navigator
    adb -s $script:CampusSerial shell am start -n com.example.campus_navigator/.MainActivity | Out-Null
    Start-Sleep -Seconds 4
    Get-CampusUi | Out-Null
}
function Set-CampusAppearance([string]$Variant, [bool]$Dark) {
    Start-CampusProduct
    Tap-CampusLabel '^Einstellungen$'
    Tap-CampusLabel '^App-Design'
    Tap-CampusLabel $(if ($Dark) { '^Dunkel$' } else { '^Hell$' })
    Tap-CampusLabel '^Campuskarte'
    Tap-CampusLabel '^Automatisch$'
    Tap-CampusLabel '^Campus-Design'
    Tap-CampusLabel $(if ($Variant -eq 'a') { 'Option A$' } else { 'Option B$' })
    adb -s $script:CampusSerial shell input keyevent 4
    Start-Sleep -Milliseconds 800
}
function Open-CampusRoom {
    $nodes=Get-CampusUi
    Tap-CampusNode ($nodes|Where-Object {$_.class -eq 'android.view.View' -and $_.clickable -eq 'true' -and $_.'content-desc' -match '^BEY 318'}|Select-Object -First 1)
    Start-Sleep -Seconds 2
    Tap-CampusLabel '^Gesamte Etage$'
}
function Select-CampusApb {
    Tap-CampusLabel '^Campuskarte[\s\S]*Tab'
    $nodes=Get-CampusUi
    Tap-CampusNode ($nodes|Where-Object {$_.class -eq 'android.widget.EditText'}|Select-Object -First 1)
    adb -s $script:CampusSerial shell input text APB
    Start-Sleep -Milliseconds 800
    $nodes=Get-CampusUi
    Tap-CampusNode ($nodes|Where-Object {$_.clickable -eq 'true' -and $_.'content-desc' -match '^APB'}|Select-Object -First 1)
    Start-Sleep -Seconds 2
}
function Save-CampusProductSet([string]$Prefix) {
    foreach ($device in @(
        @{name='phone';size='1179x2556';dpi=480},
        @{name='tablet-portrait';size='1200x1920';dpi=240},
        @{name='tablet-landscape';size='1920x1200';dpi=240})) {
        Set-CampusDevice $device.size $device.dpi
        # Density overrides may recreate the Android activity: reopen real routes.
        Start-CampusProduct
        Save-CampusShot "$($device.name)-$Prefix-hub" '^Favoriten$'
        Open-CampusRoom
        Save-CampusShot "$($device.name)-$Prefix-floor" 'BEY 318'
        adb -s $script:CampusSerial shell input keyevent 4
        Start-Sleep -Milliseconds 800
        Select-CampusApb
        Save-CampusShot "$($device.name)-$Prefix-map" '^Andreas-Pfitzmann-Bau$'
    }
}

function Set-CampusLanguage([string]$FromTag,[string]$LanguageName) {
    $strings = Get-Content (Join-Path (Split-Path $PSScriptRoot -Parent) "lib/l10n/app_$FromTag.arb") -Raw | ConvertFrom-Json
    Start-CampusProduct
    Tap-CampusLabel ('^' + [regex]::Escape($strings.settingsScreen_Title) + '$')
    Tap-CampusLabel ('^' + [regex]::Escape($strings.settingsLanguageTitle))
    Tap-CampusLabel ('^' + [regex]::Escape($LanguageName) + '$')
    adb -s $script:CampusSerial shell input keyevent 4
    Start-Sleep -Milliseconds 800
}
