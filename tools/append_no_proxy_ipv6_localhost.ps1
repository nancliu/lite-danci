# Append IPv6 loopback to user NO_PROXY (merge Machine value if User empty).
$ErrorActionPreference = "Stop"

$userVal = [Environment]::GetEnvironmentVariable("NO_PROXY", "User")
$machineVal = [Environment]::GetEnvironmentVariable("NO_PROXY", "Machine")

if (-not [string]::IsNullOrWhiteSpace($userVal)) {
    $base = $userVal
}
elseif (-not [string]::IsNullOrWhiteSpace($machineVal)) {
    $base = $machineVal
}
else {
    $base = ""
}

$ipv6Loopback = [string]::new(58, 2) + "1"

$hasIpv6Local = $false
if (-not [string]::IsNullOrWhiteSpace($base)) {
    foreach ($part in $base.Split(",")) {
        if ($part.Trim() -eq $ipv6Loopback) {
            $hasIpv6Local = $true
            break
        }
    }
}

if (-not [string]::IsNullOrWhiteSpace($base) -and $hasIpv6Local) {
    Write-Host "NO_PROXY already has IPv6 loopback. No change."
    Write-Host $base
    exit 0
}

if ([string]::IsNullOrWhiteSpace($base)) {
    $newVal = $ipv6Loopback
}
else {
    $t = $base.Trim()
    if ($t.EndsWith(",")) {
        $newVal = $t + $ipv6Loopback
    }
    else {
        $newVal = $t + "," + $ipv6Loopback
    }
}

[Environment]::SetEnvironmentVariable("NO_PROXY", $newVal, "User")
Write-Host "Updated user NO_PROXY. Reopen terminal, then run flutter doctor."
Write-Host $newVal
