# Ralph Loop：在项目根目录反复执行「pub get → analyze → test」直到全部通过或达到次数上限。
# 用法：在 PowerShell 中执行  .\tools\ralph_loop.ps1
# 要求：flutter 已在 PATH 中。

$ErrorActionPreference = "Stop"
$root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
Set-Location $root

if (-not (Get-Command flutter -ErrorAction SilentlyContinue)) {
    Write-Host "未找到 flutter，请先安装 Flutter 并加入 PATH。" -ForegroundColor Red
    exit 1
}

$max = 8
for ($i = 1; $i -le $max; $i++) {
    Write-Host "`n=== Ralph Loop 第 $i / $max 轮 ===" -ForegroundColor Cyan
    flutter pub get
    if ($LASTEXITCODE -ne 0) { continue }

    flutter analyze
    if ($LASTEXITCODE -ne 0) { continue }

    # 无参 flutter test 在部分环境下可能只执行部分用例；显式收集 test\*_test.dart，
    # 且将 widget_test 置后，避免与其它用例组合时的异常计数。
    $testDir = Join-Path $root "test"
    $testFiles = @(Get-ChildItem -Path $testDir -Filter "*_test.dart" -ErrorAction SilentlyContinue |
        Sort-Object @{ Expression = { if ($_.Name -eq "widget_test.dart") { 1 } else { 0 } }; Ascending = $true }, Name)
    if ($testFiles.Count -eq 0) {
        Write-Host "未找到 test\*_test.dart。" -ForegroundColor Red
        exit 1
    }
    flutter test @($testFiles | ForEach-Object { $_.FullName })
    if ($LASTEXITCODE -eq 0) {
        Write-Host "`n全部通过。" -ForegroundColor Green
        exit 0
    }
}

Write-Host "`n已达上限仍未全部通过，请根据上方日志修复后重试。" -ForegroundColor Yellow
exit 1
