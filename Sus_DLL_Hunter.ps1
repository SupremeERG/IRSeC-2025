# Looks for suspicious DDLs
# @author jian
# Criteria for suspicion
# In one of the following paths and (modified within 7 days or not owned by SYSTEM or TrustedInstaller)
# This ONLY prints sus DLLs, it DOES NOT delete them. The user should manually
# check each flagged DLL and only delete them if they are malicious
$searchPaths = @(
    "$env:APPDATA",
    "$env:LOCALAPPDATA",
    "$env:TEMP",
    "$env:USERPROFILE\Downloads",
    "$env:USERPROFILE\Documents",
    "$env:USERPROFILE\Desktop",
    "$env:PUBLIC",
    "$env:PUBLIC\Downloads",
    "$env:ProgramData",
    "$env:SystemRoot\System32",
    "$env:SystemRoot\SysWOW64",
    "$env:ProgramFiles",
    "$env:ProgramFiles (x86)",
    "C:\Windows\Temp",
    "C:\Windows\Installer",
    "C:\Windows\assembly",
    "C:\Windows\Fonts",
    "C:\Windows\Tasks",
    "C:\Windows\System32\Tasks",
    "C:\inetpub\wwwroot",
    "C:\Windows\Web",
    "C:\Windows\Logs",
    "C:\Windows\Debug",
    "C:\Windows\System32\spool\drivers",
    "C:\Users\Administrator",
    "C:\Users\Default",
    "C:\Users\Guest",
    "C:\Users\Public\Downloads"
)

Write-Host "`n[+] Scanning for suspicious DLLs..." -ForegroundColor Cyan

foreach ($path in $searchPaths) {
    if (Test-Path $path) {
        Get-ChildItem -Path $path -Recurse -Filter *.dll -ErrorAction SilentlyContinue | ForEach-Object {
            $dll = $_
            $owner = (Get-Acl $dll.FullName).Owner
            $lastWrite = $dll.LastWriteTime
            $sizeMB = [math]::Round($dll.Length / 1MB, 2)

            #flag recently modified DLLs
	        if ($dll.LastWriteTime -gt (Get-Date).AddDays(-7)) {
    		    Write-Host "[!] Suspicious DLL: $($dll.FullName), Recently Modified" -ForegroundColor Yellow
                Write-Host "    Owner: $owner"
                Write-Host "    Last Modified: $lastWrite"
                Write-Host "    Size: $sizeMB MB"
            }

	        # Flag DLLs not owned by SYSTEM or TrustedInstaller
            if ($owner -notmatch "SYSTEM|TrustedInstaller") {
                Write-Host "[!] Suspicious DLL: $($dll.FullName), Suspicious Owner" -ForegroundColor Yellow
                Write-Host "    Owner: $owner"
                Write-Host "    Last Modified: $lastWrite"
                Write-Host "    Size: $sizeMB MB"
            }
        }
    }
}

Write-Host "`n[+] Scan complete." -ForegroundColor Green