#!/bin/bash

# Steam Deck Backup Script
# Скрипт для резервного копирования важных данных Steam Deck
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Конфигурация
BACKUP_DIR="$HOME/SteamDeck_Backups"
DATE=$(date +%Y%m%d_%H%M%S)
BACKUP_NAME="steamdeck_backup_$DATE"

# Функции для вывода
print_message() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Создание директории для бэкапов
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        print_success "Создана директория для бэкапов: $BACKUP_DIR"
    fi
}

# Резервное копирование сохранений игр
backup_game_saves() {
    print_message "Копирование сохранений игр..."
    
    local saves_dir="$BACKUP_DIR/$BACKUP_NAME/game_saves"
    mkdir -p "$saves_dir"
    
    # Steam сохранения
    if [[ -d "$HOME/.steam/steam/userdata" ]]; then
        cp -r "$HOME/.steam/steam/userdata" "$saves_dir/steam_userdata"
        print_success "Steam сохранения скопированы"
    fi
    
    # Proton сохранения
    if [[ -d "$HOME/.steam/steam/steamapps/compatdata" ]]; then
        cp -r "$HOME/.steam/steam/steamapps/compatdata" "$saves_dir/proton_saves"
        print_success "Proton сохранения скопированы"
    fi
    
    # Wine сохранения
    if [[ -d "$HOME/.wine" ]]; then
        cp -r "$HOME/.wine" "$saves_dir/wine"
        print_success "Wine сохранения скопированы"
    fi
    
    # Bottles сохранения
    if [[ -d "$HOME/.var/app/com.usebottles.bottles" ]]; then
        cp -r "$HOME/.var/app/com.usebottles.bottles" "$saves_dir/bottles"
        print_success "Bottles сохранения скопированы"
    fi
}

# Резервное копирование конфигураций
backup_configs() {
    print_message "Копирование конфигураций..."
    
    local configs_dir="$BACKUP_DIR/$BACKUP_NAME/configs"
    mkdir -p "$configs_dir"
    
    # Steam конфиги
    if [[ -d "$HOME/.steam" ]]; then
        cp -r "$HOME/.steam" "$configs_dir/steam"
        print_success "Steam конфиги скопированы"
    fi
    
    # Системные конфиги
    if [[ -f "/etc/pacman.conf" ]]; then
        sudo cp "/etc/pacman.conf" "$configs_dir/pacman.conf"
        print_success "Pacman конфиг скопирован"
    fi
    
    # Пользовательские конфиги
    if [[ -d "$HOME/.config" ]]; then
        cp -r "$HOME/.config" "$configs_dir/user_config"
        print_success "Пользовательские конфиги скопированы"
    fi
    
    # Flatpak конфиги
    if [[ -d "$HOME/.var" ]]; then
        cp -r "$HOME/.var" "$configs_dir/flatpak_data"
        print_success "Flatpak данные скопированы"
    fi
}

# Резервное копирование списка пакетов
backup_packages() {
    print_message "Создание списка установленных пакетов..."
    
    local packages_dir="$BACKUP_DIR/$BACKUP_NAME/packages"
    mkdir -p "$packages_dir"
    
    # Pacman пакеты
    if command -v pacman &> /dev/null; then
        pacman -Qqe > "$packages_dir/pacman_packages.txt"
        print_success "Список pacman пакетов создан"
    fi
    
    # AUR пакеты
    if command -v yay &> /dev/null; then
        yay -Qm > "$packages_dir/aur_packages.txt"
        print_success "Список AUR пакетов создан"
    fi
    
    # Flatpak пакеты
    if command -v flatpak &> /dev/null; then
        flatpak list --app > "$packages_dir/flatpak_packages.txt"
        print_success "Список Flatpak пакетов создан"
    fi
}

# Создание архива
create_archive() {
    print_message "Создание архива..."
    
    local archive_path="$BACKUP_DIR/$BACKUP_NAME.tar.gz"
    
    if tar -czf "$archive_path" -C "$BACKUP_DIR" "$BACKUP_NAME"; then
        print_success "Архив создан: $archive_path"
        
        # Удаление временной директории
        rm -rf "$BACKUP_DIR/$BACKUP_NAME"
        print_success "Временные файлы удалены"
        
        # Показать размер архива
        local size=$(du -h "$archive_path" | cut -f1)
        print_message "Размер архива: $size"
    else
        print_error "Не удалось создать архив"
        exit 1
    fi
}

# Восстановление из архива
restore_backup() {
    local archive_path="$1"
    
    if [[ ! -f "$archive_path" ]]; then
        print_error "Архив не найден: $archive_path"
        exit 1
    fi
    
    print_message "Восстановление из архива: $archive_path"
    
    # Создание временной директории для восстановления
    local temp_dir=$(mktemp -d)
    
    # Распаковка архива
    if tar -xzf "$archive_path" -C "$temp_dir"; then
        print_success "Архив распакован"
        
        local backup_name=$(basename "$archive_path" .tar.gz)
        local backup_data="$temp_dir/$backup_name"
        
        # Восстановление сохранений
        if [[ -d "$backup_data/game_saves" ]]; then
            print_message "Восстановление сохранений игр..."
            cp -r "$backup_data/game_saves"/* "$HOME/"
            print_success "Сохранения восстановлены"
        fi
        
        # Восстановление конфигов
        if [[ -d "$backup_data/configs" ]]; then
            print_message "Восстановление конфигураций..."
            cp -r "$backup_data/configs"/* "$HOME/"
            print_success "Конфигурации восстановлены"
        fi
        
        # Очистка
        rm -rf "$temp_dir"
        print_success "Восстановление завершено"
    else
        print_error "Не удалось распаковать архив"
        exit 1
    fi
}

# Показать список бэкапов
list_backups() {
    print_message "Доступные бэкапы:"
    echo
    
    if [[ -d "$BACKUP_DIR" ]]; then
        for backup in "$BACKUP_DIR"/*.tar.gz; do
            if [[ -f "$backup" ]]; then
                local name=$(basename "$backup")
                local size=$(du -h "$backup" | cut -f1)
                local date=$(stat -c %y "$backup" | cut -d' ' -f1)
                echo "  $name ($size) - $date"
            fi
        done
    else
        print_warning "Директория бэкапов не найдена"
    fi
}

# Очистка старых бэкапов
cleanup_old_backups() {
    local days="$1"
    
    if [[ -z "$days" ]]; then
        days=30
    fi
    
    print_message "Удаление бэкапов старше $days дней..."
    
    if find "$BACKUP_DIR" -name "*.tar.gz" -mtime +$days -delete; then
        print_success "Старые бэкапы удалены"
    else
        print_warning "Не найдено бэкапов для удаления"
    fi
}

# Показать справку
show_help() {
    echo "Steam Deck Backup Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТ]"
    echo
    echo "ОПЦИИ:"
    echo "  backup                    - Создать полный бэкап (по умолчанию)"
    echo "  restore <архив>           - Восстановить из архива"
    echo "  list                      - Показать список бэкапов"
    echo "  cleanup [дни]             - Удалить старые бэкапы (по умолчанию 30 дней)"
    echo "  help                      - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0                        # Создать бэкап"
    echo "  $0 backup                 # Создать бэкап"
    echo "  $0 restore backup.tar.gz  # Восстановить из архива"
    echo "  $0 list                   # Показать список бэкапов"
    echo "  $0 cleanup 7              # Удалить бэкапы старше 7 дней"
    echo
    echo "Бэкапы сохраняются в: $BACKUP_DIR"
}

# Основная функция
main() {
    case "${1:-backup}" in
        "backup")
            create_backup_dir
            backup_game_saves
            backup_configs
            backup_packages
            create_archive
            print_success "Бэкап завершен успешно!"
            ;;
        "restore")
            if [[ -z "$2" ]]; then
                print_error "Укажите путь к архиву для восстановления"
                show_help
                exit 1
            fi
            restore_backup "$2"
            ;;
        "list")
            list_backups
            ;;
        "cleanup")
            cleanup_old_backups "$2"
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
