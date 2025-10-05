#!/usr/bin/env bash

# CleanMac - Ultimate macOS Cleanup CLI Tool
# Author: Shaswat Raj (Shade Solutions)
# License: MIT
# Platform: macOS (Intel, M1, M2, M3)

set -e

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored output
print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_arrow() {
    echo -e "${BLUE}➡️  $1${NC}"
}

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $3 " used / " $4 " free (" $5 " used)"}'
}

# Function to calculate freed space
calculate_freed_space() {
    local before=$1
    local after=$2
    local freed=$((before - after))
    if [ $freed -gt 1024 ]; then
        echo "$((freed / 1024)) GB"
    else
        echo "${freed} MB"
    fi
}

# Function to safely remove directory/file
safe_remove() {
    local path=$1
    if [ -e "$path" ]; then
        rm -rf "$path" 2>/dev/null || {
            print_warning "Could not remove $path (may need sudo)"
            return 1
        }
        return 0
    fi
    return 1
}

# Function to clean project folders
clean_project_folders() {
    print_arrow "Cleaning project folders (node_modules, .next, .nuxt, .expo, .vercel, dist, build)..."
    
    local count=0
    local patterns=("node_modules" ".next" ".nuxt" ".expo" ".vercel" "dist" "build")
    
    for pattern in "${patterns[@]}"; do
        while IFS= read -r dir; do
            if safe_remove "$dir"; then
                ((count++))
            fi
        done < <(find ~ -type d -name "$pattern" -not -path "*/Library/*" -not -path "*/.Trash/*" 2>/dev/null || true)
    done
    
    print_success "Removed $count project folder(s)"
}

# Function to clean package manager caches
clean_package_managers() {
    print_arrow "Cleaning package manager caches (npm, yarn, pnpm)..."
    
    # npm cache
    if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null || print_warning "Could not clean npm cache"
        print_success "npm cache cleaned"
    fi
    
    # yarn cache
    if command -v yarn &> /dev/null; then
        yarn cache clean 2>/dev/null || print_warning "Could not clean yarn cache"
        print_success "yarn cache cleaned"
    fi
    
    # pnpm store
    if command -v pnpm &> /dev/null; then
        pnpm store prune 2>/dev/null || print_warning "Could not prune pnpm store"
        print_success "pnpm store pruned"
    fi
}

# Function to clean Homebrew
clean_homebrew() {
    print_arrow "Cleaning Homebrew cache..."
    
    if command -v brew &> /dev/null; then
        brew cleanup -s 2>/dev/null || print_warning "Could not run brew cleanup"
        rm -rf "$(brew --cache)" 2>/dev/null || true
        print_success "Homebrew cleaned"
    else
        print_warning "Homebrew not installed, skipping"
    fi
}

# Function to clean Xcode
clean_xcode() {
    print_arrow "Cleaning Xcode DerivedData and device support..."
    
    local count=0
    
    # DerivedData
    if [ -d ~/Library/Developer/Xcode/DerivedData ]; then
        rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null && ((count++))
    fi
    
    # iOS DeviceSupport
    if [ -d ~/Library/Developer/Xcode/iOS\ DeviceSupport ]; then
        rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/* 2>/dev/null && ((count++))
    fi
    
    # Archives
    if [ -d ~/Library/Developer/Xcode/Archives ]; then
        rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null && ((count++))
    fi
    
    print_success "Cleaned $count Xcode cache location(s)"
}

# Function to clean CocoaPods
clean_cocoapods() {
    print_arrow "Cleaning CocoaPods cache..."
    
    if command -v pod &> /dev/null; then
        pod cache clean --all 2>/dev/null || print_warning "Could not clean pod cache"
        rm -rf ~/Library/Caches/CocoaPods 2>/dev/null || true
        print_success "CocoaPods cache cleaned"
    else
        print_warning "CocoaPods not installed, skipping"
    fi
}

# Function to clean app caches
clean_app_caches() {
    print_arrow "Cleaning app caches (VSCode, Chrome, Discord, Slack)..."
    
    local apps=(
        "$HOME/Library/Application Support/Code/Cache"
        "$HOME/Library/Application Support/Code/CachedData"
        "$HOME/Library/Application Support/Google/Chrome/Default/Cache"
        "$HOME/Library/Caches/Google/Chrome"
        "$HOME/Library/Application Support/Discord/Cache"
        "$HOME/Library/Application Support/Discord/Code Cache"
        "$HOME/Library/Application Support/Slack/Cache"
        "$HOME/Library/Application Support/Slack/Code Cache"
    )
    
    local count=0
    for app in "${apps[@]}"; do
        if [ -e "$app" ]; then
            rm -rf "$app" 2>/dev/null && ((count++))
        fi
    done
    
    print_success "Cleaned $count app cache location(s)"
}

# Function to clean Docker
clean_docker() {
    print_arrow "Cleaning Docker images and containers..."
    
    if command -v docker &> /dev/null; then
        docker system prune -a -f 2>/dev/null || print_warning "Could not prune Docker"
        print_success "Docker cleaned"
    else
        print_warning "Docker not installed, skipping"
    fi
}

# Function to clean system caches and logs
clean_system_caches() {
    print_arrow "Cleaning user/system cache and logs..."
    
    local count=0
    
    # User caches
    if [ -d ~/Library/Caches ]; then
        find ~/Library/Caches -type f -atime +30 -delete 2>/dev/null && ((count++))
    fi
    
    # User logs
    if [ -d ~/Library/Logs ]; then
        rm -rf ~/Library/Logs/* 2>/dev/null && ((count++))
    fi
    
    # System logs (requires sudo)
    if sudo -n true 2>/dev/null; then
        sudo rm -rf /private/var/log/* 2>/dev/null && ((count++))
    else
        print_warning "Skipping system logs (needs sudo)"
    fi
    
    print_success "Cleaned system caches and logs"
}

# Function to clean trash and downloads
clean_trash_downloads() {
    print_arrow "Emptying Trash and cleaning Downloads..."
    
    # Empty trash
    rm -rf ~/.Trash/* 2>/dev/null || true
    
    # Clean Downloads (older than 30 days)
    if [ -d ~/Downloads ]; then
        find ~/Downloads -type f -atime +30 -delete 2>/dev/null || true
    fi
    
    # Clean temp
    rm -rf /tmp/* 2>/dev/null || true
    
    print_success "Trash emptied and Downloads cleaned"
}

# Function to find and clean large cache files
clean_large_files() {
    print_arrow "Finding and cleaning cache files larger than 1 GB..."
    
    local count=0
    local cache_dirs=(
        "$HOME/Library/Caches"
        "$HOME/Library/Application Support"
    )
    
    for dir in "${cache_dirs[@]}"; do
        if [ -d "$dir" ]; then
            while IFS= read -r file; do
                if safe_remove "$file"; then
                    ((count++))
                fi
            done < <(find "$dir" -type f -size +1G 2>/dev/null || true)
        fi
    done
    
    print_success "Removed $count large cache file(s)"
}

# Function to clean desktop screenshots
clean_screenshots() {
    print_arrow "Cleaning old screenshots from Desktop..."
    
    local count=0
    if [ -d ~/Desktop ]; then
        while IFS= read -r file; do
            if safe_remove "$file"; then
                ((count++))
            fi
        done < <(find ~/Desktop -name "Screenshot*.png" -o -name "Screen Shot*.png" 2>/dev/null || true)
    fi
    
    print_success "Removed $count screenshot(s)"
}

# Function to run all cleanup operations
run_all_cleanup() {
    print_info "Running ALL cleanup operations..."
    echo ""
    
    clean_project_folders
    clean_package_managers
    clean_homebrew
    clean_xcode
    clean_cocoapods
    clean_app_caches
    clean_docker
    clean_system_caches
    clean_trash_downloads
    clean_large_files
    clean_screenshots
}

# Function to display menu
show_menu() {
    echo ""
    echo "🧹 CleanMac — macOS Developer System Cleaner"
    echo "-----------------------------------------------"
    echo ""
    echo "Choose cleanup option:"
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

# Main function
main() {
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    
    # Display initial disk usage
    echo ""
    echo "🧹 CleanMac — macOS Developer System Cleaner"
    echo "-----------------------------------------------"
    print_info "Disk before cleanup:  $(get_disk_usage)"
    
    # Get initial disk usage in KB
    local disk_before=$(df -k / | awk 'NR==2 {print $3}')
    
    # Interactive menu loop
    while true; do
        show_menu
        read -p "Enter your choice [0-12]: " choice
        echo ""
        
        case $choice in
            1)
                clean_project_folders
                ;;
            2)
                clean_package_managers
                ;;
            3)
                clean_homebrew
                ;;
            4)
                clean_xcode
                ;;
            5)
                clean_cocoapods
                ;;
            6)
                clean_app_caches
                ;;
            7)
                clean_docker
                ;;
            8)
                clean_system_caches
                ;;
            9)
                clean_trash_downloads
                ;;
            10)
                clean_large_files
                ;;
            11)
                clean_screenshots
                ;;
            12)
                run_all_cleanup
                ;;
            0)
                print_info "Exiting CleanMac. Goodbye!"
                break
                ;;
            *)
                print_error "Invalid option. Please choose 0-12."
                ;;
        esac
        
        echo ""
        read -p "Press Enter to continue..."
    done
    
    # Get final disk usage in KB
    local disk_after=$(df -k / | awk 'NR==2 {print $3}')
    
    # Display final results
    echo ""
    echo "🚀 Cleanup complete!"
    print_info "Disk after cleanup:   $(get_disk_usage)"
    
    # Calculate and show freed space
    local freed=$((disk_before - disk_after))
    if [ $freed -gt 0 ]; then
        local freed_gb=$(echo "scale=2; $freed / 1024 / 1024" | bc 2>/dev/null || echo "0")
        print_success "Freed approximately ${freed_gb} GB"
    fi
    
    echo ""
    echo "✨ Your Mac is now lighter and faster!"
    echo ""
}

# Run main function
main
