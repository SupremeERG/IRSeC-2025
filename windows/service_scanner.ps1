# Suspicious Windows Service Scanner
# @author Jian
# Purpose: Identify potentially malicious or misconfigured services with explanation
# This only prints suspicious services. It does NOT delete or modify the system in any way
# The user should manually check each flagged service and take appropriate actions

$suspiciousKeywords = @("powershell", "cmd", "wscript", "http", "ftp", "base64", "temp", "appdata", "frombase64string", "-enc", "-encodedcommand")
$suspiciousStartupTypes = @("Auto", "Boot", "System")
$safePaths = @(
    "C:\Windows\System32",
    "C:\Windows\SysWOW64",
    "C:\Windows\System32\svchost.exe",
    "C:\Windows\System32\services.exe"
)

# Get all services
$services = Get-WmiObject -Class Win32_Service

foreach ($service in $services) {
    $name        = $service.Name
    $displayName = $service.DisplayName
    $description = $service.Description
    $path        = $service.PathName
    $startMode   = $service.StartMode
    $state       = $service.State

    $isSuspicious = $false
    $reasons = @()

    # Normalize path
    $normalizedPath = $path.ToLower().Trim('"')
    $pathIsSafe = $safePaths | Where-Object { $normalizedPath -like "$_*" }

    # Check for suspicious keywords outside safe paths
    foreach ($keyword in $suspiciousKeywords) {
        if ($normalizedPath -match $keyword -and -not $pathIsSafe) {
            $isSuspicious = $true
            $reasons += "Path contains '$keyword' outside known safe locations"
        }
    }

    # Check for unusual startup types not running
    if ($startMode -in $suspiciousStartupTypes -and $state -ne "Running") {
        $isSuspicious = $true
        $reasons += "Startup type '$startMode' but service not running"
    }

    # Check for empty or null binary path
    if ([string]::IsNullOrWhiteSpace($path)) {
        $isSuspicious = $true
        $reasons += "Empty or missing binary path"
    }

    # Check for missing description
    if ([string]::IsNullOrWhiteSpace($description)) {
        $isSuspicious = $true
        $reasons += "Missing service description"
    }

    # Check for non-standard service names
    if ($name -match "^[a-zA-Z]{0,2}\d{4,}$" -or $name.Length -gt 30) {
        $isSuspicious = $true
        $reasons += "Non-standard or obfuscated service name"
    }

    # Output results
    if ($isSuspicious) {
        Write-Host "`n[!] Suspicious Service Detected:" -ForegroundColor Red
        Write-Host "Name        : $name"
        Write-Host "DisplayName : $displayName"
        Write-Host "StartMode   : $startMode"
        Write-Host "State       : $state"
        Write-Host "Path        : $path"
        Write-Host "Description : $description"
        Write-Host "Reasons     : $($reasons -join '; ')" -ForegroundColor Yellow
    }
}