#!/bin/bash

# Steam Deck Common Functions
# Общие функции для всех скриптов Steam Deck Enhancement Pack
# Автор: @ncux11

# Включаем строгий режим обработки ошибок
set -euo pipefail

# Определяем пользователя и пути установки (унифицированно)
DECK_USER="${STEAMDECK_USER:-deck}"
DECK_HOME="${STEAMDECK_HOME:-/home/$DECK_USER}"
INSTALL_DIR="${STEAMDECK_INSTALL_DIR:-$DECK_HOME/utils/SteamDeck}"

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_debug() {
    echo -e "${YELLOW}[DEBUG]${NC} $1" >&2
}

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

# Функция для получения корректной директории установки
get_install_directory() {
    local requested_dir="${1:-$INSTALL_DIR}"
    
    # Проверяем существование
    if [[ ! -d "$requested_dir" ]]; then
        print_message "Директория не существует, создаем: $requested_dir"
        
        # Создаем директорию
        if ! mkdir -p "$requested_dir" 2>/dev/null; then
            # Пробуем с sudo
            if ! sudo mkdir -p "$requested_dir" 2>/dev/null; then
                print_error "Не удалось создать директорию: $requested_dir"
                return 1
            fi
            # Устанавливаем правильного владельца
            sudo chown -R "$DECK_USER:$DECK_USER" "$requested_dir" 2>/dev/null || true
        fi
    fi
    
    # Проверяем права на запись
    if [[ ! -w "$requested_dir" ]]; then
        print_warning "Нет прав записи в директории: $requested_dir"
        print_message "Пытаемся исправить..."
        
        if ! chmod -R u+w "$requested_dir" 2>/dev/null; then
            if ! sudo chmod -R u+w "$requested_dir" 2>/dev/null; then
                print_error "Не удалось исправить права доступа"
                return 1
            fi
        fi
    fi
    
    # Проверяем, что директория не является символической ссылкой на проблемное место
    if [[ -L "$requested_dir" ]]; then
        local real_path=$(readlink -f "$requested_dir")
        print_warning "Обнаружена символическая ссылка: $requested_dir -> $real_path"
    fi
    
    echo "$requested_dir"
    return 0
}

# Функция для валидации пути
validate_path() {
    local path="$1"
    local path_type="${2:-directory}"
    
    if [[ -z "$path" ]]; then
        print_error "Путь не указан"
        return 1
    fi
    
    # Проверяем, что путь не содержит опасных символов
    if [[ "$path" =~ ^\.\. ]] || [[ "$path" =~ //+ ]] || [[ "$path" =~ ~ ]]; then
        print_error "Небезопасный путь: $path"
        return 1
    fi
    
    case "$path_type" in
        directory)
            # Для директории проверяем, что родительская директория существует
            local parent_dir=$(dirname "$path")
            if [[ ! -d "$parent_dir" ]]; then
                print_error "Родительская директория не существует: $parent_dir"
                return 1
            fi
            ;;
        file)
            # Для файла проверяем, что директория существует
            local parent_dir=$(dirname "$path")
            if [[ ! -d "$parent_dir" ]]; then
                print_error "Директория для файла не существует: $parent_dir"
                return 1
            fi
            ;;
    esac
    
    return 0
}

# Функция для проверки свободного места
check_disk_space() {
    local required_mb="${1:-100}"
    local target_dir="${2:-$INSTALL_DIR}"
    
    # Получаем доступное место
    local available_kb=$(df "$target_dir" 2>/dev/null | awk 'NR==2 {print $4}')
    if [[ -z "$available_kb" ]]; then
        print_warning "Не удалось определить доступное место"
        return 0
    fi
    
    local required_kb=$((required_mb * 1024))
    local available_mb=$((available_kb / 1024))
    
    if [[ $available_kb -lt $required_kb ]]; then
        print_error "Недостаточно места на диске"
        print_message "Требуется: ${required_mb} MB"
        print_message "Доступно: ${available_mb} MB"
        return 1
    fi
    
    print_success "Достаточно места: ${available_mb} MB доступно"
    return 0
}

# Функция для создания директории с правильными правами
create_directory_safe() {
    local target_dir="$1"
    local owner="${2:-$DECK_USER}"
    
    # Проверяем существование
    if [[ -d "$target_dir" ]]; then
        print_message "Директория уже существует: $target_dir"
        return 0
    fi
    
    # Создаем директорию
    print_message "Создание директории: $target_dir"
    
    # Пытаемся создать без sudo
    if mkdir -p "$target_dir" 2>/dev/null; then
        chown "$owner:$owner" "$target_dir" 2>/dev/null || true
        print_success "Директория создана: $target_dir"
        return 0
    fi
    
    # Пробуем с sudo
    if sudo mkdir -p "$target_dir" 2>/dev/null; then
        sudo chown "$owner:$owner" "$target_dir" 2>/dev/null || true
        print_success "Директория создана с sudo: $target_dir"
        return 0
    fi
    
    print_error "Не удалось создать директорию: $target_dir"
    return 1
}

# Функция для получения размера директории
get_directory_size() {
    local target_dir="$1"
    
    if [[ ! -d "$target_dir" ]]; then
        echo "0"
        return 1
    fi
    
    local size=$(du -sk "$target_dir" 2>/dev/null | cut -f1)
    echo "${size:-0}"
}

# Экспорт функций для использования в других скриптах
export -f print_debug print_message print_success print_warning print_error
export -f get_install_directory validate_path check_disk_space
export -f create_directory_safe get_directory_size

# Если скрипт запущен напрямую, показываем помощь
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    echo "Steam Deck Common Functions"
    echo "Этот скрипт содержит общие функции для других скриптов"
    echo "Для использования импортируйте его в других скриптах:"
    echo "  source scripts/steamdeck_common.sh"
fi
