#!/bin/bash

# Blue Team Defense Script - Aggressive Version
# Recursively searches for and removes red team indicators
# Version: 2.0 - Aggressive

set -euo pipefail

# Configuration
LOG_FILE="/var/log/blue_team_defense.log"
REPORT_FILE="/var/log/blue_team_report_$(date +%Y%m%d_%H%M%S).txt"
RED_INDICATORS=("redteam" "red_team" "red-team" "red team")
EXCLUDE_DIRS=("/proc" "/sys" "/dev" "/run" "/boot" "/lib" "/lib64")

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG_FILE"
}

# Initialize logs
echo "=== Blue Team Defense Scan Started ===" > "$LOG_FILE"
echo "=== AGGRESSIVE REMOVAL MODE ===" >> "$LOG_FILE"
echo "Scan Report - $(date)" > "$REPORT_FILE"

log "Starting Blue Team defense scan in AGGRESSIVE mode..."

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

# Function to detect suspicious files
scan_files() {
    log "Scanning for suspicious files..."
    local found_files=()
    
    while IFS= read -r -d '' file; do
        if should_exclude "$(dirname "$file")"; then
            continue
        fi
        
        local filename=$(basename "$file")
        local lower_filename=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
        
        for indicator in "${RED_INDICATORS[@]}"; do
            if [[ "$lower_filename" == *"$indicator"* ]]; then
                found_files+=("$file")
                log "SUSPICIOUS FILE FOUND: $file"
                echo "SUSPICIOUS FILE: $file" >> "$REPORT_FILE"
                echo "  Size: $(ls -lh "$file" 2>/dev/null | awk '{print $5}' || echo 'unknown')" >> "$REPORT_FILE"
                echo "  Permissions: $(ls -ld "$file" 2>/dev/null | awk '{print $1}' || echo 'unknown')" >> "$REPORT_FILE"
                echo "  Owner: $(ls -ld "$file" 2>/dev/null | awk '{print $3}' || echo 'unknown')" >> "$REPORT_FILE"
                break
            fi
        done
    done < <(find / -type f -print0 2>/dev/null || true)
    
    echo "${#found_files[@]}"
}

# Function to detect suspicious users
scan_users() {
    log "Scanning for suspicious users..."
    local found_users=()
    
    while IFS=: read -r username _ uid _ _ home shell; do
        if [[ $uid -ge 1000 ]] || [[ $username == "root" ]]; then
            local lower_username=$(echo "$username" | tr '[:upper:]' '[:lower:]')
            
            for indicator in "${RED_INDICATORS[@]}"; do
                if [[ "$lower_username" == *"$indicator"* ]]; then
                    found_users+=("$username")
                    log "SUSPICIOUS USER FOUND: $username"
                    echo "SUSPICIOUS USER: $username" >> "$REPORT_FILE"
                    echo "  UID: $uid" >> "$REPORT_FILE"
                    echo "  Home: $home" >> "$REPORT_FILE"
                    echo "  Shell: $shell" >> "$REPORT_FILE"
                    break
                fi
            done
        fi
    done < /etc/passwd
    
    echo "${#found_users[@]}"
}

# Function to detect suspicious processes
scan_processes() {
    log "Scanning for suspicious processes..."
    local found_processes=()
    
    while read -r pid command; do
        local lower_command=$(echo "$command" | tr '[:upper:]' '[:lower:]')
        
        for indicator in "${RED_INDICATORS[@]}"; do
            if [[ "$lower_command" == *"$indicator"* ]]; then
                found_processes+=("$pid:$command")
                log "SUSPICIOUS PROCESS FOUND: PID $pid - $command"
                echo "SUSPICIOUS PROCESS: PID $pid" >> "$REPORT_FILE"
                echo "  Command: $command" >> "$REPORT_FILE"
                echo "  User: $(ps -o user= -p $pid 2>/dev/null || echo 'unknown')" >> "$REPORT_FILE"
                break
            fi
        done
    done < <(ps -eo pid,comm,args | awk 'NR>1 {print $1, $3}')
    
    echo "${#found_processes[@]}"
}

# Function to display findings and get confirmation
confirm_actions() {
    local file_count=$1
    local user_count=$2
    local process_count=$3
    
    echo -e "\n${YELLOW}=== SCAN RESULTS ===${NC}"
    echo -e "Suspicious files found: ${RED}$file_count${NC}"
    echo -e "Suspicious users found: ${RED}$user_count${NC}"
    echo -e "Suspicious processes found: ${RED}$process_count${NC}"
    
    if [[ $file_count -eq 0 && $user_count -eq 0 && $process_count -eq 0 ]]; then
        echo -e "\n${GREEN}No red team indicators found! System appears clean.${NC}"
        return 1
    fi
    
    echo -e "\n${RED}=== WARNING: AGGRESSIVE REMOVAL MODE ===${NC}"
    echo -e "${RED}This will PERMANENTLY DELETE files and remove user accounts!${NC}"
    echo -e "${RED}This action cannot be undone!${NC}"
    
    read -p "Are you absolutely sure you want to proceed? (type 'DELETE' to confirm): " -r response
    
    if [[ "$response" == "DELETE" ]]; then
        return 0
    else
        echo "Aborting removal operations."
        return 1
    fi
}

# Function to remove suspicious files (AGGRESSIVE - permanent deletion)
remove_suspicious_files() {
    log "PERMANENTLY deleting suspicious files..."
    local deleted_count=0
    
    while IFS= read -r -d '' file; do
        if should_exclude "$(dirname "$file")"; then
            continue
        fi
        
        local filename=$(basename "$file")
        local lower_filename=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
        
        for indicator in "${RED_INDICATORS[@]}"; do
            if [[ "$lower_filename" == *"$indicator"* ]]; then
                echo -e "${RED}DELETING: $file${NC}"
                if rm -f "$file" 2>/dev/null; then
                    log "SUCCESS: Deleted file: $file"
                    echo "DELETED FILE: $file" >> "$REPORT_FILE"
                    ((deleted_count++))
                else
                    log "FAILED: Could not delete file: $file"
                    echo "FAILED TO DELETE: $file" >> "$REPORT_FILE"
                fi
                break
            fi
        done
    done < <(find / -type f -print0 2>/dev/null || true)
    
    echo "Deleted $deleted_count files"
}

# Function to remove suspicious users (AGGRESSIVE - permanent removal)
remove_suspicious_users() {
    log "PERMANENTLY removing suspicious users..."
    local removed_count=0
    
    # Create a list of users to remove first
    local users_to_remove=()
    while IFS=: read -r username _ uid _ _ home shell; do
        if [[ $uid -ge 1000 ]] || [[ $username == "root" ]]; then
            local lower_username=$(echo "$username" | tr '[:upper:]' '[:lower:]')
            
            for indicator in "${RED_INDICATORS[@]}"; do
                if [[ "$lower_username" == *"$indicator"* ]]; then
                    users_to_remove+=("$username")
                    break
                fi
            done
        fi
    done < /etc/passwd
    
    # Remove each user
    for username in "${users_to_remove[@]}"; do
        echo -e "${RED}REMOVING USER: $username${NC}"
        
        # Kill all processes by this user
        log "Killing processes for user: $username"
        pkill -9 -u "$username" 2>/dev/null || true
        sleep 2
        
        # Remove user and home directory
        if userdel -r "$username" 2>/dev/null; then
            log "SUCCESS: Removed user: $username"
            echo "REMOVED USER: $username" >> "$REPORT_FILE"
            ((removed_count++))
        else
            log "FAILED: Could not remove user: $username"
            echo "FAILED TO REMOVE USER: $username" >> "$REPORT_FILE"
            
            # Try alternative removal method
            echo "Attempting alternative removal method..."
            if deluser --remove-home "$username" 2>/dev/null; then
                log "SUCCESS: Removed user (alternative method): $username"
                echo "REMOVED USER (ALT): $username" >> "$REPORT_FILE"
                ((removed_count++))
            else
                log "FAILED: Completely failed to remove user: $username"
                echo "COMPLETELY FAILED TO REMOVE: $username" >> "$REPORT_FILE"
            fi
        fi
    done
    
    echo "Removed $removed_count users"
}

# Function to terminate suspicious processes (AGGRESSIVE)
terminate_suspicious_processes() {
    log "Terminating suspicious processes..."
    local terminated_count=0
    
    # Get current process list
    local processes=()
    while read -r pid command; do
        processes+=("$pid:$command")
    done < <(ps -eo pid,args | awk 'NR>1 {print $1, $2}')
    
    # Terminate matching processes
    for process_info in "${processes[@]}"; do
        local pid=$(echo "$process_info" | cut -d: -f1)
        local command=$(echo "$process_info" | cut -d: -f2-)
        local lower_command=$(echo "$command" | tr '[:upper:]' '[:lower:]')
        
        for indicator in "${RED_INDICATORS[@]}"; do
            if [[ "$lower_command" == *"$indicator"* ]]; then
                echo -e "${RED}TERMINATING PROCESS: PID $pid - $command${NC}"
                if kill -9 "$pid" 2>/dev/null; then
                    log "SUCCESS: Terminated PID $pid"
                    echo "TERMINATED PROCESS: PID $pid - $command" >> "$REPORT_FILE"
                    ((terminated_count++))
                else
                    log "FAILED: Could not terminate PID $pid"
                    echo "FAILED TO TERMINATE: PID $pid - $command" >> "$REPORT_FILE"
                fi
                break
            fi
        done
    done
    
    echo "Terminated $terminated_count processes"
}

# Function to clean up empty directories that might have contained red team files
cleanup_directories() {
    log "Cleaning up empty suspicious directories..."
    local dirs_cleaned=0
    
    while IFS= read -r -d '' dir; do
        if should_exclude "$dir"; then
            continue
        fi
        
        local dirname=$(basename "$dir")
        local lower_dirname=$(echo "$dirname" | tr '[:upper:]' '[:lower:]')
        
        for indicator in "${RED_INDICATORS[@]}"; do
            if [[ "$lower_dirname" == *"$indicator"* ]]; then
                # Check if directory is empty
                if [ -z "$(ls -A "$dir" 2>/dev/null)" ]; then
                    echo "Removing empty directory: $dir"
                    rmdir "$dir" 2>/dev/null && ((dirs_cleaned++)) || true
                fi
                break
            fi
        done
    done < <(find / -type d -print0 2>/dev/null || true)
    
    echo "Cleaned up $dirs_cleaned directories"
}

# Main execution
main() {
    echo -e "${RED}=== BLUE TEAM DEFENSE - AGGRESSIVE MODE ===${NC}"
    echo -e "${RED}WARNING: This script will PERMANENTLY DELETE files and users${NC}"
    echo -e "${RED}with 'red team' indicators in their names!${NC}"
    echo ""
    
    # Run scans
    file_count=$(scan_files)
    user_count=$(scan_users)
    process_count=$(scan_processes)
    
    # Report findings
    echo -e "\n${GREEN}Scan completed. Check $REPORT_FILE for details.${NC}"
    
    # Ask for confirmation before any actions
    if confirm_actions "$file_count" "$user_count" "$process_count"; then
        echo -e "\n${RED}PERFORMING AGGRESSIVE CLEANUP OPERATIONS...${NC}"
        
        # Order of operations is important:
        # 1. First terminate processes
        echo -e "\n${YELLOW}Step 1: Terminating suspicious processes...${NC}"
        terminate_suspicious_processes
        
        # 2. Then remove users (this also kills their processes)
        echo -e "\n${YELLOW}Step 2: Removing suspicious users...${NC}"
        remove_suspicious_users
        
        # 3. Then remove files
        echo -e "\n${YELLOW}Step 3: Deleting suspicious files...${NC}"
        remove_suspicious_files
        
        # 4. Clean up empty directories
        echo -e "\n${YELLOW}Step 4: Cleaning up empty directories...${NC}"
        cleanup_directories
        
        echo -e "\n${GREEN}Aggressive cleanup operations completed.${NC}"
        echo -e "${RED}Files and users have been PERMANENTLY REMOVED.${NC}"
        echo "Detailed report at: $REPORT_FILE"
    else
        echo -e "\n${GREEN}Scan completed without cleanup actions.${NC}"
    fi
    
    log "Blue Team defense scan completed"
    echo -e "\n${GREEN}=== Blue Team Defense Scan Finished ===${NC}"
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    main
else
    echo -e "${RED}This script must be run as root for full system access${NC}"
    echo "Some operations will be limited. Continue? (yes/no)"
    read -r response
    if [[ "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
        main
    else
        exit 1
    fi
fi