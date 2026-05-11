# 临时脚本：启动 Superpowers brainstorming 可视化同伴（Node），供本机浏览器打开。
$sid = "pwsh-{0}" -f [DateTimeOffset]::UtcNow.ToUnixTimeMilliseconds()
$base = Join-Path "d:\projects\lite-danci" (Join-Path ".superpowers\brainstorm" $sid)
New-Item -ItemType Directory -Force -Path (Join-Path $base "content"), (Join-Path $base "state") | Out-Null
$wd = "C:\Users\nancl\.cursor\plugins\cache\cursor-public\superpowers\b7a8f76985f1e93e75dd2f2a3b424dc731bd9d37\skills\brainstorming\scripts"
$psi = New-Object System.Diagnostics.ProcessStartInfo
$psi.FileName = "node"
$psi.Arguments = "server.cjs"
$psi.WorkingDirectory = $wd
$psi.UseShellExecute = $false
$psi.CreateNoWindow = $true
[void]$psi.EnvironmentVariables.Remove("BRAINSTORM_OWNER_PID")
$psi.EnvironmentVariables["BRAINSTORM_DIR"] = $base
$psi.EnvironmentVariables["BRAINSTORM_HOST"] = "127.0.0.1"
$psi.EnvironmentVariables["BRAINSTORM_URL_HOST"] = "localhost"
$p = [System.Diagnostics.Process]::Start($psi)
Start-Sleep -Seconds 2
$infoPath = Join-Path $base "state\server-info"
if (Test-Path $infoPath) {
    Get-Content -Raw $infoPath
    Write-Output ""
    Write-Output "SESSION_BASE=$base"
} else {
    Write-Error "server-info not found; node may have failed to start."
    exit 1
}
