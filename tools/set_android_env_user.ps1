# 将 ANDROID_HOME / JAVA_HOME 与 PATH 追加写入当前用户环境（一次性执行）。
$ErrorActionPreference = "Stop"

[Environment]::SetEnvironmentVariable("ANDROID_HOME", "D:\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("ANDROID_SDK_ROOT", "D:\Android\Sdk", "User")
[Environment]::SetEnvironmentVariable("JAVA_HOME", "D:\develop\jdk-17-temurin", "User")

$userPath = [Environment]::GetEnvironmentVariable("Path", "User")
if ([string]::IsNullOrEmpty($userPath)) {
    $userPath = ""
}

$toAdd = @(
    "D:\Android\Sdk\platform-tools",
    "D:\develop\jdk-17-temurin\bin"
)

foreach ($segment in $toAdd) {
    $parts = $userPath -split ";" | Where-Object { $_ -ne "" }
    if ($parts -notcontains $segment) {
        if ($userPath.Length -gt 0 -and -not $userPath.EndsWith(";")) {
            $userPath += ";"
        }
        $userPath += $segment
    }
}

[Environment]::SetEnvironmentVariable("Path", $userPath, "User")
Write-Host "OK: ANDROID_HOME, ANDROID_SDK_ROOT, JAVA_HOME, Path (user) updated."
