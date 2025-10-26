#!/bin/bash

# Steam Deck Update Script
# Скрипт для обновления Steam Deck Enhancement Pack через GitHub
# Автор: @ncux11
# Версия: динамическая (читается из VERSION)

# Включаем строгий режим обработки ошибок
set -euo pipefail
# Но для некоторых команд нам нужна обработка ошибок вручную
set +o pipefail  # Отключаем только pipefail для ручной обработки

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

# Определяем пользователя и пути установки
DECK_USER="${STEAMDECK_USER:-deck}"
DECK_HOME="${STEAMDECK_HOME:-/home/$DECK_USER}"
INSTALL_DIR="${STEAMDECK_INSTALL_DIR:-$DECK_HOME/utils/SteamDeck}"

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

# Загружаем конфигурацию если существует
CONFIG_FILE="$PROJECT_ROOT/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    print_message "Загружена конфигурация из $CONFIG_FILE"
fi

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

# Функция для проверки наличия необходимых утилит
check_required_tools() {
    local missing_tools=()
    
    # Проверяем sha256sum (обычно есть в Arch Linux)
    if ! command -v sha256sum &> /dev/null; then
        if ! command -v shasum &> /dev/null; then
            missing_tools+=("sha256sum (или shasum)")
        fi
    fi
    
    # Проверяем gpg (для проверки подписей)
    if ! command -v gpg &> /dev/null; then
        missing_tools+=("gpg")
    fi
    
    if [[ ${#missing_tools[@]} -gt 0 ]]; then
        print_warning "Отсутствуют некоторые утилиты: ${missing_tools[*]}"
        print_message "Проверка подписей может быть недоступна"
    fi
}

# Функция для скачивания и проверки SHA256 файла
download_and_verify_checksum() {
    local target_dir="$1"
    local version="$2"
    local checksum_file="$target_dir/CHECKSUMS.sha256"
    local temp_checksum="/tmp/checksums_$$.sha256"
    
    print_message "Скачивание файла checksums..."
    
    # Пробуем скачать с GitHub (RAW)
    local checksum_url="https://raw.githubusercontent.com/ncux-ad/SteamDeck_start/main/CHECKSUMS.sha256"
    
    if curl -sfL "$checksum_url" -o "$temp_checksum" 2>/dev/null; then
        # Копируем в целевую директорию
        cp "$temp_checksum" "$checksum_file"
        rm -f "$temp_checksum"
        print_success "Checksum файл скачан: $checksum_file"
        return 0
    else
        print_warning "Не удалось скачать checksum файл с GitHub"
        print_message "Обновление продолжится без проверки checksums"
        rm -f "$temp_checksum"
        return 1
    fi
}

# Функция для проверки checksum файла
verify_file_checksum() {
    local file_path="$1"
    local checksum_file="$2"
    
    # Проверяем наличие checksum файла
    if [[ ! -f "$checksum_file" ]]; then
        print_warning "Checksum файл не найден, пропускаем проверку"
        return 0  # Не критично, продолжаем
    fi
    
    print_debug "Проверка checksum для: $file_path"
    
    # Получаем базовое имя файла
    local basename_file=$(basename "$file_path")
    local expected_checksum=""
    
    # Ищем checksum в файле
    if command -v sha256sum &> /dev/null; then
        expected_checksum=$(grep -E "  ${basename_file}$" "$checksum_file" | awk '{print $1}')
    elif command -v shasum &> /dev/null; then
        expected_checksum=$(grep -E "  ${basename_file}$" "$checksum_file" | awk '{print $1}')
    fi
    
    if [[ -z "$expected_checksum" ]]; then
        print_warning "Checksum для $basename_file не найден в файле"
        return 0  # Не критично, продолжаем
    fi
    
    # Вычисляем реальный checksum
    local actual_checksum=""
    if command -v sha256sum &> /dev/null; then
        actual_checksum=$(sha256sum "$file_path" 2>/dev/null | awk '{print $1}')
    elif command -v shasum &> /dev/null; then
        actual_checksum=$(shasum -a 256 "$file_path" 2>/dev/null | awk '{print $1}')
    fi
    
    if [[ -z "$actual_checksum" ]]; then
        print_error "Не удалось вычислить checksum для $file_path"
        return 1
    fi
    
    # Сравниваем
    if [[ "$actual_checksum" == "$expected_checksum" ]]; then
        print_success "Checksum совпадает: $basename_file"
        return 0
    else
        print_error "Checksum НЕ совпадает для $basename_file"
        print_error "Ожидалось: $expected_checksum"
        print_error "Получено: $actual_checksum"
        return 1
    fi
}

# Функция для проверки GPG подписи (если доступна)
verify_gpg_signature() {
    local signature_file="$1"
    local file_to_verify="$2"
    local gpg_key_url="$3"
    
    # Проверяем наличие gpg
    if ! command -v gpg &> /dev/null; then
        print_warning "GPG не установлен, пропускаем проверку подписи"
        return 0  # Не критично
    fi
    
    print_message "Проверка GPG подписи..."
    
    # Скачиваем публичный ключ (если еще не импортирован)
    local key_imported=false
    if gpg --list-keys "ncux-ad@users.noreply.github.com" &>/dev/null; then
        key_imported=true
    fi
    
    if [[ "$key_imported" == "false" ]] && [[ -n "$gpg_key_url" ]]; then
        print_message "Импорт публичного ключа..."
        if curl -sL "$gpg_key_url" | gpg --import &>/dev/null; then
            key_imported=true
        else
            print_warning "Не удалось импортировать GPG ключ"
        fi
    fi
    
    if [[ "$key_imported" == "false" ]]; then
        print_warning "GPG ключ не найден, пропускаем проверку подписи"
        return 0  # Не критично
    fi
    
    # Проверяем подпись
    if gpg --verify "$signature_file" "$file_to_verify" &>/dev/null; then
        print_success "GPG подпись проверена успешно"
        return 0
    else
        print_error "GPG подпись НЕВЕРНАЯ"
        return 1
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
    # 2. В установленной директории (новая локация /home/deck/utils)
    elif [[ -f "$INSTALL_DIR/VERSION" ]]; then
        version_file="$INSTALL_DIR/VERSION"
    # 3. В текущей рабочей директории
    elif [[ -f "./VERSION" ]]; then
        version_file="./VERSION"
    # 4. В старой директории SteamDeck (для совместимости)
    elif [[ -f "$DECK_HOME/SteamDeck/VERSION" ]]; then
        version_file="$DECK_HOME/SteamDeck/VERSION"
    # 5. В новой директории utils/SteamDeck
    elif [[ -f "$DECK_HOME/utils/SteamDeck/VERSION" ]]; then
        version_file="$DECK_HOME/utils/SteamDeck/VERSION"
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
        print_debug "  - $DECK_HOME/utils/SteamDeck/VERSION" >&2
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
    local target_dir="${2:-$install_dir}"
    
    print_message "Создание резервной копии текущей версии..."
    print_debug "install_dir: $install_dir"
    print_debug "target_dir: $target_dir"
    print_debug "PROJECT_ROOT: $PROJECT_ROOT"
    
    # Определяем где создавать backup
    local backup_location=""
    
    # Если обновляем установленную в память утилиту
    if [[ "$target_dir" == "$INSTALL_DIR" ]]; then
        # Создаем backup в /home/deck/utils/SteamDeck/backups/
        backup_location="$DECK_HOME/utils/SteamDeck/backups/steamdeck_backup_$(date +%Y%m%d_%H%M%S)"
    # Если обновляем с флешки
    elif [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
        # Для флешки создаем backup рядом с PROJECT_ROOT
        local parent_dir="$(dirname "$PROJECT_ROOT")"
        backup_location="$parent_dir/steamdeck_backup_$(date +%Y%m%d_%H%M%S)"
    # Fallback - в /tmp
    else
        backup_location="/tmp/steamdeck_backup_$(date +%Y%m%d_%H%M%S)"
    fi
    
    print_debug "Резервная копия будет создана в: $backup_location"
    
    # Создаем директорию для backup
    mkdir -p "$(dirname "$backup_location")" 2>/dev/null || true
    
    # Копируем установленную утилиту
    if [[ -d "$target_dir" ]]; then
        print_debug "Копирование из: $target_dir"
        
        # Проверяем права на запись
        if [[ -w "$(dirname "$backup_location")" ]]; then
            if cp -r "$target_dir" "$backup_location"; then
                print_success "Резервная копия создана: $backup_location"
                
                # Устанавливаем права на backup
                chown -R "$(whoami):$(whoami)" "$backup_location" 2>/dev/null || true
                return 0
            else
                print_error "Не удалось создать резервную копию в: $backup_location"
                # Fallback на /tmp
                backup_location="/tmp/steamdeck_backup_$(date +%Y%m%d_%H%M%S)"
                cp -r "$target_dir" "$backup_location"
                print_success "Резервная копия создана в /tmp: $backup_location"
                return 0
            fi
        else
            # Пробуем с sudo
            if sudo cp -r "$target_dir" "$backup_location"; then
                # Исправляем права доступа
                sudo chown -R $(whoami):$(whoami) "$backup_location"
                print_success "Резервная копия создана: $backup_location"
                return 0
            else
                print_error "Не удалось создать резервную копию с sudo"
                return 1
            fi
        fi
    else
        print_warning "Не найдена папка для резервного копирования: $target_dir"
        return 1
    fi
}

# Функция для обновления
update_utility() {
    # Проверяем, не вызывается ли функция с аргументом "apply-update"
    if [[ "$1" == "apply-update" ]]; then
        # Применяем обновление к установленной версии
        local target_dir="${2:-$PROJECT_ROOT}"
        # Принимаем новую директорию как третий аргумент (если передан)
        # Используем PROJECT_ROOT как fallback (уже определен глобально)
        local new_dir="${3:-$PROJECT_ROOT}"
        
        print_message "Применение обновления к: $target_dir"
        print_debug "Источник обновления: $new_dir"
        print_debug "Целевая директория: $target_dir"
        
        # Создаем резервную копию (ПРОВЕРЯЕМ УСПЕШНОСТЬ!)
        print_message "Создание резервной копии..."
        if ! create_backup "$target_dir" ""; then
            print_error "Не удалось создать резервную копию, отменяем обновление"
            return 1
        fi
        
        # Сохраняем пользовательские настройки
        local user_config="$target_dir/user_config"
        local temp_config="/tmp/steamdeck_config_$$"
        if [[ -d "$user_config" ]]; then
            cp -r "$user_config" "$temp_config"
        fi
        
        # Определяем куда копировать
        # ВАЖНО: обновляем ТОЛЬКО директорию, откуда запущено обновление!
        # НЕ переключаемся на INSTALL_DIR, если обновление запущено с флешки
        print_debug "Целевая директория для обновления: $target_dir"
        print_debug "INSTALL_DIR: $INSTALL_DIR"
        
        # ============= ATOMIC UPDATE: Создаем временную директорию =============
        local temp_update_dir="${target_dir}.tmp_update_$$"
        print_message "Создание временной директории для обновления: $temp_update_dir"
        
        # Копируем новую версию во временную директорию
        print_message "Копирование новых файлов во временную директорию..."
        
        # Определяем владельца для файлов
        local file_owner=""
        if [[ "$target_dir" == "$INSTALL_DIR" ]] && [[ -n "$DECK_USER" ]]; then
            file_owner="$DECK_USER:$DECK_USER"
        elif [[ -n "$USER" ]]; then
            file_owner="$USER:$USER"
        else
            file_owner="$(whoami):$(whoami)"
        fi
        
        print_debug "Владелец файлов будет: $file_owner"
        
        # Копируем во временную директорию
        if [[ -w "$(dirname "$target_dir")" ]]; then
            # Копируем без sudo с сохранением прав
            if rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' --chown="$file_owner" "$new_dir/" "$temp_update_dir/"; then
                print_success "Копирование завершено успешно"
            else
                print_warning "rsync с chown не удался, пробуем без chown..."
                if rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$new_dir/" "$temp_update_dir/"; then
                    print_success "Копирование завершено успешно (без chown)"
                    # Исправляем права вручную после копирования
                    chown -R "$file_owner" "$temp_update_dir" 2>/dev/null || true
                else
                    print_error "Ошибка при копировании файлов"
                    rm -rf "$temp_update_dir"
                    return 1
                fi
            fi
        else
            # Копируем с sudo и установкой владельца
            if sudo rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' --chown="$file_owner" "$new_dir/" "$temp_update_dir/"; then
                print_success "Копирование завершено успешно"
            else
                print_warning "rsync с sudo chown не удался, пробуем без chown..."
                if sudo rsync -av --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$new_dir/" "$temp_update_dir/"; then
                    print_success "Копирование завершено успешно (без chown)"
                    # Исправляем права вручную после копирования
                    sudo chown -R "$file_owner" "$temp_update_dir" 2>/dev/null || true
                else
                    print_error "Ошибка при копировании файлов с sudo"
                    rm -rf "$temp_update_dir"
                    return 1
                fi
            fi
        fi
        
        # Восстанавливаем пользовательские настройки во временную директорию
        if [[ -d "$temp_config" ]]; then
            cp -r "$temp_config" "$temp_update_dir/user_config"
            rm -rf "$temp_config"
        fi
        
        # Устанавливаем права доступа
        if [[ -d "$temp_update_dir" ]]; then
            if [[ -w "$temp_update_dir" ]]; then
                chmod -R 755 "$temp_update_dir"
                chmod +x "$temp_update_dir/scripts"/*.sh 2>/dev/null || true
                chmod +x "$temp_update_dir"/*.sh 2>/dev/null || true
            else
                sudo chmod -R 755 "$temp_update_dir"
                sudo chmod +x "$temp_update_dir/scripts"/*.sh 2>/dev/null || true
                sudo chmod +x "$temp_update_dir"/*.sh 2>/dev/null || true
            fi
        fi
        
        # Скачиваем checksum файл (если доступен)
        local version=$(cat "$temp_update_dir/VERSION" 2>/dev/null | tr -d '\n')
        download_and_verify_checksum "$temp_update_dir" "$version"
        
        # Проверяем целостность ОБНОВЛЕНИЯ во временной директории
        print_message "Проверка целостности обновления..."
        if ! verify_update_integrity "$temp_update_dir"; then
            print_error "Обновление некорректно, выполняем откат"
            rm -rf "$temp_update_dir"
            rollback_update
            return 1
        fi
        
        # ============= ATOMIC SWAP: Атомарная подмена =============
        print_message "Атомарное применение обновления..."
        
        # Переименовываем старую версию
        local old_backup="${target_dir}.old_$$"
        if [[ -e "$target_dir" ]]; then
            if mv "$target_dir" "$old_backup"; then
                print_success "Старая версия сохранена: $old_backup"
            else
                print_error "Не удалось переместить старую версию"
                rm -rf "$temp_update_dir"
                return 1
            fi
        fi
        
        # Атомарно перемещаем новую версию на место старой
        if mv "$temp_update_dir" "$target_dir"; then
            print_success "Обновление применено атомарно"
        else
            print_error "Не удалось переместить новую версию, восстанавливаем старую"
            mv "$old_backup" "$target_dir" 2>/dev/null
            rm -rf "$temp_update_dir"
            rollback_update
            return 1
        fi
        
        # Удаляем старую версию (только после успешной подмены!)
        if [[ -d "$old_backup" ]]; then
            rm -rf "$old_backup"
        fi
        
        print_success "Обновление завершено!"
        return 0
    fi
    
    print_message "Обновление Steam Deck Enhancement Pack..."
    
    # Определяем, откуда запущено обновление
    local update_target_dir=""
    if [[ -d "$INSTALL_DIR" ]] && [[ -f "$INSTALL_DIR/scripts/steamdeck_gui.py" ]]; then
        # Утилита установлена в память Steam Deck
        update_target_dir="$INSTALL_DIR"
        print_message "Обнаружена установка в память: $update_target_dir"
        print_message "Обновление будет применено к установленной версии"
    elif [[ -d "$PROJECT_ROOT" ]]; then
        # Запущено с флешки или другого места
        update_target_dir="$PROJECT_ROOT"
        print_message "Обновление будет применено к: $update_target_dir"
    else
        print_error "Не найдена директория для обновления"
        return 1
    fi
    
    # Проверяем, запущены ли мы из обновляемой папки или из новой версии
    # Проверяем, не запущен ли уже процесс обновления
    local update_lock_dir="/tmp/steamdeck_update_lock_$$"
    
    # Используем mkdir для атомарного создания lock (best practice!)
    if ! mkdir "$update_lock_dir" 2>/dev/null; then
        # Проверяем, действительно ли процесс жив
        local lock_pid=$(cat "$update_lock_dir/PID" 2>/dev/null)
        if [[ -n "$lock_pid" ]] && kill -0 "$lock_pid" 2>/dev/null; then
            print_error "Обновление уже выполняется (PID: $lock_pid)"
            print_message "Если это ошибочно, удалите директорию: $update_lock_dir"
            return 1
        else
            # Процесс завершился некорректно, удаляем старый lock
            print_warning "Обнаружен старый lock, удаляем его..."
            rm -rf "$update_lock_dir"
            # Пробуем создать снова
            if ! mkdir "$update_lock_dir" 2>/dev/null; then
                print_error "Не удалось создать lock, возможно другой процесс создал его"
                return 1
            fi
        fi
    fi
    
    # Сохраняем PID в lock-директории
    echo $$ > "$update_lock_dir/PID"
    
    # Устанавливаем trap для очистки lock при выходе
    trap "rm -rf '$update_lock_dir'" EXIT INT TERM
    
    # Мы запущены из обновляемой папки - запускаем схему обновления
    print_message "Запуск схемы безопасного обновления..."
    print_debug "Целевая директория для обновления: $update_target_dir"
    
    # Очищаем и создаем временную папку для новой версии
    local temp_new_dir="/tmp/steamdeck_update_new_$$"
    rm -rf "$temp_new_dir"
    
    # Проверяем, что можем создать временную директорию
    if ! mkdir -p "$temp_new_dir" 2>/dev/null; then
        print_error "Не удалось создать временную директорию: $temp_new_dir"
        rm -rf "$update_lock_dir"
        return 1
    fi
    
    # Сохраняем текущую директорию
    local original_dir="$(pwd)"
    
    # Клонируем последнюю версию
    print_message "Загрузка последней версии с GitHub..."
    print_debug "Клонирование в: $temp_new_dir"
    
    # Пробуем клонировать с различными опциями
    if git clone "$REPO_URL" "$temp_new_dir/steamdeck_latest" 2>&1 | tee /tmp/git_clone.log; then
        print_success "Последняя версия загружена"
    else
        print_error "Не удалось загрузить последнюю версию с GitHub"
        print_message "Детали ошибки:"
        cat /tmp/git_clone.log | head -20
        print_message ""
        print_warning "Проверьте интернет-соединение и доступность GitHub"
        rm -rf "$temp_new_dir"
        rm -rf "$update_lock_dir"
        trap - EXIT INT TERM
        return 1
    fi
    
    # Возвращаемся в оригинальную директорию
    cd "$original_dir"
    
    # Сохраняем флаг, был ли запущен GUI перед обновлением
    local gui_was_running=false
    if pgrep -f "steamdeck_gui.py" > /dev/null; then
        gui_was_running=true
        print_message "Остановка текущего GUI..."
        pkill -f "steamdeck_gui.py"
        sleep 2  # Даем время GUI корректно закрыться
    fi
    
    # ПРИМЕНЯЕМ ОБНОВЛЕНИЕ НАПРЯМУЮ (без рекурсивного вызова)
    print_message "Применение обновления к: $update_target_dir"
    print_debug "Источник обновления: $temp_new_dir/steamdeck_latest"
    
    # Вызываем apply-update напрямую
    if update_utility "apply-update" "$update_target_dir" "$temp_new_dir/steamdeck_latest"; then
        print_success "Обновление применено успешно"
        
        # Очищаем временную папку
        rm -rf "$temp_new_dir"
        
        # Удаляем lock директорию
        rm -rf "$update_lock_dir"
        
        # Снимаем trap
        trap - EXIT INT TERM
        
        # Запускаем GUI из новой версии (только если был запущен до обновления)
        if [[ "$gui_was_running" == "true" ]] && [[ -f "$update_target_dir/scripts/steamdeck_gui.py" ]]; then
            print_message "Перезапуск обновленного GUI..."
            
            # Создаем временный скрипт для запуска GUI в отдельном процессе
            local restart_script="/tmp/steamdeck_restart_gui_$$.sh"
            cat > "$restart_script" << 'RESTARTEOF'
#!/bin/bash
# Временный скрипт для перезапуска GUI после обновления
# This script will be called with target directory as first argument

TARGET_DIR="$1"

if [[ -z "$TARGET_DIR" ]]; then
    echo "Ошибка: не указана целевая директория"
    exit 1
fi

sleep 2  # Небольшая задержка для завершения текущего процесса

# Запускаем новый GUI
cd "$TARGET_DIR"
if [[ -f "scripts/steamdeck_gui.py" ]]; then
    python3 scripts/steamdeck_gui.py &
    echo "GUI перезапущен успешно из: $TARGET_DIR"
else
    echo "Ошибка: файл GUI не найден в: $TARGET_DIR"
    exit 1
fi

# Удаляем временный скрипт
rm -f "$0"
RESTARTEOF
            chmod +x "$restart_script"
            
            # Запускаем скрипт с передачей целевой директории как аргумента
            nohup bash "$restart_script" "$update_target_dir" > /dev/null 2>&1 &
            
            print_success "GUI будет перезапущен автоматически из $update_target_dir"
        else
            if [[ "$gui_was_running" == "true" ]]; then
                print_warning "GUI был запущен, но файл не найден после обновления в $update_target_dir"
            else
                print_message "GUI не был запущен перед обновлением"
            fi
        fi
    else
        print_error "Ошибка при применении обновления"
        
        # Очищаем временную папку
        rm -rf "$temp_new_dir"
        
        # Удаляем lock директорию
        rm -rf "$update_lock_dir"
        
        # Снимаем trap
        trap - EXIT INT TERM
        
        # Пытаемся откатить изменения, если доступен backup
        local backup_search="$target_dir/steamdeck_backup_*"
        if compgen -G "$backup_search" > /dev/null; then
            print_message "Попытка откатить изменения из резервной копии..."
            # Здесь можно добавить логику отката
        fi
        
        return 1
    fi
    
    return 0
}

# Функция для проверки целостности обновления
verify_update_integrity() {
    local target_dir="${1:-}"
    
    # Если target_dir не передан, пытаемся определить автоматически
    if [[ -z "$target_dir" ]]; then
        if [[ -d "$INSTALL_DIR" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
            target_dir="$INSTALL_DIR"
        elif [[ -d "$PROJECT_ROOT" ]]; then
            target_dir="$PROJECT_ROOT"
        else
            print_error "Не найдена директория для проверки"
            return 1
        fi
    fi
    
    print_message "Проверка целостности обновления в: $target_dir"
    
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
    
    # Проверяем, что файлы не пустые
    for file in "${key_files[@]}"; do
        if [[ ! -s "$target_dir/$file" ]]; then
            print_error "Файл пустой: $file"
            return 1
        fi
    done
    
    # Проверяем версию файла VERSION
    if [[ -f "$target_dir/VERSION" ]]; then
        local version=$(cat "$target_dir/VERSION" | tr -d '\n')
        if [[ -n "$version" ]] && [[ "$version" != "unknown" ]]; then
            print_success "Версия обновленной утилиты: $version"
        else
            print_warning "Не удалось прочитать версию из VERSION файла"
        fi
    fi
    
    # Проверяем checksums (если доступны)
    local checksum_file="$target_dir/CHECKSUMS.sha256"
    if [[ -f "$checksum_file" ]]; then
        print_message "Проверка checksums ключевых файлов..."
        local checksum_failed=false
        
        for file in "${key_files[@]}"; do
            if ! verify_file_checksum "$target_dir/$file" "$checksum_file"; then
                checksum_failed=true
            fi
        done
        
        if [[ "$checksum_failed" == "true" ]]; then
            print_error "Некоторые файлы не прошли проверку checksum"
            return 1
        fi
    else
        print_warning "Checksum файл не найден, пропускаем проверку checksums"
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
    
    # 1. Ищем в /home/deck/utils/SteamDeck/backups/ (новое место для установленной утилиты)
    if [[ -d "$DECK_HOME/utils/SteamDeck/backups" ]]; then
        backup_dirs+=($DECK_HOME/utils/SteamDeck/backups/steamdeck_backup_*)
    fi
    
    # 2. Ищем в директории установленной утилиты (старая логика для совместимости)
    if [[ -d "$INSTALL_DIR" ]]; then
        backup_dirs+=($(dirname "$INSTALL_DIR")/SteamDeck_backup_*)
        backup_dirs+=($(dirname "$INSTALL_DIR")/steamdeck_backup_*)
    fi
    
    # 3. Ищем в директории проекта (для флешки)
    if [[ -d "$PROJECT_ROOT" ]] && [[ "$PROJECT_ROOT" != "$INSTALL_DIR" ]]; then
        backup_dirs+=($(dirname "$PROJECT_ROOT")/steamdeck_backup_*)
        backup_dirs+=($(dirname "$PROJECT_ROOT")/SteamDeck_backup_*)
    fi
    
    # 4. Ищем в домашней директории пользователя (старая логика)
    backup_dirs+=($HOME/SteamDeck_backup_*)
    
    # 5. Fallback - в /tmp
    backup_dirs+=(/tmp/steamdeck_backup_*)
    
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
            check_required_tools || true  # Не критично, продолжаем
            update_utility
            ;;
        "apply-update")
            # Внутренняя команда для применения обновления
            # Вызывается из новой версии для обновления старой
            shift  # Убираем "apply-update" из аргументов
            update_utility "apply-update" "$@"
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
