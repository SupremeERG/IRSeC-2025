#!/bin/bash

# Blue Team Defense - File Scanner
# @author Ryan
# Scans for suspicious files but does NOT remove them

if [[ -z "${IRSEC_REPO_DIR:-}" ]]; then
    IRSEC_REPO_DIR=~/IRSeC-2025/
fi
source $IRSEC_REPO_DIR/linux/scripts/blue_team_configuration.sh

scan_files() {
    log "Starting file system scan..."
    local found_files=()
    local scan_count=0
    
    echo "=== SUSPICIOUS FILES ===" >> "$REPORT_FILE"
    
    # Define important directories to scan (common attack targets)
    local important_dirs=(
        "/home"
        "/root"
        "/tmp"
        "/var/tmp"
        "/etc"
        "/opt"
        "/usr/local"
        "/var/www"
        "/var/log"
        "/var/spool"
        "/dev/shm"
        "/run/user"
        "$(pwd)"
    )
    
    # Add current user's home directory if not already included
    local user_home="$HOME"
    if [[ ! " ${important_dirs[@]} " =~ " ${user_home} " ]]; then
        important_dirs+=("$user_home")
    fi
    
    log "Scanning important directories: ${important_dirs[*]}"
    
    for dir in "${important_dirs[@]}"; do
        if [[ ! -d "$dir" ]]; then
            continue
        fi
        
        log "Scanning directory: $dir"
        echo -e "\n${YELLOW}Scanning: $dir${NC}"
        
        while IFS= read -r -d '' file; do
            ((scan_count++))
            
            if should_exclude "$(dirname "$file")"; then
                continue
            fi
            
            local filename=$(basename "$file")
            local lower_filename=$(echo "$filename" | tr '[:upper:]' '[:lower:]')
            
            for indicator in "${RED_INDICATORS[@]}"; do
                if [[ "$lower_filename" == *"$indicator"* ]]; then
                    found_files+=("$file")
                    log "SUSPICIOUS FILE FOUND: $file"
                    echo "FILE: $file" >> "$REPORT_FILE"
                    echo "  Size: $(ls -lh "$file" 2>/dev/null | awk '{print $5}' || echo 'unknown')" >> "$REPORT_FILE"
                    echo "  Permissions: $(ls -ld "$file" 2>/dev/null | awk '{print $1}' || echo 'unknown')" >> "$REPORT_FILE"
                    echo "  Owner: $(ls -ld "$file" 2>/dev/null | awk '{print $3}' || echo 'unknown')" >> "$REPORT_FILE"
                    echo "  Modified: $(ls -ld "$file" 2>/dev/null | awk '{print $6, $7, $8}' || echo 'unknown')" >> "$REPORT_FILE"
                    echo "" >> "$REPORT_FILE"
                    break
                fi
            done
            
            # Progress indicator for large scans
            if (( scan_count % 500 == 0 )); then
                echo -ne "Scanned $scan_count files... Found ${#found_files[@]} suspicious\r"
            fi
        done < <(find "$dir" -type f -print0 2>/dev/null || true)
    done
    
    echo -e "\nFile scan completed: ${#found_files[@]} suspicious files found"
    log "File scan completed: ${#found_files[@]} suspicious files found out of $scan_count scanned"
    echo "${#found_files[@]}"
}

main() {
    init_logs
    log "Starting file scanning mode"
    echo -e "${YELLOW}=== FILE SCANNING MODE ===${NC}"
    echo -e "${GREEN}This will scan for suspicious files but NOT remove them${NC}"
    echo -e "${YELLOW}Scanning important directories only (not entire filesystem)${NC}"
    
    file_count=$(scan_files)
    
    echo -e "\n${YELLOW}=== SCAN RESULTS ===${NC}"
    echo -e "Suspicious files found: ${RED}$file_count${NC}"
    echo -e "Detailed report: $REPORT_FILE"
    echo -e "Log file: $LOG_FILE"
    
    if [[ $file_count -eq 0 ]]; then
        echo -e "\n${GREEN}No suspicious files detected!${NC}"
    else
        echo -e "\n${YELLOW}Review the report and consider manual investigation before removal.${NC}"
    fi
}

# Check if running as root
if [[ $EUID -eq 0 ]]; then
    main
else
    echo -e "${RED}Run as root for complete file system access${NC}"
    read -p "Continue with limited access? (yes/no): " -r response
    if [[ "$response" =~ ^[Yy][Ee][Ss]$ ]]; then
        main
    else
        exit 1
    fi
fi