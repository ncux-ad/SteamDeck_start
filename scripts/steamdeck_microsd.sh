#!/bin/bash

# Steam Deck MicroSD Management Script
# Скрипт для управления MicroSD картами в Steam Deck
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Функции вывода
print_header() {
    echo -e "${CYAN}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Функция для проверки MicroSD карт
check_microsd() {
    print_header "ПРОВЕРКА MICROSD КАРТ"
    
    # Проверяем подключенные устройства
    echo "🔍 Поиск MicroSD карт..."
    
    # Ищем устройства mmcblk
    local devices=$(ls /dev/mmcblk* 2>/dev/null | grep -E 'mmcblk[0-9]+$' || true)
    
    if [[ -z "$devices" ]]; then
        print_warning "MicroSD карты не найдены"
        return 1
    fi
    
    echo "📱 Найденные устройства:"
    for device in $devices; do
        local size=$(lsblk -d -n -o SIZE "$device" 2>/dev/null || echo "Неизвестно")
        local model=$(lsblk -d -n -o MODEL "$device" 2>/dev/null || echo "Неизвестно")
        echo "  $device - $size - $model"
    done
    
    return 0
}

# Функция для получения информации о монтировании
get_mount_info() {
    print_header "ИНФОРМАЦИЯ О МОНТИРОВАНИИ"
    
    echo "📊 Текущие точки монтирования:"
    mount | grep -E '(mmcblk|sd[a-z])' || echo "  Нет смонтированных устройств"
    
    echo
    echo "📁 Содержимое /run/media:"
    if [[ -d "/run/media" ]]; then
        ls -la /run/media/ 2>/dev/null || echo "  Пусто"
    else
        echo "  Директория не существует"
    fi
    
    echo
    echo "🔗 Символические ссылки:"
    ls -la /run/media/mmcblk* 2>/dev/null || echo "  Нет ссылок"
}

# Функция для диагностики проблем с UI
diagnose_ui_issue() {
    print_header "ДИАГНОСТИКА UI ПРОБЛЕМ"
    
    echo "🔍 Проверка процессов Steam:"
    ps aux | grep -i steam | grep -v grep || echo "  Steam не запущен"
    
    echo
    echo "🔍 Проверка процессов Dolphin:"
    ps aux | grep -i dolphin | grep -v grep || echo "  Dolphin не запущен"
    
    echo
    echo "🔍 Проверка udev правил:"
    if [[ -f "/etc/udev/rules.d/99-steamdeck.rules" ]]; then
        echo "  Steam Deck udev правила найдены"
        cat /etc/udev/rules.d/99-steamdeck.rules
    else
        echo "  Steam Deck udev правила не найдены"
    fi
    
    echo
    echo "🔍 Проверка systemd сервисов:"
    systemctl status udisks2 2>/dev/null || echo "  udisks2 не активен"
}

# Функция для принудительного обновления UI
refresh_ui() {
    print_header "ОБНОВЛЕНИЕ UI"
    
    echo "🔄 Попытка обновления UI Steam Deck..."
    
    # Перезапуск udisks2
    print_info "Перезапуск udisks2..."
    sudo systemctl restart udisks2 2>/dev/null || print_warning "Не удалось перезапустить udisks2"
    
    # Обновление udev правил
    print_info "Обновление udev правил..."
    sudo udevadm control --reload-rules 2>/dev/null || print_warning "Не удалось обновить udev правила"
    
    # Триггер udev событий
    print_info "Триггер udev событий..."
    sudo udevadm trigger 2>/dev/null || print_warning "Не удалось запустить udev trigger"
    
    # Обновление desktop файлов
    print_info "Обновление desktop файлов..."
    update-desktop-database ~/.local/share/applications 2>/dev/null || print_warning "Не удалось обновить desktop базу"
    
    print_success "UI обновлен"
}

# Функция для безопасного извлечения
safely_remove() {
    print_header "БЕЗОПАСНОЕ ИЗВЛЕЧЕНИЕ MICROSD"
    
    # Находим смонтированные MicroSD карты
    local mounted=$(mount | grep -E 'mmcblk[0-9]+p[0-9]+' | awk '{print $1}' | sort -u)
    
    if [[ -z "$mounted" ]]; then
        print_warning "Нет смонтированных MicroSD карт"
        return 1
    fi
    
    echo "📱 Смонтированные карты:"
    for device in $mounted; do
        local mount_point=$(mount | grep "$device" | awk '{print $3}')
        echo "  $device -> $mount_point"
    done
    
    echo
    read -p "Извлечь все MicroSD карты? (y/N): " confirm
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        for device in $mounted; do
            print_info "Извлечение $device..."
            sudo umount "$device" 2>/dev/null || print_warning "Не удалось извлечь $device"
        done
        print_success "MicroSD карты извлечены"
    else
        print_info "Отменено пользователем"
    fi
}

# Функция для исправления проблем
fix_microsd_issues() {
    print_header "ИСПРАВЛЕНИЕ ПРОБЛЕМ MICROSD"
    
    echo "🔧 Выполнение исправлений..."
    
    # Создание необходимых директорий
    print_info "Создание директорий..."
    sudo mkdir -p /run/media/mmcblk0p1 2>/dev/null || true
    sudo chown deck:deck /run/media/mmcblk0p1 2>/dev/null || true
    
    # Установка правильных прав
    print_info "Установка прав доступа..."
    sudo chmod 755 /run/media/mmcblk0p1 2>/dev/null || true
    
    # Создание udev правил для Steam Deck
    print_info "Создание udev правил..."
    sudo tee /etc/udev/rules.d/99-steamdeck-microsd.rules > /dev/null << 'EOF'
# Steam Deck MicroSD rules
SUBSYSTEM=="block", KERNEL=="mmcblk*", ATTR{removable}=="1", GROUP="deck", MODE="0664"
SUBSYSTEM=="block", KERNEL=="mmcblk*", ATTR{removable}=="1", RUN+="/bin/mkdir -p /run/media/%k"
EOF
    
    # Перезагрузка udev правил
    print_info "Перезагрузка udev правил..."
    sudo udevadm control --reload-rules
    sudo udevadm trigger
    
    # Перезапуск udisks2
    print_info "Перезапуск udisks2..."
    sudo systemctl restart udisks2
    
    print_success "Исправления применены"
}

# Функция для тестирования MicroSD
test_microsd() {
    print_header "ТЕСТИРОВАНИЕ MICROSD"
    
    # Проверяем доступность устройств
    if ! check_microsd; then
        print_error "MicroSD карты не найдены"
        return 1
    fi
    
    # Тестируем монтирование
    print_info "Тестирование монтирования..."
    
    local devices=$(ls /dev/mmcblk* 2>/dev/null | grep -E 'mmcblk[0-9]+$')
    for device in $devices; do
        echo "Тестирование $device..."
        
        # Проверяем файловую систему
        local fstype=$(lsblk -d -n -o FSTYPE "$device" 2>/dev/null || echo "unknown")
        echo "  Файловая система: $fstype"
        
        # Проверяем размер
        local size=$(lsblk -d -n -o SIZE "$device" 2>/dev/null || echo "unknown")
        echo "  Размер: $size"
        
        # Проверяем состояние
        local state=$(cat "/sys/block/$(basename $device)/removable" 2>/dev/null || echo "unknown")
        echo "  Состояние: $state"
    done
    
    print_success "Тестирование завершено"
}

# Функция для показа справки
show_help() {
    echo "Steam Deck MicroSD Management Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ]"
    echo
    echo "ОПЦИИ:"
    echo "  check                     - Проверить MicroSD карты (по умолчанию)"
    echo "  mount-info                - Показать информацию о монтировании"
    echo "  diagnose                  - Диагностика UI проблем"
    echo "  refresh                   - Обновить UI"
    echo "  safely-remove             - Безопасно извлечь карты"
    echo "  fix                       - Исправить проблемы"
    echo "  test                      - Тестирование MicroSD"
    echo "  help                      - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 check                  # Проверить карты"
    echo "  $0 diagnose               # Диагностика проблем"
    echo "  $0 fix                    # Исправить проблемы"
    echo "  $0 safely-remove          # Извлечь карты"
}

# Основная функция
main() {
    case "${1:-check}" in
        "check")
            check_microsd
            ;;
        "mount-info")
            get_mount_info
            ;;
        "diagnose")
            diagnose_ui_issue
            ;;
        "refresh")
            refresh_ui
            ;;
        "safely-remove")
            safely_remove
            ;;
        "fix")
            fix_microsd_issues
            ;;
        "test")
            test_microsd
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
