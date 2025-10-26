#!/bin/bash

# Basic tests for core functions
# Author: @ncux11

set -e

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# Test counter
TESTS_PASSED=0
TESTS_FAILED=0

# Load core library
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
source "$PROJECT_ROOT/lib/core.sh"

# Test functions
assert_true() {
    if "$@"; then
        echo -e "${GREEN}✓${NC} $*"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $*"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_false() {
    if ! "$@"; then
        echo -e "${GREEN}✓${NC} $*"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} $*"
        ((TESTS_FAILED++))
        return 1
    fi
}

assert_equal() {
    if [[ "$1" == "$2" ]]; then
        echo -e "${GREEN}✓${NC} '$1' == '$2'"
        ((TESTS_PASSED++))
        return 0
    else
        echo -e "${RED}✗${NC} '$1' != '$2'"
        ((TESTS_FAILED++))
        return 1
    fi
}

# Test validate_path
echo "=== Testing validate_path ==="
assert_true "validate_path '/tmp'"
assert_true "validate_path '$(pwd)'"
assert_false "validate_path '../../../etc/passwd'"
assert_false "validate_path ''"

# Test print functions
echo ""
echo "=== Testing print functions ==="
assert_true "print_message 'Test message'"
assert_true "print_success 'Success'"
assert_true "print_warning 'Warning'"
assert_true "print_error 'Error'"

# Test logging
echo ""
echo "=== Testing logging ==="
LOG_DIR="$HOME/.steamdeck_logs_test"
rm -rf "$LOG_DIR"
mkdir -p "$LOG_DIR"
export STEAMDECK_LOG_DIR="$LOG_DIR"
assert_true "log_info 'Test log'"
assert_true "[[ -f $(ls $LOG_DIR/*.log | head -1) ]]"

# Test Proton detection
echo ""
echo "=== Testing Proton detection ==="
PROTON_PATH=$(get_proton_path 2>/dev/null || echo "")
if [[ -n "$PROTON_PATH" ]]; then
    echo "Proton found: $PROTON_PATH"
    assert_true "check_proton"
else
    echo "Proton not found (expected in test environment)"
    assert_true "! check_proton"
fi

# Summary
echo ""
echo "=== Test Summary ==="
echo "Tests passed: $TESTS_PASSED"
echo "Tests failed: $TESTS_FAILED"

if [[ $TESTS_FAILED -eq 0 ]]; then
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
else
    echo -e "${RED}Some tests failed!${NC}"
    exit 1
fi
