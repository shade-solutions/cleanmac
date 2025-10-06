#!/bin/bash

################################################################################
# CleanMac - Scanner Module
# Implements intelligent file and directory scanning with filtering
################################################################################

# Source required modules
if [ -z "$CLEANMAC_CORE_LOADED" ]; then
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
    source "${SCRIPT_DIR}/core.sh"
fi

# Scan result structure (stored in arrays)
declare -a SCAN_RESULTS_PATHS
declare -a SCAN_RESULTS_SIZES
declare -a SCAN_RESULTS_TYPES
declare -a SCAN_RESULTS_AGES

# Common cleanup targets - simple array for bash 3.2 compatibility
CLEANUP_TARGETS_NAMES=(
    "node_modules"
    ".npm"
    ".yarn"
    "bower_components"
    "vendor"
    "Pods"
    "build"
    "dist"
    ".gradle"
    ".m2"
    "target"
    "__pycache__"
    ".pytest_cache"
    "*.pyc"
    ".cache"
    "cache"
    "tmp"
    "temp"
    ".DS_Store"
    ".Trash"
    "*.log"
    "*.tmp"
)

# Scan directories based on current arguments
# Uses global variables: SCAN_PATHS, SCAN_DEPTH, ONLY_TARGETS, EXCLUDE_PATTERNS, etc.
scan_directories() {
    local total_found=0
    local total_size=0
    
    # Clear previous results
    SCAN_RESULTS_PATHS=()
    SCAN_RESULTS_SIZES=()
    SCAN_RESULTS_TYPES=()
    SCAN_RESULTS_AGES=()
    
    if [ "$VERBOSE" = true ]; then
        print_info "Starting directory scan..."
        print_info "Paths: ${SCAN_PATHS[*]}"
        [ "$SCAN_DEPTH" -ge 0 ] && print_info "Max depth: $SCAN_DEPTH"
        [ ${#ONLY_TARGETS[@]} -gt 0 ] && print_info "Only targets: ${ONLY_TARGETS[*]}"
    fi
    
    # Scan each path
    for scan_path in "${SCAN_PATHS[@]}"; do
        if [ ! -d "$scan_path" ]; then
            print_warning "Skipping non-existent path: $scan_path"
            continue
        fi
        
        if [ "$QUIET" = false ]; then
            print_info "Scanning: $scan_path"
        fi
        
        # Build find command based on arguments
        local find_cmd="find \"$scan_path\""
        
        # Add depth limit
        if [ "$SCAN_DEPTH" -ge 0 ]; then
            find_cmd+=" -maxdepth $SCAN_DEPTH"
        fi
        
        # Add type (directory or file)
        if [ ${#ONLY_TARGETS[@]} -gt 0 ]; then
            # Search for specific targets
            for target in "${ONLY_TARGETS[@]}"; do
                scan_for_target "$scan_path" "$target"
            done
        else
            # General scan for common cleanup targets
            scan_common_targets "$scan_path"
        fi
    done
    
    if [ "$VERBOSE" = true ]; then
        print_success "Scan complete. Found ${#SCAN_RESULTS_PATHS[@]} items"
    fi
    
    return 0
}

# Scan for a specific target type
scan_for_target() {
    local base_path="$1"
    local target="$2"
    local depth_opt=""
    
    if [ "$SCAN_DEPTH" -ge 0 ]; then
        depth_opt="-maxdepth $SCAN_DEPTH"
    fi
    
    # Determine if target is a directory or file pattern
    if [[ "$target" == *.* ]] || [[ "$target" == \** ]]; then
        # File pattern
        scan_file_pattern "$base_path" "$target" "$depth_opt"
    else
        # Directory name
        scan_directory_name "$base_path" "$target" "$depth_opt"
    fi
}

# Scan for directories with specific name
scan_directory_name() {
    local base_path="$1"
    local dir_name="$2"
    local depth_opt="$3"
    
    while IFS= read -r -d '' dir; do
        # Apply filters
        if ! should_include_item "$dir"; then
            continue
        fi
        
        # Get metadata
        local size=$(get_dir_size_bytes "$dir")
        local age=$(get_file_age_days "$dir")
        
        # Add to results
        SCAN_RESULTS_PATHS+=("$dir")
        SCAN_RESULTS_SIZES+=("$size")
        SCAN_RESULTS_TYPES+=("$dir_name")
        SCAN_RESULTS_AGES+=("$age")
        
        if [ "$VERBOSE" = true ]; then
            print_info "  Found: $dir ($(bytes_to_human "$size"), ${age}d old)"
        fi
    done < <(find "$base_path" $depth_opt -type d -name "$dir_name" -print0 2>/dev/null)
}

# Scan for files matching pattern
scan_file_pattern() {
    local base_path="$1"
    local pattern="$2"
    local depth_opt="$3"
    
    while IFS= read -r -d '' file; do
        # Apply filters
        if ! should_include_item "$file"; then
            continue
        fi
        
        # Get metadata
        local size=$(stat -f%z "$file" 2>/dev/null || echo 0)
        local age=$(get_file_age_days "$file")
        
        # Add to results
        SCAN_RESULTS_PATHS+=("$file")
        SCAN_RESULTS_SIZES+=("$size")
        SCAN_RESULTS_TYPES+=("$pattern")
        SCAN_RESULTS_AGES+=("$age")
        
        if [ "$VERBOSE" = true ]; then
            print_info "  Found: $file ($(bytes_to_human "$size"), ${age}d old)"
        fi
    done < <(find "$base_path" $depth_opt -type f -name "$pattern" -print0 2>/dev/null)
}

# Scan for common cleanup targets
scan_common_targets() {
    local base_path="$1"
    
    for target in "${CLEANUP_TARGETS_NAMES[@]}"; do
        if [[ "$target" == *.* ]] || [[ "$target" == \** ]]; then
            # File pattern
            scan_for_target "$base_path" "$target"
        else
            # Directory
            scan_for_target "$base_path" "$target"
        fi
    done
}

# Check if item should be included based on filters
should_include_item() {
    local item="$1"
    
    # Check exclusion patterns
    if [ ${#EXCLUDE_PATTERNS[@]} -gt 0 ]; then
        for pattern in "${EXCLUDE_PATTERNS[@]}"; do
            if [[ "$item" == *"$pattern"* ]]; then
                [ "$VERBOSE" = true ] && print_info "  Excluded (pattern): $item"
                return 1
            fi
        done
    fi
    
    # Check age filter
    if [ "$MAX_AGE_DAYS" -ge 0 ]; then
        if ! is_older_than "$item" "$MAX_AGE_DAYS"; then
            [ "$VERBOSE" = true ] && print_info "  Excluded (age): $item"
            return 1
        fi
    fi
    
    # Check size filter
    if [ "$MIN_SIZE_BYTES" -gt 0 ]; then
        local item_size=0
        if [ -d "$item" ]; then
            item_size=$(get_dir_size_bytes "$item")
        else
            item_size=$(stat -f%z "$item" 2>/dev/null || echo 0)
        fi
        
        if [ "$item_size" -lt "$MIN_SIZE_BYTES" ]; then
            [ "$VERBOSE" = true ] && print_info "  Excluded (size): $item"
            return 1
        fi
    fi
    
    return 0
}

# Get total size of all scan results
get_scan_total_size() {
    local total=0
    for size in "${SCAN_RESULTS_SIZES[@]}"; do
        total=$((total + size))
    done
    echo "$total"
}

# Get count of scan results
get_scan_count() {
    echo "${#SCAN_RESULTS_PATHS[@]}"
}

# Print scan results summary
print_scan_summary() {
    local total_count="${#SCAN_RESULTS_PATHS[@]}"
    local total_size=$(get_scan_total_size)
    
    echo ""
    draw_box "Scan Results"
    echo ""
    
    if [ "$total_count" -eq 0 ]; then
        print_info "No items found matching the criteria"
        return
    fi
    
    print_info "Total items found: $total_count"
    print_info "Total size: $(bytes_to_human "$total_size")"
    echo ""
    
    # Group by type
    declare -A type_counts
    declare -A type_sizes
    
    for i in "${!SCAN_RESULTS_PATHS[@]}"; do
        local type="${SCAN_RESULTS_TYPES[$i]}"
        local size="${SCAN_RESULTS_SIZES[$i]}"
        
        if [ -z "${type_counts[$type]}" ]; then
            type_counts[$type]=0
            type_sizes[$type]=0
        fi
        
        type_counts[$type]=$((type_counts[$type] + 1))
        type_sizes[$type]=$((type_sizes[$type] + size))
    done
    
    # Print breakdown
    print_info "Breakdown by type:"
    for type in "${!type_counts[@]}"; do
        local count="${type_counts[$type]}"
        local size="${type_sizes[$type]}"
        printf "  %-20s %5d items   %10s\n" \
            "$type:" "$count" "$(bytes_to_human "$size")"
    done
    
    echo ""
}

# Print detailed scan results
print_scan_details() {
    if [ "${#SCAN_RESULTS_PATHS[@]}" -eq 0 ]; then
        return
    fi
    
    echo ""
    print_info "Detailed results:"
    echo ""
    
    for i in "${!SCAN_RESULTS_PATHS[@]}"; do
        local path="${SCAN_RESULTS_PATHS[$i]}"
        local size="${SCAN_RESULTS_SIZES[$i]}"
        local type="${SCAN_RESULTS_TYPES[$i]}"
        local age="${SCAN_RESULTS_AGES[$i]}"
        
        printf "  [%s] %s\n" "$type" "$path"
        printf "      Size: %-10s  Age: %d days\n" "$(bytes_to_human "$size")" "$age"
    done
    
    echo ""
}

# Clear scan results
clear_scan_results() {
    SCAN_RESULTS_PATHS=()
    SCAN_RESULTS_SIZES=()
    SCAN_RESULTS_TYPES=()
    SCAN_RESULTS_AGES=()
}

# Export functions
export -f scan_directories
export -f scan_for_target
export -f scan_directory_name
export -f scan_file_pattern
export -f scan_common_targets
export -f should_include_item
export -f get_scan_total_size
export -f get_scan_count
export -f print_scan_summary
export -f print_scan_details
export -f clear_scan_results

# Export arrays (bash 4.4+ feature, fallback for older versions)
if [ "${BASH_VERSINFO[0]}" -ge 4 ] && [ "${BASH_VERSINFO[1]}" -ge 4 ]; then
    export SCAN_RESULTS_PATHS
    export SCAN_RESULTS_SIZES
    export SCAN_RESULTS_TYPES
    export SCAN_RESULTS_AGES
fi
