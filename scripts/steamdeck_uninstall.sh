#!/bin/bash

# Steam Deck Enhancement Pack - Uninstall Script
# Скрипт для полного удаления утилиты
# Автор: @ncux11
# Версия: 0.1 (Январь 2025)

set +e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

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

# Определяем пути
SCRIPT_PATH="$(readlink -f "$0")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Пользователь и пути
DECK_USER="${STEAMDECK_USER:-deck}"
DECK_HOME="${STEAMDECK_HOME:-/home/$DECK_USER}"
INSTALL_DIR="${STEAMDECK_INSTALL_DIR:-$DECK_HOME/utils/SteamDeck}"

# Список файлов для удаления
FILES_TO_REMOVE=(
    "$DECK_HOME/.local/share/applications/steamdeck-enhancement-pack.desktop"
    "$DECK_HOME/.local/share/applications/steamdeck-enhancement-steam.desktop"
    "$DECK_HOME/steamdeck-setup"
    "$DECK_HOME/steamdeck-gui"
    "$DECK_HOME/steamdeck-backup"
    "$DECK_HOME/steamdeck-cleanup"
    "$DECK_HOME/steamdeck-optimizer"
    "$DECK_HOME/steamdeck-microsd"
    "$DECK_HOME/steamdeck-update"
    "$DECK_HOME/steamdeck-utils"
    "$DECK_HOME/steamdeck-uninstall"
)

# Функция для подтверждения
confirm_uninstall() {
    print_header "УДАЛЕНИЕ STEAM DECK ENHANCEMENT PACK"
    
    print_warning "Это действие удалит следующие компоненты:"
    echo "  • Директорию установки: $INSTALL_DIR"
    echo "  • Все созданные ссылки в $DECK_HOME"
    echo "  • Все desktop-файлы"
    echo "  • Резервные копии (если не указано иное)"
    echo ""
    
    print_error "ВНИМАНИЕ: Это действие нельзя отменить!"
    echo ""
    
    read -p "Вы уверены, что хотите удалить Steam Deck Enhancement Pack? (yes/NO): " confirm
    
    if [[ "$confirm" != "yes" ]]; then
        print_message "Удаление отменено"
        return 1
    fi
    
    return 0
}

# Удаление файлов
remove_files() {
    print_header "УДАЛЕНИЕ ФАЙЛОВ"
    
    local removed=0
    local failed=0
    
    for file in "${FILES_TO_REMOVE[@]}"; do
        if [[ -e "$file" ]]; then
            if rm -f "$file" 2>/dev/null; then
                print_success "Удален: $file"
                ((removed++))
            else
                print_warning "Не удалось удалить: $file (может потребоваться sudo)"
                # Попробуем с sudo
                if sudo rm -f "$file" 2>/dev/null; then
                    print_success "Удален с sudo: $file"
                    ((removed++))
                else
                    print_error "Не удалось удалить: $file"
                    ((failed++))
                fi
            fi
        else
            print_debug "Не существует: $file"
        fi
    done
    
    echo
    print_success "Удалено файлов: $removed"
    if [[ $failed -gt 0 ]]; then
        print_warning "Не удалено: $failed"
    fi
}

# Удаление директории установки
remove_install_directory() {
    print_header "УДАЛЕНИЕ ДИРЕКТОРИИ УСТАНОВКИ"
    
    if [[ ! -d "$INSTALL_DIR" ]]; then
        print_warning "Директория установки не найдена: $INSTALL_DIR"
        return 0
    fi
    
    # Спросить про backups
    echo ""
    read -p "Удалить резервные копии? (y/N): " remove_backups
    
    if [[ "$remove_backups" != "y" && "$remove_backups" != "Y" ]]; then
        print_message "Сохранение резервных копий"
        
        # Удаляем все кроме backups
        if rm -rf "$INSTALL_DIR"/* "$INSTALL_DIR"/.* 2>/dev/null; then
            # Восстанавливаем директорию backups если она была
            if [[ -d "$INSTALL_DIR/backups" ]] && [[ -n "$(ls -A "$INSTALL_DIR/backups" 2>/dev/null)" ]]; then
                mkdir -p "$INSTALL_DIR/backups" 2>/dev/null || true
                print_message "Резервные копии сохранены в: $INSTALL_DIR/backups"
            fi
            print_success "Директория установки очищена (кроме backups)"
        else
            print_warning "Не удалось полностью очистить директорию"
            if sudo rm -rf "$INSTALL_DIR"/* "$INSTALL_DIR"/.* 2>/dev/null; then
                print_success "Директория очищена с sudo"
            else
                print_error "Не удалось очистить директорию даже с sudo"
            fi
        fi
    else
        # Удаляем все включая backups
        print_message "Удаление директории включая backups..."
        
        if rm -rf "$INSTALL_DIR" 2>/dev/null; then
            print_success "Директория удалена: $INSTALL_DIR"
        else
            print_warning "Не удалось удалить директорию, пробуем с sudo..."
            if sudo rm -rf "$INSTALL_DIR" 2>/dev/null; then
                print_success "Директория удалена с sudo"
            else
                print_error "Не удалось удалить директорию даже с sudo"
            fi
        fi
    fi
}

# Обновление desktop базы
update_desktop_database() {
    print_message "Обновление desktop базы..."
    
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$DECK_HOME/.local/share/applications" 2>/dev/null || true
        print_success "Desktop база обновлена"
    else
        print_debug "update-desktop-database не найден"
    fi
}

# Удаление из Steam shortcuts
remove_from_steam() {
    print_header "УДАЛЕНИЕ ИЗ STEAM"
    
    local steam_dir="$DECK_HOME/.steam/steam"
    local shortcuts_pattern="$steam_dir/userdata/*/config/shortcuts.vdf"
    
    local found=false
    
    for shortcuts_file in $shortcuts_pattern; do
        if [[ -f "$shortcuts_file" ]]; then
            print_message "Найден файл shortcuts: $shortcuts_file"
            
            # Создаем бэкап
            cp "$shortcuts_file" "$shortcuts_file.backup_$(date +%Y%m%d_%H%M%S)"
            
            print_warning "Ручное удаление из Steam shortcuts рекомендуется"
            print_message "Файл shortcuts сохранен: $shortcuts_file"
            
            found=true
            break
        fi
    done
    
    if [[ "$found" == "false" ]]; then
        print_warning "Файл shortcuts.vdf не найден"
    fi
}

# Показать итоги
show_summary() {
    print_header "ИТОГИ УДАЛЕНИЯ"
    
    echo "Удалено:"
    echo "  • Все символические ссылки"
    echo "  • Все desktop-файлы"
    echo "  • Директория установки"
    
    echo ""
    echo "Осталось:"
    
    local remaining=false
    
    # Проверяем что осталось
    for file in "${FILES_TO_REMOVE[@]}"; do
        if [[ -e "$file" ]]; then
            echo "  ⚠️  $file"
            remaining=true
        fi
    done
    
    if [[ -d "$INSTALL_DIR" ]]; then
        echo "  ⚠️  $INSTALL_DIR"
        remaining=true
    fi
    
    if [[ "$remaining" == "false" ]]; then
        print_success "Все файлы успешно удалены!"
    else
        print_warning "Некоторые файлы не удалены. Попробуйте вручную с sudo"
    fi
    
    echo ""
    print_message "Ручное удаление из Steam:"
    echo "  1. Откройте Steam"
    echo "  2. Найдите 'Steam Deck Enhancement Pack' в библиотеке"
    echo "  3. Правый клик → Remove from library"
}

# Показать справку
show_help() {
    cat << EOF
Steam Deck Enhancement Pack - Uninstall Script v0.1

ИСПОЛЬЗОВАНИЕ:
    $0 [OPTIONS]

ОПЦИИ:
    -h, --help          Показать эту справку
    -y, --yes           Удалить без подтверждения
    --keep-backups      Сохранить резервные копии
    --remove-backups    Удалить резервные копии

ПРИМЕРЫ:
    $0                  Интерактивное удаление
    $0 -y               Удалить без подтверждения
    $0 --keep-backups   Сохранить backups

EOF
}

# Главная функция
main() {
    local auto_confirm=false
    local keep_backups=false
    
    # Обработка аргументов
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_help
                exit 0
                ;;
            -y|--yes)
                auto_confirm=true
                shift
                ;;
            --keep-backups)
                keep_backups=true
                shift
                ;;
            --remove-backups)
                keep_backups=false
                shift
                ;;
            *)
                print_error "Неизвестная опция: $1"
                show_help
                exit 1
                ;;
        esac
    done
    
    # Проверка запуска от правильного пользователя
    if [[ "$USER" != "$DECK_USER" ]] && [[ "$USER" != "root" ]]; then
        print_error "Запустите от пользователя $DECK_USER или root"
        exit 1
    fi
    
    # Подтверждение
    if [[ "$auto_confirm" == "false" ]]; then
        if ! confirm_uninstall; then
            exit 0
        fi
    fi
    
    # Удаление
    remove_files
    remove_install_directory
    update_desktop_database
    remove_from_steam
    show_summary
    
    print_success "Удаление завершено!"
}

# Запуск
main "$@"
