#!/bin/bash

# Docker Entrypoint для SteamOS эмуляции
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() { echo -e "${BLUE}[DOCKER]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Функция для инициализации окружения
init_environment() {
    print_message "Инициализация SteamOS эмуляции..."
    
    # Запускаем systemd
    if command -v systemctl &> /dev/null; then
        sudo systemctl start dbus
        sudo systemctl start systemd-resolved
    fi
    
    # Создаем необходимые директории
    mkdir -p ~/.steam/steam/userdata
    mkdir -p ~/.local/share/Steam
    mkdir -p ~/.config/steam
    
    print_success "Окружение инициализировано"
}

# Функция для запуска тестов
run_tests() {
    print_message "Запуск тестов Steam Deck Enhancement Pack..."
    
    cd /home/deck/SteamDeck
    
    # Тест 1: Проверка скриптов
    print_message "Тест 1: Проверка скриптов"
    for script in scripts/*.sh; do
        if [[ -f "$script" ]]; then
            if bash -n "$script"; then
                print_success "✓ $script - синтаксис корректен"
            else
                print_error "✗ $script - ошибка синтаксиса"
            fi
        fi
    done
    
    # Тест 2: Проверка Python GUI
    print_message "Тест 2: Проверка Python GUI"
    if python3 -m py_compile scripts/steamdeck_gui.py; then
        print_success "✓ steamdeck_gui.py - синтаксис корректен"
    else
        print_error "✗ steamdeck_gui.py - ошибка синтаксиса"
    fi
    
    # Тест 3: Проверка зависимостей
    print_message "Тест 3: Проверка зависимостей"
    if python3 -c "import tkinter" 2>/dev/null; then
        print_success "✓ tkinter доступен"
    else
        print_error "✗ tkinter недоступен"
    fi
    
    if python3 -c "import psutil" 2>/dev/null; then
        print_success "✓ psutil доступен"
    else
        print_error "✗ psutil недоступен"
    fi
    
    # Тест 4: Тестирование setup скрипта
    print_message "Тест 4: Тестирование setup скрипта"
    if ./scripts/steamdeck_setup.sh status; then
        print_success "✓ setup скрипт работает"
    else
        print_error "✗ setup скрипт не работает"
    fi
    
    # Тест 5: Тестирование GUI
    print_message "Тест 5: Тестирование GUI (headless)"
    if timeout 5 python3 scripts/steamdeck_gui.py --help 2>/dev/null; then
        print_success "✓ GUI запускается"
    else
        print_warning "⚠ GUI не может запуститься в headless режиме"
    fi
    
    print_success "Тесты завершены"
}

# Функция для интерактивного режима
interactive_mode() {
    print_message "Запуск интерактивного режима..."
    print_message "Доступные команды:"
    echo "  test     - Запустить тесты"
    echo "  gui      - Запустить GUI"
    echo "  setup    - Запустить setup"
    echo "  shell    - Открыть shell"
    echo "  exit     - Выход"
    echo
    
    while true; do
        read -p "steamos-emu> " command
        case $command in
            test)
                run_tests
                ;;
            gui)
                print_message "Запуск GUI..."
                python3 scripts/steamdeck_gui.py
                ;;
            setup)
                print_message "Запуск setup..."
                ./scripts/steamdeck_setup.sh
                ;;
            shell)
                print_message "Открытие shell..."
                bash
                ;;
            exit)
                print_message "Выход из эмуляции..."
                exit 0
                ;;
            *)
                print_warning "Неизвестная команда: $command"
                ;;
        esac
    done
}

# Главная функция
main() {
    print_message "SteamOS Emulation Container v1.0"
    print_message "Steam Deck Enhancement Pack Test Environment"
    echo
    
    # Инициализация
    init_environment
    
    # Проверяем аргументы командной строки
    case "${1:-interactive}" in
        test)
            run_tests
            ;;
        gui)
            print_message "Запуск GUI..."
            python3 scripts/steamdeck_gui.py
            ;;
        setup)
            print_message "Запуск setup..."
            ./scripts/steamdeck_setup.sh
            ;;
        shell)
            print_message "Открытие shell..."
            bash
            ;;
        interactive)
            interactive_mode
            ;;
        *)
            print_error "Неизвестная команда: $1"
            print_message "Использование: $0 [test|gui|setup|shell|interactive]"
            exit 1
            ;;
    esac
}

# Запуск
main "$@"
