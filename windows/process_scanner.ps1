# Suspicious Process Scanner for Windows Clients and Servers
# @author Jian
# Purpose: Identify potentially malicious or misconfigured processes with explanation
# This prints suspicious processes but does not modify the system in any way
# The user should manually check each flagged process and take appropriate actions

$suspiciousKeywords = @("powershell", "cmd", "wscript", "http", "ftp", "base64", "appdata", "temp", "-enc", "-encodedcommand", "frombase64string")
$safePaths = @("C:\Windows\System32", "C:\Windows\SysWOW64", "C:\Program Files", "C:\Program Files (x86)")
$knownSystemProcesses = @("wininit.exe", "csrss.exe", "smss.exe", "services.exe", "lsass.exe", "svchost.exe",
"winlogon.exe", "explorer.exe", "spoolsv.exe", "dwm.exe", "taskhostw.exe", "MpDefenderCoreService.exe", "Microsoft.ActiveDirectory.WebServices.exe",
"Registry", "System", "System Idle Process", "powershell.exe", "NisSrv.exe", "SecurityHealthService.exe", "MsMpEng.exe")

$processes = Get-CimInstance Win32_Process

foreach ($proc in $processes) {
    $procId      = $proc.ProcessId
    $name        = $proc.Name
    $path        = $proc.ExecutablePath
    $parentPid   = $proc.ParentProcessId
    $commandLine = $proc.CommandLine

    $normalizedPath = if ($path) { $path.ToLower().Trim('"') } else { "" }
    $isSuspicious = $false
    $reasons = @()

    # Skip known system processes entirely
    if ($knownSystemProcesses -contains $name.ToLower()) {
        continue
    }

    # Check for suspicious keywords in path or command line
    foreach ($keyword in $suspiciousKeywords) {
        if (($normalizedPath -match $keyword -or $commandLine -match $keyword) -and ($safePaths -notcontains $normalizedPath)) {
            $isSuspicious = $true
            $reasons += "Contains '$keyword' outside safe paths"
        }
    }

    # Check for execution from user or temp directories
    if ($normalizedPath -match "users\\.*\\appdata" -or $normalizedPath -match "temp\\") {
        $isSuspicious = $true
        $reasons += "Executed from user or temp directory"
    }

    # Check for missing executable path
    if ([string]::IsNullOrWhiteSpace($path)) {
        $isSuspicious = $true
        $reasons += "Missing executable path"
    }

    # Check for non-standard process names
    if ($name -match "^[a-zA-Z]{0,2}\d{4,}$" -or $name.Length -gt 30) {
        $isSuspicious = $true
        $reasons += "Obfuscated or non-standard process name"
    }

    # Check for suspicious parent process (e.g., powershell spawned by explorer)
    try {
        $parent = Get-CimInstance Win32_Process -Filter "ProcessId = $parentPid"
        if ($name -match "powershell|cmd|wscript" -and $parent.Name -match "explorer") {
            $isSuspicious = $true
            $reasons += "Suspicious parent process: $($parent.Name)"
        }
    } catch {}

    # Output results
    if ($isSuspicious) {
        Write-Host "`n[!] Suspicious Process Detected:" -ForegroundColor Red
        Write-Host "Name        : $name"
        Write-Host "PID         : $procId"
        Write-Host "Parent PID  : $parentPid"
        Write-Host "Path        : $path"
        Write-Host "CommandLine : $commandLine"
        Write-Host "Reasons     : $($reasons -join '; ')" -ForegroundColor Yellow
    }
}