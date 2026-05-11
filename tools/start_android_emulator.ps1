# 在本机启动 Android 模拟器：优先使用 ANDROID_HOME / ANDROID_SDK_ROOT，其次常见路径。
# 用法：在 PowerShell 中执行  .\tools\start_android_emulator.ps1
# 可选参数：.\tools\start_android_emulator.ps1 -AvdName "你的AVD名称"

param(
    [string] $AvdName = ""
)

$ErrorActionPreference = "Stop"

function Get-SdkRoot {
    foreach ($k in @("ANDROID_HOME", "ANDROID_SDK_ROOT")) {
        $v = [Environment]::GetEnvironmentVariable($k, "User")
        if (-not [string]::IsNullOrWhiteSpace($v) -and (Test-Path $v)) {
            return $v.TrimEnd("\")
        }
        $v = [Environment]::GetEnvironmentVariable($k, "Machine")
        if (-not [string]::IsNullOrWhiteSpace($v) -and (Test-Path $v)) {
            return $v.TrimEnd("\")
        }
    }
    $local = Join-Path $env:LOCALAPPDATA "Android\Sdk"
    if (Test-Path $local) {
        return $local
    }
    $d = "D:\Android\Sdk"
    if (Test-Path $d) {
        return $d
    }
    return $null
}

$sdk = Get-SdkRoot
if ($null -eq $sdk) {
    Write-Host "未找到 Android SDK。请设置环境变量 ANDROID_HOME 或安装 Android Studio / SDK。" -ForegroundColor Red
    exit 1
}

$emu = Join-Path $sdk "emulator\emulator.exe"
if (-not (Test-Path $emu)) {
    Write-Host "未找到模拟器程序: $emu" -ForegroundColor Yellow
    Write-Host "请先安装组件 emulator，例如在 SDK 目录下执行：" -ForegroundColor Yellow
    Write-Host '  .\cmdline-tools\latest\bin\sdkmanager.bat "emulator"' -ForegroundColor Cyan
    exit 1
}

$env:ANDROID_SDK_ROOT = $sdk
$env:ANDROID_HOME = $sdk

& $emu -list-avds
$avds = @(& $emu -list-avds 2>$null | Where-Object { $_ -match "\S" })
if ($avds.Count -eq 0) {
    Write-Host "`n当前没有任何 AVD。请用 Android Studio -> Device Manager 新建虚拟设备，或命令行：" -ForegroundColor Yellow
    Write-Host '  sdkmanager "system-images;android-36;google_apis;x86_64"' -ForegroundColor Cyan
    Write-Host '  avdmanager create avd -n Pixel_36 -k "system-images;android-36;google_apis;x86_64"' -ForegroundColor Cyan
    exit 1
}

$pick = $AvdName
if ([string]::IsNullOrWhiteSpace($pick)) {
    $pick = $avds[0]
    Write-Host "`n将启动 AVD: $pick （共 $($avds.Count) 个，可用 -AvdName 指定）" -ForegroundColor Green
} else {
    Write-Host "`n将启动 AVD: $pick" -ForegroundColor Green
}

Start-Process -FilePath $emu -ArgumentList @("-avd", $pick) -WindowStyle Normal
Write-Host "已在独立窗口启动模拟器，首次开机可能较慢。随后可执行: flutter run" -ForegroundColor Green
