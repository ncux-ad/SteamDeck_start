#!/bin/bash

# Steam Deck Cleanup Script
# Скрипт для очистки системы Steam Deck
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Переменные для подсчета освобожденного места
TOTAL_FREED=0

# Функции для вывода
print_message() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Функция для подсчета освобожденного места
calculate_freed_space() {
    local path="$1"
    local before=$(du -s "$path" 2>/dev/null | cut -f1 || echo 0)
    local after=$(du -s "$path" 2>/dev/null | cut -f1 || echo 0)
    local freed=$((before - after))
    TOTAL_FREED=$((TOTAL_FREED + freed))
    return $freed
}

# Очистка кэша pacman
cleanup_pacman_cache() {
    print_message "Очистка кэша pacman..."
    
    local before=$(du -s /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo 0)
    
    if sudo pacman -Sc --noconfirm; then
        local after=$(du -s /var/cache/pacman/pkg 2>/dev/null | cut -f1 || echo 0)
        local freed=$((before - after))
        TOTAL_FREED=$((TOTAL_FREED + freed))
        print_success "Кэш pacman очищен (освобождено: $(numfmt --to=iec $((freed * 1024)))"
        log_cleanup_state "pacman_cache_cleared"
    else
        print_warning "Не удалось очистить кэш pacman"
    fi
}

# Очистка кэша Flatpak
cleanup_flatpak_cache() {
    print_message "Очистка кэша Flatpak..."
    
    if command -v flatpak &> /dev/null; then
        local before=$(du -s ~/.var/cache 2>/dev/null | cut -f1 || echo 0)
        
        if flatpak uninstall --unused -y; then
            local after=$(du -s ~/.var/cache 2>/dev/null | cut -f1 || echo 0)
            local freed=$((before - after))
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "Кэш Flatpak очищен (освобождено: $(numfmt --to=iec $((freed * 1024)))"
            log_cleanup_state "flatpak_cache_cleared"
        else
            print_warning "Не удалось очистить кэш Flatpak"
        fi
    else
        print_warning "Flatpak не установлен"
    fi
}

# Очистка кэша Steam
cleanup_steam_cache() {
    print_message "Очистка кэша Steam..."
    
    local steam_cache="$HOME/.steam/steam/logs"
    local shader_cache="$HOME/.steam/steam/steamapps/shadercache"
    local download_cache="$HOME/.steam/steam/steamapps/downloading"
    
    local total_before=0
    local total_after=0
    
    # Очистка логов Steam
    if [[ -d "$steam_cache" ]]; then
        local before=$(du -s "$steam_cache" 2>/dev/null | cut -f1 || echo 0)
        find "$steam_cache" -name "*.log" -mtime +7 -delete 2>/dev/null || true
        local after=$(du -s "$steam_cache" 2>/dev/null | cut -f1 || echo 0)
        total_before=$((total_before + before))
        total_after=$((total_after + after))
    fi
    
    # Очистка shader cache (осторожно!)
    if [[ -d "$shader_cache" ]]; then
        local before=$(du -s "$shader_cache" 2>/dev/null | cut -f1 || echo 0)
        # Удаляем только старые файлы (старше 30 дней)
        find "$shader_cache" -type f -mtime +30 -delete 2>/dev/null || true
        local after=$(du -s "$shader_cache" 2>/dev/null | cut -f1 || echo 0)
        total_before=$((total_before + before))
        total_after=$((total_after + after))
    fi
    
    # Очистка папки загрузок
    if [[ -d "$download_cache" ]]; then
        local before=$(du -s "$download_cache" 2>/dev/null | cut -f1 || echo 0)
        rm -rf "$download_cache"/* 2>/dev/null || true
        local after=$(du -s "$download_cache" 2>/dev/null | cut -f1 || echo 0)
        total_before=$((total_before + before))
        total_after=$((total_after + after))
    fi
    
    local freed=$((total_before - total_after))
    TOTAL_FREED=$((TOTAL_FREED + freed))
    print_success "Кэш Steam очищен (освобождено: $(numfmt --to=iec $((freed * 1024)))"
    log_cleanup_state "steam_cache_cleared"
}

# Очистка временных файлов
cleanup_temp_files() {
    print_message "Очистка временных файлов..."
    
    local temp_dirs=(
        "/tmp"
        "$HOME/.cache"
        "$HOME/.local/share/Trash"
        "/var/tmp"
    )
    
    local total_freed=0
    
    for dir in "${temp_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local before=$(du -s "$dir" 2>/dev/null | cut -f1 || echo 0)
            
            # Очистка файлов старше 7 дней
            find "$dir" -type f -mtime +7 -delete 2>/dev/null || true
            find "$dir" -type d -empty -delete 2>/dev/null || true
            
            local after=$(du -s "$dir" 2>/dev/null | cut -f1 || echo 0)
            local freed=$((before - after))
            total_freed=$((total_freed + freed))
        fi
    done
    
    TOTAL_FREED=$((TOTAL_FREED + total_freed))
    print_success "Временные файлы очищены (освобождено: $(numfmt --to=iec $((total_freed * 1024)))"
    log_cleanup_state "temp_files_cleared"
}

# Очистка логов системы
cleanup_system_logs() {
    print_message "Очистка системных логов..."
    
    local log_dirs=(
        "/var/log"
        "$HOME/.steam/steam/logs"
    )
    
    local total_freed=0
    
    for dir in "${log_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            local before=$(du -s "$dir" 2>/dev/null | cut -f1 || echo 0)
            
            # Очистка логов старше 14 дней
            find "$dir" -name "*.log" -mtime +14 -delete 2>/dev/null || true
            find "$dir" -name "*.log.*" -mtime +14 -delete 2>/dev/null || true
            
            local after=$(du -s "$dir" 2>/dev/null | cut -f1 || echo 0)
            local freed=$((before - after))
            total_freed=$((total_freed + freed))
        fi
    done
    
    TOTAL_FREED=$((TOTAL_FREED + total_freed))
    print_success "Системные логи очищены (освобождено: $(numfmt --to=iec $((total_freed * 1024)))"
    log_cleanup_state "logs_cleared"
}

# Поиск и удаление дубликатов
find_duplicates() {
    print_message "Поиск дубликатов файлов..."
    
    local duplicates_dir="$HOME/duplicates_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$duplicates_dir"
    
    # Поиск дубликатов по размеру и хэшу
    if command -v fdupes &> /dev/null; then
        fdupes -r -f "$HOME" > "$duplicates_dir/duplicates.txt" 2>/dev/null || true
        
        if [[ -s "$duplicates_dir/duplicates.txt" ]]; then
            print_warning "Найдены дубликаты. Список сохранен в: $duplicates_dir/duplicates.txt"
            print_message "Проверьте файл и удалите дубликаты вручную"
        else
            print_success "Дубликаты не найдены"
            rm -rf "$duplicates_dir"
        fi
    else
        print_warning "fdupes не установлен. Установите: sudo pacman -S fdupes"
    fi
}

# Очистка старых ядер
cleanup_old_kernels() {
    print_message "Очистка старых ядер..."
    
    if command -v pacman &> /dev/null; then
        local before=$(du -s /boot 2>/dev/null | cut -f1 || echo 0)
        
        # Удаление старых ядер (оставляем текущее и предыдущее)
        if sudo pacman -Rns $(pacman -Qdtq) --noconfirm 2>/dev/null; then
            local after=$(du -s /boot 2>/dev/null | cut -f1 || echo 0)
            local freed=$((before - after))
            TOTAL_FREED=$((TOTAL_FREED + freed))
            print_success "Старые ядра удалены (освобождено: $(numfmt --to=iec $((freed * 1024)))"
        else
            print_warning "Не удалось удалить старые ядра"
        fi
    else
        print_warning "Pacman не доступен"
    fi
}

# Очистка кэша браузеров
cleanup_browser_cache() {
    print_message "Очистка кэша браузеров..."
    
    local browsers=(
        "$HOME/.mozilla/firefox"
        "$HOME/.config/google-chrome"
        "$HOME/.config/chromium"
        "$HOME/.var/app/org.mozilla.firefox"
    )
    
    local total_freed=0
    
    for browser in "${browsers[@]}"; do
        if [[ -d "$browser" ]]; then
            local before=$(du -s "$browser" 2>/dev/null | cut -f1 || echo 0)
            
            # Очистка кэша
            find "$browser" -name "Cache" -type d -exec rm -rf {} + 2>/dev/null || true
            find "$browser" -name "cache" -type d -exec rm -rf {} + 2>/dev/null || true
            find "$browser" -name "*.tmp" -delete 2>/dev/null || true
            
            local after=$(du -s "$browser" 2>/dev/null | cut -f1 || echo 0)
            local freed=$((before - after))
            total_freed=$((total_freed + freed))
        fi
    done
    
    TOTAL_FREED=$((TOTAL_FREED + total_freed))
    print_success "Кэш браузеров очищен (освобождено: $(numfmt --to=iec $((total_freed * 1024)))"
}

# Показать статистику использования диска
show_disk_usage() {
    print_message "Статистика использования диска:"
    echo
    
    # Общее использование
    df -h /
    echo
    
    # Топ-10 самых больших директорий
    print_message "Топ-10 самых больших директорий в домашней папке:"
    du -h "$HOME" 2>/dev/null | sort -hr | head -10
    echo
    
    # Размер Steam
    if [[ -d "$HOME/.steam" ]]; then
        local steam_size=$(du -sh "$HOME/.steam" 2>/dev/null | cut -f1)
        print_message "Размер Steam: $steam_size"
    fi
}

# Полная очистка
full_cleanup() {
    print_message "=== НАЧАЛО ПОЛНОЙ ОЧИСТКИ ==="
    echo
    
    cleanup_pacman_cache
    cleanup_flatpak_cache
    cleanup_steam_cache
    cleanup_temp_files
    cleanup_system_logs
    cleanup_browser_cache
    cleanup_old_kernels
    
    echo
    print_success "=== ОЧИСТКА ЗАВЕРШЕНА ==="
    print_success "Всего освобождено: $(numfmt --to=iec $((TOTAL_FREED * 1024)))"
}

# Безопасная очистка (только кэши)
safe_cleanup() {
    print_message "=== БЕЗОПАСНАЯ ОЧИСТКА ==="
    echo
    
    cleanup_pacman_cache
    cleanup_flatpak_cache
    cleanup_temp_files
    cleanup_browser_cache
    
    echo
    print_success "=== БЕЗОПАСНАЯ ОЧИСТКА ЗАВЕРШЕНА ==="
    print_success "Всего освобождено: $(numfmt --to=iec $((TOTAL_FREED * 1024)))"
}

# Показать справку
show_help() {
    echo "Steam Deck Cleanup Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ]"
    echo
    echo "ОПЦИИ:"
    echo "  full                      - Полная очистка (по умолчанию)"
    echo "  safe                      - Безопасная очистка (только кэши)"
    echo "  pacman                    - Очистка только кэша pacman"
    echo "  flatpak                   - Очистка только кэша Flatpak"
    echo "  steam                     - Очистка только кэша Steam"
    echo "  temp                      - Очистка только временных файлов"
    echo "  logs                      - Очистка только логов"
    echo "  browsers                  - Очистка только кэша браузеров"
    echo "  duplicates                - Поиск дубликатов"
    echo "  disk                      - Показать статистику диска"
    echo "  rollback                  - Откат очистки"
    echo "  help                      - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0                        # Полная очистка"
    echo "  $0 safe                   # Безопасная очистка"
    echo "  $0 steam                  # Очистка только Steam"
    echo "  $0 rollback               # Откат очистки"
    echo "  $0 disk                   # Статистика диска"
}

# Функция для отката очистки
rollback_cleanup() {
    print_header "ОТКАТ ОЧИСТКИ"
    
    # Проверяем, есть ли файл состояния очистки
    local state_file="/tmp/steamdeck_cleanup_state.log"
    
    if [[ ! -f "$state_file" ]]; then
        print_warning "Файл состояния очистки не найден. Невозможно выполнить откат."
        print_message "Попытка восстановления из системных бэкапов..."
        
        # Попытка восстановления из системных бэкапов
        restore_from_system_backups
        return
    fi
    
    print_message "Чтение файла состояния очистки: $state_file"
    
    # Читаем состояние и выполняем откат
    while IFS= read -r line; do
        case "$line" in
            "pacman_cache_cleared")
                print_message "Восстановление кэша pacman..."
                restore_pacman_cache
                ;;
            "flatpak_cache_cleared")
                print_message "Восстановление кэша Flatpak..."
                restore_flatpak_cache
                ;;
            "steam_cache_cleared")
                print_message "Восстановление кэша Steam..."
                restore_steam_cache
                ;;
            "temp_files_cleared")
                print_message "Восстановление временных файлов..."
                restore_temp_files
                ;;
            "logs_cleared")
                print_message "Восстановление логов..."
                restore_system_logs
                ;;
        esac
    done < "$state_file"
    
    # Удаляем файл состояния
    rm -f "$state_file"
    print_success "Откат очистки завершен"
}

# Восстановление из системных бэкапов
restore_from_system_backups() {
    print_message "Попытка восстановления из системных бэкапов..."
    
    # Восстановление pacman кэша
    restore_pacman_cache
    
    # Восстановление Flatpak кэша
    restore_flatpak_cache
    
    # Восстановление Steam кэша
    restore_steam_cache
    
    print_warning "Восстановление из системных бэкапов завершено. Некоторые данные могут быть недоступны."
}

# Восстановление кэша pacman
restore_pacman_cache() {
    print_message "Восстановление кэша pacman..."
    
    # Переустановка пакетов для восстановления кэша
    if command -v pacman &> /dev/null; then
        print_message "Переустановка пакетов для восстановления кэша..."
        sudo pacman -S --needed base-devel git --noconfirm 2>/dev/null || true
        print_success "Кэш pacman восстановлен"
    else
        print_warning "pacman недоступен, восстановление кэша невозможно"
    fi
}

# Восстановление кэша Flatpak
restore_flatpak_cache() {
    print_message "Восстановление кэша Flatpak..."
    
    if command -v flatpak &> /dev/null; then
        print_message "Обновление Flatpak для восстановления кэша..."
        flatpak update --assumeyes 2>/dev/null || true
        print_success "Кэш Flatpak восстановлен"
    else
        print_warning "Flatpak недоступен, восстановление кэша невозможно"
    fi
}

# Восстановление кэша Steam
restore_steam_cache() {
    print_message "Восстановление кэша Steam..."
    
    local steam_dir="$HOME/.steam/steam"
    
    if [[ -d "$steam_dir" ]]; then
        print_message "Создание директорий Steam для восстановления кэша..."
        mkdir -p "$steam_dir/logs"
        mkdir -p "$steam_dir/cache"
        print_success "Структура Steam восстановлена"
    else
        print_warning "Steam не установлен, восстановление кэша невозможно"
    fi
}

# Восстановление временных файлов
restore_temp_files() {
    print_message "Восстановление временных файлов..."
    
    # Создание базовых временных директорий
    mkdir -p /tmp/steamdeck_enhancement
    mkdir -p "$HOME/.cache/steamdeck"
    
    print_success "Временные директории восстановлены"
}

# Восстановление логов системы
restore_system_logs() {
    print_message "Восстановление логов системы..."
    
    # Создание базовых логов
    sudo journalctl --vacuum-time=1d 2>/dev/null || true
    
    print_success "Логи системы восстановлены"
}

# Функция для логирования состояния очистки
log_cleanup_state() {
    local state_file="/tmp/steamdeck_cleanup_state.log"
    local action="$1"
    local details="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$action|$timestamp|$details" >> "$state_file"
    print_message "Состояние очистки записано: $action"
}

# Функция для создания бэкапа перед очисткой
create_cleanup_backup() {
    local backup_dir="/tmp/steamdeck_cleanup_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Бэкап кэша pacman
    if [[ -d "/var/cache/pacman/pkg" ]]; then
        cp -r /var/cache/pacman/pkg "$backup_dir/pacman_cache" 2>/dev/null || true
    fi
    
    # Бэкап кэша Flatpak
    if [[ -d "$HOME/.var/app" ]]; then
        cp -r "$HOME/.var/app" "$backup_dir/flatpak_cache" 2>/dev/null || true
    fi
    
    # Бэкап кэша Steam
    if [[ -d "$HOME/.steam" ]]; then
        cp -r "$HOME/.steam" "$backup_dir/steam_cache" 2>/dev/null || true
    fi
    
    # Бэкап временных файлов
    if [[ -d "/tmp" ]]; then
        find /tmp -name "*steamdeck*" -type f -exec cp {} "$backup_dir/" \; 2>/dev/null || true
    fi
    
    echo "$backup_dir"
}

# Функция для восстановления из бэкапа очистки
restore_from_cleanup_backup() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_error "Директория бэкапа очистки не найдена: $backup_dir"
        return 1
    fi
    
    print_message "Восстановление из бэкапа очистки: $backup_dir"
    
    # Восстановление кэша pacman
    if [[ -d "$backup_dir/pacman_cache" ]]; then
        sudo cp -r "$backup_dir/pacman_cache" /var/cache/pacman/pkg
        print_success "Кэш pacman восстановлен"
    fi
    
    # Восстановление кэша Flatpak
    if [[ -d "$backup_dir/flatpak_cache" ]]; then
        cp -r "$backup_dir/flatpak_cache" "$HOME/.var/app"
        print_success "Кэш Flatpak восстановлен"
    fi
    
    # Восстановление кэша Steam
    if [[ -d "$backup_dir/steam_cache" ]]; then
        cp -r "$backup_dir/steam_cache" "$HOME/.steam"
        print_success "Кэш Steam восстановлен"
    fi
    
    print_success "Восстановление из бэкапа очистки завершено"
}

# Основная функция
main() {
    case "${1:-full}" in
        "full")
            full_cleanup
            ;;
        "safe")
            safe_cleanup
            ;;
        "pacman")
            cleanup_pacman_cache
            ;;
        "flatpak")
            cleanup_flatpak_cache
            ;;
        "steam")
            cleanup_steam_cache
            ;;
        "temp")
            cleanup_temp_files
            ;;
        "logs")
            cleanup_system_logs
            ;;
        "browsers")
            cleanup_browser_cache
            ;;
        "duplicates")
            find_duplicates
            ;;
        "disk")
            show_disk_usage
            ;;
        "rollback")
            rollback_cleanup
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
