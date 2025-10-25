#!/bin/bash

# Steam Deck Update Script
# Скрипт для обновления Steam Deck Enhancement Pack через GitHub
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e  # Выход при ошибке

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Конфигурация
REPO_URL="https://github.com/ncux-ad/SteamDeck_start.git"
INSTALL_DIR="/home/deck/SteamDeck"
BACKUP_DIR="/home/deck/SteamDeck_backup_$(date +%Y%m%d_%H%M%S)"
TEMP_DIR="/tmp/steamdeck_update"

# Функции для вывода
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
    local version_file="$INSTALL_DIR/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "unknown"
    fi
}

# Функция для получения последней версии с GitHub
get_latest_version() {
    local temp_repo="/tmp/steamdeck_latest"
    
    # Клонируем репозиторий во временную папку
    if [[ -d "$temp_repo" ]]; then
        rm -rf "$temp_repo"
    fi
    
    git clone --depth 1 "$REPO_URL" "$temp_repo" &> /dev/null
    
    local version_file="$temp_repo/VERSION"
    if [[ -f "$version_file" ]]; then
        cat "$version_file"
    else
        echo "unknown"
    fi
    
    # Очищаем временную папку
    rm -rf "$temp_repo"
}

# Функция для создания резервной копии
create_backup() {
    print_message "Создание резервной копии текущей версии..."
    
    if [[ -d "$INSTALL_DIR" ]]; then
        cp -r "$INSTALL_DIR" "$BACKUP_DIR"
        print_success "Резервная копия создана: $BACKUP_DIR"
        return 0
    else
        print_warning "Папка установки не найдена: $INSTALL_DIR"
        return 1
    fi
}

# Функция для обновления
update_utility() {
    print_message "Обновление Steam Deck Enhancement Pack..."
    
    # Создаем временную папку
    mkdir -p "$TEMP_DIR"
    cd "$TEMP_DIR"
    
    # Клонируем последнюю версию
    print_message "Загрузка последней версии с GitHub..."
    if git clone "$REPO_URL" steamdeck_latest; then
        print_success "Последняя версия загружена"
    else
        print_error "Не удалось загрузить последнюю версию"
        return 1
    fi
    
    # Останавливаем GUI если запущен
    print_message "Остановка GUI (если запущен)..."
    pkill -f "steamdeck_gui.py" 2>/dev/null || true
    
    # Создаем резервную копию
    create_backup
    
    # Копируем новые файлы
    print_message "Установка обновления..."
    if [[ -d "$INSTALL_DIR" ]]; then
        # Сохраняем пользовательские настройки
        local user_config="$INSTALL_DIR/user_config"
        if [[ -d "$user_config" ]]; then
            cp -r "$user_config" "$TEMP_DIR/"
        fi
        
        # Удаляем старую версию
        rm -rf "$INSTALL_DIR"
    fi
    
    # Копируем новую версию
    cp -r "$TEMP_DIR/steamdeck_latest" "$INSTALL_DIR"
    
    # Восстанавливаем пользовательские настройки
    if [[ -d "$TEMP_DIR/user_config" ]]; then
        cp -r "$TEMP_DIR/user_config" "$INSTALL_DIR/"
    fi
    
    # Устанавливаем права доступа
    chown -R deck:deck "$INSTALL_DIR"
    chmod -R 755 "$INSTALL_DIR"
    chmod +x "$INSTALL_DIR/scripts"/*.sh 2>/dev/null || true
    chmod +x "$INSTALL_DIR"/*.sh 2>/dev/null || true
    
    # Обновляем символические ссылки
    print_message "Обновление символических ссылок..."
    ln -sf "$INSTALL_DIR/scripts/steamdeck_setup.sh" "/home/deck/steamdeck-setup" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/scripts/steamdeck_gui.py" "/home/deck/steamdeck-gui" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/scripts/steamdeck_backup.sh" "/home/deck/steamdeck-backup" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/scripts/steamdeck_cleanup.sh" "/home/deck/steamdeck-cleanup" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/scripts/steamdeck_optimizer.sh" "/home/deck/steamdeck-optimizer" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/scripts/steamdeck_microsd.sh" "/home/deck/steamdeck-microsd" 2>/dev/null || true
    ln -sf "$INSTALL_DIR/scripts/steamdeck_update.sh" "/home/deck/steamdeck-update" 2>/dev/null || true
    
    # Очищаем временную папку
    rm -rf "$TEMP_DIR"
    
    print_success "Обновление завершено!"
}

# Функция для проверки обновлений
check_updates() {
    print_header "ПРОВЕРКА ОБНОВЛЕНИЙ"
    
    local current_version=$(get_current_version)
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
        chown -R deck:deck "$INSTALL_DIR"
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
