#!/bin/bash

################################################################################
# CleanMac Core Functions
# Provides core utilities and helper functions
################################################################################

# Color codes for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

# Global variables
DRY_RUN=false
VERBOSE=false
QUIET=false
USE_COLOR=true

# Check if running on macOS
check_os() {
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
}

# Print colored messages
print_info() {
    if [ "$QUIET" = false ]; then
        if [ "$USE_COLOR" = true ]; then
            echo -e "${BLUE}➡️  $1${NC}"
        else
            echo "INFO: $1"
        fi
    fi
}

print_success() {
    if [ "$QUIET" = false ]; then
        if [ "$USE_COLOR" = true ]; then
            echo -e "${GREEN}✅ $1${NC}"
        else
            echo "SUCCESS: $1"
        fi
    fi
}

print_warning() {
    if [ "$USE_COLOR" = true ]; then
        echo -e "${YELLOW}⚠️  $1${NC}"
    else
        echo "WARNING: $1"
    fi
}

print_error() {
    if [ "$USE_COLOR" = true ]; then
        echo -e "${RED}❌ $1${NC}" >&2
    else
        echo "ERROR: $1" >&2
    fi
}

print_tip() {
    if [ "$QUIET" = false ]; then
        if [ "$USE_COLOR" = true ]; then
            echo -e "${CYAN}💡 $1${NC}"
        else
            echo "TIP: $1"
        fi
    fi
}

# Verbose logging
log_verbose() {
    if [ "$VERBOSE" = true ]; then
        echo -e "${MAGENTA}[VERBOSE] $1${NC}"
    fi
}

# Get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $3 " used / " $4 " free (" $5 " used)"}'
}

# Get disk usage in GB (numeric)
get_disk_used_gb() {
    df -g / | awk 'NR==2 {print $3}'
}

get_disk_free_gb() {
    df -g / | awk 'NR==2 {print $4}'
}

get_disk_percent() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# Calculate directory size
get_dir_size() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sh "$dir" 2>/dev/null | awk '{print $1}' || echo "0B"
    else
        echo "0B"
    fi
}

# Calculate directory size in bytes
get_dir_size_bytes() {
    local dir="$1"
    if [ -d "$dir" ]; then
        du -sk "$dir" 2>/dev/null | awk '{print $1 * 1024}' || echo "0"
    else
        echo "0"
    fi
}

# Count files in directory
count_files() {
    local dir="$1"
    if [ -d "$dir" ]; then
        find "$dir" -type f 2>/dev/null | wc -l | tr -d ' '
    else
        echo "0"
    fi
}

# Convert size to human readable
bytes_to_human() {
    local bytes=$1
    if [ "$bytes" -lt 1024 ]; then
        echo "${bytes}B"
    elif [ "$bytes" -lt 1048576 ]; then
        echo "$(( bytes / 1024 ))KB"
    elif [ "$bytes" -lt 1073741824 ]; then
        echo "$(( bytes / 1048576 ))MB"
    else
        echo "$(( bytes / 1073741824 ))GB"
    fi
}

# Parse size string to bytes (e.g., "10MB", "1GB")
parse_size_to_bytes() {
    local size_str="$1"
    local num=$(echo "$size_str" | sed 's/[^0-9.]//g')
    local unit=$(echo "$size_str" | sed 's/[0-9.]//g' | tr '[:lower:]' '[:upper:]')
    
    case "$unit" in
        "KB"|"K")
            echo "$(echo "$num * 1024" | bc | cut -d. -f1)"
            ;;
        "MB"|"M")
            echo "$(echo "$num * 1048576" | bc | cut -d. -f1)"
            ;;
        "GB"|"G")
            echo "$(echo "$num * 1073741824" | bc | cut -d. -f1)"
            ;;
        "B"|"")
            echo "$num"
            ;;
        *)
            echo "0"
            ;;
    esac
}

# Get file age in days
get_file_age_days() {
    local file="$1"
    if [ -e "$file" ]; then
        local now=$(date +%s)
        local mtime=$(stat -f %m "$file" 2>/dev/null)
        if [ -n "$mtime" ]; then
            echo $(( (now - mtime) / 86400 ))
        else
            echo "0"
        fi
    else
        echo "0"
    fi
}

# Check if file is older than N days
is_older_than() {
    local file="$1"
    local days="$2"
    local file_age=$(get_file_age_days "$file")
    [ "$file_age" -gt "$days" ]
}

# Check if directory size is larger than threshold
is_larger_than() {
    local dir="$1"
    local threshold_bytes="$2"
    local dir_size=$(get_dir_size_bytes "$dir")
    [ "$dir_size" -gt "$threshold_bytes" ]
}

# Confirm action with user
confirm() {
    local message="$1"
    local default="${2:-n}"
    
    if [ "$default" = "y" ]; then
        read -p "$message [Y/n]: " -n 1 -r
    else
        read -p "$message [y/N]: " -n 1 -r
    fi
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        return 0
    else
        return 1
    fi
}

# Create directory if it doesn't exist
ensure_dir() {
    local dir="$1"
    if [ ! -d "$dir" ]; then
        mkdir -p "$dir" 2>/dev/null
    fi
}

# Get timestamp for filenames
get_timestamp() {
    date +"%Y-%m-%d_%H-%M-%S"
}

# Get ISO timestamp
get_iso_timestamp() {
    date -u +"%Y-%m-%dT%H:%M:%SZ"
}

# Check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Expand tilde in path
expand_path() {
    local path="$1"
    eval echo "$path"
}

# Sanitize path (remove trailing slash, expand tilde)
sanitize_path() {
    local path="$1"
    path=$(expand_path "$path")
    # Remove trailing slash
    path="${path%/}"
    echo "$path"
}

# Check if path is excluded
is_excluded() {
    local path="$1"
    local exclusions=("$@")
    
    for exclusion in "${exclusions[@]:1}"; do
        if [[ "$path" == $exclusion ]]; then
            return 0
        fi
    done
    return 1
}

# Initialize CleanMac directories
init_cleanmac_dirs() {
    ensure_dir "$HOME/.cleanmac"
    ensure_dir "$HOME/.cleanmac/manifests"
    ensure_dir "$HOME/.cleanmac/reports"
    ensure_dir "$HOME/.cleanmac/backups"
    ensure_dir "$HOME/.cleanmac/cache"
}

# Export functions for use in other scripts
export -f print_info
export -f print_success
export -f print_warning
export -f print_error
export -f print_tip
export -f log_verbose
export -f get_disk_usage
export -f get_dir_size
export -f get_dir_size_bytes
export -f count_files
export -f bytes_to_human
export -f parse_size_to_bytes
export -f get_file_age_days
export -f is_older_than
export -f is_larger_than
export -f confirm
export -f ensure_dir
export -f get_timestamp
export -f get_iso_timestamp
export -f command_exists
export -f sanitize_path
export -f is_excluded
