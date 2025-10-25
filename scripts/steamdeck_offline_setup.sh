#!/bin/bash

# Steam Deck Offline Setup Script v0.1
# Автоматическая настройка Steam Deck для offline-режима
# Дата: 25 октября 2025

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Функции для вывода
print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
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

print_message() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

print_info() {
    echo -e "${PURPLE}🔧 $1${NC}"
}

# Проверка прав пользователя
check_root() {
    if [[ $EUID -eq 0 ]]; then
        print_error "Не запускайте скрипт от имени root!"
        exit 1
    fi
}

# Проверка пароля sudo
check_password() {
    if ! sudo -n true 2>/dev/null; then
        print_warning "Требуется пароль sudo для настройки offline-режима"
        print_message "Убедитесь, что пароль установлен командой: passwd"
        sudo -v
    fi
}

# Создание директорий для offline-режима
create_offline_directories() {
    print_header "СОЗДАНИЕ ДИРЕКТОРИЙ ДЛЯ OFFLINE-РЕЖИМА"
    
    local directories=(
        "$HOME/SteamDeck_Offline"
        "$HOME/SteamDeck_Offline/Games"
        "$HOME/SteamDeck_Offline/Media"
        "$HOME/SteamDeck_Offline/Media/Movies"
        "$HOME/SteamDeck_Offline/Media/TV_Shows"
        "$HOME/SteamDeck_Offline/Media/Music"
        "$HOME/SteamDeck_Offline/Media/Books"
        "$HOME/SteamDeck_Offline/Mods"
        "$HOME/SteamDeck_Offline/Mods/ready_to_install"
        "$HOME/SteamDeck_Offline/Mods/installed"
        "$HOME/SteamDeck_Offline/Backups"
        "$HOME/SteamDeck_Offline/Profiles"
        "$HOME/SteamDeck_Offline/ROMs"
        "$HOME/SteamDeck_Offline/ROMs/NES"
        "$HOME/SteamDeck_Offline/ROMs/SNES"
        "$HOME/SteamDeck_Offline/ROMs/GameBoy"
        "$HOME/SteamDeck_Offline/ROMs/GameBoyAdvance"
        "$HOME/SteamDeck_Offline/ROMs/PlayStation"
        "$HOME/SteamDeck_Offline/ROMs/Nintendo64"
        "$HOME/.steamdeck_profiles"
    )
    
    for dir in "${directories[@]}"; do
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir"
            print_success "Создана директория: $dir"
        else
            print_message "Директория уже существует: $dir"
        fi
    done
}

# Настройка Steam для offline-режима
configure_steam_offline() {
    print_header "НАСТРОЙКА STEAM ДЛЯ OFFLINE-РЕЖИМА"
    
    local steam_config="$HOME/.steam/steam/config/config.vdf"
    
    # Создание бэкапа конфигурации
    if [[ -f "$steam_config" ]]; then
        cp "$steam_config" "$steam_config.backup.$(date +%Y%m%d_%H%M%S)"
        print_success "Создан бэкап конфигурации Steam"
    fi
    
    # Настройка offline-режима
    print_message "Настройка Steam для offline-режима..."
    
    # Отключение автоматических обновлений
    if ! grep -q "AutoUpdateBehavior" "$steam_config" 2>/dev/null; then
        echo "AutoUpdateBehavior=0" >> "$steam_config"
        print_success "Отключены автоматические обновления"
    fi
    
    # Отключение облачных сохранений (опционально)
    if ! grep -q "CloudEnabled" "$steam_config" 2>/dev/null; then
        echo "CloudEnabled=0" >> "$steam_config"
        print_success "Отключены облачные сохранения"
    fi
    
    # Настройка кэширования
    if ! grep -q "DownloadThrottleKbps" "$steam_config" 2>/dev/null; then
        echo "DownloadThrottleKbps=0" >> "$steam_config"
        print_success "Настроено кэширование"
    fi
    
    # Включение консоли Steam
    if ! grep -q "EnableDevConsole" "$steam_config" 2>/dev/null; then
        echo "EnableDevConsole=1" >> "$steam_config"
        print_success "Включена консоль Steam"
    fi
    
    # Включение отладочной информации
    if ! grep -q "EnableDebugMenu" "$steam_config" 2>/dev/null; then
        echo "EnableDebugMenu=1" >> "$steam_config"
        print_success "Включено отладочное меню"
    fi
}

# Установка необходимых пакетов для offline-режима
install_offline_packages() {
    print_header "УСТАНОВКА ПАКЕТОВ ДЛЯ OFFLINE-РЕЖИМА"
    
    local packages=(
        "vlc"           # Медиа-плеер
        "retroarch"     # Эмулятор
        "unzip"         # Архиватор
        "unrar"         # RAR архивы
        "p7zip"         # 7z архивы
        "rsync"         # Синхронизация файлов
        "htop"          # Мониторинг системы
        "neofetch"      # Информация о системе
        "tree"          # Дерево директорий
        "jq"            # JSON парсер
        "curl"          # HTTP клиент
        "wget"          # Загрузчик
    )
    
    for package in "${packages[@]}"; do
        if ! pacman -Qi "$package" &>/dev/null; then
            print_message "Установка пакета: $package"
            if sudo pacman -S --needed "$package" --noconfirm; then
                print_success "Пакет $package установлен"
            else
                print_warning "Не удалось установить пакет $package"
            fi
        else
            print_message "Пакет $package уже установлен"
        fi
    done
}

# Создание профилей производительности
create_performance_profiles() {
    print_header "СОЗДАНИЕ ПРОФИЛЕЙ ПРОИЗВОДИТЕЛЬНОСТИ"
    
    # Профиль "Максимальная производительность"
    cat > "$HOME/.steamdeck_profiles/max_performance.sh" << 'EOF'
#!/bin/bash
# Максимальная производительность

echo "Активация профиля: Максимальная производительность"

# TDP на максимум
echo 15 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true

# CPU governor на performance
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Яркость на максимум
echo 100 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

# Включение Wi-Fi
sudo rfkill unblock wifi 2>/dev/null || true

echo "Профиль максимальной производительности активирован"
EOF

    # Профиль "Баланс"
    cat > "$HOME/.steamdeck_profiles/balanced.sh" << 'EOF'
#!/bin/bash
# Баланс производительности и батареи

echo "Активация профиля: Баланс"

# TDP средний
echo 10 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true

# CPU governor на schedutil
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Яркость средняя
echo 70 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

echo "Профиль баланса активирован"
EOF

    # Профиль "Экономия батареи"
    cat > "$HOME/.steamdeck_profiles/battery_saver.sh" << 'EOF'
#!/bin/bash
# Экономия батареи

echo "Активация профиля: Экономия батареи"

# TDP минимальный
echo 5 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true

# CPU governor на powersave
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Яркость низкая
echo 40 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

# Отключение Wi-Fi для экономии
sudo rfkill block wifi 2>/dev/null || true

echo "Профиль экономии батареи активирован"
EOF

    # Профиль "Offline"
    cat > "$HOME/.steamdeck_profiles/offline.sh" << 'EOF'
#!/bin/bash
# Offline режим

echo "Активация профиля: Offline"

# Баланс производительности и батареи
echo 10 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Яркость средняя
echo 70 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

# Отключение всех сетевых интерфейсов
sudo rfkill block wifi 2>/dev/null || true
sudo rfkill block bluetooth 2>/dev/null || true

# Запуск Steam в offline-режиме
steam --offline &

echo "Offline-профиль активирован"
EOF

    # Делаем профили исполняемыми
    chmod +x "$HOME/.steamdeck_profiles"/*.sh
    
    print_success "Профили производительности созданы"
}

# Создание утилит для offline-режима
create_offline_utilities() {
    print_header "СОЗДАНИЕ УТИЛИТ ДЛЯ OFFLINE-РЕЖИМА"
    
    # Утилита для очистки памяти
    cat > "$HOME/SteamDeck_Offline/free_memory.sh" << 'EOF'
#!/bin/bash
# Очистка памяти перед запуском игры

echo "Очистка памяти перед запуском игры..."

# Очистка кэша страниц
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Очистка swap
sudo swapoff -a
sudo swapon -a

# Очистка временных файлов
rm -rf /tmp/*
rm -rf ~/.cache/*

# Показ свободной памяти
echo "Свободная память:"
free -h

echo "Память очищена!"
EOF

    # Утилита для бэкапа сохранений
    cat > "$HOME/SteamDeck_Offline/backup_saves.sh" << 'EOF'
#!/bin/bash
# Бэкап сохранений игр

BACKUP_DIR="$HOME/SteamDeck_Offline/Backups/saves_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Создание бэкапа сохранений..."

# Поиск всех сохранений
find ~/.steam/steam/userdata -name "remote" -type d | while read save_dir; do
    game_id=$(echo "$save_dir" | cut -d'/' -f6)
    echo "Копирование сохранений игры: $game_id"
    cp -r "$save_dir" "$BACKUP_DIR/game_$game_id"
done

echo "Сохранения скопированы в: $BACKUP_DIR"
EOF

    # Утилита для управления медиа
    cat > "$HOME/SteamDeck_Offline/manage_media.sh" << 'EOF'
#!/bin/bash
# Управление медиа-библиотекой

MEDIA_DIR="$HOME/SteamDeck_Offline/Media"
BACKUP_DIR="/run/media/mmcblk0p1/Media_Backup"

case "${1:-help}" in
    "scan")
        echo "Сканирование медиа-библиотеки..."
        find "$MEDIA_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.mp3" -o -name "*.flac" \) | while read file; do
            echo "Найден файл: $(basename "$file")"
        done
        ;;
    "backup")
        echo "Создание бэкапа медиа..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$MEDIA_DIR"/* "$BACKUP_DIR/"
        echo "Медиа скопированы в: $BACKUP_DIR"
        ;;
    "restore")
        echo "Восстановление медиа..."
        if [[ -d "$BACKUP_DIR" ]]; then
            cp -r "$BACKUP_DIR"/* "$MEDIA_DIR/"
            echo "Медиа восстановлены"
        else
            echo "Бэкап не найден: $BACKUP_DIR"
        fi
        ;;
    "organize")
        echo "Организация медиа по типам..."
        find "$MEDIA_DIR" -type f | while read file; do
            ext="${file##*.}"
            case "$ext" in
                "mp4"|"mkv"|"avi"|"mov") 
                    mv "$file" "$MEDIA_DIR/Movies/"
                    ;;
                "mp3"|"flac"|"wav"|"ogg")
                    mv "$file" "$MEDIA_DIR/Music/"
                    ;;
                "pdf"|"epub"|"mobi")
                    mv "$file" "$MEDIA_DIR/Books/"
                    ;;
            esac
        done
        echo "Медиа организованы по типам"
        ;;
    *)
        echo "Использование: $0 [scan|backup|restore|organize]"
        echo "  scan     - Сканировать медиа-библиотеку"
        echo "  backup   - Создать бэкап медиа"
        echo "  restore  - Восстановить медиа"
        echo "  organize - Организовать медиа по типам"
        ;;
esac
EOF

    # Утилита для управления ROM-ами
    cat > "$HOME/SteamDeck_Offline/manage_roms.sh" << 'EOF'
#!/bin/bash
# Управление ROM-ами

ROMS_DIR="$HOME/SteamDeck_Offline/ROMs"
BACKUP_DIR="/run/media/mmcblk0p1/ROMs_Backup"

case "${1:-help}" in
    "backup")
        echo "Создание бэкапа ROM-ов..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$ROMS_DIR"/* "$BACKUP_DIR/"
        echo "ROM-ы скопированы в: $BACKUP_DIR"
        ;;
    "restore")
        echo "Восстановление ROM-ов..."
        if [[ -d "$BACKUP_DIR" ]]; then
            cp -r "$BACKUP_DIR"/* "$ROMS_DIR/"
            echo "ROM-ы восстановлены"
        else
            echo "Бэкап не найден: $BACKUP_DIR"
        fi
        ;;
    "organize")
        echo "Организация ROM-ов по системам..."
        for rom_file in "$ROMS_DIR"/*; do
            if [[ -f "$rom_file" ]]; then
                ext="${rom_file##*.}"
                case "$ext" in
                    "nes") system="NES" ;;
                    "snes") system="SNES" ;;
                    "gb") system="GameBoy" ;;
                    "gba") system="GameBoyAdvance" ;;
                    "psx") system="PlayStation" ;;
                    "n64") system="Nintendo64" ;;
                    *) system="Other" ;;
                esac
                mkdir -p "$ROMS_DIR/$system"
                mv "$rom_file" "$ROMS_DIR/$system/"
            fi
        done
        echo "ROM-ы организованы по системам"
        ;;
    *)
        echo "Использование: $0 [backup|restore|organize]"
        echo "  backup   - Создать бэкап ROM-ов"
        echo "  restore  - Восстановить ROM-ы"
        echo "  organize - Организовать ROM-ы по системам"
        ;;
esac
EOF

    # Утилита для автоматического переключения профилей
    cat > "$HOME/SteamDeck_Offline/auto_profile_switch.sh" << 'EOF'
#!/bin/bash
# Автоматическое переключение профилей

# Проверка подключения к сети
check_network() {
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "online"
    else
        echo "offline"
    fi
}

# Проверка уровня батареи
check_battery() {
    local battery_level=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "100")
    echo "$battery_level"
}

# Автоматический выбор профиля
auto_select_profile() {
    local network_status=$(check_network)
    local battery_level=$(check_battery)
    
    if [[ "$network_status" == "offline" ]]; then
        echo "Сеть недоступна - активация offline-профиля"
        ~/.steamdeck_profiles/offline.sh
    elif [[ "$battery_level" -lt 30 ]]; then
        echo "Низкий заряд батареи - активация профиля экономии батареи"
        ~/.steamdeck_profiles/battery_saver.sh
    else
        echo "Оптимальные условия - активация профиля баланса"
        ~/.steamdeck_profiles/balanced.sh
    fi
}

# Запуск автоматического выбора
auto_select_profile
EOF

    # Делаем утилиты исполняемыми
    chmod +x "$HOME/SteamDeck_Offline"/*.sh
    
    print_success "Утилиты для offline-режима созданы"
}

# Настройка RetroArch для offline-игр
configure_retroarch() {
    print_header "НАСТРОЙКА RETROARCH ДЛЯ OFFLINE-ИГР"
    
    # Создание конфигурации RetroArch
    mkdir -p ~/.config/retroarch
    
    cat > ~/.config/retroarch/retroarch.cfg << 'EOF'
# Steam Deck Optimized RetroArch Config
input_joypad_driver = sdl2
video_driver = vulkan
audio_driver = pulse
video_fullscreen = true
video_windowed_fullscreen = true
input_remapping_directory = ~/.config/retroarch/remaps
savefile_directory = ~/SteamDeck_Offline/ROMs/saves
screenshot_directory = ~/SteamDeck_Offline/ROMs/screenshots
system_directory = ~/SteamDeck_Offline/ROMs/system
EOF

    print_success "RetroArch настроен для offline-игр"
}

# Создание главного меню offline-утилит
create_offline_menu() {
    print_header "СОЗДАНИЕ ГЛАВНОГО МЕНЮ OFFLINE-УТИЛИТ"
    
    cat > "$HOME/SteamDeck_Offline/offline_menu.sh" << 'EOF'
#!/bin/bash
# Главное меню offline-утилит

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m'

print_header() {
    echo -e "${BLUE}=== $1 ===${NC}"
}

print_success() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_message() {
    echo -e "${CYAN}ℹ️  $1${NC}"
}

# Главное меню
show_menu() {
    clear
    print_header "STEAM DECK OFFLINE МЕНЮ"
    echo
    echo "1. Профили производительности"
    echo "2. Управление играми"
    echo "3. Управление медиа"
    echo "4. Управление ROM-ами"
    echo "5. Резервное копирование"
    echo "6. Очистка системы"
    echo "7. Мониторинг системы"
    echo "8. Настройки"
    echo "9. Выход"
    echo
}

# Меню профилей
show_profiles_menu() {
    clear
    print_header "ПРОФИЛИ ПРОИЗВОДИТЕЛЬНОСТИ"
    echo
    echo "1. Максимальная производительность"
    echo "2. Баланс"
    echo "3. Экономия батареи"
    echo "4. Offline режим"
    echo "5. Автоматический выбор"
    echo "6. Назад"
    echo
}

# Меню игр
show_games_menu() {
    clear
    print_header "УПРАВЛЕНИЕ ИГРАМИ"
    echo
    echo "1. Очистка памяти"
    echo "2. Бэкап сохранений"
    echo "3. Восстановление сохранений"
    echo "4. Создание ярлыков"
    echo "5. Назад"
    echo
}

# Меню медиа
show_media_menu() {
    clear
    print_header "УПРАВЛЕНИЕ МЕДИА"
    echo
    echo "1. Сканировать медиа-библиотеку"
    echo "2. Создать бэкап медиа"
    echo "3. Восстановить медиа"
    echo "4. Организовать медиа"
    echo "5. Назад"
    echo
}

# Меню ROM-ов
show_roms_menu() {
    clear
    print_header "УПРАВЛЕНИЕ ROM-АМИ"
    echo
    echo "1. Создать бэкап ROM-ов"
    echo "2. Восстановить ROM-ы"
    echo "3. Организовать ROM-ы"
    echo "4. Запустить RetroArch"
    echo "5. Назад"
    echo
}

# Меню бэкапа
show_backup_menu() {
    clear
    print_header "РЕЗЕРВНОЕ КОПИРОВАНИЕ"
    echo
    echo "1. Бэкап сохранений"
    echo "2. Бэкап медиа"
    echo "3. Бэкап ROM-ов"
    echo "4. Полный бэкап системы"
    echo "5. Назад"
    echo
}

# Меню очистки
show_cleanup_menu() {
    clear
    print_header "ОЧИСТКА СИСТЕМЫ"
    echo
    echo "1. Очистить память"
    echo "2. Очистить кэш Steam"
    echo "3. Очистить временные файлы"
    echo "4. Очистить логи"
    echo "5. Назад"
    echo
}

# Меню мониторинга
show_monitor_menu() {
    clear
    print_header "МОНИТОРИНГ СИСТЕМЫ"
    echo
    echo "1. Статус системы"
    echo "2. Использование памяти"
    echo "3. Использование диска"
    echo "4. Температура"
    echo "5. Батарея"
    echo "6. Назад"
    echo
}

# Меню настроек
show_settings_menu() {
    clear
    print_header "НАСТРОЙКИ"
    echo
    echo "1. Настройки Steam"
    echo "2. Настройки RetroArch"
    echo "3. Настройки VLC"
    echo "4. Системные настройки"
    echo "5. Назад"
    echo
}

# Основной цикл меню
main_menu() {
    while true; do
        show_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                profiles_menu
                ;;
            2)
                games_menu
                ;;
            3)
                media_menu
                ;;
            4)
                roms_menu
                ;;
            5)
                backup_menu
                ;;
            6)
                cleanup_menu
                ;;
            7)
                monitor_menu
                ;;
            8)
                settings_menu
                ;;
            9)
                print_message "Выход из меню"
                exit 0
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню профилей
profiles_menu() {
    while true; do
        show_profiles_menu
        read -p "Выберите профиль: " choice
        
        case $choice in
            1)
                ~/.steamdeck_profiles/max_performance.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                ~/.steamdeck_profiles/balanced.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                ~/.steamdeck_profiles/battery_saver.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                ~/.steamdeck_profiles/offline.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                ~/SteamDeck_Offline/auto_profile_switch.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            6)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню игр
games_menu() {
    while true; do
        show_games_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                ~/SteamDeck_Offline/free_memory.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                ~/SteamDeck_Offline/backup_saves.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                read -p "Введите путь к бэкапу: " backup_path
                if [[ -d "$backup_path" ]]; then
                    cp -r "$backup_path"/* ~/.steam/steam/userdata/
                    print_success "Сохранения восстановлены"
                else
                    print_warning "Путь не найден"
                fi
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                # Создание ярлыков для игр
                find ~/.steam/steam/steamapps/common -maxdepth 1 -type d | while read game_dir; do
                    game_name=$(basename "$game_dir")
                    if [[ "$game_name" != "common" ]]; then
                        cat > "$HOME/SteamDeck_Offline/Games/${game_name}.sh" << GAME_EOF
#!/bin/bash
# Game Launcher: $game_name

cd "$game_dir"
./${game_name}.sh
GAME_EOF
                        chmod +x "$HOME/SteamDeck_Offline/Games/${game_name}.sh"
                    fi
                done
                print_success "Ярлыки созданы"
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню медиа
media_menu() {
    while true; do
        show_media_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                ~/SteamDeck_Offline/manage_media.sh scan
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                ~/SteamDeck_Offline/manage_media.sh backup
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                ~/SteamDeck_Offline/manage_media.sh restore
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                ~/SteamDeck_Offline/manage_media.sh organize
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню ROM-ов
roms_menu() {
    while true; do
        show_roms_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                ~/SteamDeck_Offline/manage_roms.sh backup
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                ~/SteamDeck_Offline/manage_roms.sh restore
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                ~/SteamDeck_Offline/manage_roms.sh organize
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                retroarch &
                print_success "RetroArch запущен"
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню бэкапа
backup_menu() {
    while true; do
        show_backup_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                ~/SteamDeck_Offline/backup_saves.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                ~/SteamDeck_Offline/manage_media.sh backup
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                ~/SteamDeck_Offline/manage_roms.sh backup
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                print_message "Создание полного бэкапа системы..."
                # Здесь можно добавить полный бэкап
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню очистки
cleanup_menu() {
    while true; do
        show_cleanup_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                ~/SteamDeck_Offline/free_memory.sh
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                print_message "Очистка кэша Steam..."
                rm -rf ~/.steam/steam/logs/*
                print_success "Кэш Steam очищен"
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                print_message "Очистка временных файлов..."
                rm -rf /tmp/*
                rm -rf ~/.cache/*
                print_success "Временные файлы очищены"
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                print_message "Очистка логов..."
                sudo journalctl --vacuum-time=1d
                print_success "Логи очищены"
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню мониторинга
monitor_menu() {
    while true; do
        show_monitor_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                clear
                print_header "СТАТУС СИСТЕМЫ"
                neofetch
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                clear
                print_header "ИСПОЛЬЗОВАНИЕ ПАМЯТИ"
                free -h
                echo
                htop -n 1
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                clear
                print_header "ИСПОЛЬЗОВАНИЕ ДИСКА"
                df -h
                echo
                du -sh ~/SteamDeck_Offline/* 2>/dev/null | sort -hr
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                clear
                print_header "ТЕМПЕРАТУРА"
                sensors 2>/dev/null || echo "Датчики температуры недоступны"
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                clear
                print_header "БАТАРЕЯ"
                cat /sys/class/power_supply/BAT0/capacity 2>/dev/null && echo "%"
                cat /sys/class/power_supply/BAT0/status 2>/dev/null
                read -p "Нажмите Enter для продолжения..."
                ;;
            6)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Меню настроек
settings_menu() {
    while true; do
        show_settings_menu
        read -p "Выберите опцию: " choice
        
        case $choice in
            1)
                print_message "Открытие настроек Steam..."
                steam &
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                print_message "Открытие настроек RetroArch..."
                retroarch &
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                print_message "Открытие настроек VLC..."
                vlc &
                read -p "Нажмите Enter для продолжения..."
                ;;
            4)
                print_message "Открытие системных настроек..."
                # Здесь можно добавить системные настройки
                read -p "Нажмите Enter для продолжения..."
                ;;
            5)
                break
                ;;
            *)
                print_warning "Неверный выбор"
                ;;
        esac
    done
}

# Запуск главного меню
main_menu
EOF

    chmod +x "$HOME/SteamDeck_Offline/offline_menu.sh"
    
    print_success "Главное меню offline-утилит создано"
}

# Создание ярлыка для Steam
create_steam_shortcut() {
    print_header "СОЗДАНИЕ ЯРЛЫКА ДЛЯ STEAM"
    
    cat > "$HOME/SteamDeck_Offline/launch_steam_offline.sh" << 'EOF'
#!/bin/bash
# Запуск Steam в offline-режиме

echo "Запуск Steam в offline-режиме..."

# Активация offline-профиля
~/.steamdeck_profiles/offline.sh

# Очистка памяти
~/SteamDeck_Offline/free_memory.sh

# Запуск Steam
steam --offline
EOF

    chmod +x "$HOME/SteamDeck_Offline/launch_steam_offline.sh"
    
    print_success "Ярлык для Steam создан"
}

# Основная функция
main() {
    print_header "STEAM DECK OFFLINE SETUP"
    echo
    print_message "Настройка Steam Deck для offline-режима..."
    echo
    
    check_root
    check_password
    
    create_offline_directories
    configure_steam_offline
    install_offline_packages
    create_performance_profiles
    create_offline_utilities
    configure_retroarch
    create_offline_menu
    create_steam_shortcut
    
    echo
    print_success "=== НАСТРОЙКА OFFLINE-РЕЖИМА ЗАВЕРШЕНА ==="
    echo
    print_message "Созданные утилиты:"
    print_message "- Главное меню: ~/SteamDeck_Offline/offline_menu.sh"
    print_message "- Запуск Steam: ~/SteamDeck_Offline/launch_steam_offline.sh"
    print_message "- Профили: ~/.steamdeck_profiles/"
    echo
    print_message "Для запуска главного меню выполните:"
    print_message "~/SteamDeck_Offline/offline_menu.sh"
    echo
    print_warning "Рекомендуется перезагрузить Steam Deck для применения всех настроек"
}

# Обработка аргументов командной строки
case "${1:-setup}" in
    "setup")
        main
        ;;
    "menu")
        ~/SteamDeck_Offline/offline_menu.sh
        ;;
    "steam")
        ~/SteamDeck_Offline/launch_steam_offline.sh
        ;;
    "help"|"-h"|"--help")
        echo "Steam Deck Offline Setup Script v0.1"
        echo
        echo "Использование: $0 [ОПЦИЯ]"
        echo
        echo "ОПЦИИ:"
        echo "  setup     - Полная настройка offline-режима (по умолчанию)"
        echo "  menu      - Запуск главного меню offline-утилит"
        echo "  steam     - Запуск Steam в offline-режиме"
        echo "  help      - Показать эту справку"
        echo
        echo "ПРИМЕРЫ:"
        echo "  $0              # Полная настройка"
        echo "  $0 setup        # Полная настройка"
        echo "  $0 menu         # Главное меню"
        echo "  $0 steam        # Запуск Steam offline"
        ;;
    *)
        print_error "Неизвестная опция: $1"
        echo "Используйте '$0 help' для справки"
        exit 1
        ;;
esac
