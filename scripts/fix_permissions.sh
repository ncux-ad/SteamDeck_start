#!/bin/bash

# Script for fixing permissions on Steam Deck
# Автор: @ncux11
# Версия: 0.3.1

set -e

# Цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Определяем директорию проекта
if [[ -n "$1" ]]; then
    PROJECT_DIR="$1"
else
    PROJECT_DIR="$(pwd)"
fi

# Проверяем что мы в правильной директории
if [[ ! -f "$PROJECT_DIR/README.md" ]]; then
    print_error "Ошибка: Запустите скрипт из директории SteamDeck"
    exit 1
fi

print_message "Исправление прав доступа в: $PROJECT_DIR"

# Определяем пользователя
if [[ -n "$DECK_USER" ]]; then
    USER="$DECK_USER"
elif id -u deck >/dev/null 2>&1; then
    USER="deck"
else
    USER="$(whoami)"
fi

print_message "Пользователь: $USER"

# Исправляем права на директории
print_message "Исправление прав на директории..."
find "$PROJECT_DIR" -type d -exec chmod 755 {} \;

# Исправляем права на файлы
print_message "Исправление прав на файлы..."
find "$PROJECT_DIR" -type f -exec chmod 644 {} \;

# Устанавливаем исполняемые права на скрипты
print_message "Установка исполняемых прав на скрипты..."
chmod +x "$PROJECT_DIR"/scripts/*.sh 2>/dev/null || true
chmod +x "$PROJECT_DIR"/scripts/*.py 2>/dev/null || true

# Устанавливаем правильного владельца
if [[ "$USER" != "$(whoami)" ]]; then
    print_message "Установка владельца: $USER"
    if sudo chown -R "$USER:$USER" "$PROJECT_DIR" 2>/dev/null; then
        print_success "Владелец установлен успешно"
    else
        print_warning "Не удалось установить владельца (возможно нет sudo)"
    fi
else
    print_message "Текущий пользователь уже владелец"
    chown -R "$USER:$USER" "$PROJECT_DIR" 2>/dev/null || true
fi

# Проверяем результат
print_message "Проверка прав..."
ls -la "$PROJECT_DIR/scripts" | head -5

print_success "Готово! Права исправлены."
