#!/bin/bash

################################################################################
# CleanMac UI Components
# Provides user interface functions and interactive elements
################################################################################

# Draw a horizontal line
draw_line() {
    local char="${1:--}"
    local width="${2:-66}"
    printf '%*s\n' "$width" | tr ' ' "$char"
}

# Draw a box around text
draw_box() {
    local text="$1"
    local width=66
    
    echo "╔$(draw_line '=' $((width-2)))╗"
    printf "║ %-$((width-4))s ║\n" "$text"
    echo "╚$(draw_line '=' $((width-2)))╝"
}

# Print header
print_header() {
    echo ""
    draw_box "🧹 CleanMac — macOS Developer System Cleaner"
    echo "📊 Disk before cleanup: $(get_disk_usage)"
    echo ""
}

# Print footer with results
print_footer() {
    local space_freed="$1"
    echo ""
    echo "🚀 Cleanup complete!"
    echo "📊 Disk after cleanup: $(get_disk_usage)"
    if [ -n "$space_freed" ]; then
        echo "✨ Space freed: $space_freed"
    fi
    echo "✨ Your Mac is now lighter and faster!"
    echo ""
}

# Show loading spinner
show_spinner() {
    local pid=$1
    local message="${2:-Processing...}"
    local spin='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    local i=0
    
    while kill -0 $pid 2>/dev/null; do
        i=$(( (i+1) %10 ))
        printf "\r${spin:$i:1} $message"
        sleep .1
    done
    printf "\r"
}

# Show progress bar
show_progress() {
    local current=$1
    local total=$2
    local width=50
    local percentage=$((current * 100 / total))
    local filled=$((current * width / total))
    local empty=$((width - filled))
    
    printf "\r["
    printf "%${filled}s" | tr ' ' '█'
    printf "%${empty}s" | tr ' ' '░'
    printf "] %d%% (%d/%d)" "$percentage" "$current" "$total"
}

# Interactive menu
show_menu() {
    echo ""
    echo "Choose what to clean:"
    echo ""
    echo "1)  Project folders (node_modules, .next, dist, build)"
    echo "2)  Package manager caches (npm, yarn, pnpm)"
    echo "3)  Homebrew cache"
    echo "4)  Xcode DerivedData and device support"
    echo "5)  CocoaPods cache"
    echo "6)  App caches (VSCode, Chrome, Discord, Slack)"
    echo "7)  Docker cleanup"
    echo "8)  User/system cache and logs"
    echo "9)  Trash, Downloads, temp"
    echo "10) Large cache files"
    echo "11) Desktop screenshots"
    echo "12) Run ALL"
    echo "0)  Exit"
    echo ""
}

# Show file selection interface
show_file_selection() {
    local -n items=$1  # nameref to array
    local selected=()
    local current=0
    
    # Initialize all as selected
    for i in "${!items[@]}"; do
        selected[$i]=1
    done
    
    while true; do
        clear
        echo "╔════════════════════════════════════════════════════════════════╗"
        echo "║  Select items to delete (Space to toggle, Enter to confirm)   ║"
        echo "╠════════════════════════════════════════════════════════════════╣"
        
        for i in "${!items[@]}"; do
            local marker=" "
            if [ "${selected[$i]}" = "1" ]; then
                marker="✓"
            fi
            
            local arrow="  "
            if [ "$i" = "$current" ]; then
                arrow="→ "
            fi
            
            echo "$arrow[$marker] ${items[$i]}"
        done
        
        echo "╚════════════════════════════════════════════════════════════════╝"
        echo ""
        echo "Commands: [Space] Toggle  [A] All  [N] None  [Enter] Confirm  [Q] Cancel"
        
        read -rsn1 key
        case "$key" in
            " ")  # Space - toggle current
                if [ "${selected[$current]}" = "1" ]; then
                    selected[$current]=0
                else
                    selected[$current]=1
                fi
                ;;
            "A"|"a")  # Select all
                for i in "${!items[@]}"; do
                    selected[$i]=1
                done
                ;;
            "N"|"n")  # Select none
                for i in "${!items[@]}"; do
                    selected[$i]=0
                done
                ;;
            "Q"|"q")  # Cancel
                return 1
                ;;
            "")  # Enter - confirm
                # Return selected indices
                for i in "${!selected[@]}"; do
                    if [ "${selected[$i]}" = "1" ]; then
                        echo "$i"
                    fi
                done
                return 0
                ;;
        esac
    done
}

# Show tree view of directories
show_tree() {
    local root="$1"
    local prefix="${2:-}"
    local max_depth="${3:-3}"
    local current_depth="${4:-0}"
    
    if [ "$current_depth" -ge "$max_depth" ]; then
        return
    fi
    
    if [ ! -d "$root" ]; then
        return
    fi
    
    local items=($(ls -A "$root" 2>/dev/null))
    local total=${#items[@]}
    
    for i in "${!items[@]}"; do
        local item="${items[$i]}"
        local path="$root/$item"
        local is_last=$((i == total - 1))
        
        local connector="├─"
        local extension="│  "
        if [ "$is_last" = 1 ]; then
            connector="└─"
            extension="   "
        fi
        
        if [ -d "$path" ]; then
            echo "${prefix}${connector} 📁 $item"
            show_tree "$path" "${prefix}${extension}" "$max_depth" $((current_depth + 1))
        else
            echo "${prefix}${connector} 📄 $item"
        fi
    done
}

# Show pre-deletion preview with details
show_deletion_preview() {
    local -n files_array=$1  # nameref to array
    local total_size=0
    local total_count=${#files_array[@]}
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Deletion Preview                                              ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    
    for file in "${files_array[@]}"; do
        if [ -e "$file" ]; then
            local size=$(get_dir_size "$file")
            local age=$(get_file_age_days "$file")
            local status="✅"
            
            if [ "$age" -lt 7 ]; then
                status="⚠️ "
            fi
            
            printf "║  %s %-40s %8s %4dd ║\n" "$status" "$(basename "$file")" "$size" "$age"
            
            local size_bytes=$(get_dir_size_bytes "$file")
            total_size=$((total_size + size_bytes))
        fi
    done
    
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  Total: %d items, %s                                    ║\n" \
        "$total_count" "$(bytes_to_human $total_size)"
    echo "╚════════════════════════════════════════════════════════════════╝"
    echo ""
    echo "Legend: ✅ Safe to delete  ⚠️  Recently modified"
}

# Show summary table
show_summary_table() {
    local -n data=$1  # nameref to associative array
    
    echo "╔════════════════════════════════════════════════════════════════╗"
    echo "║  Cleanup Summary                                               ║"
    echo "╠════════════════════════════════════════════════════════════════╣"
    printf "║  %-30s %10s %10s ║\n" "Category" "Files" "Size"
    echo "╠════════════════════════════════════════════════════════════════╣"
    
    for category in "${!data[@]}"; do
        printf "║  %-30s %10s %10s ║\n" \
            "$category" \
            "${data[$category,files]}" \
            "${data[$category,size]}"
    done
    
    echo "╚════════════════════════════════════════════════════════════════╝"
}

# Show confirmation dialog with details
show_confirmation() {
    local category="$1"
    local file_count="$2"
    local total_size="$3"
    local details="$4"
    
    echo ""
    echo "⚠️  CONFIRMATION REQUIRED"
    echo ""
    echo "You are about to delete:"
    echo "├─ Category: $category"
    echo "├─ Files: $file_count"
    echo "└─ Total size: $total_size"
    
    if [ -n "$details" ]; then
        echo ""
        echo "Details:"
        echo "$details" | head -10
        if [ "$(echo "$details" | wc -l)" -gt 10 ]; then
            echo "... and $(($(echo "$details" | wc -l) - 10)) more items"
        fi
    fi
    
    echo ""
    echo "⚠️  This action cannot be easily undone"
    echo ""
}

# Export functions
export -f draw_line
export -f draw_box
export -f print_header
export -f print_footer
export -f show_spinner
export -f show_progress
export -f show_menu
export -f show_tree
export -f show_deletion_preview
export -f show_summary_table
export -f show_confirmation
