#!/bin/bash

################################################################################
# CleanMac - Test Script for Path-Specific Scanning
# Tests Issue #6 implementation
################################################################################

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Change to project root to ensure relative paths work
cd "$PROJECT_ROOT"

# Source modules (they will auto-source dependencies)
source "lib/core.sh"
source "lib/ui.sh"
source "lib/args.sh"
source "lib/scanner.sh"

# Test colors
TEST_PASS="${GREEN}✓${NC}"
TEST_FAIL="${RED}✗${NC}"

# Test counter
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Helper function to run a test
run_test() {
    local test_name="$1"
    shift
    local test_command="$@"
    
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -ne "Testing: $test_name ... "
    
    if eval "$test_command" &>/dev/null; then
        echo -e "$TEST_PASS"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "$TEST_FAIL"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Helper to check variable value
check_var() {
    local var_name="$1"
    local expected="$2"
    local actual="${!var_name}"
    
    if [ "$actual" = "$expected" ]; then
        return 0
    else
        echo "Expected: $expected, Got: $actual"
        return 1
    fi
}

# Create test directory structure
setup_test_env() {
    print_header "Setting up test environment"
    
    TEST_DIR="/tmp/cleanmac_test_$$"
    mkdir -p "$TEST_DIR"
    
    # Create test directories
    mkdir -p "$TEST_DIR/project1/node_modules"
    mkdir -p "$TEST_DIR/project1/dist"
    mkdir -p "$TEST_DIR/project2/node_modules"
    mkdir -p "$TEST_DIR/project2/.cache"
    mkdir -p "$TEST_DIR/nested/level1/level2/node_modules"
    
    # Create test files
    echo "test" > "$TEST_DIR/project1/test.log"
    echo "test" > "$TEST_DIR/project2/test.tmp"
    dd if=/dev/zero of="$TEST_DIR/large_file.bin" bs=1m count=10 2>/dev/null
    
    # Make some files old (by touching with old timestamp)
    touch -t 202301010000 "$TEST_DIR/project1/test.log"
    
    print_success "Test environment created at: $TEST_DIR"
}

# Cleanup test environment
cleanup_test_env() {
    print_header "Cleaning up test environment"
    rm -rf "$TEST_DIR"
    print_success "Test environment cleaned"
}

# Test 1: Argument parsing - single path
test_single_path() {
    print_header "Test 1: Single Path Argument"
    
    # Reset variables
    SCAN_PATHS=()
    
    parse_arguments --path "$TEST_DIR"
    
    run_test "Parse single path" "[ \${#SCAN_PATHS[@]} -eq 1 ]"
    run_test "Path contains test dir" "[[ \"\${SCAN_PATHS[0]}\" == *\"cleanmac_test\"* ]]"
}

# Test 2: Argument parsing - multiple paths
test_multiple_paths() {
    print_header "Test 2: Multiple Paths Argument"
    
    SCAN_PATHS=()
    local path1="$TEST_DIR/project1"
    local path2="$TEST_DIR/project2"
    parse_arguments --paths "$path1,$path2"
    
    run_test "Parse multiple paths" "[ \${#SCAN_PATHS[@]} -eq 2 ]"
    run_test "First path contains project1" "[[ \"\${SCAN_PATHS[0]}\" == *\"project1\" ]]"
    run_test "Second path contains project2" "[[ \"\${SCAN_PATHS[1]}\" == *\"project2\" ]]"
}

# Test 3: Depth limiting
test_depth_limit() {
    print_header "Test 3: Depth Limiting"
    
    SCAN_DEPTH=-1
    parse_arguments --depth 2
    
    run_test "Parse depth argument" "[ \"\$SCAN_DEPTH\" = \"2\" ]"
}

# Test 4: Only targets filter
test_only_targets() {
    print_header "Test 4: Only Targets Filter"
    
    ONLY_TARGETS=()
    parse_arguments --only "node_modules,cache"
    
    run_test "Parse only targets" "[ \${#ONLY_TARGETS[@]} -eq 2 ]"
    run_test "First target correct" "[ \"\${ONLY_TARGETS[0]}\" = \"node_modules\" ]"
}

# Test 5: Exclude patterns
test_exclude_patterns() {
    print_header "Test 5: Exclude Patterns"
    
    EXCLUDE_PATTERNS=()
    parse_arguments --exclude ".git,important"
    
    run_test "Parse exclude patterns" "[ \${#EXCLUDE_PATTERNS[@]} -eq 2 ]"
}

# Test 6: Age filter
test_age_filter() {
    print_header "Test 6: Age Filter"
    
    MAX_AGE_DAYS=-1
    parse_arguments --max-age 30
    
    run_test "Parse max-age" "[ \"\$MAX_AGE_DAYS\" = \"30\" ]"
}

# Test 7: Size filter
test_size_filter() {
    print_header "Test 7: Size Filter"
    
    MIN_SIZE_BYTES=0
    parse_arguments --min-size 100MB
    
    run_test "Parse min-size" "[ \"\$MIN_SIZE_BYTES\" -gt 0 ]"
}

# Test 8: Dry run mode
test_dry_run() {
    print_header "Test 8: Dry Run Mode"
    
    DRY_RUN=false
    parse_arguments --dry-run
    
    run_test "Parse dry-run" "[ \"\$DRY_RUN\" = \"true\" ]"
}

# Test 9: Verbose mode
test_verbose() {
    print_header "Test 9: Verbose Mode"
    
    VERBOSE=false
    parse_arguments --verbose
    
    run_test "Parse verbose" "[ \"\$VERBOSE\" = \"true\" ]"
}

# Test 10: Scanning with path
test_scan_specific_path() {
    print_header "Test 10: Scan Specific Path"
    
    SCAN_PATHS=("$TEST_DIR/project1")
    SCAN_DEPTH=-1
    ONLY_TARGETS=("node_modules")
    MAX_AGE_DAYS=-1
    MIN_SIZE_BYTES=0
    EXCLUDE_PATTERNS=()
    VERBOSE=false
    
    scan_directories
    
    local count=$(get_scan_count)
    run_test "Find node_modules in project1" "[ \"\$count\" -ge 1 ]"
}

# Test 11: Scanning with depth limit
test_scan_with_depth() {
    print_header "Test 11: Scan with Depth Limit"
    
    SCAN_PATHS=("$TEST_DIR")
    SCAN_DEPTH=2
    ONLY_TARGETS=("node_modules")
    MAX_AGE_DAYS=-1
    MIN_SIZE_BYTES=0
    EXCLUDE_PATTERNS=()
    VERBOSE=false
    
    clear_scan_results
    scan_directories
    
    local count=$(get_scan_count)
    # Should find project1 and project2 node_modules, but not nested/level1/level2
    run_test "Depth limit works" "[ \"\$count\" -eq 2 ]"
}

# Test 12: Scanning with exclusion
test_scan_with_exclusion() {
    print_header "Test 12: Scan with Exclusion Pattern"
    
    SCAN_PATHS=("$TEST_DIR")
    SCAN_DEPTH=-1
    ONLY_TARGETS=("node_modules")
    EXCLUDE_PATTERNS=("project1")
    MAX_AGE_DAYS=-1
    MIN_SIZE_BYTES=0
    VERBOSE=false
    
    clear_scan_results
    scan_directories
    
    # Check that no project1 paths are in results
    local found_excluded=false
    for path in "${SCAN_RESULTS_PATHS[@]}"; do
        if [[ "$path" == *"project1"* ]]; then
            found_excluded=true
            break
        fi
    done
    
    run_test "Exclusion pattern works" "[ \"\$found_excluded\" = \"false\" ]"
}

# Test 13: Help command
test_help_command() {
    print_header "Test 13: Help Command"
    
    run_test "Help shows usage" "parse_arguments --help 2>&1 | grep -q 'USAGE'"
}

# Main test execution
main() {
    print_header "CleanMac Path-Specific Scanning Tests"
    echo ""
    
    # Setup
    setup_test_env
    echo ""
    
    # Run all tests
    test_single_path
    test_multiple_paths
    test_depth_limit
    test_only_targets
    test_exclude_patterns
    test_age_filter
    test_size_filter
    test_dry_run
    test_verbose
    test_scan_specific_path
    test_scan_with_depth
    test_scan_with_exclusion
    test_help_command
    
    # Cleanup
    echo ""
    cleanup_test_env
    
    # Summary
    echo ""
    print_header "Test Summary"
    echo ""
    echo "Total tests: $TESTS_RUN"
    echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    echo ""
    
    if [ $TESTS_FAILED -eq 0 ]; then
        print_success "All tests passed! ✨"
        exit 0
    else
        print_error "Some tests failed"
        exit 1
    fi
}

# Run main
main "$@"
