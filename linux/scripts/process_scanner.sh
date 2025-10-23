#!/bin/bash

# Improved version
source ./blue_team_configuration.sh


improved_scan_processes() {
    log "Starting process scan..."
    local found_processes=()
    
    echo "=== SUSPICIOUS PROCESSES ===" >> "$REPORT_FILE"
    
    # Input validation
    if [[ -z "$REPORT_FILE" || -z "${RED_INDICATORS[@]}" ]]; then
        log "ERROR: Missing required configuration"
        return 1
    fi
    
    # Get all process info in single call
    while IFS= read -r line; do
        local pid=$(echo "$line" | awk '{print $1}')
        local user=$(echo "$line" | awk '{print $2}')
        local command=$(echo "$line" | cut -d' ' -f6-)
        local lower_command=$(echo "$command" | tr '[:upper:]' '[:lower:]')
        
        # Verify process still exists
        if ! kill -0 "$pid" 2>/dev/null; then
            continue
        fi
        
        for indicator in "${RED_INDICATORS[@]}"; do
            local lower_indicator=$(echo "$indicator" | tr '[:upper:]' '[:lower:]')
            
            # Use word boundaries for exact matching
            if echo "$lower_command" | grep -qw "$lower_indicator"; then
                found_processes+=("$pid:$command")
                log "SUSPICIOUS PROCESS FOUND: PID $pid - $command"
                
                # Append to report safely
                {
                    echo "PROCESS: PID $pid"
                    echo "  User: $user"
                    echo "  Command: $command"
                    echo "  Start Time: $(ps -o lstart= -p "$pid" 2>/dev/null || echo 'unknown')"
                    echo "  CPU: $(ps -o %cpu= -p "$pid" 2>/dev/null || echo 'unknown')%"
                    echo "  Memory: $(ps -o %mem= -p "$pid" 2>/dev/null || echo 'unknown')%"
                    echo ""
                } >> "$REPORT_FILE"
                break
            fi
        done
    done < <(ps -eo pid,user,args --no-headers 2>/dev/null | awk '{print $1, $2, substr($0, index($0,$3))}')
    
    echo "Process scan completed: ${#found_processes[@]} suspicious processes found"
    log "Process scan completed: ${#found_processes[@]} suspicious processes found"
    echo "${#found_processes[@]}"
}


improved_scan_processes