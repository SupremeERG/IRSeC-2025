#!/bin/bash
# =====================================================
# Simple SSH key setup script for Ansible access
# Generates a key, adds it to ssh-agent, and deploys it
# =====================================================

KEY_PATH="$HOME/.ssh/ansible_auth_key"

# Check for required argument
if [ $# -lt 1 ]; then
    echo "Usage: $0 host1 [host2 ...]"
    exit 1
fi

# Create .ssh directory if needed
mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

# Generate SSH key if it doesn't already exist
if [ ! -f "$KEY_PATH" ]; then
    echo "🔑 Generating SSH key at $KEY_PATH..."
    ssh-keygen -t ed25519 -f "$KEY_PATH" -N "" -C "ansible_auth_key"
else
    echo "✅ SSH key already exists at $KEY_PATH"
fi

# Start the ssh-agent if not running
if ! pgrep -u "$USER" ssh-agent > /dev/null; then
    echo "🚀 Starting ssh-agent..."
    eval "$(ssh-agent -s)"
fi

# Add key to agent
ssh-add "$KEY_PATH"

# Copy public key to each host
for host in "$@"; do
    echo "📤 Copying public key to $host..."
    ssh-copy-id -i "${KEY_PATH}.pub" "$host"
done

echo "✅ Done! The SSH key is stored at: $KEY_PATH"


echo "[+] Once Ansible is installed, add \"ansible_connection=ssh\" to applicable hosts in inventory file"