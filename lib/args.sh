#!/bin/bash

################################################################################
# CleanMac - Argument Parsing Module
# Handles command-line argument parsing and validation
################################################################################

# Source required modules
if [ -z "$CLEANMAC_CORE_LOADED" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/core.sh"
fi

# Global argument variables
SCAN_PATHS=()
SCAN_RECURSIVE=true
SCAN_DEPTH=-1  # -1 means unlimited
ONLY_TARGETS=()
EXCLUDE_PATTERNS=()
MAX_AGE_DAYS=-1  # -1 means no age filter
MIN_SIZE_BYTES=0
DRY_RUN=false
VERBOSE=false
QUIET=false
INTERACTIVE=true
AUTO_YES=false
CONFIG_FILE=""
PRESET=""

# Parse command-line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            # Path-specific scanning
            -p|--path)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --path requires a directory argument"
                    exit 1
                fi
                # Use readlink if realpath not available (macOS default)
                if command -v realpath &> /dev/null; then
                    SCAN_PATHS+=("$(realpath "$1")")
                else
                    SCAN_PATHS+=("$(cd "$1" && pwd)")
                fi
                shift
                ;;
            
            --paths)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --paths requires comma-separated directories"
                    exit 1
                fi
                IFS=',' read -ra PATHS <<< "$1"
                for path in "${PATHS[@]}"; do
                    path=$(echo "$path" | xargs)  # trim whitespace
                    if command -v realpath &> /dev/null; then
                        SCAN_PATHS+=("$(realpath "$path")")
                    else
                        SCAN_PATHS+=("$(cd "$path" && pwd)")
                    fi
                done
                shift
                ;;
            
            -d|--depth)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --depth requires a number"
                    exit 1
                fi
                if ! [[ "$1" =~ ^[0-9]+$ ]]; then
                    print_error "Error: --depth must be a positive number"
                    exit 1
                fi
                SCAN_DEPTH="$1"
                shift
                ;;
            
            --no-recursive)
                SCAN_RECURSIVE=false
                shift
                ;;
            
            # Filtering options
            --only)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --only requires target types"
                    exit 1
                fi
                IFS=',' read -ra TARGETS <<< "$1"
                for target in "${TARGETS[@]}"; do
                    ONLY_TARGETS+=("$(echo "$target" | xargs)")
                done
                shift
                ;;
            
            --exclude)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --exclude requires patterns"
                    exit 1
                fi
                IFS=',' read -ra PATTERNS <<< "$1"
                for pattern in "${PATTERNS[@]}"; do
                    EXCLUDE_PATTERNS+=("$(echo "$pattern" | xargs)")
                done
                shift
                ;;
            
            --max-age)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --max-age requires a number (days)"
                    exit 1
                fi
                if ! [[ "$1" =~ ^[0-9]+$ ]]; then
                    print_error "Error: --max-age must be a positive number"
                    exit 1
                fi
                MAX_AGE_DAYS="$1"
                shift
                ;;
            
            --min-size)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --min-size requires a size (e.g., 100MB)"
                    exit 1
                fi
                MIN_SIZE_BYTES=$(parse_size_to_bytes "$1")
                if [ $? -ne 0 ]; then
                    print_error "Error: Invalid size format: $1"
                    exit 1
                fi
                shift
                ;;
            
            # Execution modes
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            
            -y|--yes)
                AUTO_YES=true
                INTERACTIVE=false
                shift
                ;;
            
            -n|--non-interactive)
                INTERACTIVE=false
                shift
                ;;
            
            # Output options
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            
            -q|--quiet)
                QUIET=true
                shift
                ;;
            
            # Configuration
            -c|--config)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --config requires a file path"
                    exit 1
                fi
                if command -v realpath &> /dev/null; then
                    CONFIG_FILE="$(realpath "$1")"
                else
                    CONFIG_FILE="$(cd "$(dirname "$1")" && pwd)/$(basename "$1")"
                fi
                if [ ! -f "$CONFIG_FILE" ]; then
                    print_error "Error: Config file not found: $CONFIG_FILE"
                    exit 1
                fi
                shift
                ;;
            
            --preset)
                shift
                if [ -z "$1" ]; then
                    print_error "Error: --preset requires a preset name"
                    exit 1
                fi
                PRESET="$1"
                shift
                ;;
            
            # Help and version
            -h|--help)
                show_help
                exit 0
                ;;
            
            -V|--version)
                show_version
                exit 0
                ;;
            
            # Unknown option
            -*)
                print_error "Unknown option: $1"
                show_help
                exit 1
                ;;
            
            # Positional argument (treat as path)
            *)
                if command -v realpath &> /dev/null; then
                    SCAN_PATHS+=("$(realpath "$1")")
                else
                    SCAN_PATHS+=("$(cd "$1" && pwd)")
                fi
                shift
                ;;
        esac
    done
    
    # Validate arguments
    validate_arguments
}

# Validate parsed arguments
validate_arguments() {
    # If no paths specified, use current directory
    if [ ${#SCAN_PATHS[@]} -eq 0 ]; then
        SCAN_PATHS=("$HOME")
    fi
    
    # Validate all paths exist
    for path in "${SCAN_PATHS[@]}"; do
        if [ ! -d "$path" ]; then
            print_error "Error: Directory not found: $path"
            exit 1
        fi
    done
    
    # Warn if both verbose and quiet are set
    if [ "$VERBOSE" = true ] && [ "$QUIET" = true ]; then
        print_warning "Warning: Both --verbose and --quiet specified. Defaulting to quiet mode."
        VERBOSE=false
    fi
    
    # Warn about dry-run mode
    if [ "$DRY_RUN" = true ]; then
        print_info "Running in DRY-RUN mode - no files will be deleted"
    fi
}

# Show help message
show_help() {
    cat << EOF
${GREEN}CleanMac${NC} - Ultimate macOS Cleanup CLI Tool

${BLUE}USAGE:${NC}
    cleanmac [OPTIONS] [PATHS...]

${BLUE}PATH OPTIONS:${NC}
    -p, --path <DIR>           Scan specific directory
    --paths <DIR1,DIR2,...>    Scan multiple directories (comma-separated)
    -d, --depth <N>            Limit scan depth (0 = current level only)
    --no-recursive             Don't scan subdirectories

${BLUE}FILTER OPTIONS:${NC}
    --only <TYPE1,TYPE2,...>   Only scan specific targets (e.g., node_modules,cache)
    --exclude <PAT1,PAT2,...>  Exclude patterns (e.g., .git,important-*)
    --max-age <DAYS>           Only include files older than N days
    --min-size <SIZE>          Only include files larger than SIZE (e.g., 100MB, 1GB)

${BLUE}EXECUTION OPTIONS:${NC}
    --dry-run                  Show what would be deleted without deleting
    -y, --yes                  Skip confirmation prompts
    -n, --non-interactive      Run without interactive menus

${BLUE}OUTPUT OPTIONS:${NC}
    -v, --verbose              Show detailed output
    -q, --quiet                Minimize output

${BLUE}CONFIGURATION:${NC}
    -c, --config <FILE>        Use custom config file
    --preset <NAME>            Use preset configuration (web-dev, mobile-dev, etc.)

${BLUE}OTHER:${NC}
    -h, --help                 Show this help message
    -V, --version              Show version information

${BLUE}EXAMPLES:${NC}
    # Interactive mode (default)
    cleanmac

    # Scan specific directory
    cleanmac --path ~/Desktop

    # Scan multiple directories for old node_modules
    cleanmac --paths ~/Projects,~/Desktop --only node_modules --max-age 30

    # Dry-run to preview deletions
    cleanmac --dry-run --only cache,logs

    # Clean specific directory with size filter
    cleanmac --path ~/Downloads --min-size 100MB

    # Use preset with depth limit
    cleanmac --preset web-dev --depth 3

    # Non-interactive mode with filters
    cleanmac --non-interactive --only node_modules,cache --max-age 60 --yes

${BLUE}DOCUMENTATION:${NC}
    GitHub: https://github.com/shade-solutions/cleanmac
    Issues: https://github.com/shade-solutions/cleanmac/issues

EOF
}

# Show version information
show_version() {
    cat << EOF
CleanMac v0.2.0-alpha
Platform: macOS
License: MIT
Author: Shaswat Raj (Shade Solutions)
GitHub: https://github.com/shade-solutions/cleanmac
EOF
}

# Get argument summary for display
get_args_summary() {
    local summary=""
    
    # Scan paths
    if [ ${#SCAN_PATHS[@]} -gt 0 ]; then
        summary+="Scan Paths: "
        for path in "${SCAN_PATHS[@]}"; do
            summary+="$path "
        done
        summary+="\n"
    fi
    
    # Depth
    if [ "$SCAN_DEPTH" -ge 0 ]; then
        summary+="Scan Depth: $SCAN_DEPTH\n"
    fi
    
    # Only targets
    if [ ${#ONLY_TARGETS[@]} -gt 0 ]; then
        summary+="Only Scanning: ${ONLY_TARGETS[*]}\n"
    fi
    
    # Exclusions
    if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
        summary+="Excluding: ${EXCLUDE_PATTERNS[*]}\n"
    fi
    
    # Age filter
    if [ "$MAX_AGE_DAYS" -ge 0 ]; then
        summary+="Max Age: $MAX_AGE_DAYS days\n"
    fi
    
    # Size filter
    if [ "$MIN_SIZE_BYTES" -gt 0 ]; then
        summary+="Min Size: $(bytes_to_human "$MIN_SIZE_BYTES")\n"
    fi
    
    # Dry run
    if [ "$DRY_RUN" = true ]; then
        summary+="Mode: DRY-RUN (no deletions)\n"
    fi
    
    echo -e "$summary"
}

# Export functions for use in other modules
export -f parse_arguments
export -f validate_arguments
export -f show_help
export -f show_version
export -f get_args_summary
