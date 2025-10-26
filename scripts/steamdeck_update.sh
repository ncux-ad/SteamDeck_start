#!/bin/bash

# Steam Deck Update Script
# Скрипт для обновления Steam Deck Enhancement Pack через GitHub
# Автор: @ncux11
# Версия: динамическая (читается из VERSION)

# set -e отключен для корректной обработки кодов возврата
set +e

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
        # Мы запущены из новой версии - применяем обновление к старой
        local target_dir="${2:-$PROJECT_ROOT}"
        local new_dir="$(dirname "$(dirname "$(realpath "$0")")")"
        
        print_message "Применение обновления к: $target_dir"
        print_debug "Источник обновления: $new_dir"
        print_debug "Целевая директория: $target_dir"
        
        # Создаем резервную копию
        create_backup "$target_dir" ""
        
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
        
        # Копируем новые файлы
        print_message "Копирование новых файлов..."
        
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
        
        if [[ -w "$target_dir" ]]; then
            # Копируем без sudo с сохранением прав
            if rsync -av --delete --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' --chown="$file_owner" "$new_dir/" "$target_dir/"; then
                print_success "Копирование завершено успешно"
            else
                print_warning "rsync с chown не удался, пробуем без chown..."
                if rsync -av --delete --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$new_dir/" "$target_dir/"; then
                    print_success "Копирование завершено успешно (без chown)"
                    # Исправляем права вручную после копирования
                    chown -R "$file_owner" "$target_dir" 2>/dev/null || true
                else
                    print_error "Ошибка при копировании файлов"
                    return 1
                fi
            fi
        else
            # Копируем с sudo и установкой владельца
            if sudo rsync -av --delete --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' --chown="$file_owner" "$new_dir/" "$target_dir/"; then
                print_success "Копирование завершено успешно"
            else
                print_warning "rsync с sudo chown не удался, пробуем без chown..."
                if sudo rsync -av --delete --exclude='.git' --exclude='__pycache__' --exclude='*.pyc' "$new_dir/" "$target_dir/"; then
                    print_success "Копирование завершено успешно (без chown)"
                    # Исправляем права вручную после копирования
                    sudo chown -R "$file_owner" "$target_dir" 2>/dev/null || true
                else
                    print_error "Ошибка при копировании файлов с sudo"
                    return 1
                fi
            fi
        fi
        
        # Восстанавливаем пользовательские настройки
        if [[ -d "$temp_config" ]]; then
            cp -r "$temp_config" "$target_dir/user_config"
            rm -rf "$temp_config"
        fi
        
        # Устанавливаем права доступа
        if [[ -d "$target_dir" ]]; then
            if [[ -w "$target_dir" ]]; then
                chmod -R 755 "$target_dir"
                chmod +x "$target_dir/scripts"/*.sh 2>/dev/null || true
                chmod +x "$target_dir"/*.sh 2>/dev/null || true
            else
                sudo chmod -R 755 "$target_dir"
                sudo chmod +x "$target_dir/scripts"/*.sh 2>/dev/null || true
                sudo chmod +x "$target_dir"/*.sh 2>/dev/null || true
            fi
        fi
        
        # Проверяем целостность обновления
        verify_update_integrity "$target_dir"
        
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
    local update_lock_file="/tmp/steamdeck_update.lock"
    if [[ -f "$update_lock_file" ]]; then
        local lock_pid=$(cat "$update_lock_file")
        if kill -0 "$lock_pid" 2>/dev/null; then
            print_error "Обновление уже выполняется (PID: $lock_pid)"
            print_message "Если это ошибочно, удалите файл: $update_lock_file"
            return 1
        else
            # Процесс завершился некорректно, удаляем lock
            rm -f "$update_lock_file"
        fi
    fi
    
    # Создаем lock файл
    echo $$ > "$update_lock_file"
    
    # Устанавливаем trap для очистки lock при выходе
    trap "rm -f '$update_lock_file'" EXIT INT TERM
    
    # Мы запущены из обновляемой папки - запускаем схему обновления
    print_message "Запуск схемы безопасного обновления..."
    print_debug "Целевая директория для обновления: $update_target_dir"
    
    # Очищаем и создаем временную папку для новой версии
    local temp_new_dir="/tmp/steamdeck_update_new_$$"
    rm -rf "$temp_new_dir"
    
    # Проверяем, что можем создать временную директорию
    if ! mkdir -p "$temp_new_dir" 2>/dev/null; then
        print_error "Не удалось создать временную директорию: $temp_new_dir"
        rm -f "$update_lock_file"
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
        rm -f "$update_lock_file"
        trap - EXIT INT TERM
        return 1
    fi
    
    # Возвращаемся в оригинальную директорию
    cd "$original_dir"
    
    # Запускаем updater из новой версии
    print_message "Запуск updater из новой версии..."
    print_debug "Источник: $temp_new_dir/steamdeck_latest/scripts/steamdeck_update.sh"
    print_debug "Цель: $PROJECT_ROOT"
    
    # Сохраняем флаг, был ли запущен GUI перед обновлением
    local gui_was_running=false
    if pgrep -f "steamdeck_gui.py" > /dev/null; then
        gui_was_running=true
        print_message "Остановка текущего GUI..."
        pkill -f "steamdeck_gui.py"
        sleep 2  # Даем время GUI корректно закрыться
    fi
    
    if bash "$temp_new_dir/steamdeck_latest/scripts/steamdeck_update.sh" apply-update "$update_target_dir"; then
        print_success "Обновление применено успешно"
        
        # Очищаем временную папку
        rm -rf "$temp_new_dir"
        
        # Удаляем lock файл
        rm -f "$update_lock_file"
        
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
        
        # Удаляем lock файл
        rm -f "$update_lock_file"
        
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
