#!/bin/bash
# remove_unauthorized_users.sh
# This script detects and removes unauthorized users on a Debian system.

if [[ -z "${IRSEC_REPO_DIR:-}" ]]; then
    IRSEC_REPO_DIR=$HOME/IRSeC-2025/
fi
source $IRSEC_REPO_DIR/linux/scripts/blue_team_configuration.sh


# Define known default Debian accounts
DEFAULT_USERS=(
  root daemon bin sys sync games man lp mail news uucp proxy www-data
  backup list irc gnats nobody systemd-network systemd-resolve
  systemd-timesync messagebus syslog _apt
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

# Ask for confirmation before deleting
read -p "Do you want to delete these users? (y/N): " confirm
if [[ "$confirm" =~ ^[Yy]$ ]]; then
    for user in "${UNAUTHORIZED[@]}"; do
        echo "Deleting user: $user"
        deluser --remove-home "$user"
    done
    echo "✅ All unauthorized users have been removed."
else
    echo "❌ Aborted. No changes made."
fi
