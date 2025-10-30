#!/bin/bash
# Moves a file to a quarantine folder (/var/quarantine/)

# Exit if no argument provided
if [ -z "$1" ]; then
    echo "Usage: $0 <file>"
    exit 1
fi

FILE="$1"
BASENAME=$(basename "$FILE")
DEST="/var/quarantine/$BASENAME"

# Ensure quarantine directory exists
mkdir -p /var/quarantine

# Move file
if mv "$FILE" "$DEST"; then
    echo "Moved $FILE to $DEST"
else
    echo "Failed to move $FILE"
    exit 1
fi
