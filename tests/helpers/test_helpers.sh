#!/bin/bash

# Test Helper Functions
# Автор: @ncux11
# Версия: 0.3.1

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Счетчики тестов
TESTS_PASSED=0
TESTS_FAILED=0
TESTS_TOTAL=0

# Функция для инициализации тестов
init_test() {
    echo -e "${BLUE}====================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}====================================${NC}"
    echo
}

# Функция для вывода результата теста
assert() {
    local test_name="$1"
    local test_command="$2"
    
    ((TESTS_TOTAL++)) || true
    echo -n "  Test: $test_name ... " >&2
    
    if eval "$test_command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}" >&2
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}" >&2
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# Функция для проверки равенства
assert_equal() {
    local expected="$1"
    local actual="$2"
    local test_name="${3:-Values should be equal}"
    
    assert "$test_name" "[ \"$expected\" == \"$actual\" ]"
}

# Функция для проверки неравенства
assert_not_equal() {
    local val1="$1"
    local val2="$2"
    local test_name="${3:-Values should not be equal}"
    
    assert "$test_name" "[ \"$val1\" != \"$val2\" ]"
}

# Функция для проверки существования файла
assert_file_exists() {
    local file="$1"
    local test_name="${2:-File should exist: $file}"
    
    assert "$test_name" "[ -f \"$file\" ]"
}

# Функция для проверки существования директории
assert_dir_exists() {
    local dir="$1"
    local test_name="${2:-Directory should exist: $dir}"
    
    assert "$test_name" "[ -d \"$dir\" ]"
}

# Функция для проверки отсутствия файла
assert_file_not_exists() {
    local file="$1"
    local test_name="${2:-File should not exist: $file}"
    
    assert "$test_name" "[ ! -f \"$file\" ]"
}

# Функция для проверки выполнения команды
assert_command_success() {
    local command="$1"
    local test_name="${2:-Command should succeed: $command}"
    
    assert "$test_name" "$command"
}

# Функция для проверки неуспешного выполнения команды
assert_command_fail() {
    local command="$1"
    local test_name="${2:-Command should fail: $command}"
    
    ((TESTS_TOTAL++)) || true
    echo -n "  Test: $test_name ... " >&2
    
    if ! eval "$command" >/dev/null 2>&1; then
        echo -e "${GREEN}✓ PASS${NC}" >&2
        ((TESTS_PASSED++)) || true
        return 0
    else
        echo -e "${RED}✗ FAIL${NC}" >&2
        ((TESTS_FAILED++)) || true
        return 1
    fi
}

# Функция для создания временной директории
create_temp_dir() {
    local prefix="${1:-test_}"
    local temp_dir=$(mktemp -d -t "${prefix}XXXXXX")
    echo "$temp_dir"
}

# Функция для очистки временной директории
cleanup_temp_dir() {
    local dir="$1"
    if [[ -n "$dir" ]] && [[ -d "$dir" ]]; then
        rm -rf "$dir"
    fi
}

# Функция для вывода итогов тестов
print_test_summary() {
    echo >&2
    echo -e "${BLUE}====================================${NC}" >&2
    echo -e "Всего тестов: $TESTS_TOTAL" >&2
    echo -e "${GREEN}Пройдено: $TESTS_PASSED${NC}" >&2
    echo -e "${RED}Провалено: $TESTS_FAILED${NC}" >&2
    
    if [[ $TESTS_FAILED -eq 0 ]]; then
        echo -e "${GREEN}Все тесты прошли успешно!${NC}" >&2
        echo -e "${BLUE}====================================${NC}" >&2
        return 0
    else
        echo -e "${RED}Некоторые тесты провалились!${NC}" >&2
        echo -e "${BLUE}====================================${NC}" >&2
        return 1
    fi
}

# Функция для сброса счетчиков
reset_test_counters() {
    TESTS_PASSED=0
    TESTS_FAILED=0
    TESTS_TOTAL=0
}

# Функция для безопасного выполнения с проверкой
safe_run() {
    local command="$1"
    local expected_exit_code="${2:-0}"
    
    if eval "$command" > /tmp/test_output.log 2>&1; then
        exit_code=$?
    else
        exit_code=$?
    fi
    
    if [[ $exit_code -eq $expected_exit_code ]]; then
        return 0
    else
        cat /tmp/test_output.log
        return 1
    fi
}

# Функция для мокирования команды
mock_command() {
    local command="$1"
    local mock_file="$2"
    
    # Создаем mock версию команды
    echo "#!/bin/bash" > "$mock_file"
    echo "# Mock for $command" >> "$mock_file"
    chmod +x "$mock_file"
}

# Экспорт функций
export -f assert
export -f assert_equal
export -f assert_not_equal
export -f assert_file_exists
export -f assert_dir_exists
export -f assert_file_not_exists
export -f assert_command_success
export -f assert_command_fail
export -f print_test_summary
export -f reset_test_counters
export -f create_temp_dir
export -f cleanup_temp_dir
export -f safe_run
