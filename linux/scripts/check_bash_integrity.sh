#!/bin/bash

# Bash Integrity Check Script for Blue/Red Team Competitions
# Usage: ./bash_check.sh
# @author Ryan

echo "=================================================="
echo "    Bash Integrity Check - Blue/Red Team"
echo "=================================================="
echo "Timestamp: $(date)"
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

if [[ -z "$IRSEC_REPO_DIR" ]]; then
    IRSEC_REPO_DIR="$(pwd)"
fi
source $IRSEC_REPO_DIR/linux/scripts/blue_team_configuration.sh

log_message() {
    echo "$1" | tee -a "$LOG_FILE"
}

check_command() {
    if ! command -v "$1" &> /dev/null; then
        log_message "${RED}[ERROR] Command $1 not found${NC}"
        return 1
    fi
    return 0
}

# Initial checks
log_message "${YELLOW}[INFO] Starting Bash integrity checks...${NC}"

# 1. Check if /bin/bash exists and basic properties
log_message "\n1. Basic File Properties:"
if [ -e "/bin/bash" ]; then
    log_message "${GREEN}[PASS] /bin/bash exists${NC}"
    
    # File permissions
    perms=$(stat -c "%A %U %G" /bin/bash 2>/dev/null)
    log_message "   Permissions: $perms"
    
    # File size and type
    size=$(stat -c "%s" /bin/bash 2>/dev/null)
    file_type=$(file /bin/bash 2>/dev/null)
    log_message "   Size: $size bytes"
    log_message "   Type: $file_type"
    
    # Check if it's a symlink
    if [ -L "/bin/bash" ]; then
        log_message "${YELLOW}[WARNING] /bin/bash is a symlink${NC}"
        real_path=$(readlink -f /bin/bash)
        log_message "   Real path: $real_path"
    fi
else
    log_message "${RED}[CRITICAL] /bin/bash does not exist!${NC}"
    exit 1
fi

# 2. Check file integrity with hashes
log_message "\n2. File Integrity Hashes:"
check_command "sha256sum" && {
    sha256=$(sha256sum /bin/bash 2>/dev/null | cut -d' ' -f1)
    log_message "   SHA256: $sha256"
}

check_command "md5sum" && {
    md5=$(md5sum /bin/bash 2>/dev/null | cut -d' ' -f1)
    log_message "   MD5:    $md5"
}

# 3. Check dynamic dependencies
log_message "\n3. Dynamic Library Dependencies:"
if check_command "ldd"; then
    ldd_output=$(ldd /bin/bash 2>/dev/null)
    if [ $? -eq 0 ]; then
        log_message "   Dynamic dependencies:"
        echo "$ldd_output" | while read -r line; do
            log_message "   $line"
        done
        
        # Check for missing libraries
        missing_libs=$(ldd /bin/bash 2>/dev/null | grep "not found")
        if [ -n "$missing_libs" ]; then
            log_message "${RED}[ERROR] Missing libraries:${NC}"
            echo "$missing_libs" | while read -r line; do
                log_message "   $line"
            done
        else
            log_message "${GREEN}[PASS] No missing libraries${NC}"
        fi
    fi
fi

# 4. Check binary security features
log_message "\n4. Security Features:"
if check_command "readelf"; then
    # Check for PIE
    readelf -h /bin/bash 2>/dev/null | grep -q "Type.*DYN"
    if [ $? -eq 0 ]; then
        log_message "${GREEN}[PASS] PIE (Position Independent Executable) enabled${NC}"
    else
        log_message "${YELLOW}[WARNING] PIE not enabled${NC}"
    fi
    
    # Check for RELRO
    readelf -l /bin/bash 2>/dev/null | grep -q "GNU_RELRO"
    if [ $? -eq 0 ]; then
        log_message "${GREEN}[PASS] RELRO (Relocation Read-Only) enabled${NC}"
    else
        log_message "${YELLOW}[WARNING] RELRO not fully enabled${NC}"
    fi
    
    # Check for Stack Canary
    readelf -s /bin/bash 2>/dev/null | grep -q "__stack_chk_fail"
    if [ $? -eq 0 ]; then
        log_message "${GREEN}[PASS] Stack canary enabled${NC}"
    else
        log_message "${YELLOW}[WARNING] Stack canary not enabled${NC}"
    fi
    
    # Check for NX
    readelf -l /bin/bash 2>/dev/null | grep -q "GNU_STACK"
    if [ $? -eq 0 ]; then
        nx_bit=$(readelf -l /bin/bash 2>/dev/null | grep "GNU_STACK" | grep -q "RWE")
        if [ $? -eq 0 ]; then
            log_message "${YELLOW}[WARNING] NX bit not enabled${NC}"
        else
            log_message "${GREEN}[PASS] NX (No Execute) bit enabled${NC}"
        fi
    fi
fi

# 5. Check for suspicious strings or modifications
log_message "\n5. Suspicious Content Check:"
if check_command "strings"; then
    suspicious_strings=$(strings /bin/bash 2>/dev/null | grep -i -E "(r00t|backdoor|malware|virus|trojan|exploit|shellcode)")
    if [ -n "$suspicious_strings" ]; then
        log_message "${RED}[SUSPICIOUS] Found potentially malicious strings:${NC}"
        echo "$suspicious_strings" | head -10 | while read -r line; do
            log_message "   $line"
        done
    else
        log_message "${GREEN}[PASS] No obvious malicious strings found${NC}"
    fi
fi

# 6. Check for unusual processes or connections
log_message "\n6. Process and Connection Check:"
# Check if bash is running with unusual privileges
suspicious_processes=$(ps aux 2>/dev/null | grep -E "bash.*-p|bash.*-s" | grep -v grep)
if [ -n "$suspicious_processes" ]; then
    log_message "${YELLOW}[WARNING] Suspicious bash processes:${NC}"
    echo "$suspicious_processes" | while read -r line; do
        log_message "   $line"
    done
fi

# 7. Check bash version and known vulnerabilities
log_message "\n7. Version Information:"
bash_version=$(/bin/bash --version 2>/dev/null | head -1)
log_message "   $bash_version"

# 8. Check file modification time
log_message "\n8. File Timeline:"
mod_time=$(stat -c "%y" /bin/bash 2>/dev/null)
log_message "   Last modified: $mod_time"

# 9. Compare with package manager version (if available)
log_message "\n9. Package Manager Verification:"
if check_command "dpkg"; then
    pkg_info=$(dpkg -S /bin/bash 2>/dev/null)
    if [ $? -eq 0 ]; then
        log_message "   Package: $pkg_info"
        pkg_name=$(echo "$pkg_info" | cut -d: -f1)
        pkg_status=$(dpkg -l "$pkg_name" 2>/dev/null | grep "^ii")
        if [ -n "$pkg_status" ]; then
            log_message "${GREEN}[PASS] Bash is from maintained package${NC}"
        fi
    fi
elif check_command "rpm"; then
    pkg_info=$(rpm -qf /bin/bash 2>/dev/null)
    if [ $? -eq 0 ]; then
        log_message "   Package: $pkg_info"
        log_message "${GREEN}[PASS] Bash is from maintained package${NC}"
    fi
else
    log_message "${YELLOW}[INFO] No package manager found for verification${NC}"
fi

# 10. Check for hidden or additional bash binaries
log_message "\n10. Additional Bash Instances:"
additional_bash=$(find / -name "bash" -type f 2>/dev/null | grep -v "^/bin/bash" | grep -v "^/usr/bin/bash")
if [ -n "$additional_bash" ]; then
    log_message "${YELLOW}[WARNING] Additional bash binaries found:${NC}"
    echo "$additional_bash" | while read -r path; do
        log_message "   $path"
    done
else
    log_message "${GREEN}[PASS] No additional bash binaries found${NC}"
fi

log_message "\n${GREEN}==================================================${NC}"
log_message "${GREEN}Check completed. Log saved to: $LOG_FILE${NC}"
log_message "${GREEN}Review the results and investigate any warnings.${NC}"
log_message "${GREEN}==================================================${NC}"

# Save baseline hashes for future comparison
echo "BASELINE_CREATED: $(date)" >> "$LOG_FILE"
echo "BASH_SHA256: $sha256" >> "$LOG_FILE"
echo "BASH_MD5: $md5" >> "$LOG_FILE"