# Blue Team Registry Hunt Script
# @author jian
# Purpose: Detect suspicious registry entries used for persistence or payload hiding
# This script ONLY prints suspicious registry values, it DOES NOT delete or modify anything in any way.
# The user should manually check each flagged registry value and ONLY delete it
if the user has confirmed that it is malicious

# Define common persistence paths
$registryPaths = @(
	"HKCU:\Software\Microsoft\Windows\CurrentVersion\Run",
	"HKLM:\Software\Microsoft\Windows\CurrentVersion\Run",
	"HKLM:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
	"HKCU:\Software\Microsoft\Windows\CurrentVersion\RunOnce",
	"HKLM:\System\CurrentControlSet\Services",
	"HKCU:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon",
	"HKLM:\Software\Microsoft\Windows NT\CurrentVersion\Winlogon",
	"HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\System",
	"HKLM:\Software\Microsoft\Windows\CurrentVersion\Policies\System"
)

# Function to check
for suspicious values

function Check - RegistryPath
{
	param($path)
	try
	{
		$items = Get - ItemProperty - Path $path - ErrorAction SilentlyContinue
		if ($items)
		{
			foreach($property in $items.PSObject.Properties)
			{
				# Skip PowerShell metadata properties
				if ($property.Name - in @("PSPath", "PSParentPath", "PSChildName", "PSProvider"))
				{
					continue
				}

				$value = $property.Value
				if ($value - match "powershell" - or $value - match "cmd" - or $value - match "wscript" - or $value - match "http" - or $value - match "base64")
				{
					Write - Host "`n[!] Suspicious entry in ${path}:`n$($property.Name) = $value" - ForegroundColor Red
				}
			}
		}
	}
	catch
	{
		Write - Host "[-] Failed to access $path" - ForegroundColor Yellow
	}
}

# Scan each path
foreach($path in $registryPaths)
{
	Write - Host "`n--- Scanning $path ---" - ForegroundColor Cyan
	Check - RegistryPath - path $path
}

# Bonus: Look
for hidden keys under HKCU\ Software
Write - Host "`n--- Scanning for hidden keys under HKCU:\Software ---" - ForegroundColor Cyan
Get - ChildItem - Path "HKCU:\Software" - ErrorAction SilentlyContinue | ForEach - Object
{
	if ($_.Name - match "clsid" - or $_.Name - match "shell" - or $_.Name - match "debug")
	{
		Write - Host "[!] Potential hiding spot: $($_.Name)" - ForegroundColor Magenta
	}
}