#!/bin/bash
# remove_unauthorized_users.sh
# This script detects and removes unauthorized users on a Debian system,
# logging details about each deleted account to unauthorized_users.csv.

source ./blue_team_configuration.sh

# Define known default Debian accounts
DEFAULT_USERS=(
  root daemon bin sys sync games man lp mail news uucp proxy www-data
  backup list irc gnats nobody systemd-network systemd-resolve
  systemd-timesync messagebus syslog _apt drwho marymcFly arthurdent sambeckett loki riphunter theflash tonystark drstrange bartallen
)

# Get current users
ALL_USERS=($(awk -F: '{print $1}' /etc/passwd))

# Function to check if user is installed by a package (service account)
is_service_user() {
    local user="$1"
    # Check if user has a home directory under /var, /usr, or /srv (typical for services)
    local homedir
    homedir=$(getent passwd "$user" | cut -d: -f6)
    if [[ "$homedir" =~ ^/(var|usr|srv)/ ]]; then
        return 0
    fi
    # Check if user's shell is /usr/sbin/nologin or /bin/false (system/service accounts)
    local shell
    shell=$(getent passwd "$user" | cut -d: -f7)
    if [[ "$shell" == "/usr/sbin/nologin" || "$shell" == "/bin/false" ]]; then
        return 0
    fi
    return 1
}

# Build list of unauthorized users
UNAUTHORIZED=()

for user in "${ALL_USERS[@]}"; do
    if [[ " ${DEFAULT_USERS[*]} " == *" $user "* ]]; then
        continue
    elif is_service_user "$user"; then
        continue
    else
        UNAUTHORIZED+=("$user")
    fi
done

if [[ ${#UNAUTHORIZED[@]} -eq 0 ]]; then
    echo "✅ No unauthorized users found."
    exit 0
fi

echo "⚠️ Unauthorized users detected:"
printf '%s\n' "${UNAUTHORIZED[@]}"
echo

# Ensure CSV log file exists with headers
LOG_FILE="../logging/unauthorized_users.csv"
if [[ ! -f "$LOG_FILE" ]]; then
    echo "username,uid,gid,groups" > "$LOG_FILE"
fi

# Ask confirmation for each user individually
for user in "${UNAUTHORIZED[@]}"; do
    read -p "Do you want to delete user '$user'? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        echo "Deleting user: $user"
        
        # Collect user info before deletion
        uid=$(id -u "$user" 2>/dev/null)
        gid=$(id -g "$user" 2>/dev/null)
        groups=$(id -nG "$user" 2>/dev/null | tr ' ' ';')  # separate multiple groups with semicolon

        # Append user info to CSV log
        echo "$user,$uid,$gid,$groups" >> "$LOG_FILE"

        # Delete user and home directory
        deluser --remove-home "$user"

        echo "✅ User '$user' deleted and logged to $LOG_FILE."
    else
        echo "❌ Skipped user: $user"
    fi
    echo
done

echo "✅ Process complete."
echo "All deleted users have been recorded in: $LOG_FILE"

