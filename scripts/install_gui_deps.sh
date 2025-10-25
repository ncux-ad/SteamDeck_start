#!/bin/bash

# Steam Deck GUI Dependencies Installer
# Установка зависимостей для GUI приложения
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции для вывода
print_message() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

print_message "Установка зависимостей для Steam Deck GUI..."

# Проверяем, что мы в режиме разработчика (только для SteamOS)
if command -v steamos-readonly &> /dev/null; then
    if ! steamos-readonly status | grep -q "disabled"; then
        print_warning "Требуется отключить режим только для чтения"
        print_message "Запустите: sudo steamos-readonly disable"
        exit 1
    fi
else
    print_message "Не SteamOS, пропускаем проверку readonly режима"
fi

# Определяем дистрибутив
if command -v pacman &> /dev/null; then
    DISTRO="arch"
    print_message "Обнаружен Arch Linux / SteamOS"
    print_message "Обновление базы данных пакетов..."
    sudo pacman -Sy
elif command -v apt &> /dev/null; then
    DISTRO="debian"
    print_message "Обнаружен Debian / Ubuntu"
    print_message "Обновление списка пакетов..."
    sudo apt update
elif command -v dnf &> /dev/null; then
    DISTRO="fedora"
    print_message "Обнаружен Fedora / RHEL"
    print_message "Обновление базы данных пакетов..."
    sudo dnf update
else
    print_error "Неподдерживаемый дистрибутив Linux"
    exit 1
fi

# Функция для установки пакетов в зависимости от дистрибутива
install_package() {
    local package="$1"
    local arch_package="$2"
    local debian_package="$3"
    local fedora_package="$4"
    
    case "$DISTRO" in
        "arch")
            if ! pacman -Qi "$arch_package" &>/dev/null; then
                sudo pacman -S "$arch_package" --noconfirm
            else
                print_message "$arch_package уже установлен"
            fi
            ;;
        "debian")
            if ! dpkg -l | grep -q "^ii.*$debian_package "; then
                sudo apt install -y "$debian_package"
            else
                print_message "$debian_package уже установлен"
            fi
            ;;
        "fedora")
            if ! rpm -q "$fedora_package" &>/dev/null; then
                sudo dnf install -y "$fedora_package"
            else
                print_message "$fedora_package уже установлен"
            fi
            ;;
    esac
}

# Устанавливаем Python и зависимости
print_message "Установка Python и зависимостей..."
install_package "python" "python" "python3" "python3"
install_package "pip" "python-pip" "python3-pip" "python3-pip"
install_package "tk" "tk" "python3-tk" "tkinter"

# Устанавливаем дополнительные Python пакеты
print_message "Установка Python пакетов..."
if command -v pip3 &> /dev/null; then
    pip3 install --user psutil
elif command -v pip &> /dev/null; then
    pip install --user psutil
else
    print_warning "pip не найден, пробуем установить через пакетный менеджер..."
    case "$DISTRO" in
        "arch")
            install_package "psutil" "python-psutil" "" ""
            ;;
        "debian")
            install_package "psutil" "" "python3-psutil" ""
            ;;
        "fedora")
            install_package "psutil" "" "" "python3-psutil"
            ;;
    esac
fi

# Устанавливаем системные утилиты
print_message "Установка системных утилит..."
install_package "htop" "htop" "htop" "htop"
install_package "neofetch" "neofetch" "neofetch" "neofetch"

# Проверяем установку
print_message "Проверка установки..."

if command -v python3 &> /dev/null; then
    print_success "Python3 установлен"
else
    print_error "Python3 не установлен"
    exit 1
fi

if python3 -c "import tkinter" 2>/dev/null; then
    print_success "Tkinter доступен"
else
    print_error "Tkinter не доступен"
    exit 1
fi

if python3 -c "import psutil" 2>/dev/null; then
    print_success "psutil установлен"
else
    print_warning "psutil не установлен, некоторые функции могут не работать"
fi

print_success "Зависимости установлены успешно!"
print_message "Теперь можно запустить GUI: ./scripts/steamdeck_gui.py"
