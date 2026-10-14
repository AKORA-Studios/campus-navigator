# Dot-source from PowerShell: . .\tools\dev-env.ps1
# SDKs are local to this workspace; no permanent PATH change is required.
param([string]$ToolchainRoot = (Join-Path (Split-Path $PSScriptRoot -Parent) '..\toolchains'))

$ToolchainRoot = (Resolve-Path -LiteralPath $ToolchainRoot -ErrorAction Stop).Path
$flutterRoot = Join-Path $ToolchainRoot 'flutter-3.24.5'
$javaRoot = Join-Path $ToolchainRoot 'java\jdk-17.0.20.1+1'
$androidRoot = Join-Path $ToolchainRoot 'android-sdk'
foreach ($requiredFile in @("$flutterRoot\bin\flutter.bat", "$javaRoot\bin\java.exe", "$androidRoot\platform-tools\adb.exe")) {
    if (-not (Test-Path -LiteralPath $requiredFile)) { throw "Missing tool: $requiredFile" }
}

$gitCommand = Get-Command git.exe -ErrorAction Stop
$gitRoot = Split-Path (Split-Path $gitCommand.Source -Parent) -Parent
$gitHelpers = Join-Path $gitRoot 'mingw64\bin'
if (Test-Path -LiteralPath (Join-Path $gitHelpers 'git-remote-https.exe')) {
    $env:GIT_EXEC_PATH = $gitHelpers
}
$env:PATH = "$flutterRoot\bin;$javaRoot\bin;$androidRoot\platform-tools;$androidRoot\cmdline-tools\latest\bin;$androidRoot\emulator;$env:PATH"
$env:JAVA_HOME = $javaRoot
$env:ANDROID_HOME = $androidRoot
$env:ANDROID_SDK_ROOT = $androidRoot
$env:PUB_CACHE = Join-Path $ToolchainRoot 'pub-cache'
$env:GRADLE_USER_HOME = Join-Path $ToolchainRoot 'gradle-cache'
$env:ANDROID_AVD_HOME = Join-Path $ToolchainRoot 'avd'
