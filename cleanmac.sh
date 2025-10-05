#!/bin/bash

################################################################################
# CleanMac — Ultimate macOS Cleanup CLI Tool
# Author: Shaswat Raj (Shade Solutions)
# GitHub: https://github.com/shade-solutions/cleanmac
# License: MIT
# Platform: macOS (Intel, M1, M2, M3)
################################################################################

set -e

# Color codes for better terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to print colored messages
print_info() {
    echo -e "${BLUE}➡️  $1${NC}"
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

# Function to get disk usage
get_disk_usage() {
    df -h / | awk 'NR==2 {print $3 " used / " $4 " free (" $5 " used)"}'
}

# Function to calculate directory size
get_dir_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | awk '{print $1}' || echo "0B"
    else
        echo "0B"
    fi
}

# Header
print_header() {
    echo ""
    echo "🧹 CleanMac — macOS Developer System Cleaner"
    echo "-----------------------------------------------"
    echo "📊 Disk before cleanup: $(get_disk_usage)"
    echo ""
}

# Clean project folders (node_modules, .next, dist, build, etc.)
clean_project_folders() {
    print_info "Cleaning project folders (node_modules, .next, dist, build, .expo, .vercel, .nuxt)..."
    
    local dirs=("node_modules" ".next" ".nuxt" ".expo" ".vercel" "dist" "build" ".turbo")
    local total_cleaned=0
    
    for dir in "${dirs[@]}"; do
        while IFS= read -r -d '' folder; do
            size=$(du -sk "$folder" 2>/dev/null | awk '{print $1}')
            rm -rf "$folder" 2>/dev/null && total_cleaned=$((total_cleaned + size))
        done < <(find ~/Desktop ~/Documents ~/Projects ~ -maxdepth 5 -type d -name "$dir" -print0 2>/dev/null)
    done
    
    print_success "Done — cleaned project folders"
}

# Clean package manager caches
clean_package_caches() {
    print_info "Cleaning package manager caches (npm, yarn, pnpm)..."
    
    # npm cache
    if command -v npm &> /dev/null; then
        npm cache clean --force 2>/dev/null || true
    fi
    
    # yarn cache
    if command -v yarn &> /dev/null; then
        yarn cache clean 2>/dev/null || true
    fi
    
    # pnpm cache
    if command -v pnpm &> /dev/null; then
        pnpm store prune 2>/dev/null || true
    fi
    
    print_success "Done — cleaned package manager caches"
}

# Clean Homebrew cache
clean_homebrew() {
    print_info "Cleaning Homebrew cache..."
    
    if command -v brew &> /dev/null; then
        brew cleanup -s 2>/dev/null || true
        rm -rf "$(brew --cache)" 2>/dev/null || true
    else
        print_warning "Homebrew not found, skipping"
    fi
    
    print_success "Done — cleaned Homebrew"
}

# Clean Xcode DerivedData and device support
clean_xcode() {
    print_info "Cleaning Xcode DerivedData and iOS DeviceSupport..."
    
    rm -rf ~/Library/Developer/Xcode/DerivedData/* 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/iOS\ DeviceSupport/* 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/watchOS\ DeviceSupport/* 2>/dev/null || true
    rm -rf ~/Library/Developer/Xcode/Archives/* 2>/dev/null || true
    
    print_success "Done — cleaned Xcode"
}

# Clean CocoaPods cache
clean_cocoapods() {
    print_info "Cleaning CocoaPods cache..."
    
    rm -rf ~/Library/Caches/CocoaPods 2>/dev/null || true
    
    if command -v pod &> /dev/null; then
        pod cache clean --all 2>/dev/null || true
    fi
    
    print_success "Done — cleaned CocoaPods"
}

# Clean app caches (VSCode, Chrome, Discord, Slack)
clean_app_caches() {
    print_info "Cleaning app caches (VSCode, Chrome, Discord, Slack)..."
    
    # VSCode
    rm -rf ~/Library/Caches/com.microsoft.VSCode 2>/dev/null || true
    rm -rf ~/.vscode/extensions/*/node_modules 2>/dev/null || true
    
    # Chrome
    rm -rf ~/Library/Caches/Google/Chrome 2>/dev/null || true
    
    # Discord
    rm -rf ~/Library/Caches/com.hnc.Discord 2>/dev/null || true
    rm -rf ~/Library/Application\ Support/Discord/Cache 2>/dev/null || true
    rm -rf ~/Library/Application\ Support/Discord/Code\ Cache 2>/dev/null || true
    
    # Slack
    rm -rf ~/Library/Caches/com.tinyspeck.slackmacgap 2>/dev/null || true
    rm -rf ~/Library/Application\ Support/Slack/Cache 2>/dev/null || true
    rm -rf ~/Library/Application\ Support/Slack/Code\ Cache 2>/dev/null || true
    
    print_success "Done — cleaned app caches"
}

# Clean Docker
clean_docker() {
    print_info "Cleaning Docker (images, containers, volumes)..."
    
    if command -v docker &> /dev/null; then
        docker system prune -a -f --volumes 2>/dev/null || true
    else
        print_warning "Docker not found, skipping"
    fi
    
    print_success "Done — cleaned Docker"
}

# Clean user and system caches and logs
clean_system_caches() {
    print_info "Cleaning user and system caches and logs..."
    
    # User caches
    rm -rf ~/Library/Caches/* 2>/dev/null || true
    
    # User logs
    rm -rf ~/Library/Logs/* 2>/dev/null || true
    
    # System logs (requires sudo)
    if [ "$EUID" -eq 0 ]; then
        rm -rf /private/var/log/* 2>/dev/null || true
        rm -rf /Library/Logs/* 2>/dev/null || true
    else
        print_warning "Skipping system logs (requires sudo)"
    fi
    
    print_success "Done — cleaned caches and logs"
}

# Clean trash, downloads, and temp files
clean_trash_downloads() {
    print_info "Cleaning Trash, Downloads, and temporary files..."
    
    # Empty Trash
    rm -rf ~/.Trash/* 2>/dev/null || true
    
    # Clean Downloads (optional - be careful!)
    read -p "⚠️  Do you want to delete ALL files in Downloads? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf ~/Downloads/* 2>/dev/null || true
        print_success "Downloads folder cleaned"
    else
        print_info "Skipping Downloads folder"
    fi
    
    # Temp files
    rm -rf /tmp/* 2>/dev/null || true
    rm -rf ~/Library/Application\ Support/CrashReporter/* 2>/dev/null || true
    
    print_success "Done — cleaned trash and temp files"
}

# Find and delete large cache files (>1GB)
clean_large_files() {
    print_info "Finding and deleting cache files larger than 1GB..."
    
    find ~/Library/Caches -type f -size +1G -delete 2>/dev/null || true
    
    print_success "Done — cleaned large cache files"
}

# Clean desktop screenshots
clean_screenshots() {
    print_info "Cleaning Desktop screenshots..."
    
    find ~/Desktop -name "Screen Shot*.png" -delete 2>/dev/null || true
    find ~/Desktop -name "Screenshot*.png" -delete 2>/dev/null || true
    
    print_success "Done — cleaned screenshots"
}

# Run all cleanup tasks
run_all_cleanup() {
    clean_project_folders
    clean_package_caches
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

# Main function
main() {
    # Check if running on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS only"
        exit 1
    fi
    
    print_header
    
    while true; do
        show_menu
        read -p "Enter your choice [0-12]: " choice
        
        case $choice in
            1) clean_project_folders ;;
            2) clean_package_caches ;;
            3) clean_homebrew ;;
            4) clean_xcode ;;
            5) clean_cocoapods ;;
            6) clean_app_caches ;;
            7) clean_docker ;;
            8) clean_system_caches ;;
            9) clean_trash_downloads ;;
            10) clean_large_files ;;
            11) clean_screenshots ;;
            12) run_all_cleanup ;;
            0) 
                echo ""
                echo "🚀 Cleanup complete!"
                echo "📊 Disk after cleanup: $(get_disk_usage)"
                echo "✨ Your Mac is now lighter and faster!"
                echo ""
                exit 0
                ;;
            *)
                print_error "Invalid choice. Please try again."
                ;;
        esac
    done
}

# Run the script
main
