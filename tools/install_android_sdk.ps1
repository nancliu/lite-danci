# 下载 Temurin JDK 17（zip）与 Android cmdline-tools，并用 sdkmanager 安装 SDK 组件。
$ErrorActionPreference = "Stop"

$tmpRoot = $env:TEMP
if ([string]::IsNullOrWhiteSpace($tmpRoot)) {
    $tmpRoot = [System.IO.Path]::GetTempPath().TrimEnd("\")
}

$sdkRoot = "D:\Android\Sdk"
$jdkDir = "D:\develop\jdk-17-temurin"
$jdkZip = Join-Path $tmpRoot "temurin17.zip"

# Google 官方 cmdline-tools（win）— 版本号会随时间更新，若 404 请到 developer.android.com 查最新 zip 名
# 变量名勿用 cmdline 前缀，否则 PowerShell 会把 $cmdlineZipUrl 解析成 $cmdline + ZipUrl
$androidCmdlineToolsZipUrl = "https://dl.google.com/android/repository/commandlinetools-win-11076708_latest.zip"
$cmdlineZip = Join-Path $tmpRoot "commandlinetools-win.zip"

New-Item -ItemType Directory -Force -Path $sdkRoot | Out-Null
New-Item -ItemType Directory -Force -Path "D:\develop" | Out-Null

Write-Host "Downloading JDK 17 (Temurin)..."
$jdkUrl = "https://api.adoptium.net/v3/binary/latest/17/ga/windows/x64/jdk/hotspot/normal/eclipse?project=jdk"
Invoke-WebRequest -Uri $jdkUrl -OutFile $jdkZip -UseBasicParsing

if (Test-Path $jdkDir) {
    Remove-Item $jdkDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $jdkDir | Out-Null
Expand-Archive -Path $jdkZip -DestinationPath $jdkDir -Force
$nested = Get-ChildItem $jdkDir -Directory | Select-Object -First 1
if ($null -ne $nested -and $nested.Name -match "^jdk") {
    Get-ChildItem $nested.FullName | Move-Item -Destination $jdkDir -Force
    Remove-Item $nested.FullName -Recurse -Force
}

$env:JAVA_HOME = $jdkDir
$env:Path = "$jdkDir\bin;" + $env:Path

Write-Host "java version:"
& "$jdkDir\bin\java.exe" -version

Write-Host "Downloading Android commandline-tools..."
Invoke-WebRequest -Uri $androidCmdlineToolsZipUrl -OutFile $cmdlineZip -UseBasicParsing

$extractTmp = Join-Path $tmpRoot "android-cmdline-extract"
if (Test-Path $extractTmp) {
    Remove-Item $extractTmp -Recurse -Force
}
Expand-Archive -Path $cmdlineZip -DestinationPath $extractTmp -Force

$cmdlineTools = Join-Path $sdkRoot "cmdline-tools"
$latestDir = Join-Path $cmdlineTools "latest"
if (Test-Path $latestDir) {
    Remove-Item $latestDir -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $latestDir | Out-Null
$inner = Join-Path $extractTmp "cmdline-tools"
if (-not (Test-Path $inner)) {
    throw "Expected folder cmdline-tools in zip, got: $(Get-ChildItem $extractTmp | ForEach-Object Name)"
}
Move-Item -Path (Join-Path $inner "*") -Destination $latestDir -Force

$env:ANDROID_HOME = $sdkRoot
$env:ANDROID_SDK_ROOT = $sdkRoot

$sdkmanager = Join-Path $latestDir "bin\sdkmanager.bat"
if (-not (Test-Path $sdkmanager)) {
    throw "sdkmanager not found at $sdkmanager"
}

Write-Host "Accepting SDK licenses (sdkmanager)..."
1..50 | ForEach-Object { "y" } | & $sdkmanager --sdk_root=$sdkRoot --licenses

Write-Host "Installing SDK packages (may take several minutes)..."
$pkgs = @(
    "platform-tools",
    "platforms;android-35",
    "platforms;android-36",
    "build-tools;35.0.0",
    "build-tools;36.1.0",
    "build-tools;28.0.3",
    "cmdline-tools;latest"
)
& $sdkmanager --sdk_root=$sdkRoot @pkgs

Write-Host "Done. Set user environment ANDROID_HOME and PATH, then: flutter config --android-sdk $sdkRoot"
Write-Host "Accept licenses: flutter doctor --android-licenses"
