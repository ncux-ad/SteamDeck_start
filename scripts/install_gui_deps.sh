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

# Проверяем, что мы в режиме разработчика
if ! steamos-readonly status | grep -q "disabled"; then
    print_warning "Требуется отключить режим только для чтения"
    print_message "Запустите: sudo steamos-readonly disable"
    exit 1
fi

# Обновляем базу данных пакетов
print_message "Обновление базы данных пакетов..."
sudo pacman -Sy

# Устанавливаем Python и зависимости
print_message "Установка Python и зависимостей..."
sudo pacman -S python python-pip python-tkinter --noconfirm

# Устанавливаем дополнительные Python пакеты
print_message "Установка Python пакетов..."
pip install --user psutil

# Устанавливаем системные утилиты
print_message "Установка системных утилит..."
sudo pacman -S htop neofetch --noconfirm

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
