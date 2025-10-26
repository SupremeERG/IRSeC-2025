# Requires: Active Directory module
# @author Jian
# Removes unauthorized domain users
# UNTESTED

Import-Module ActiveDirectory

# Define your whitelist of allowed usernames (sAMAccountName)
$allowedUsers = @(
    "fathertime",
    "chronos",
    "aion",
    "kairos",
    "merlin",
    "terminator",
    "mrpeabody",
    "jamescole",
    "docbrown",
    "professorparadox"
)

# Get all domain users
$allUsers = Get-ADUser -Filter * -Properties SamAccountName

foreach ($user in $allUsers) {
    $username = $user.SamAccountName

    if (-not ($allowedUsers -contains $username)) {
        Write-Host "Removing user: $username"
        try {
            Disable-ADAccount -Identity $username
        } catch {
            Write-Warning "Failed to remove $username"
        }
    }
}