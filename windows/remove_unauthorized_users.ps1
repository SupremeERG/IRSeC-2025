# @author jian
# removes all users not in the authorized users list

# Define authorized users
$authorizedUsers = @("Administrator", "Guest", "krbtgt", "jians", "jsmith")

# Get all local users
$localUsers = Get-LocalUser | Where-Object { $_.Name -notlike '*$' }

# Filter out authorized users
$unauthorizedUsers = $localUsers | Where-Object {
    $authorizedUsers -notcontains $_.Name -and $_.Enabled -eq $true
}

# Log and remove unauthorized users
foreach ($user in $unauthorizedUsers) {
    Write-Host "Removing unauthorized user: $($user.Name)"
    try {
        Remove-LocalUser -Name $user.Name
        Write-Host "Successfully removed $($user.Name)"
    } catch {
        Write-Warning "Failed to remove $($user.Name): $_"
    }
}