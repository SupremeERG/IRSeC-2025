#!/bin/bash

# Blue Team Defense - Process Scanner
# @author Ryan
# Scans for suspicious running processes

source ./blue_team_config.sh

scan_processes() {
    log "Starting process scan..."
    local found_processes=()
    
    echo "=== SUSPICIOUS PROCESSES ===" >> "$REPORT_FILE"
    
    while read -r pid user command; do
        local lower_command=$(echo "$command" | tr '[:upper:]' '[:lower:]')
        
        for indicator in "${RED_INDICATORS[@]}"; do
            if [[ "$lower_command" == *"$indicator"* ]]; then
                found_processes+=("$pid:$command")
                log "SUSPICIOUS PROCESS FOUND: PID $pid - $command"
                echo "PROCESS: PID $pid" >> "$REPORT_FILE"
                echo "  User: $user" >> "$REPORT_FILE"
                echo "  Command: $command" >> "$REPORT_FILE"
                echo "  Start Time: $(ps -o lstart= -p $pid 2>/dev/null || echo 'unknown')" >> "$REPORT_FILE"
                echo "  CPU: $(ps -o %cpu= -p $pid 2>/dev/null || echo 'unknown')%" >> "$REPORT_FILE"
                echo "  Memory: $(ps -o %mem= -p $pid 2>/dev/null || echo 'unknown')%" >> "$REPORT_FILE"
                echo "" >> "$REPORT_FILE"
                break
            fi
        done
    done < <(ps -eo pid,user,args --no-headers | awk '{print $1, $2, substr($0, index($0,$3))}')
    
    echo "Process scan completed: ${#found_processes[@]} suspicious processes found"
    log "Process scan completed: ${#found_processes[@]} suspicious processes found"
    echo "${#found_processes[@]}"
}

main() {
    init_logs
    log "Starting process scanning mode"
    echo -e "${YELLOW}=== PROCESS SCANNING MODE ===${NC}"
    
    process_count=$(scan_processes)
    
    echo -e "\n${YELLOW}=== SCAN RESULTS ===${NC}"
    echo -e "Suspicious processes found: ${RED}$process_count${NC}"
    echo -e "Detailed report: $REPORT_FILE"
    
    if [[ $process_count -eq 0 ]]; then
        echo -e "\n${GREEN}No suspicious processes detected!${NC}"
    else
        echo -e "\n${YELLOW}Investigate these processes before termination.${NC}"
    fi
}

main