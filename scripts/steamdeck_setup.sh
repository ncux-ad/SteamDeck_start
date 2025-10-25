#!/bin/bash

# Steam Deck Setup Script
# Скрипт для подготовки Steam Deck к установке стороннего ПО
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

# set -e  # Временно отключено для лучшего отслеживания ошибок

# Переменные для отслеживания ошибок
ERRORS=()
WARNINGS=()
SUCCESS_COUNT=0
ERROR_COUNT=0
WARNING_COUNT=0
LOG_FILE="/tmp/steamdeck_setup_$(date +%Y%m%d_%H%M%S).log"

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

# Функция для вывода сообщений
print_message() {
    echo -e "${BLUE}[INFO]${NC} $1"
    log_to_file "INFO" "$1"
}

print_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
    log_to_file "SUCCESS" "$1"
    ((SUCCESS_COUNT++))
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
    log_to_file "WARNING" "$1"
    WARNINGS+=("$1")
    ((WARNING_COUNT++))
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
    log_to_file "ERROR" "$1"
    ERRORS+=("$1")
    ((ERROR_COUNT++))
}

# Функция для логирования в файл
log_to_file() {
    local level="$1"
    local message="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "[$timestamp] [$level] $message" >> "$LOG_FILE"
}

# Функция для показа сводки ошибок
show_summary() {
    echo
    print_header "СВОДКА НАСТРОЙКИ"
    
    print_message "Успешно выполнено операций: $SUCCESS_COUNT"
    print_message "Предупреждений: $WARNING_COUNT"
    print_message "Ошибок: $ERROR_COUNT"
    
    if [[ ${#WARNINGS[@]} -gt 0 ]]; then
        echo
        print_warning "ПРЕДУПРЕЖДЕНИЯ:"
        for warning in "${WARNINGS[@]}"; do
            echo "  • $warning"
        done
    fi
    
    if [[ ${#ERRORS[@]} -gt 0 ]]; then
        echo
        print_error "ОШИБКИ:"
        for error in "${ERRORS[@]}"; do
            echo "  • $error"
        done
    fi
    
    echo
    if [[ $ERROR_COUNT -eq 0 ]]; then
        print_success "Настройка завершена успешно!"
    else
        print_warning "Настройка завершена с ошибками. Проверьте список выше."
    fi
    
    # Показываем путь к логу
    if [[ -f "$LOG_FILE" ]]; then
        print_message "Подробный лог сохранен: $LOG_FILE"
    fi
}

# Функция для проверки прав root
check_root() {
    # Проверяем, запущен ли скрипт напрямую от root (без sudo)
    if [[ $EUID -eq 0 ]] && [[ -z "$SUDO_USER" ]]; then
        print_error "Не запускайте скрипт напрямую от имени root!"
        print_message "Используйте: ./steamdeck_setup.sh"
        exit 1
    fi
    
    # Если запущен с sudo, проверяем что SUDO_USER установлен
    if [[ $EUID -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
        print_message "Скрипт запущен с правами sudo от пользователя: $SUDO_USER"
    fi
}

# Функция для проверки пароля пользователя
check_password() {
    # Если уже запущен с sudo, проверяем что пароль уже введен
    if [[ $EUID -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
        print_message "Права sudo уже получены от пользователя: $SUDO_USER"
        return 0
    fi
    
    # Если запущен обычным пользователем, проверяем sudo
    if ! sudo -n true 2>/dev/null; then
        print_warning "Требуется ввести пароль пользователя"
        print_message "Убедитесь, что пароль установлен командой: passwd"
        sudo -v
    fi
}

# Вспомогательная функция для выполнения команд с sudo
run_sudo() {
    if [[ $EUID -eq 0 ]]; then
        # Если уже запущен с sudo, выполняем команду напрямую
        "$@"
    else
        # Если запущен обычным пользователем, используем sudo
        sudo "$@"
    fi
}

# Функция для отключения readonly режима
disable_readonly() {
    print_message "Отключение режима только для чтения..."
    
    if run_sudo steamos-readonly disable; then
        print_success "Режим только для чтения отключен"
        log_setup_state "readonly_disabled"
    else
        print_error "Не удалось отключить режим только для чтения"
        exit 1
    fi
}

# Функция для включения readonly режима
enable_readonly() {
    print_message "Включение режима только для чтения..."
    
    if run_sudo steamos-readonly enable; then
        print_success "Режим только для чтения включен"
    else
        print_warning "Не удалось включить режим только для чтения"
    fi
}

# Функция для отката изменений setup
rollback_setup() {
    print_header "ОТКАТ ИЗМЕНЕНИЙ SETUP"
    
    # Проверяем, есть ли файл состояния
    local state_file="/tmp/steamdeck_setup_state.log"
    
    if [[ ! -f "$state_file" ]]; then
        print_warning "Файл состояния не найден. Невозможно выполнить полный откат."
        print_message "Попытка базового отката..."
        
        # Базовый откат
        basic_rollback
        return
    fi
    
    print_message "Чтение файла состояния: $state_file"
    
    # Поиск детального бэкапа
    local backup_dir=$(find /tmp -name "steamdeck_backup_*" -type d | sort | tail -1)
    if [[ -n "$backup_dir" ]] && [[ -d "$backup_dir" ]]; then
        print_message "Найден детальный бэкап: $backup_dir"
        read -p "Использовать детальный бэкап для восстановления? (Y/n): " use_backup
        if [[ "$use_backup" != "n" && "$use_backup" != "N" ]]; then
            restore_from_detailed_backup "$backup_dir"
            print_success "Восстановление из детального бэкапа завершено"
            return 0
        fi
    fi
    
    # Читаем состояние и выполняем откат
    local rollback_count=0
    while IFS='|' read -r action timestamp details; do
        case "$action" in
            "readonly_disabled")
                print_message "Восстановление readonly режима... ($timestamp)"
                if enable_readonly; then
                    ((rollback_count++))
                fi
                ;;
            "pacman_configured")
                print_message "Восстановление pacman.conf... ($timestamp)"
                if restore_pacman_config; then
                    ((rollback_count++))
                fi
                ;;
            "pacman_key_initialized")
                print_message "Сброс pacman-key... ($timestamp)"
                if reset_pacman_key; then
                    ((rollback_count++))
                fi
                ;;
            "packages_installed")
                print_message "Удаление установленных пакетов... ($timestamp)"
                if [[ -n "$details" ]]; then
                    if uninstall_packages "$details"; then
                        ((rollback_count++))
                    fi
                fi
                ;;
            "sniper_installed")
                print_message "Sniper был установлен, но не требует отката ($timestamp)"
                ;;
        esac
    done < "$state_file"
    
    # Удаляем файл состояния
    rm -f "$state_file"
    print_success "Откат setup завершен. Выполнено действий: $rollback_count"
}

# Базовый откат без файла состояния
basic_rollback() {
    print_message "Выполнение базового отката..."
    
    # Включаем readonly режим
    enable_readonly
    
    # Восстанавливаем pacman.conf
    restore_pacman_config
    
    # Сбрасываем pacman-key
    reset_pacman_key
    
    print_warning "Базовый откат завершен. Некоторые изменения могут остаться."
}

# Восстановление pacman.conf
restore_pacman_config() {
    print_message "Восстановление pacman.conf..."
    
    local pacman_conf="/etc/pacman.conf"
    local backup_conf="/etc/pacman.conf.backup"
    
    if [[ -f "$backup_conf" ]]; then
        if run_sudo cp "$backup_conf" "$pacman_conf"; then
            print_success "pacman.conf восстановлен из бэкапа"
        else
            print_error "Не удалось восстановить pacman.conf"
        fi
    else
        print_warning "Бэкап pacman.conf не найден"
        # Создаем стандартную конфигурацию
        create_default_pacman_config
    fi
}

# Создание стандартной конфигурации pacman
create_default_pacman_config() {
    print_message "Создание стандартной конфигурации pacman.conf..."
    
    run_sudo tee /etc/pacman.conf > /dev/null << 'EOF'
[options]
HoldPkg     = pacman glibc
Architecture = auto
CheckSpace
SigLevel    = Required DatabaseOptional
LocalFileSigLevel = Optional

[core]
Include = /etc/pacman.d/mirrorlist

[extra]
Include = /etc/pacman.d/mirrorlist

[community]
Include = /etc/pacman.d/mirrorlist
EOF
    
    print_success "Стандартная конфигурация pacman.conf создана"
}

# Сброс pacman-key
reset_pacman_key() {
    print_message "Сброс pacman-key..."
    
    if run_sudo pacman-key --init; then
        print_success "pacman-key инициализирован"
    else
        print_warning "Не удалось инициализировать pacman-key"
    fi
    
    if run_sudo pacman-key --populate archlinux; then
        print_success "Ключи Arch Linux загружены"
    else
        print_warning "Не удалось загрузить ключи Arch Linux"
    fi
}

# Удаление установленных пакетов
uninstall_packages() {
    local packages="$1"
    
    if [[ -n "$packages" ]]; then
        print_message "Удаление пакетов: $packages"
        
        # Разбиваем пакеты по пробелам
        IFS=' ' read -ra PACKAGES <<< "$packages"
        
        for package in "${PACKAGES[@]}"; do
            if [[ -n "$package" ]]; then
                print_message "Удаление пакета: $package"
                if run_sudo pacman -R --noconfirm "$package" 2>/dev/null; then
                    print_success "Пакет $package удален"
                else
                    print_warning "Не удалось удалить пакет $package"
                fi
            fi
        done
    fi
}

# Функция для логирования состояния
log_setup_state() {
    local state_file="/tmp/steamdeck_setup_state.log"
    local action="$1"
    local details="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    
    echo "$action|$timestamp|$details" >> "$state_file"
    print_message "Состояние записано: $action"
}

# Функция для создания детального бэкапа
create_detailed_backup() {
    local backup_dir="/tmp/steamdeck_backup_$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$backup_dir"
    
    # Бэкап конфигурационных файлов
    if [[ -f "/etc/pacman.conf" ]]; then
        cp /etc/pacman.conf "$backup_dir/pacman.conf"
    fi
    
    # Бэкап ключей pacman
    if [[ -d "/etc/pacman.d/gnupg" ]]; then
        cp -r /etc/pacman.d/gnupg "$backup_dir/gnupg"
    fi
    
    # Бэкап списка установленных пакетов
    pacman -Q > "$backup_dir/installed_packages.txt" 2>/dev/null || true
    
    # Бэкап Flatpak приложений
    flatpak list > "$backup_dir/flatpak_apps.txt" 2>/dev/null || true
    
    echo "$backup_dir"
}

# Функция для восстановления из детального бэкапа
restore_from_detailed_backup() {
    local backup_dir="$1"
    
    if [[ ! -d "$backup_dir" ]]; then
        print_error "Директория бэкапа не найдена: $backup_dir"
        return 1
    fi
    
    print_message "Восстановление из бэкапа: $backup_dir"
    
    # Восстановление pacman.conf
    if [[ -f "$backup_dir/pacman.conf" ]]; then
        run_sudo cp "$backup_dir/pacman.conf" /etc/pacman.conf
        print_success "pacman.conf восстановлен"
    fi
    
    # Восстановление ключей
    if [[ -d "$backup_dir/gnupg" ]]; then
        run_sudo cp -r "$backup_dir/gnupg" /etc/pacman.d/
        print_success "Ключи pacman восстановлены"
    fi
    
    print_success "Восстановление из бэкапа завершено"
}

# Функция для настройки pacman.conf
configure_pacman() {
    print_message "Настройка pacman.conf..."
    
    local pacman_conf="/etc/pacman.conf"
    local backup_file="/etc/pacman.conf.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Создание резервной копии
    if [[ ! -f "$backup_file" ]]; then
        run_sudo cp "$pacman_conf" "$backup_file"
        print_success "Создана резервная копия: $backup_file"
    fi
    
    # Проверка, не настроен ли уже pacman
    if grep -q "SigLevel = TrustAll" "$pacman_conf"; then
        print_warning "Pacman уже настроен (SigLevel = TrustAll найден)"
        return 0
    fi
    
    # Комментирование старой строки и добавление новой
    run_sudo sed -i 's/^SigLevel.*= Required DatabaseOptional/#&/' "$pacman_conf"
    run_sudo sed -i '/^#SigLevel.*= Required DatabaseOptional/a SigLevel = TrustAll' "$pacman_conf"
    
    print_success "Pacman настроен для установки неподписанных пакетов"
    log_setup_state "pacman_configured"
}

# Функция для инициализации ключей
init_keys() {
    print_message "Инициализация ключей pacman..."
    if run_sudo pacman-key --init; then
        print_success "Ключи pacman инициализированы"
        log_setup_state "pacman_key_initialized"
    else
        print_error "Не удалось инициализировать ключи pacman"
        exit 1
    fi
}

# Функция для установки базовых пакетов
install_base_packages() {
    print_message "Установка базовых пакетов для разработки..."
    
    # Обновление базы данных пакетов
    run_sudo pacman -Sy
    
    # Установка базовых пакетов
    if run_sudo pacman -S --needed base-devel git --noconfirm; then
        print_success "Базовые пакеты установлены"
        log_setup_state "packages_installed:base-devel git"
    else
        print_warning "Не удалось установить некоторые пакеты"
    fi
}

# Функция для установки AUR-хелпера
install_aur_helper() {
    print_message "Установка AUR-хелпера (Yay)..."
    
    if command -v yay &> /dev/null; then
        print_warning "Yay уже установлен"
        return 0
    fi
    
    # Создание временной директории
    local temp_dir=$(mktemp -d)
    cd "$temp_dir"
    
    # Клонирование и установка Yay
    if git clone https://aur.archlinux.org/yay.git; then
        cd yay
        if makepkg -si --noconfirm; then
            print_success "Yay установлен успешно"
        else
            print_error "Не удалось установить Yay"
        fi
    else
        print_error "Не удалось клонировать репозиторий Yay"
    fi
    
    # Очистка
    cd /
    rm -rf "$temp_dir"
}

# Функция для установки Wine
install_wine() {
    print_message "Установка Wine..."
    
    if command -v wine &> /dev/null; then
        print_warning "Wine уже установлен"
    else
        if run_sudo pacman -S wine --noconfirm; then
            print_success "Wine установлен"
        else
            print_warning "Не удалось установить Wine"
        fi
    fi
}

# Функция для установки ProtonTricks
install_protontricks() {
    print_message "Установка ProtonTricks..."
    
    if command -v protontricks &> /dev/null; then
        print_warning "ProtonTricks уже установлен"
    else
        if flatpak install flathub com.github.Matoking.protontricks -y; then
            print_success "ProtonTricks установлен"
        else
            print_warning "Не удалось установить ProtonTricks через Flatpak"
            print_message "Попробуйте установить через Discover"
        fi
    fi
}

# Функция для установки ProtonUp-Qt
install_protonup() {
    print_message "Установка ProtonUp-Qt..."
    
    if flatpak list | grep -q "net.davidotek.pupgui2"; then
        print_warning "ProtonUp-Qt уже установлен"
    else
        if flatpak install flathub net.davidotek.pupgui2 -y; then
            print_success "ProtonUp-Qt установлен"
        else
            print_warning "Не удалось установить ProtonUp-Qt через Flatpak"
            print_message "Попробуйте установить через Discover"
        fi
    fi
}

# Функция для установки SteamLinuxRuntime - Sniper
install_sniper() {
    print_message "Установка SteamLinuxRuntime - Sniper..."
    
    # Определяем правильный путь к Steam в зависимости от пользователя
    local sniper_dir
    if [[ $EUID -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
        # Если запущен с sudo, используем путь пользователя
        sniper_dir="/home/$SUDO_USER/.steam/steam/steamapps/common/SteamLinuxRuntime_sniper"
    else
        # Если запущен обычным пользователем
        sniper_dir="$HOME/.steam/steam/steamapps/common/SteamLinuxRuntime_sniper"
    fi
    
    if [[ -d "$sniper_dir" ]]; then
        print_warning "SteamLinuxRuntime - Sniper уже установлен"
        return 0
    fi
    
    if command -v steam &> /dev/null; then
        print_message "Загрузка SteamLinuxRuntime - Sniper через Steam..."
        
        # Если запущен с sudo, переключаемся на пользователя для запуска Steam
        if [[ $EUID -eq 0 ]] && [[ -n "$SUDO_USER" ]]; then
            if runuser -l "$SUDO_USER" -c "steam steam://install/1628350" &>/dev/null; then
                print_success "SteamLinuxRuntime - Sniper установлен"
                log_setup_state "sniper_installed"
            else
                print_warning "Не удалось установить SteamLinuxRuntime - Sniper"
                print_message "Попробуйте установить вручную через Steam (ID: 1628350)"
                print_message "Или пропустите этот шаг - Sniper не критичен для работы"
            fi
        else
            if steam steam://install/1628350 &>/dev/null; then
                print_success "SteamLinuxRuntime - Sniper установлен"
                log_setup_state "sniper_installed"
            else
                print_warning "Не удалось установить SteamLinuxRuntime - Sniper"
                print_message "Попробуйте установить вручную через Steam (ID: 1628350)"
                print_message "Или пропустите этот шаг - Sniper не критичен для работы"
            fi
        fi
    else
        print_warning "Steam не найден, установка SteamLinuxRuntime - Sniper пропущена"
        print_message "Альтернатива: установите через Steam вручную (ID: 1628350)"
    fi
}

# Функция для очистки кэша
cleanup_cache() {
    print_message "Очистка кэша pacman..."
    if run_sudo pacman -Sc --noconfirm; then
        print_success "Кэш очищен"
    else
        print_warning "Не удалось очистить кэш"
    fi
}

# Функция для отображения статуса
show_status() {
    echo
    print_message "=== СТАТУС СИСТЕМЫ ==="
    
    # Проверка readonly режима
    if steamos-readonly status | grep -q "disabled"; then
        print_success "Режим только для чтения: ОТКЛЮЧЕН"
    else
        print_warning "Режим только для чтения: ВКЛЮЧЕН"
    fi
    
    # Проверка pacman
    if grep -q "SigLevel = TrustAll" /etc/pacman.conf; then
        print_success "Pacman: настроен для неподписанных пакетов"
    else
        print_warning "Pacman: требует настройки"
    fi
    
    # Проверка установленных инструментов
    echo
    print_message "=== УСТАНОВЛЕННЫЕ ИНСТРУМЕНТЫ ==="
    
    if command -v yay &> /dev/null; then
        print_success "Yay: установлен"
    else
        print_warning "Yay: не установлен"
    fi
    
    if command -v wine &> /dev/null; then
        print_success "Wine: установлен"
    else
        print_warning "Wine: не установлен"
    fi
    
    if command -v protontricks &> /dev/null; then
        print_success "ProtonTricks: установлен"
    else
        print_warning "ProtonTricks: не установлен"
    fi
    
    if flatpak list | grep -q "net.davidotek.pupgui2"; then
        print_success "ProtonUp-Qt: установлен"
    else
        print_warning "ProtonUp-Qt: не установлен"
    fi
    
    if [[ -d "$HOME/.steam/steam/steamapps/common/SteamLinuxRuntime_sniper" ]]; then
        print_success "SteamLinuxRuntime - Sniper: установлен"
    else
        print_warning "SteamLinuxRuntime - Sniper: не установлен"
    fi
}

# Функция для отображения справки
show_help() {
    echo "Steam Deck Setup Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ]"
    echo
    echo "ОПЦИИ:"
    echo "  setup          - Полная настройка системы (по умолчанию)"
    echo "  disable        - Отключить режим только для чтения"
    echo "  enable         - Включить режим только для чтения"
    echo "  rollback       - Откат изменений setup"
    echo "  install-utils  - Установить утилиты в основную память"
    echo "  status         - Показать статус системы"
    echo "  help           - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0                  # Полная настройка"
    echo "  $0 setup            # Полная настройка"
    echo "  $0 disable          # Только отключить readonly"
    echo "  $0 enable           # Только включить readonly"
    echo "  $0 rollback         # Откат изменений setup"
    echo "  $0 install-utils    # Установить утилиты"
    echo "  $0 status           # Показать статус"
}

# Функция для установки Steam Deck Utils
install_steamdeck_utils() {
    print_message "Установка Steam Deck Enhancement Pack..."
    
    local utils_dir="$INSTALL_DIR"
    local current_dir=$(dirname "$(readlink -f "$0")")
    
    # Создаем директорию для утилит
    if [[ ! -d "$utils_dir" ]]; then
        print_message "Создание директории $utils_dir..."
        mkdir -p "$utils_dir"
        chown deck:deck "$utils_dir"
    fi
    
    # Копируем все файлы проекта
    print_message "Копирование файлов утилиты..."
    cp -r "$current_dir"/* "$utils_dir/" 2>/dev/null || {
        print_warning "Не удалось скопировать все файлы"
        print_message "Попытка копирования основных компонентов..."
        
        # Копируем основные скрипты
        mkdir -p "$utils_dir/scripts"
        cp "$current_dir"/*.sh "$utils_dir/scripts/" 2>/dev/null || true
        cp "$current_dir"/*.py "$utils_dir/scripts/" 2>/dev/null || true
        
        # Копируем руководства
        mkdir -p "$utils_dir/guides"
        cp "$current_dir/guides"/*.md "$utils_dir/guides/" 2>/dev/null || true
        
        # Копируем конфигурационные файлы
        cp "$current_dir"/*.md "$utils_dir/" 2>/dev/null || true
        cp "$current_dir"/*.yml "$utils_dir/" 2>/dev/null || true
        cp "$current_dir"/*.sh "$utils_dir/" 2>/dev/null || true
    }
    
    # Устанавливаем права доступа
    print_message "Установка прав доступа..."
    chown -R deck:deck "$utils_dir"
    chmod -R 755 "$utils_dir"
    chmod +x "$utils_dir/scripts"/*.sh 2>/dev/null || true
    chmod +x "$utils_dir"/*.sh 2>/dev/null || true
    
    # Создаем символические ссылки для быстрого доступа
    print_message "Создание символических ссылок..."
    
    # Ссылка на главный скрипт настройки
    ln -sf "$utils_dir/scripts/steamdeck_setup.sh" "$DECK_HOME/steamdeck-setup" 2>/dev/null || true
    
    # Ссылка на GUI
    ln -sf "$utils_dir/scripts/steamdeck_gui.py" "$DECK_HOME/steamdeck-gui" 2>/dev/null || true
    
    # Ссылка на скрипт бэкапа
    ln -sf "$utils_dir/scripts/steamdeck_backup.sh" "$DECK_HOME/steamdeck-backup" 2>/dev/null || true
    
    # Ссылка на скрипт очистки
    ln -sf "$utils_dir/scripts/steamdeck_cleanup.sh" "$DECK_HOME/steamdeck-cleanup" 2>/dev/null || true
    
    # Ссылка на скрипт оптимизации
    ln -sf "$utils_dir/scripts/steamdeck_optimizer.sh" "$DECK_HOME/steamdeck-optimizer" 2>/dev/null || true
    
    # Ссылка на скрипт MicroSD
    ln -sf "$utils_dir/scripts/steamdeck_microsd.sh" "$DECK_HOME/steamdeck-microsd" 2>/dev/null || true
    
    # Ссылка на скрипт обновления
    ln -sf "$utils_dir/scripts/steamdeck_update.sh" "$DECK_HOME/steamdeck-update" 2>/dev/null || true
    
    # Создаем desktop файл для GUI
    print_message "Создание desktop файла для GUI..."
    cat > "$DECK_HOME/.local/share/applications/steamdeck-enhancement-pack.desktop" << 'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Steam Deck Enhancement Pack
Comment=Утилиты для управления Steam Deck
Exec=python3 $INSTALL_DIR/scripts/steamdeck_gui.py
Icon=steam
Terminal=false
Categories=Utility;System;
StartupNotify=true
EOF
    
    chmod +x "$DECK_HOME/.local/share/applications/steamdeck-enhancement-pack.desktop"
    chown $DECK_USER:$DECK_USER "$DECK_HOME/.local/share/applications/steamdeck-enhancement-pack.desktop"
    
    # Обновляем desktop базу
    update-desktop-database "$DECK_HOME/.local/share/applications" 2>/dev/null || true
    
    # Создаем скрипт быстрого запуска
    print_message "Создание скрипта быстрого запуска..."
    cat > "$DECK_HOME/steamdeck-utils" << 'EOF'
#!/bin/bash
# Steam Deck Enhancement Pack - Быстрый запуск
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

echo "🎮 Steam Deck Enhancement Pack v0.1"
echo "=================================="
echo
echo "Доступные команды:"
echo "  steamdeck-setup     - Настройка системы"
echo "  steamdeck-gui       - Графический интерфейс"
echo "  steamdeck-backup    - Резервное копирование"
echo "  steamdeck-cleanup   - Очистка системы"
echo "  steamdeck-optimizer - Оптимизация"
echo "  steamdeck-microsd   - Управление MicroSD"
echo "  steamdeck-update    - Обновление утилиты"
echo
echo "Или запустите GUI: python3 ~/SteamDeck/scripts/steamdeck_gui.py"
echo
EOF
    
    chmod +x "$DECK_HOME/steamdeck-utils"
    chown $DECK_USER:$DECK_USER "$DECK_HOME/steamdeck-utils"
    
    # Копируем готовые обложки утилиты
    print_message "Копирование обложек утилиты..."
    local artwork_source_dir="$current_dir/../artwork/utils"
    local artwork_dest_dir="$utils_dir/artwork/utils"
    
    if [[ -d "$artwork_source_dir" ]]; then
        mkdir -p "$artwork_dest_dir"
        cp -r "$artwork_source_dir"/* "$artwork_dest_dir/" 2>/dev/null || true
        chown -R deck:deck "$artwork_dest_dir" 2>/dev/null || true
        print_success "Обложки утилиты скопированы"
    else
        print_warning "Папка с обложками не найдена: $artwork_source_dir"
    fi
    
    # Создаем README для пользователя
    print_message "Создание пользовательского README..."
    cat > "$INSTALL_DIR/QUICK_START.md" << 'EOF'
# Steam Deck Enhancement Pack - Быстрый старт

## 🚀 Быстрый запуск

### Графический интерфейс:
```bash
python3 ~/SteamDeck/scripts/steamdeck_gui.py
```

### Командная строка:
```bash
# Настройка системы
~/steamdeck-setup

# Резервное копирование
~/steamdeck-backup

# Очистка системы
~/steamdeck-cleanup

# Оптимизация
~/steamdeck-optimizer

# Управление MicroSD
~/steamdeck-microsd

# Обновление утилиты
~/steamdeck-update

# Показать все команды
~/steamdeck-utils
```

## 📁 Расположение файлов

- **Скрипты:** `~/SteamDeck/scripts/`
- **Руководства:** `~/SteamDeck/guides/`
- **Символические ссылки:** `~/steamdeck-*`

## 🎯 Первый запуск

1. Запустите GUI: `python3 ~/SteamDeck/scripts/steamdeck_gui.py`
2. Нажмите "Настройка системы" для первоначальной настройки
3. Используйте другие функции по необходимости

## 📚 Документация

Все руководства находятся в папке `~/SteamDeck/guides/`

---
*Steam Deck Enhancement Pack v0.1*
*Автор: @ncux11*
EOF
    
    chown $DECK_USER:$DECK_USER "$INSTALL_DIR/QUICK_START.md"
    
    print_success "Steam Deck Enhancement Pack установлен в $utils_dir"
    print_message "Созданы символические ссылки для быстрого доступа"
    print_message "Desktop файл создан для запуска из меню приложений"
    print_message "Быстрый старт: ~/steamdeck-utils"
    
    log_setup_state "utils_installed" "$utils_dir"
}

# Основная функция настройки
main_setup() {
    print_message "=== НАЧАЛО НАСТРОЙКИ STEAM DECK ==="
    echo
    
    check_root
    check_password
    
    # Создание детального бэкапа перед началом
    print_message "Создание детального бэкапа..."
    local backup_dir=$(create_detailed_backup)
    log_setup_state "backup_created" "$backup_dir"
    
    disable_readonly
    configure_pacman
    init_keys
    install_base_packages
    install_aur_helper
    install_wine
    install_protontricks
    install_protonup
    install_sniper
    install_steamdeck_utils
    cleanup_cache
    
    echo
    print_success "=== НАСТРОЙКА ЗАВЕРШЕНА ==="
    echo
    print_message "Теперь вы можете:"
    print_message "- Устанавливать пакеты через Yay: yay -S название_пакета"
    print_message "- Использовать ProtonTricks для настройки игр"
    print_message "- Управлять версиями Proton через ProtonUp-Qt"
    print_message "- Устанавливать приложения через Discover"
    echo
    print_warning "После завершения работы рекомендуется включить readonly режим:"
    print_message "$0 enable"
    
    # Показываем сводку
    show_summary
}

# Обработка аргументов командной строки
case "${1:-setup}" in
    "setup")
        main_setup
        ;;
    "disable")
        check_root
        check_password
        disable_readonly
        print_success "Режим только для чтения отключен"
        ;;
    "enable")
        check_root
        check_password
        enable_readonly
        print_success "Режим только для чтения включен"
        ;;
    "status")
        show_status
        ;;
    "rollback")
        check_root
        check_password
        rollback_setup
        ;;
    "install-utils")
        check_root
        check_password
        install_steamdeck_utils
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
