#!/bin/bash

# Тесты для steamdeck_update.sh
# Автор: @ncux11
# Версия: 0.3.1

set -e

# Подключаем вспомогательные функции
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../helpers/test_helpers.sh"

# Подключаем тестируемый скрипт
PROJECT_ROOT="$(dirname "$(dirname "$SCRIPT_DIR")")"
export PROJECT_ROOT

# Временные переменные
CLEANUP_DIRS=()

# Функция очистки
cleanup() {
    for dir in "${CLEANUP_DIRS[@]}"; do
        cleanup_temp_dir "$dir" 2>/dev/null || true
    done
}

# Устанавливаем trap для очистки
trap cleanup EXIT

# Тест 1: Функция safe_remove_dir - обычная директория
test_safe_remove_dir_normal() {
    init_test "Test 1: safe_remove_dir - Normal Directory"
    
    local test_dir=$(create_temp_dir "test_safe_remove_dir")
    CLEANUP_DIRS+=("$test_dir")
    
    # Создаем директорию с файлами
    mkdir -p "$test_dir/subdir"
    touch "$test_dir/file1.txt"
    touch "$test_dir/subdir/file2.txt"
    
    # Выполняем скрипт для получения функции safe_remove_dir
    bash -c "
        set -e
        source '$PROJECT_ROOT/scripts/steamdeck_update.sh' 2>/dev/null || true
        safe_remove_dir '$test_dir' 2>/dev/null || true
    "
    
    assert_file_not_exists "$test_dir" "Directory should be removed"
    
    print_test_summary
}

# Тест 2: VERSION файл
test_version_file() {
    init_test "Test 2: VERSION File"
    
    assert_file_exists "$PROJECT_ROOT/VERSION" "VERSION file should exist"
    
    # Читаем версию
    local version=$(cat "$PROJECT_ROOT/VERSION" | tr -d '\n')
    
    # Проверяем формат (должен быть X.Y.Z)
    assert_command_success "echo '$version' | grep -qE '^[0-9]+\\.[0-9]+\\.[0-9]+$'" "Version format should be X.Y.Z"
    
    print_test_summary
}

# Тест 3: Структура директорий
test_directory_structure() {
    init_test "Test 3: Directory Structure"
    
    # Проверяем наличие основных директорий
    assert_dir_exists "$PROJECT_ROOT/scripts" "scripts directory should exist"
    assert_dir_exists "$PROJECT_ROOT/guides" "guides directory should exist"
    assert_dir_exists "$PROJECT_ROOT/tests" "tests directory should exist"
    
    # Проверяем основные файлы
    assert_file_exists "$PROJECT_ROOT/README.md" "README.md should exist"
    assert_file_exists "$PROJECT_ROOT/VERSION" "VERSION should exist"
    
    print_test_summary
}

# Тест 4: Исполняемые права
test_executable_permissions() {
    init_test "Test 4: Executable Permissions"
    
    # Проверяем что скрипты исполняемые
    assert_command_success "test -x '$PROJECT_ROOT/scripts/steamdeck_update.sh'" "steamdeck_update.sh should be executable"
    assert_command_success "test -x '$PROJECT_ROOT/scripts/steamdeck_setup.sh'" "steamdeck_setup.sh should be executable"
    assert_command_success "test -x '$PROJECT_ROOT/scripts/steamdeck_gui.py'" "steamdeck_gui.py should be executable"
    
    print_test_summary
}

# Тест 5: Проверка синтаксиса bash
test_bash_syntax() {
    init_test "Test 5: Bash Syntax Check"
    
    # Проверяем синтаксис основных bash скриптов
    assert_command_success "bash -n '$PROJECT_ROOT/scripts/steamdeck_update.sh'" "steamdeck_update.sh should have valid syntax"
    assert_command_success "bash -n '$PROJECT_ROOT/scripts/steamdeck_setup.sh'" "steamdeck_setup.sh should have valid syntax"
    assert_command_success "bash -n '$PROJECT_ROOT/scripts/steamdeck_cleanup.sh'" "steamdeck_cleanup.sh should have valid syntax"
    
    print_test_summary
}

# Тест 6: Python синтаксис
test_python_syntax() {
    init_test "Test 6: Python Syntax Check"
    
    # Проверяем синтаксис Python файлов
    assert_command_success "python3 -m py_compile '$PROJECT_ROOT/scripts/steamdeck_gui.py'" "steamdeck_gui.py should have valid syntax"
    assert_command_success "python3 -m py_compile '$PROJECT_ROOT/scripts/steamdeck_logger.py'" "steamdeck_logger.py should have valid syntax"
    
    print_test_summary
}

# Тест 7: Git репозиторий
test_git_repository() {
    init_test "Test 7: Git Repository"
    
    # Проверяем что это git репозиторий
    assert_dir_exists "$PROJECT_ROOT/.git" ".git directory should exist"
    
    # Проверяем наличие remote
    assert_command_success "cd '$PROJECT_ROOT' && git remote -v | grep -q origin" "Git remote origin should exist"
    
    print_test_summary
}

# Запуск всех тестов
main() {
    init_test "Steam Deck Update Script Tests"
    
    reset_test_counters
    
    test_version_file
    test_directory_structure
    test_executable_permissions
    test_bash_syntax
    test_python_syntax
    test_git_repository
    
    # Итоговый отчет
    print_test_summary
    
    # Возвращаем код выхода
    if [[ $TESTS_FAILED -eq 0 ]]; then
        exit 0
    else
        exit 1
    fi
}

# Запуск main если скрипт вызван напрямую
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
