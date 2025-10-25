#!/bin/bash

# Steam Deck Update Script
# Скрипт для обновления Steam Deck Enhancement Pack через GitHub
# Автор: @ncux11
# Версия: динамическая (читается из VERSION)

set -e  # Выход при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Загружаем конфигурацию если существует
CONFIG_FILE="$(dirname "$(dirname "$(readlink -f "$0")")")/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    print_message "Загружена конфигурация из $CONFIG_FILE"
fi

# Определяем пользователя и пути установки
DECK_USER="${STEAMDECK_USER:-deck}"
DECK_HOME="${STEAMDECK_HOME:-/home/$DECK_USER}"
INSTALL_DIR="${STEAMDECK_INSTALL_DIR:-$DECK_HOME/SteamDeck}"

# Конфигурация
REPO_URL="https://github.com/ncux-ad/SteamDeck_start.git"

# Определяем текущее местоположение утилиты
CURRENT_DIR=$(dirname "$(readlink -f "$0")")
BACKUP_DIR="${INSTALL_DIR}_backup_$(date +%Y%m%d_%H%M%S)"
TEMP_DIR="/tmp/steamdeck_update"

# Функция для получения версии
get_version() {
    local version_file="$(dirname "$(dirname "$(readlink -f "$0")")")/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file" | tr -d '\n'
    else
        echo "0.1.3"  # Fallback версия
    fi
}

# Функции для вывода
print_debug() {
    echo -e "${YELLOW}[DEBUG]${NC} $1"
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

print_header() {
    echo
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE} $1${NC}"
    echo -e "${BLUE}================================${NC}"
    echo
}

# Функция для проверки интернет-соединения
check_internet() {
    print_message "Проверка интернет-соединения..."
    if ping -c 1 github.com &> /dev/null; then
        print_success "Интернет-соединение работает"
        return 0
    else
        print_error "Нет интернет-соединения"
        return 1
    fi
}

# Функция для проверки git
check_git() {
    if ! command -v git &> /dev/null; then
        print_error "Git не установлен. Установите git: sudo pacman -S git"
        exit 1
    fi
}

# Функция для получения текущей версии
get_current_version() {
    # Определяем текущую директорию скрипта
    local script_dir="$(dirname "$(readlink -f "$0")")"
    local project_root="$(dirname "$script_dir")"
    
    # Пробуем найти VERSION в разных местах
    local version_file=""
    
    # 1. В директории проекта (где запущен скрипт)
    if [[ -f "$project_root/VERSION" ]]; then
        version_file="$project_root/VERSION"
    # 2. В установленной директории
    elif [[ -f "$INSTALL_DIR/VERSION" ]]; then
        version_file="$INSTALL_DIR/VERSION"
    # 3. В текущей рабочей директории
    elif [[ -f "./VERSION" ]]; then
        version_file="./VERSION"
    # 4. В домашней директории пользователя
    elif [[ -f "$DECK_HOME/SteamDeck/VERSION" ]]; then
        version_file="$DECK_HOME/SteamDeck/VERSION"
    fi
    
    if [[ -n "$version_file" ]]; then
        print_debug "Найден файл VERSION: $version_file"
        cat "$version_file" | tr -d '\n'
    else
        print_debug "Файл VERSION не найден в:"
        print_debug "  - $project_root/VERSION"
        print_debug "  - $INSTALL_DIR/VERSION"
        print_debug "  - ./VERSION"
        print_debug "  - $DECK_HOME/SteamDeck/VERSION"
        echo "unknown"
    fi
}

# Функция для получения последней версии с GitHub
get_latest_version() {
    local temp_repo="$TEMP_DIR/version_check"
    
    # Очищаем и создаем временную папку
    rm -rf "$temp_repo"
    mkdir -p "$temp_repo"
    
    # Клонируем репозиторий во временную папку
    if git clone --depth 1 "$REPO_URL" "$temp_repo" &> /dev/null; then
        local version_file="$temp_repo/VERSION"
        if [[ -f "$version_file" ]]; then
            cat "$version_file"
        else
            echo "unknown"
        fi
    else
        echo "unknown"
    fi
    
    # Очищаем временную папку
    rm -rf "$temp_repo"
}

# Функция для создания резервной копии
create_backup() {
    local install_dir="$1"
    local backup_dir="$2"
    
    print_message "Создание резервной копии текущей версии..."
    print_debug "install_dir: $install_dir"
    print_debug "backup_dir: $backup_dir"
    
    # Определяем текущую директорию проекта
    local script_path="$(readlink -f "$0")"
    local script_dir="$(dirname "$script_path")"
    local current_project_dir="$(dirname "$script_dir")"
    print_debug "script_path: $script_path"
    print_debug "script_dir: $script_dir"
    print_debug "current_project_dir: $current_project_dir"
    
    if [[ -d "$current_project_dir" ]]; then
        # Если запускаем с флешки или другой директории
        local backup_name="$(basename "$current_project_dir")_backup_$(date +%Y%m%d_%H%M%S)"
        local backup_path="$(dirname "$current_project_dir")/$backup_name"
        print_debug "Создание резервной копии в: $backup_path"
        cp -r "$current_project_dir" "$backup_path"
        print_success "Резервная копия создана: $backup_path"
        return 0
    elif [[ -d "$install_dir" ]]; then
        # Если утилита установлена в память Steam Deck
        print_debug "Создание резервной копии установленной утилиты"
        cp -r "$install_dir" "$backup_dir"
        print_success "Резервная копия создана: $backup_dir"
        return 0
    else
        print_warning "Не найдена папка для резервного копирования"
        return 1
    fi
}

# Функция для обновления
update_utility() {
    print_message "Обновление Steam Deck Enhancement Pack..."
    
    # Очищаем и создаем временную папку
    print_message "Очистка временной папки..."
    rm -rf "$TEMP_DIR"
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Клонируем последнюю версию
    print_message "Загрузка последней версии с GitHub..."
    if git clone "$REPO_URL" steamdeck_latest; then
        print_success "Последняя версия загружена"
    else
        print_error "Не удалось загрузить последнюю версию"
        # Очищаем временную папку при ошибке
        rm -rf "$TEMP_DIR"
        return 1
    fi
    
    # Останавливаем GUI если запущен
    print_message "Остановка GUI (если запущен)..."
    pkill -f "steamdeck_gui.py" 2>/dev/null || true
    
    # Создаем резервную копию
    create_backup "$INSTALL_DIR" "$BACKUP_DIR"
    
    # Копируем новые файлы
    print_message "Установка обновления..."
    
    # Определяем текущую директорию проекта
    local script_path="$(readlink -f "$0")"
    local script_dir="$(dirname "$script_path")"
    local current_project_dir="$(dirname "$script_dir")"
    print_debug "Обновление - script_path: $script_path"
    print_debug "Обновление - current_project_dir: $current_project_dir"
    
    if [[ -d "$INSTALL_DIR" ]]; then
        # Если утилита установлена в память Steam Deck
        print_message "Обновление установленной утилиты в $INSTALL_DIR..."
        
        # Сохраняем пользовательские настройки
        local user_config="$INSTALL_DIR/user_config"
        if [[ -d "$user_config" ]]; then
            cp -r "$user_config" "$TEMP_DIR/"
        fi
        
        # Удаляем старую версию (с проверкой прав доступа)
        print_message "Проверка прав доступа для удаления старой версии..."
        if [[ -w "$INSTALL_DIR" ]]; then
            print_message "Удаление старой версии без sudo..."
            rm -rf "$INSTALL_DIR"
        else
            print_message "Требуются права администратора для удаления старой версии..."
            # Проверяем, можем ли мы удалить с sudo
            if sudo -n true 2>/dev/null; then
                sudo rm -rf "$INSTALL_DIR"
            else
                print_error "Не удалось получить права администратора. Попробуйте запустить с sudo:"
                print_error "sudo bash scripts/steamdeck_update.sh update"
                return 1
            fi
        fi
        
        # Копируем новую версию в установленную директорию
        print_message "Копирование новой версии в установленную директорию..."
        if [[ -w "$(dirname "$INSTALL_DIR")" ]]; then
            print_message "Копирование новой версии без sudo..."
            cp -r "$TEMP_DIR/steamdeck_latest" "$INSTALL_DIR"
        else
            print_message "Требуются права администратора для копирования новой версии..."
            if sudo -n true 2>/dev/null; then
                sudo cp -r "$TEMP_DIR/steamdeck_latest" "$INSTALL_DIR"
            else
                print_error "Не удалось получить права администратора. Попробуйте запустить с sudo:"
                print_error "sudo bash scripts/steamdeck_update.sh update"
                return 1
            fi
        fi
        
    elif [[ -d "$current_project_dir" ]]; then
        # Если запускаем с флешки или другой директории
        print_message "Обновление утилиты в текущей директории: $current_project_dir..."
        
        # Сохраняем пользовательские настройки
        local user_config="$current_project_dir/user_config"
        if [[ -d "$user_config" ]]; then
            cp -r "$user_config" "$TEMP_DIR/"
        fi
        
        # Удаляем старую версию
        print_message "Удаление старой версии..."
        rm -rf "$current_project_dir"/*
        
        # Копируем новую версию
        print_message "Копирование новой версии..."
        cp -r "$TEMP_DIR/steamdeck_latest"/* "$current_project_dir/"
        
    else
        print_error "Не найдена директория для обновления"
        return 1
    fi
    
    # Восстанавливаем пользовательские настройки
    if [[ -d "$TEMP_DIR/user_config" ]]; then
        if [[ -d "$INSTALL_DIR" ]]; then
            cp -r "$TEMP_DIR/user_config" "$INSTALL_DIR/"
        elif [[ -d "$current_project_dir" ]]; then
            cp -r "$TEMP_DIR/user_config" "$current_project_dir/"
        fi
    fi
    
    # Устанавливаем права доступа (только для установленной утилиты)
    if [[ -d "$INSTALL_DIR" ]]; then
        # Проверяем, есть ли пользователь deck
        if id "$DECK_USER" &>/dev/null; then
            chown -R $DECK_USER:$DECK_USER "$INSTALL_DIR"
        else
            print_warning "Пользователь '$DECK_USER' не найден, пропускаем chown"
        fi
    fi
    # Устанавливаем права доступа
    if [[ -d "$INSTALL_DIR" ]]; then
        # Для установленной утилиты
        chmod -R 755 "$INSTALL_DIR"
        chmod +x "$INSTALL_DIR/scripts"/*.sh 2>/dev/null || true
        chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    elif [[ -d "$current_project_dir" ]]; then
        # Для утилиты на флешке
        chmod -R 755 "$current_project_dir"
        chmod +x "$current_project_dir/scripts"/*.sh 2>/dev/null || true
        chmod +x "$current_project_dir"/*.sh 2>/dev/null || true
    fi
    
    # Обновляем символические ссылки (только если пользователь существует)
    if id "$DECK_USER" &>/dev/null; then
        print_message "Обновление символических ссылок..."
        ln -sf "$INSTALL_DIR/scripts/steamdeck_setup.sh" "$DECK_HOME/steamdeck-setup" 2>/dev/null || true
        ln -sf "$INSTALL_DIR/scripts/steamdeck_gui.py" "$DECK_HOME/steamdeck-gui" 2>/dev/null || true
        ln -sf "$INSTALL_DIR/scripts/steamdeck_backup.sh" "$DECK_HOME/steamdeck-backup" 2>/dev/null || true
        ln -sf "$INSTALL_DIR/scripts/steamdeck_cleanup.sh" "$DECK_HOME/steamdeck-cleanup" 2>/dev/null || true
        ln -sf "$INSTALL_DIR/scripts/steamdeck_optimizer.sh" "$DECK_HOME/steamdeck-optimizer" 2>/dev/null || true
        ln -sf "$INSTALL_DIR/scripts/steamdeck_microsd.sh" "$DECK_HOME/steamdeck-microsd" 2>/dev/null || true
        ln -sf "$INSTALL_DIR/scripts/steamdeck_update.sh" "$DECK_HOME/steamdeck-update" 2>/dev/null || true
    else
        print_warning "Пользователь '$DECK_USER' не найден, пропускаем создание символических ссылок"
    fi
    
    # Очищаем временную папку
    rm -rf "$TEMP_DIR"
    
    print_success "Обновление завершено!"
}

# Функция для проверки обновлений
check_updates() {
    print_header "ПРОВЕРКА ОБНОВЛЕНИЙ"
    
    print_debug "Поиск текущей версии..."
    local current_version=$(get_current_version)
    print_debug "Получение последней версии с GitHub..."
    local latest_version=$(get_latest_version)
    
    print_message "Текущая версия: $current_version"
    print_message "Последняя версия: $latest_version"
    
    if [[ "$current_version" != "$latest_version" ]] && [[ "$latest_version" != "unknown" ]]; then
        print_warning "Доступно обновление!"
        return 0
    else
        print_success "У вас установлена последняя версия"
        return 1
    fi
}

# Функция для отката
rollback_update() {
    print_header "ОТКАТ ОБНОВЛЕНИЯ"
    
    if [[ -d "$BACKUP_DIR" ]]; then
        print_message "Восстановление из резервной копии..."
        
        # Останавливаем GUI
        pkill -f "steamdeck_gui.py" 2>/dev/null || true
        
        # Удаляем текущую версию
        rm -rf "$INSTALL_DIR"
        
        # Восстанавливаем из бэкапа
        mv "$BACKUP_DIR" "$INSTALL_DIR"
        
        # Восстанавливаем права доступа
        chown -R $DECK_USER:$DECK_USER "$INSTALL_DIR"
        chmod -R 755 "$INSTALL_DIR"
        chmod +x "$INSTALL_DIR/scripts"/*.sh 2>/dev/null || true
        chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
        
        print_success "Откат завершен"
    else
        print_error "Резервная копия не найдена: $BACKUP_DIR"
        return 1
    fi
}

# Функция для показа статуса
show_status() {
    print_header "СТАТУС ОБНОВЛЕНИЙ"
    
    local current_version=$(get_current_version)
    print_message "Текущая версия: $current_version"
    
    if check_internet; then
        local latest_version=$(get_latest_version)
        print_message "Последняя версия: $latest_version"
        
        if [[ "$current_version" != "$latest_version" ]] && [[ "$latest_version" != "unknown" ]]; then
            print_warning "Доступно обновление!"
        else
            print_success "У вас установлена последняя версия"
        fi
    else
        print_warning "Нет интернет-соединения для проверки обновлений"
    fi
}

# Функция для показа справки
show_help() {
    echo "Steam Deck Update Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ]"
    echo
    echo "ОПЦИИ:"
    echo "  update      - Обновить утилиту до последней версии"
    echo "  check       - Проверить наличие обновлений"
    echo "  rollback    - Откатить последнее обновление"
    echo "  status      - Показать статус обновлений"
    echo "  help        - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 update       # Обновить утилиту"
    echo "  $0 check        # Проверить обновления"
    echo "  $0 rollback     # Откатить обновление"
    echo "  $0 status       # Показать статус"
    echo
}

# Основная функция
main() {
    case "${1:-help}" in
        "update")
            print_header "ОБНОВЛЕНИЕ STEAM DECK ENHANCEMENT PACK"
            check_internet || exit 1
            check_git || exit 1
            update_utility
            ;;
        "check")
            check_internet || exit 1
            check_git || exit 1
            check_updates
            ;;
        "rollback")
            print_header "ОТКАТ ОБНОВЛЕНИЯ"
            rollback_update
            ;;
        "status")
            show_status
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
    esac
}

# Запуск
main "$@"
