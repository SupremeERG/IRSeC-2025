#!/usr/bin/env bash
# bash_check.sh - Robust Bash Integrity & Sanity Checker for competition boxes
# Author: Ryan (refactor)
# Usage: ./bash_check.sh
# Notes:
#  - Script will re-exec itself under bash if invoked with sh/dash.
#  - Optionally place a blue_team_configuration.sh in the same dir to override LOG_FILE/REPORT_FILE/Baseline path.
#  - Safe to run on Kali or disposable competition VMs. Avoid destructive tests unless you snapshot first.

set -euo pipefail
IFS=$'\n\t'

# ----- Force bash (re-exec) -----
if [ -z "${BASH_VERSION:-}" ]; then
  exec /usr/bin/env bash "$0" "$@"
fi

# ----- Defaults (can be overridden by ./blue_team_configuration.sh) -----
: "${LOG_FILE:=/var/log/blue_team_defense.log}"
: "${REPORT_FILE:=/var/log/blue_team_report_$(date +%Y%m%d_%H%M%S).txt}"
: "${BASELINE_FILE:=/var/lib/blue_team/bash_baseline.json}"
: "${SCOPE_DIRS:=/bin:/usr/bin:/usr/local/bin}"
: "${EXTRA_SEARCH_DIRS:=/sbin:/usr/sbin}"   # will search limited dirs for extra bash copies
: "${RED_INDICATORS:=('redteam' 'red_team' 'red-team' 'red team')}"

# Colors (only for console)
RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
YELLOW=$'\033[1;33m'
BLUE=$'\033[0;34m'
NC=$'\033[0m'

# If a local config file exists, source it (portable '.' used)
if [ -f ./blue_team_configuration.sh ]; then
  # shellcheck disable=SC1091
  . ./blue_team_configuration.sh
fi

# ----- Helpers -----
strip_ansi() { sed -r 's/\x1B\[[0-9;]*[mK]//g'; }

# console prints colored; log gets stripped
cprint() { printf "%b\n" "$1"; printf "%s\n" "$1" | strip_ansi >> "$LOG_FILE"; }
info()   { cprint "${GREEN}[INFO]${NC} $1"; }
warn()   { cprint "${YELLOW}[WARN]${NC} $1"; }
error()  { cprint "${RED}[ERROR]${NC} $1"; }
section(){ cprint "${BLUE}==> $1${NC}"; }

ensure_writable_log() {
  local dir
  dir=$(dirname "$LOG_FILE")
  if [ ! -d "$dir" ]; then
    mkdir -p "$dir" 2>/dev/null || true
  fi
  # If not writable, fallback to cwd files
  if ! touch "$LOG_FILE" >/dev/null 2>&1; then
    LOG_FILE="./bash_check.log"
    REPORT_FILE="./bash_check_report_$(date +%Y%m%d_%H%M%S).txt"
    BASELINE_FILE="./bash_baseline.json"
    warn "Log directory not writable; falling back to local files: $LOG_FILE"
  fi
}

init_logs() {
  ensure_writable_log
  : > "$LOG_FILE"
  : > "$REPORT_FILE"
  printf "=== Bash Integrity Check Started: %s ===\n" "$(date '+%Y-%m-%d %H:%M:%S')" >> "$LOG_FILE"
  printf "Log: %s\nReport: %s\nBaseline: %s\n\n" "$LOG_FILE" "$REPORT_FILE" "$BASELINE_FILE" | strip_ansi >> "$LOG_FILE"
  cprint "${GREEN}Starting Bash integrity checks...${NC}"
}

# Check for a program's existence
have_cmd() { command -v "$1" >/dev/null 2>&1; }

# Safe readers
safe_stat() { stat --printf="$2" "$1" 2>/dev/null || echo "N/A"; }

# Read baseline JSON into associative arrays (simple parser)
load_baseline() {
  OLD_SHA256="N/A"
  OLD_MD5="N/A"
  if [ -f "$BASELINE_FILE" ]; then
    # naive JSON parse - safe because we control format
    OLD_SHA256=$(grep -Po '"sha256":\s*"\K[^"]+' "$BASELINE_FILE" 2>/dev/null || echo "N/A")
    OLD_MD5=$(grep -Po '"md5":\s*"\K[^"]+' "$BASELINE_FILE" 2>/dev/null || echo "N/A")
  fi
}

save_baseline() {
  mkdir -p "$(dirname "$BASELINE_FILE")" 2>/dev/null || true
  cat > "$BASELINE_FILE" <<EOF
{
  "created":"$(date -Iseconds)",
  "path":"/bin/bash",
  "sha256":"${sha256:-N/A}",
  "md5":"${md5:-N/A}"
}
EOF
  printf "Saved baseline to %s\n" "$BASELINE_FILE" | strip_ansi >> "$LOG_FILE"
}

# Compare baseline values and write to report
compare_baseline() {
  if [ -f "$BASELINE_FILE" ]; then
    echo "Baseline comparison:" >> "$REPORT_FILE"
    if [ "$sha256" != "$OLD_SHA256" ]; then
      echo "  WARNING: SHA256 changed (baseline vs current)" >> "$REPORT_FILE"
      warn "SHA256 differed from baseline"
    else
      echo "  OK: SHA256 matches baseline" >> "$REPORT_FILE"
      info "SHA256 matches baseline"
    fi
    if [ "$md5" != "$OLD_MD5" ]; then
      echo "  NOTICE: MD5 changed (baseline vs current)" >> "$REPORT_FILE"
    fi
  else
    echo "No baseline present; baseline will be created." >> "$REPORT_FILE"
    save_baseline
  fi
}

# Print a short divider
hr() { printf "%s\n" "------------------------------------------------------------" | strip_ansi >> "$LOG_FILE"; printf "%s\n" "------------------------------------------------------------"; }

# ----- Begin checks -----
init_logs
hr

# 1) Existence & basic properties
section "1) /bin/bash existence and basic properties"
if [ ! -e /bin/bash ]; then
  error "/bin/bash does not exist!"
  echo "FAILED: /bin/bash missing" >> "$REPORT_FILE"
  exit 2
fi

if [ ! -x /bin/bash ]; then
  warn "/bin/bash is not executable"
fi

# file type + ELF check
file_out=$(file -L /bin/bash 2>/dev/null || echo "unknown")
printf "   file: %s\n" "$file_out"
printf "   file: %s\n" "$file_out" | strip_ansi >> "$LOG_FILE"
if echo "$file_out" | grep -qi 'ELF'; then
  info "/bin/bash is an ELF binary"
else
  warn "/bin/bash is not an ELF binary (suspicious wrapper or script?)"
fi

# ownership and perms
stat_perms=$(stat -c "%a %U %G" /bin/bash 2>/dev/null || echo "N/A")
printf "   perms/owner: %s\n" "$stat_perms" | tee >(strip_ansi >> "$LOG_FILE") >/dev/null

if [ "$(stat -c "%U" /bin/bash)" != "root" ]; then
  warn "/bin/bash owner is not root (expected root)"
fi

# SUID or SGID
mode_oct=$(stat -c "%a" /bin/bash 2>/dev/null || echo "000")
if [ "${mode_oct:0:1}" != "0" ]; then
  warn "/bin/bash has special permissions (SUID/SGID) - mode: $mode_oct"
fi

# capabilities
if have_cmd getcap; then
  caps=$(getcap /bin/bash 2>/dev/null || true)
  [ -n "$caps" ] && warn "File capabilities: $caps"
fi

# 2) Check for wrappers/fakes earlier in PATH or in common locations
section "2) PATH hijack / duplicate 'bash' binaries"
# capture PATH at time of run
IFS=':' read -r -a PATH_DIRS <<< "${PATH:-/usr/local/bin:/usr/bin:/bin}"
found_early=0
for d in "${PATH_DIRS[@]}"; do
  # stop when we reach /bin (the canonical location)
  if [ "$d" = "/bin" ]; then
    break
  fi
  if [ -x "$d/bash" ]; then
    warn "Executable 'bash' found earlier in PATH: $d/bash"
    found_early=1
    printf "   %s\n" "$d/bash" | strip_ansi >> "$LOG_FILE"
  fi
done
# Search common dirs for odd bash binaries (but avoid full FS)
for d in $(printf "%s" "$SCOPE_DIRS:$EXTRA_SEARCH_DIRS" | tr ':' ' '); do
  if [ -x "$d/bash" ] && [ "$d" != "/bin" ] && [ "$d" != "/usr/bin" ]; then
    warn "Non-standard bash binary: $d/bash"
    printf "   %s\n" "$d/bash" | strip_ansi >> "$LOG_FILE"
  fi
done

if [ "$found_early" -eq 0 ]; then
  info "No PATH hijack with earlier 'bash' detected"
fi

# 3) Is /bin/sh pointing to dash or something else? (competition boxes sometimes replace /bin/sh)
section "3) /bin/sh symlink sanity"
if [ -L /bin/sh ]; then
  sh_target=$(readlink -f /bin/sh || echo "")
  printf "   /bin/sh -> %s\n" "$sh_target"
  printf "   /bin/sh -> %s\n" "$sh_target" | strip_ansi >> "$LOG_FILE"
  if [ "$sh_target" = "/bin/dash" ]; then
    info "/bin/sh points to dash (normal on Debian/Kali)"
  else
    warn "/bin/sh points to non-standard shell: $sh_target"
  fi
else
  warn "/bin/sh is not a symlink; unexpected"
fi

# 4) Hashes / baseline
section "4) Hashes (SHA256 / MD5) and baseline comparison"
sha256="N/A"
md5="N/A"
if have_cmd sha256sum; then
  sha256=$(sha256sum /bin/bash 2>/dev/null | awk '{print $1}' || echo "N/A")
  printf "   SHA256: %s\n" "$sha256" | strip_ansi >> "$LOG_FILE"
else
  warn "sha256sum not available"
fi
if have_cmd md5sum; then
  md5=$(md5sum /bin/bash 2>/dev/null | awk '{print $1}' || echo "N/A")
  printf "   MD5:    %s\n" "$md5" | strip_ansi >> "$LOG_FILE"
fi

load_baseline
compare_baseline

# 5) Dynamic dependencies / ldd warnings
section "5) Dynamic dependencies (ldd)"
if have_cmd ldd; then
  # ldd can be dangerous on untrusted ELFs; but /bin/bash on a sane system is fine
  ldd_out=$(ldd /bin/bash 2>&1 || true)
  printf "%s\n" "$ldd_out" | sed 's/^/   /' | tee -a "$LOG_FILE"
  if echo "$ldd_out" | grep -qi 'not found'; then
    error "Missing shared libraries detected for /bin/bash"
    echo "$ldd_out" | grep -i 'not found' | sed 's/^/   /' | tee -a "$REPORT_FILE"
  else
    info "No missing shared libraries detected"
  fi
else
  warn "ldd not found; cannot check dynamic libs"
fi

# 6) ELF sanity: stripped? unusual sections? (heuristic)
section "6) ELF sanity checks"
if have_cmd readelf; then
  # check for GNU_RELRO + BIND_NOW
  if readelf -l /bin/bash 2>/dev/null | grep -q 'GNU_RELRO'; then
    if readelf -d /bin/bash 2>/dev/null | grep -q 'BIND_NOW'; then
      info "Full RELRO present"
    else
      warn "Partial RELRO (GNU_RELRO present but BIND_NOW not)"
    fi
  else
    warn "No RELRO"
  fi
  # stack-protector symbol presence
  if readelf -s /bin/bash 2>/dev/null | grep -q '__stack_chk_fail'; then
    info "Stack-canary symbol detected"
  else
    warn "No stack-canary symbol detected"
  fi
  # GNU_STACK flags for NX
  if readelf -l /bin/bash 2>/dev/null | grep -q 'GNU_STACK'; then
    gline=$(readelf -l /bin/bash 2>/dev/null | awk '/GNU_STACK/ {print $0}')
    if echo "$gline" | grep -q 'RWE'; then
      warn "Executable stack flagged (RWE) - NX disabled"
    else
      info "NX (non-exec stack) appears enabled"
    fi
  fi

  # stripped check (many ELFs are stripped; warn only if suspicious)
  if readelf -S /bin/bash 2>/dev/null | grep -q '.symtab'; then
    info "Symbol table present (not stripped)"
  else
    warn "Binary appears stripped (may be normal in distribution builds)"
  fi
else
  warn "readelf missing; skip ELF deep checks"
fi

# 7) Suspicious strings
section "7) Quick strings scan for common indicators"
if have_cmd strings; then
  matches=$(strings /bin/bash 2>/dev/null | tr '[:upper:]' '[:lower:]' | egrep "$(printf "%s|" "${RED_INDICATORS[@]}" | sed 's/|$//')" || true)
  if [ -n "$matches" ]; then
    warn "Suspicious indicators found inside binary (grep output saved)"
    printf "%s\n" "$matches" | sed 's/^/   /' | tee -a "$REPORT_FILE" >> "$LOG_FILE"
  else
    info "No obvious red-indicator strings found"
  fi
else
  warn "strings not available; cannot scan binary contents"
fi

# 8) Running processes that look odd
section "8) Running processes: suspicious bash invocation patterns"
ps_out=$(ps aux 2>/dev/null)
suspicious_ps=$(printf "%s\n" "$ps_out" | grep -E 'bash .*(-p|-s|--noprofile|--norc)' || true)
if [ -n "$suspicious_ps" ]; then
  warn "Suspicious bash processes found:"
  printf "%s\n" "$suspicious_ps" | sed 's/^/   /' | tee -a "$REPORT_FILE" >> "$LOG_FILE"
else
  info "No obviously suspicious bash processes"
fi

# 9) Environmental hijacks
section "9) Environment checks (LD_PRELOAD, LD_LIBRARY_PATH, PATH order)"
if [ -n "${LD_PRELOAD:-}" ]; then
  warn "LD_PRELOAD set in environment: $LD_PRELOAD"
fi
if [ -n "${LD_LIBRARY_PATH:-}" ]; then
  warn "LD_LIBRARY_PATH set: $LD_LIBRARY_PATH"
fi
# PATH order verification already partially done. Log PATH.
printf "   PATH: %s\n" "${PATH}" | strip_ansi >> "$LOG_FILE"

# 10) Package manager verification
section "10) Package verification (dpkg/rpm)"
if have_cmd dpkg; then
  pkg=$(dpkg -S /bin/bash 2>/dev/null | head -1 || true)
  if [ -n "$pkg" ]; then
    info "Bash package: $pkg"
    if have_cmd debsums; then
      if debsums -s bash >/dev/null 2>&1; then
        info "debsums OK for package 'bash'"
      else
        warn "debsums reported changes for 'bash'"
      fi
    fi
  else
    warn "dpkg couldn't resolve /bin/bash to a package"
  fi
elif have_cmd rpm; then
  pkg=$(rpm -qf /bin/bash 2>/dev/null || true)
  if [ -n "$pkg" ]; then
    info "Bash package: $pkg"
    if rpm -Vf /bin/bash >/dev/null 2>&1; then
      info "rpm verification cleaned (no changed files)"
    else
      warn "rpm verification flagged changes"
    fi
  else
    warn "rpm couldn't map /bin/bash to a package"
  fi
else
  warn "No package manager tools detected to validate package integrity"
fi

# 11) Quick sanity checks & heuristics
section "11) Heuristics & quick sanity checks"
# Is /bin/bash symlinked to something odd?
if [ -L /bin/bash ]; then
  rp=$(readlink -f /bin/bash || echo "")
  warn "/bin/bash is a symlink -> $rp"
fi

# any unusual hardlinks (same inode in odd place)? (search limited dirs)
inode=$(stat -c "%i" /bin/bash 2>/dev/null || echo "0")
if [ "$inode" != "0" ]; then
  # find files with same inode in /bin /usr/bin /usr/local/bin
  same_inode=$(find /bin /usr/bin /usr/local/bin -xdev -inum "$inode" 2>/dev/null || true)
  if echo "$same_inode" | grep -v "/bin/bash" >/dev/null 2>&1; then
    warn "Other files share inode with /bin/bash: $(echo "$same_inode" | sed 's/^/   /')"
  fi
fi

# 12) Search for wrapper scripts named 'bash' that are not ELF
section "12) Look for wrapper scripts in PATH that masquerade as bash"
for p in $(printf "%s" "${PATH}" | tr ':' ' '); do
  [ -z "$p" ] && continue
  candidate="$p/bash"
  if [ -f "$candidate" ] && [ ! -x "$candidate" ]; then
    : # skip non-executable
  elif [ -f "$candidate" ] && [ -x "$candidate" ]; then
    ftype=$(file -L "$candidate" 2>/dev/null || echo "")
    if echo "$ftype" | grep -qi 'text'; then
      warn "Wrapper/script named 'bash' in PATH: $candidate (text/script)"
      printf "   %s\n" "$ftype" | strip_ansi >> "$LOG_FILE"
    fi
  fi
done

# 13) Summarize & Baseline save if none existed
section "Summary & Baseline"
printf "SHA256: %s\nMD5: %s\n" "${sha256:-N/A}" "${md5:-N/A}" >> "$REPORT_FILE"
if [ ! -f "$BASELINE_FILE" ]; then
  info "No baseline present; creating one for future runs"
  save_baseline
else
  info "Baseline present at $BASELINE_FILE (compared above)"
fi

# final footer
hr
info "Integrity check complete. Report saved to: $REPORT_FILE"
info "Detailed log saved to: $LOG_FILE"
hr
