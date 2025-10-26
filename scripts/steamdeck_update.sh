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

# Определяем текущую директорию скрипта (глобально)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Загружаем конфигурацию если существует
CONFIG_FILE="$PROJECT_ROOT/config.env"
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
    
    # Проверяем доступность GitHub API
    if curl -s --head --request GET "https://api.github.com" | grep "200 OK" > /dev/null; then
        print_success "Интернет-соединение работает"
        return 0
    fi
    
    # Fallback: проверяем обычный GitHub
    if curl -s --head --request GET "https://github.com" | grep "200 OK" > /dev/null; then
        print_success "Интернет-соединение работает"
        return 0
    fi
    
    # Fallback: проверяем ping
    if ping -c 1 github.com &> /dev/null; then
        print_success "Интернет-соединение работает"
        return 0
    fi
    
    print_error "Нет интернет-соединения"
    return 1
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
        print_debug "Найден файл VERSION: $version_file" >&2
        cat "$version_file" | tr -d '\n'
    else
        print_debug "Файл VERSION не найден в:" >&2
        print_debug "  - $project_root/VERSION" >&2
        print_debug "  - $INSTALL_DIR/VERSION" >&2
        print_debug "  - ./VERSION" >&2
        print_debug "  - $DECK_HOME/SteamDeck/VERSION" >&2
        echo "unknown"
    fi
}

# Функция для получения последней версии с GitHub через API
get_latest_version() {
    # Используем GitHub API для получения содержимого файла VERSION
    local api_url="https://api.github.com/repos/ncux-ad/SteamDeck_start/contents/VERSION"
    
    print_debug "Получение версии через GitHub API..." >&2
    
    # Получаем содержимое файла VERSION через API
    local version_response=$(curl -s "$api_url" 2>/dev/null)
    
    if [[ $? -eq 0 ]] && [[ -n "$version_response" ]]; then
        # Извлекаем содержимое файла из JSON ответа
        local version=$(echo "$version_response" | grep -o '"content" *: *"[^"]*"' | sed 's/"content" *: *"//;s/"//' | sed 's/\\n$//' | base64 -d 2>/dev/null | tr -d '\n')
        
        if [[ -n "$version" ]] && [[ "$version" != "null" ]]; then
            echo "$version"
            return 0
        fi
    fi
    
    # Fallback: используем старый метод с клонированием
    print_debug "API недоступен, используем клонирование..." >&2
    get_latest_version_fallback
}

# Fallback функция для получения версии через клонирование
get_latest_version_fallback() {
    local temp_repo="$TEMP_DIR/version_check"
    
    # Очищаем и создаем временную папку
    rm -rf "$temp_repo"
    if ! mkdir -p "$temp_repo" 2>/dev/null; then
        print_debug "Не удалось создать временную папку: $temp_repo" >&2
        echo "unknown"
        return 1
    fi
    
    # Клонируем репозиторий во временную папку
    if git clone --depth 1 "$REPO_URL" "$temp_repo" &> /dev/null; then
        local version_file="$temp_repo/VERSION"
        if [[ -f "$version_file" ]]; then
            local version=$(cat "$version_file" | tr -d '\n')
            if [[ -n "$version" ]]; then
                echo "$version"
            else
                echo "unknown"
            fi
        else
            print_debug "Файл VERSION не найден в репозитории" >&2
            echo "unknown"
        fi
    else
        print_debug "Не удалось клонировать репозиторий для проверки версии" >&2
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
    print_debug "PROJECT_ROOT: $PROJECT_ROOT"
    
    if [[ -d "$PROJECT_ROOT" ]] && [[ "$PROJECT_ROOT" != "$install_dir" ]]; then
        # Если запускаем с флешки или другой директории
        local backup_name="$(basename "$PROJECT_ROOT")_backup_$(date +%Y%m%d_%H%M%S)"
        local backup_path="$(dirname "$PROJECT_ROOT")/$backup_name"
        print_debug "Создание резервной копии в: $backup_path"
        
        if [[ -w "$(dirname "$PROJECT_ROOT")" ]]; then
            cp -r "$PROJECT_ROOT" "$backup_path"
        else
            sudo cp -r "$PROJECT_ROOT" "$backup_path"
            # Исправляем права доступа для текущего пользователя
            sudo chown -R $(whoami):$(whoami) "$backup_path"
        fi
        
        print_success "Резервная копия создана: $backup_path"
        return 0
    elif [[ -d "$install_dir" ]]; then
        # Если утилита установлена в память Steam Deck
        print_debug "Создание резервной копии установленной утилиты"
        
        if [[ -w "$(dirname "$install_dir")" ]]; then
            cp -r "$install_dir" "$backup_dir"
        else
            sudo cp -r "$install_dir" "$backup_dir"
            # Исправляем права доступа для текущего пользователя
            sudo chown -R $(whoami):$(whoami) "$backup_dir"
        fi
        
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
    create_backup "$INSTALL_DIR" ""
    
    # Копируем новые файлы
    print_message "Установка обновления..."
    print_debug "Обновление - PROJECT_ROOT: $PROJECT_ROOT"
    print_debug "Обновление - INSTALL_DIR: $INSTALL_DIR"
    
    if [[ -d "$INSTALL_DIR" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
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
        # Исключаем .git и __pycache__ при копировании
        if rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$TEMP_DIR/steamdeck_latest/" "$INSTALL_DIR/"; then
            print_success "Копирование завершено успешно"
            else
                print_error "Ошибка при копировании файлов"
                return 1
            fi
        else
            print_message "Требуются права администратора для копирования новой версии..."
            if sudo -n true 2>/dev/null; then
                # Исключаем .git и __pycache__ при копировании
                if sudo rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$TEMP_DIR/steamdeck_latest/" "$INSTALL_DIR/"; then
                    print_success "Копирование завершено успешно"
                else
                    print_error "Ошибка при копировании файлов с sudo"
                    return 1
                fi
            else
                print_error "Не удалось получить права администратора. Попробуйте запустить с sudo:"
                print_error "sudo bash scripts/steamdeck_update.sh update"
                return 1
            fi
        fi
        
    elif [[ -d "$PROJECT_ROOT" ]]; then
        # Если запускаем с флешки или другой директории
        print_message "Обновление утилиты в текущей директории: $PROJECT_ROOT..."
        print_debug "PROJECT_ROOT: $PROJECT_ROOT"
        print_debug "TEMP_DIR: $TEMP_DIR"
        print_debug "Источник: $TEMP_DIR/steamdeck_latest/"
        print_debug "Назначение: $PROJECT_ROOT/"
        
        # Сохраняем пользовательские настройки
        local user_config="$PROJECT_ROOT/user_config"
        if [[ -d "$user_config" ]]; then
            cp -r "$user_config" "$TEMP_DIR/"
        fi
        
        # Удаляем старую версию (с проверкой прав доступа)
        print_message "Проверка прав доступа для удаления старой версии..."
        if [[ -w "$PROJECT_ROOT" ]]; then
            print_message "Удаление старой версии без sudo..."
            rm -rf "$PROJECT_ROOT"/*
        else
            print_message "Требуются права администратора для удаления старой версии..."
            # Проверяем, можем ли мы удалить с sudo
            if sudo -n true 2>/dev/null; then
                sudo rm -rf "$PROJECT_ROOT"/*
            else
                print_error "Не удалось получить права администратора. Попробуйте запустить с sudo:"
                print_error "sudo bash scripts/steamdeck_update.sh update"
                return 1
            fi
        fi
        
        # Копируем новую версию (с проверкой прав доступа)
        print_message "Проверка прав доступа для копирования новой версии..."
        if [[ -w "$PROJECT_ROOT" ]]; then
            print_message "Копирование новой версии без sudo..."
            # Исключаем .git и __pycache__ при копировании
            if rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$TEMP_DIR/steamdeck_latest/" "$PROJECT_ROOT/"; then
                print_success "Копирование завершено успешно"
            else
                print_error "Ошибка при копировании файлов"
                return 1
            fi
        else
            print_message "Требуются права администратора для копирования новой версии..."
            if sudo -n true 2>/dev/null; then
                # Исключаем .git и __pycache__ при копировании
                if sudo rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$TEMP_DIR/steamdeck_latest/" "$PROJECT_ROOT/"; then
                    print_success "Копирование завершено успешно"
                else
                    print_error "Ошибка при копировании файлов с sudo"
                    return 1
                fi
            else
                print_error "Не удалось получить права администратора. Попробуйте запустить с sudo:"
                print_error "sudo bash scripts/steamdeck_update.sh update"
                return 1
            fi
        fi
        
    else
        print_error "Не найдена директория для обновления"
        return 1
    fi
    
    # Восстанавливаем пользовательские настройки
    if [[ -d "$TEMP_DIR/user_config" ]]; then
        if [[ -d "$INSTALL_DIR" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
            if cp -r "$TEMP_DIR/user_config" "$INSTALL_DIR/"; then
                print_success "Пользовательские настройки восстановлены"
            else
                print_warning "Не удалось восстановить пользовательские настройки"
            fi
        elif [[ -d "$PROJECT_ROOT" ]]; then
            if cp -r "$TEMP_DIR/user_config" "$PROJECT_ROOT/"; then
                print_success "Пользовательские настройки восстановлены"
            else
                print_warning "Не удалось восстановить пользовательские настройки"
            fi
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
    if [[ -d "$INSTALL_DIR" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
        # Для установленной утилиты
        chmod -R 755 "$INSTALL_DIR"
        chmod +x "$INSTALL_DIR/scripts"/*.sh 2>/dev/null || true
        chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    elif [[ -d "$PROJECT_ROOT" ]]; then
        # Для утилиты на флешке (с проверкой прав доступа)
        print_message "Установка прав доступа для обновленных файлов..."
        if [[ -w "$PROJECT_ROOT" ]]; then
            chmod -R 755 "$PROJECT_ROOT"
            chmod +x "$PROJECT_ROOT/scripts"/*.sh 2>/dev/null || true
            chmod +x "$PROJECT_ROOT"/*.sh 2>/dev/null || true
        else
            if sudo -n true 2>/dev/null; then
                sudo chmod -R 755 "$PROJECT_ROOT"
                sudo chmod +x "$PROJECT_ROOT/scripts"/*.sh 2>/dev/null || true
                sudo chmod +x "$PROJECT_ROOT"/*.sh 2>/dev/null || true
            else
                print_warning "Не удалось установить права доступа без sudo"
            fi
        fi
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
    
    # Проверяем целостность обновления
    verify_update_integrity
    
    print_success "Обновление завершено!"
}

# Функция для проверки целостности обновления
verify_update_integrity() {
    print_message "Проверка целостности обновления..."
    
    local target_dir=""
    if [[ -d "$INSTALL_DIR" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
        target_dir="$INSTALL_DIR"
    elif [[ -d "$PROJECT_ROOT" ]]; then
        target_dir="$PROJECT_ROOT"
    else
        print_error "Не найдена директория для проверки"
        return 1
    fi
    
    # Проверяем ключевые файлы
    local key_files=(
        "VERSION"
        "scripts/steamdeck_update.sh"
        "scripts/steamdeck_gui.py"
        "scripts/steamdeck_setup.sh"
        "README.md"
    )
    
    local failed_files=()
    
    for file in "${key_files[@]}"; do
        if [[ ! -f "$target_dir/$file" ]]; then
            failed_files+=("$file")
            print_error "Отсутствует файл: $file"
        else
            print_success "Файл найден: $file"
        fi
    done
    
    if [[ ${#failed_files[@]} -gt 0 ]]; then
        print_error "Обновление неполное! Отсутствуют файлы:"
        for file in "${failed_files[@]}"; do
            print_error "  - $file"
        done
        return 1
    fi
    
    # Проверяем версию
    local current_version=$(get_current_version)
    local latest_version=$(get_latest_version)
    
    if [[ "$latest_version" == "unknown" ]]; then
        print_warning "Не удалось получить последнюю версию с GitHub, пропускаем проверку версии"
        print_success "Проверка целостности пройдена успешно (без проверки версии)"
        return 0
    fi
    
    if [[ "$current_version" == "$latest_version" ]]; then
        print_success "Версия соответствует ожидаемой: $current_version"
    else
        print_error "Несоответствие версий! Текущая: $current_version, Ожидаемая: $latest_version"
        return 1
    fi
    
    print_success "Проверка целостности пройдена успешно"
    return 0
}

# Функция для проверки обновлений
check_updates() {
    print_header "ПРОВЕРКА ОБНОВЛЕНИЙ"
    
    print_debug "Поиск текущей версии..." >&2
    local current_version=$(get_current_version)
    print_debug "Получение последней версии с GitHub..." >&2
    local latest_version=$(get_latest_version)
    
    print_message "Текущая версия: $current_version"
    print_message "Последняя версия: $latest_version"
    
    if [[ "$current_version" != "$latest_version" ]] && [[ "$latest_version" != "unknown" ]]; then
        print_warning "Доступно обновление!"
        return 0
    else
        print_success "У вас установлена последняя версия"
        return 0
    fi
}

# Функция для отката
rollback_update() {
    print_header "ОТКАТ ОБНОВЛЕНИЯ"
    
    # Ищем резервные копии
    local backup_dirs=()
    
    # Ищем в директории установленной утилиты
    if [[ -d "$INSTALL_DIR" ]]; then
        backup_dirs+=($(dirname "$INSTALL_DIR")/SteamDeck_backup_*)
    fi
    
    # Ищем в директории проекта (для флешки)
    if [[ -d "$PROJECT_ROOT" ]]; then
        backup_dirs+=($(dirname "$PROJECT_ROOT")/SteamDeck_backup_*)
    fi
    
    # Ищем в домашней директории пользователя
    backup_dirs+=($HOME/SteamDeck_backup_*)
    
    # Фильтруем только существующие директории
    local existing_backups=()
    for backup_dir in "${backup_dirs[@]}"; do
        if [[ -d "$backup_dir" ]]; then
            existing_backups+=("$backup_dir")
        fi
    done
    
    if [[ ${#existing_backups[@]} -eq 0 ]]; then
        print_error "Резервные копии не найдены"
        print_message "Искал в:"
        for backup_dir in "${backup_dirs[@]}"; do
            print_message "  - $backup_dir"
        done
        return 1
    fi
    
    # Выбираем самую новую резервную копию
    local latest_backup=""
    for backup_dir in "${existing_backups[@]}"; do
        if [[ -z "$latest_backup" ]] || [[ "$backup_dir" -nt "$latest_backup" ]]; then
            latest_backup="$backup_dir"
        fi
    done
    
    print_message "Найдена резервная копия: $latest_backup"
    
    # Определяем, куда восстанавливать
    local restore_target=""
    if [[ -d "$INSTALL_DIR" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
        restore_target="$INSTALL_DIR"
    elif [[ -d "$PROJECT_ROOT" ]]; then
        restore_target="$PROJECT_ROOT"
    else
        print_error "Не найдена директория для восстановления"
        return 1
    fi
    
    print_message "Восстановление из резервной копии..."
    
    # Останавливаем GUI
    pkill -f "steamdeck_gui.py" 2>/dev/null || true
    
    # Удаляем текущую версию
    if [[ -w "$restore_target" ]]; then
        rm -rf "$restore_target"
    else
        sudo rm -rf "$restore_target"
    fi
    
    # Восстанавливаем из бэкапа
    cp -r "$latest_backup" "$restore_target"
    
    # Восстанавливаем права доступа
    if [[ -d "$INSTALL_DIR" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
        if id "$DECK_USER" &>/dev/null; then
            chown -R $DECK_USER:$DECK_USER "$INSTALL_DIR"
        fi
        chmod -R 755 "$INSTALL_DIR"
        chmod +x "$INSTALL_DIR/scripts"/*.sh 2>/dev/null || true
        chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    elif [[ -d "$PROJECT_ROOT" ]]; then
        if [[ -w "$PROJECT_ROOT" ]]; then
            chmod -R 755 "$PROJECT_ROOT"
            chmod +x "$PROJECT_ROOT/scripts"/*.sh 2>/dev/null || true
            chmod +x "$PROJECT_ROOT"/*.sh 2>/dev/null || true
        else
            sudo chmod -R 755 "$PROJECT_ROOT"
            sudo chmod +x "$PROJECT_ROOT/scripts"/*.sh 2>/dev/null || true
            sudo chmod +x "$PROJECT_ROOT"/*.sh 2>/dev/null || true
        fi
    fi
    
    print_success "Откат завершен!"
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
