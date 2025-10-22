#!/bin/bash

# Blue Team Defense - User Account Scanner
# @author Ryan
# Scans for suspicious user accounts

if [[ -z "${IRSEC_REPO_DIR:-}" ]]; then
    IRSEC_REPO_DIR=~/IRSeC-2025/
fi
source $IRSEC_REPO_DIR/linux/scripts/blue_team_configuration.sh



scan_users() {
    log "Starting user account scan..."
    local found_users=()
    
    echo "=== SUSPICIOUS USERS ===" >> "$REPORT_FILE"
    
    while IFS=: read -r username _ uid gid _ home shell; do
        local lower_username=$(echo "$username" | tr '[:upper:]' '[:lower:]')
        
        for indicator in "${RED_INDICATORS[@]}"; do
            if [[ "$lower_username" == *"$indicator"* ]]; then
                found_users+=("$username")
                log "SUSPICIOUS USER FOUND: $username"
                echo "USER: $username" >> "$REPORT_FILE"
                echo "  UID: $uid" >> "$REPORT_FILE"
                echo "  GID: $gid" >> "$REPORT_FILE"
                echo "  Home: $home" >> "$REPORT_FILE"
                echo "  Shell: $shell" >> "$REPORT_FILE"
                echo "  Last Login: $(lastlog -u "$username" 2>/dev/null | tail -1 || echo 'unknown')" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                break
            fi
        done
    done < /etc/passwd
    
    echo "User scan completed: ${#found_users[@]} suspicious users found"
    log "User scan completed: ${#found_users[@]} suspicious users found"
    echo "${#found_users[@]}"
}

main() {
    init_logs
    log "Starting user scanning mode"
    echo -e "${YELLOW}=== USER ACCOUNT SCANNING MODE ===${NC}"
    
    user_count=$(scan_users)
    
    echo -e "\n${YELLOW}=== SCAN RESULTS ===${NC}"
    echo -e "Suspicious users found: ${RED}$user_count${NC}"
    echo -e "Detailed report: $REPORT_FILE"
    
    if [[ $user_count -eq 0 ]]; then
        echo -e "\n${GREEN}No suspicious users detected!${NC}"
    else
        echo -e "\n${YELLOW}Review suspicious users before taking any action.${NC}"
    fi
}

main