# @author jian
# resets the passwords of all authorized users to "P@ssw0rd123!"

# Define the list of authorized users
$authorizedUsers = @(
    "martymcFly",
    "drwho", 
    "arthurdent", 
    "sambeckett", 
    "loki",
    "riphunter",
    "theflash",
    "tonystark",
    "drstrange",
    "bartallen")

# Define the new password
$newPassword = ConvertTo-SecureString "P@ssw0rd123!" -AsPlainText -Force

# Loop through each authorized user and set the password
foreach ($user in $authorizedUsers) {
    try {
        Set-LocalUser -Name $user -Password $newPassword
        Write-Host "Password updated for user: $user"
    } catch {
        Write-Warning "Failed to update password for $user"
    }
}