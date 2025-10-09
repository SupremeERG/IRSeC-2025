#!/bin/bash

# Blue Team Defense - Configuration File
# @author Ryan
# Source this file in other scripts

set -euo pipefail

# Configuration
LOG_FILE="/var/log/blue_team_defense.log"
REPORT_FILE="/var/log/blue_team_report_$(date +%Y%m%d_%H%M%S).txt"
RED_INDICATORS=("redteam" "red_team" "red-team" "red team")
EXCLUDE_DIRS=("/proc" "/sys" "/dev" "/run" "/boot" "/lib" "/lib64" "/usr/share" "/var/cache")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Function to check if directory should be excluded
should_exclude() {
    local dir="$1"
    for exclude in "${EXCLUDE_DIRS[@]}"; do
        if [[ "$dir" == "$exclude"* ]]; then
            return 0
        fi
    done
    return 1
}

# Initialize logs
init_logs() {
    echo "=== Blue Team Defense Scan Started ===" > "$LOG_FILE"
    echo "Scan Report - $(date)" > "$REPORT_FILE"
    log "Logging initialized"
}