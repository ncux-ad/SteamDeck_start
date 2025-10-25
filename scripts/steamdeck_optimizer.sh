#!/bin/bash

# Steam Deck Optimizer Script
# Скрипт для оптимизации производительности Steam Deck
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Функции для вывода
print_message() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${CYAN}=== $1 ===${NC}"; }

# Конфигурационные файлы
CONFIG_DIR="$HOME/.config/steamdeck_optimizer"
TDP_CONFIG="$CONFIG_DIR/tdp_profiles.conf"
GPU_CONFIG="$CONFIG_DIR/gpu_profiles.conf"

# Создание директории конфигурации
create_config_dir() {
    if [[ ! -d "$CONFIG_DIR" ]]; then
        mkdir -p "$CONFIG_DIR"
        print_success "Создана директория конфигурации: $CONFIG_DIR"
    fi
}

# Установка профилей TDP
setup_tdp_profiles() {
    print_message "Настройка профилей TDP..."
    
    cat > "$TDP_CONFIG" << 'EOF'
# Steam Deck TDP Profiles
# Формат: PROFILE_NAME:TDP_VALUE:GPU_FREQ:CPU_FREQ

# Профили производительности
PERFORMANCE:15:1600:3500
BALANCED:10:1200:3000
BATTERY_SAVER:5:800:2000
CUSTOM:12:1400:3200

# Профили для конкретных игр
CYBERPUNK:12:1400:3000
ELDEN_RING:10:1200:2800
GTA_V:8:1000:2500
INDIE_GAMES:5:800:2000
EOF
    
    print_success "Профили TDP созданы"
}

# Установка профилей GPU
setup_gpu_profiles() {
    print_message "Настройка профилей GPU..."
    
    cat > "$GPU_CONFIG" << 'EOF'
# Steam Deck GPU Profiles
# Формат: PROFILE_NAME:GPU_FREQ:GPU_VOLTAGE

# Стандартные профили
HIGH_PERFORMANCE:1600:1000
BALANCED:1200:900
POWER_SAVING:800:800
CUSTOM:1400:950
EOF
    
    print_success "Профили GPU созданы"
}

# Применение профиля TDP
apply_tdp_profile() {
    local profile="$1"
    
    if [[ ! -f "$TDP_CONFIG" ]]; then
        setup_tdp_profiles
    fi
    
    local profile_line=$(grep "^$profile:" "$TDP_CONFIG" 2>/dev/null || echo "")
    
    if [[ -z "$profile_line" ]]; then
        print_error "Профиль '$profile' не найден"
        return 1
    fi
    
    IFS=':' read -r name tdp gpu_freq cpu_freq <<< "$profile_line"
    
    print_message "Применение профиля: $name"
    print_message "TDP: ${tdp}W, GPU: ${gpu_freq}MHz, CPU: ${cpu_freq}MHz"
    
    # Применение TDP (требует root)
    if [[ -w "/sys/class/hwmon/hwmon*/power1_cap" ]]; then
        echo "$((tdp * 1000000))" | sudo tee /sys/class/hwmon/hwmon*/power1_cap > /dev/null 2>&1 || true
        print_success "TDP установлен: ${tdp}W"
    else
        print_warning "Не удалось установить TDP (требуются права root)"
    fi
    
    # Применение частоты GPU
    if [[ -w "/sys/class/drm/card0/device/gt_max_freq_mhz" ]]; then
        echo "$gpu_freq" | sudo tee /sys/class/drm/card0/device/gt_max_freq_mhz > /dev/null 2>&1 || true
        print_success "Частота GPU установлена: ${gpu_freq}MHz"
    else
        print_warning "Не удалось установить частоту GPU"
    fi
    
    # Сохранение текущего профиля
    echo "$profile" > "$CONFIG_DIR/current_profile"
    print_success "Профиль '$profile' применен"
}

# Оптимизация для конкретной игры
optimize_for_game() {
    local game="$1"
    
    case "$game" in
        "cyberpunk"|"cyberpunk2077")
            apply_tdp_profile "CYBERPUNK"
            ;;
        "elden"|"eldenring")
            apply_tdp_profile "ELDEN_RING"
            ;;
        "gta"|"gtav")
            apply_tdp_profile "GTA_V"
            ;;
        "indie"|"indiegames")
            apply_tdp_profile "INDIE_GAMES"
            ;;
        *)
            print_warning "Неизвестная игра: $game"
            print_message "Доступные игры: cyberpunk, elden, gta, indie"
            ;;
    esac
}

# Настройка swap
configure_swap() {
    local swap_size="$1"
    
    if [[ -z "$swap_size" ]]; then
        swap_size="2G"
    fi
    
    print_message "Настройка swap: $swap_size"
    
    # Создание swap файла
    if [[ ! -f "/swapfile" ]]; then
        sudo fallocate -l "$swap_size" /swapfile
        sudo chmod 600 /swapfile
        sudo mkswap /swapfile
        sudo swapon /swapfile
        
        # Добавление в fstab
        echo "/swapfile none swap sw 0 0" | sudo tee -a /etc/fstab
        
        print_success "Swap файл создан: $swap_size"
    else
        print_warning "Swap файл уже существует"
    fi
}

# Настройка zram
configure_zram() {
    print_message "Настройка zram..."
    
    # Установка zram-generator
    if ! command -v zram-generator &> /dev/null; then
        sudo pacman -S zram-generator --noconfirm
    fi
    
    # Создание конфигурации zram
    sudo tee /etc/systemd/zram-generator.conf > /dev/null << 'EOF'
[zram0]
zram-size = ram / 2
compression-algorithm = lz4
swap-priority = 100
EOF
    
    # Перезапуск службы
    sudo systemctl daemon-reload
    sudo systemctl start systemd-zram-setup@zram0.service
    
    print_success "Zram настроен"
}

# Оптимизация ядра
optimize_kernel() {
    print_message "Оптимизация параметров ядра..."
    
    # Создание файла с параметрами ядра
    sudo tee /etc/sysctl.d/99-steamdeck.conf > /dev/null << 'EOF'
# Steam Deck Kernel Optimizations

# Сетевые оптимизации
net.core.rmem_max = 134217728
net.core.wmem_max = 134217728
net.ipv4.tcp_rmem = 4096 65536 134217728
net.ipv4.tcp_wmem = 4096 65536 134217728

# Оптимизация памяти
vm.swappiness = 10
vm.vfs_cache_pressure = 50
vm.dirty_ratio = 15
vm.dirty_background_ratio = 5

# Оптимизация файловой системы
fs.file-max = 2097152
EOF
    
    # Применение настроек
    sudo sysctl -p /etc/sysctl.d/99-steamdeck.conf
    
    print_success "Параметры ядра оптимизированы"
}

# Оптимизация Steam
optimize_steam() {
    print_message "Оптимизация Steam..."
    
    # Создание конфигурации Steam
    local steam_config="$HOME/.steam/steam/config/config.vdf"
    
    if [[ -f "$steam_config" ]]; then
        # Резервная копия
        cp "$steam_config" "$steam_config.backup.$(date +%Y%m%d_%H%M%S)"
        
        # Оптимизация настроек Steam
        print_message "Настройка Steam для оптимальной производительности..."
        print_warning "Рекомендуется настроить Steam вручную:"
        print_message "- Отключить Steam Overlay для игр"
        print_message "- Включить Hardware-accelerated GPU scheduling"
        print_message "- Настроить Shader Pre-caching"
    else
        print_warning "Конфигурация Steam не найдена"
    fi
}

# Оптимизация для батареи
optimize_battery() {
    print_message "Оптимизация для батареи..."
    
    # Установка профиля энергосбережения
    apply_tdp_profile "BATTERY_SAVER"
    
    # Настройка CPU governor
    if [[ -w "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" ]]; then
        echo "powersave" | sudo tee /sys/devices/system/cpu/cpufreq/policy*/scaling_governor > /dev/null 2>&1 || true
        print_success "CPU governor установлен: powersave"
    fi
    
    # Отключение ненужных служб
    local services=("bluetooth" "cups" "avahi-daemon")
    for service in "${services[@]}"; do
        if systemctl is-enabled "$service" &> /dev/null; then
            sudo systemctl disable "$service" 2>/dev/null || true
            print_message "Служба $service отключена"
        fi
    done
    
    print_success "Оптимизация для батареи завершена"
}

# Оптимизация для производительности
optimize_performance() {
    print_message "Оптимизация для производительности..."
    
    # Установка профиля производительности
    apply_tdp_profile "PERFORMANCE"
    
    # Настройка CPU governor
    if [[ -w "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" ]]; then
        echo "performance" | sudo tee /sys/devices/system/cpu/cpufreq/policy*/scaling_governor > /dev/null 2>&1 || true
        print_success "CPU governor установлен: performance"
    fi
    
    # Настройка GPU
    if [[ -w "/sys/class/drm/card0/device/power_dpm_force_performance_level" ]]; then
        echo "high" | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level > /dev/null 2>&1 || true
        print_success "GPU режим установлен: high performance"
    fi
    
    print_success "Оптимизация для производительности завершена"
}

# Сброс к настройкам по умолчанию
reset_to_default() {
    print_message "Сброс к настройкам по умолчанию..."
    
    # Сброс TDP
    if [[ -w "/sys/class/hwmon/hwmon*/power1_cap" ]]; then
        echo "15000000" | sudo tee /sys/class/hwmon/hwmon*/power1_cap > /dev/null 2>&1 || true
        print_success "TDP сброшен к 15W"
    fi
    
    # Сброс CPU governor
    if [[ -w "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" ]]; then
        echo "schedutil" | sudo tee /sys/devices/system/cpu/cpufreq/policy*/scaling_governor > /dev/null 2>&1 || true
        print_success "CPU governor сброшен к schedutil"
    fi
    
    # Удаление конфигурации
    rm -f "$CONFIG_DIR/current_profile"
    
    print_success "Настройки сброшены к умолчанию"
}

# Показать текущие настройки
show_current_settings() {
    print_header "ТЕКУЩИЕ НАСТРОЙКИ"
    
    # Текущий профиль
    if [[ -f "$CONFIG_DIR/current_profile" ]]; then
        local current_profile=$(cat "$CONFIG_DIR/current_profile")
        echo "Текущий профиль: $current_profile"
    else
        echo "Текущий профиль: не установлен"
    fi
    
    # TDP
    if [[ -f "/sys/class/hwmon/hwmon*/power1_cap" ]]; then
        local tdp=$(cat /sys/class/hwmon/hwmon*/power1_cap 2>/dev/null | head -1)
        local tdp_w=$((tdp / 1000000))
        echo "TDP: ${tdp_w}W"
    fi
    
    # CPU Governor
    if [[ -f "/sys/devices/system/cpu/cpufreq/policy0/scaling_governor" ]]; then
        local governor=$(cat /sys/devices/system/cpu/cpufreq/policy0/scaling_governor)
        echo "CPU Governor: $governor"
    fi
    
    # GPU частота
    if [[ -f "/sys/class/drm/card0/device/gt_cur_freq_mhz" ]]; then
        local gpu_freq=$(cat /sys/class/drm/card0/device/gt_cur_freq_mhz)
        echo "GPU частота: ${gpu_freq}MHz"
    fi
    
    # Swap
    echo "Swap:"
    free -h | grep Swap
    
    echo
}

# Показать доступные профили
list_profiles() {
    print_header "ДОСТУПНЫЕ ПРОФИЛИ"
    
    if [[ -f "$TDP_CONFIG" ]]; then
        echo "TDP профили:"
        while IFS=':' read -r name tdp gpu_freq cpu_freq; do
            if [[ ! "$name" =~ ^# ]]; then
                echo "  $name: TDP=${tdp}W, GPU=${gpu_freq}MHz, CPU=${cpu_freq}MHz"
            fi
        done < "$TDP_CONFIG"
    else
        print_warning "Профили TDP не настроены. Запустите: $0 setup"
    fi
    
    echo
}

# Показать справку
show_help() {
    echo "Steam Deck Optimizer Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТ]"
    echo
    echo "ОПЦИИ:"
    echo "  setup                     - Первоначальная настройка"
    echo "  profile <имя>             - Применить профиль TDP"
    echo "  game <игра>               - Оптимизировать для игры"
    echo "  performance               - Оптимизация для производительности"
    echo "  battery                   - Оптимизация для батареи"
    echo "  swap [размер]             - Настроить swap (по умолчанию 2G)"
    echo "  zram                      - Настроить zram"
    echo "  kernel                    - Оптимизировать ядро"
    echo "  steam                     - Оптимизировать Steam"
    echo "  status                    - Показать текущие настройки"
    echo "  list                      - Показать доступные профили"
    echo "  reset                     - Сброс к настройкам по умолчанию"
    echo "  help                      - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 setup                  # Первоначальная настройка"
    echo "  $0 profile PERFORMANCE    # Применить профиль производительности"
    echo "  $0 game cyberpunk         # Оптимизировать для Cyberpunk 2077"
    echo "  $0 battery                # Оптимизировать для батареи"
    echo "  $0 status                 # Показать текущие настройки"
}

# Основная функция
main() {
    create_config_dir
    
    case "${1:-help}" in
        "setup")
            setup_tdp_profiles
            setup_gpu_profiles
            optimize_kernel
            print_success "Первоначальная настройка завершена"
            ;;
        "profile")
            if [[ -z "$2" ]]; then
                print_error "Укажите имя профиля"
                list_profiles
                exit 1
            fi
            apply_tdp_profile "$2"
            ;;
        "game")
            if [[ -z "$2" ]]; then
                print_error "Укажите название игры"
                exit 1
            fi
            optimize_for_game "$2"
            ;;
        "performance")
            optimize_performance
            ;;
        "battery")
            optimize_battery
            ;;
        "swap")
            configure_swap "$2"
            ;;
        "zram")
            configure_zram
            ;;
        "kernel")
            optimize_kernel
            ;;
        "steam")
            optimize_steam
            ;;
        "status")
            show_current_settings
            ;;
        "list")
            list_profiles
            ;;
        "reset")
            reset_to_default
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
