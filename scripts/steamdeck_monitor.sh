#!/bin/bash

# Steam Deck Monitor Script
# Скрипт для мониторинга системы Steam Deck
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

# Получение информации о CPU
get_cpu_info() {
    print_header "CPU ИНФОРМАЦИЯ"
    
    # Модель процессора
    local cpu_model=$(lscpu | grep "Model name" | cut -d: -f2 | xargs)
    echo "Модель: $cpu_model"
    
    # Количество ядер
    local cores=$(nproc)
    echo "Ядра: $cores"
    
    # Текущая частота
    local freq=$(cat /proc/cpuinfo | grep "cpu MHz" | head -1 | cut -d: -f2 | xargs)
    echo "Частота: ${freq} MHz"
    
    # Загрузка CPU
    local load=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    echo "Загрузка: $load"
    
    # Использование CPU по ядрам
    echo "Использование по ядрам:"
    top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print "  CPU: " 100 - $1 "%"}'
    
    echo
}

# Получение информации о GPU
get_gpu_info() {
    print_header "GPU ИНФОРМАЦИЯ"
    
    # Информация о GPU
    if command -v lspci &> /dev/null; then
        local gpu=$(lspci | grep -i vga | cut -d: -f3 | xargs)
        echo "GPU: $gpu"
    fi
    
    # Использование GPU (если доступно)
    if command -v nvidia-smi &> /dev/null; then
        nvidia-smi --query-gpu=utilization.gpu,memory.used,memory.total --format=csv,noheader,nounits
    elif [[ -f "/sys/class/drm/card0/device/gpu_busy_percent" ]]; then
        local gpu_usage=$(cat /sys/class/drm/card0/device/gpu_busy_percent 2>/dev/null || echo "N/A")
        echo "Использование GPU: $gpu_usage%"
    else
        echo "Информация о GPU недоступна"
    fi
    
    # Частота GPU
    if [[ -f "/sys/class/drm/card0/device/gt_cur_freq_mhz" ]]; then
        local gpu_freq=$(cat /sys/class/drm/card0/device/gt_cur_freq_mhz 2>/dev/null || echo "N/A")
        echo "Частота GPU: ${gpu_freq} MHz"
    fi
    
    echo
}

# Получение информации о памяти
get_memory_info() {
    print_header "ПАМЯТЬ"
    
    # Общая информация о RAM
    free -h | grep -E "(Mem|Swap)"
    
    # Детальная информация
    echo
    echo "Детальная информация:"
    cat /proc/meminfo | grep -E "(MemTotal|MemFree|MemAvailable|Buffers|Cached|SwapTotal|SwapFree)"
    
    echo
}

# Получение информации о диске
get_disk_info() {
    print_header "ДИСКИ"
    
    # Использование дисков
    df -h | grep -E "(Filesystem|/dev/)"
    
    # Информация о inode
    echo
    echo "Использование inode:"
    df -i | grep -E "(Filesystem|/dev/)"
    
    # Топ-10 самых больших директорий
    echo
    echo "Топ-10 самых больших директорий в /:"
    sudo du -h / 2>/dev/null | sort -hr | head -10
    
    echo
}

# Получение информации о температуре
get_temperature_info() {
    print_header "ТЕМПЕРАТУРА"
    
    # Температура CPU
    if [[ -f "/sys/class/thermal/thermal_zone0/temp" ]]; then
        local cpu_temp=$(cat /sys/class/thermal/thermal_zone0/temp)
        local cpu_temp_c=$((cpu_temp / 1000))
        echo "CPU: ${cpu_temp_c}°C"
    fi
    
    # Температура GPU
    if [[ -f "/sys/class/drm/card0/device/hwmon/hwmon*/temp1_input" ]]; then
        local gpu_temp_file=$(find /sys/class/drm/card0/device/hwmon/hwmon*/temp1_input 2>/dev/null | head -1)
        if [[ -f "$gpu_temp_file" ]]; then
            local gpu_temp=$(cat "$gpu_temp_file")
            local gpu_temp_c=$((gpu_temp / 1000))
            echo "GPU: ${gpu_temp_c}°C"
        fi
    fi
    
    # Температура батареи
    if [[ -f "/sys/class/power_supply/BAT0/temp" ]]; then
        local bat_temp=$(cat /sys/class/power_supply/BAT0/temp 2>/dev/null || echo "N/A")
        if [[ "$bat_temp" != "N/A" ]]; then
            local bat_temp_c=$((bat_temp / 10))
            echo "Батарея: ${bat_temp_c}°C"
        fi
    fi
    
    echo
}

# Получение информации о батарее
get_battery_info() {
    print_header "БАТАРЕЯ"
    
    if [[ -f "/sys/class/power_supply/BAT0/capacity" ]]; then
        local capacity=$(cat /sys/class/power_supply/BAT0/capacity)
        local status=$(cat /sys/class/power_supply/BAT0/status)
        local voltage=$(cat /sys/class/power_supply/BAT0/voltage_now 2>/dev/null || echo "N/A")
        local current=$(cat /sys/class/power_supply/BAT0/current_now 2>/dev/null || echo "N/A")
        
        echo "Заряд: $capacity%"
        echo "Статус: $status"
        
        if [[ "$voltage" != "N/A" ]]; then
            local voltage_v=$((voltage / 1000000))
            echo "Напряжение: ${voltage_v}.${voltage: -3}V"
        fi
        
        if [[ "$current" != "N/A" ]]; then
            local current_ma=$((current / 1000))
            echo "Ток: ${current_ma}mA"
        fi
        
        # Время работы (если доступно)
        if command -v upower &> /dev/null; then
            local time_to_empty=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "time to empty" | cut -d: -f2 | xargs)
            local time_to_full=$(upower -i /org/freedesktop/UPower/devices/battery_BAT0 | grep "time to full" | cut -d: -f2 | xargs)
            
            if [[ -n "$time_to_empty" ]]; then
                echo "Время до разряда: $time_to_empty"
            fi
            if [[ -n "$time_to_full" ]]; then
                echo "Время до полной зарядки: $time_to_full"
            fi
        fi
    else
        echo "Информация о батарее недоступна"
    fi
    
    echo
}

# Получение информации о сети
get_network_info() {
    print_header "СЕТЬ"
    
    # Активные соединения
    echo "Активные сетевые интерфейсы:"
    ip addr show | grep -E "(inet |UP)" | grep -v "127.0.0.1"
    
    # Статистика трафика
    echo
    echo "Статистика трафика:"
    cat /proc/net/dev | grep -E "(wlan|eth)" | head -5
    
    # WiFi информация
    if command -v iwconfig &> /dev/null; then
        echo
        echo "WiFi информация:"
        iwconfig 2>/dev/null | grep -E "(ESSID|Signal|Bit Rate)" || echo "WiFi не активен"
    fi
    
    echo
}

# Получение информации о процессах
get_process_info() {
    print_header "ПРОЦЕССЫ"
    
    # Топ-10 процессов по использованию CPU
    echo "Топ-10 процессов по CPU:"
    ps aux --sort=-%cpu | head -11 | awk '{printf "%-8s %-8s %6s %6s %s\n", $1, $2, $3, $4, $11}'
    
    echo
    echo "Топ-10 процессов по памяти:"
    ps aux --sort=-%mem | head -11 | awk '{printf "%-8s %-8s %6s %6s %s\n", $1, $2, $3, $4, $11}'
    
    echo
}

# Получение информации о Steam
get_steam_info() {
    print_header "STEAM"
    
    # Статус Steam
    if pgrep -x "steam" > /dev/null; then
        echo "Steam: Запущен"
        
        # Количество запущенных игр
        local running_games=$(pgrep -f "steamapps" | wc -l)
        echo "Запущенных игр: $running_games"
    else
        echo "Steam: Не запущен"
    fi
    
    # Размер Steam
    if [[ -d "$HOME/.steam" ]]; then
        local steam_size=$(du -sh "$HOME/.steam" 2>/dev/null | cut -f1)
        echo "Размер Steam: $steam_size"
    fi
    
    # Количество установленных игр
    if [[ -d "$HOME/.steam/steam/steamapps" ]]; then
        local game_count=$(find "$HOME/.steam/steam/steamapps" -name "*.acf" | wc -l)
        echo "Установленных игр: $game_count"
    fi
    
    echo
}

# Получение информации о системе
get_system_info() {
    print_header "СИСТЕМА"
    
    # Время работы
    local uptime=$(uptime -p)
    echo "Время работы: $uptime"
    
    # Загрузка системы
    local load=$(uptime | awk -F'load average:' '{print $2}' | xargs)
    echo "Загрузка системы: $load"
    
    # Версия ядра
    local kernel=$(uname -r)
    echo "Ядро: $kernel"
    
    # Версия SteamOS
    if [[ -f "/etc/os-release" ]]; then
        local os_name=$(grep "PRETTY_NAME" /etc/os-release | cut -d= -f2 | tr -d '"')
        echo "ОС: $os_name"
    fi
    
    # Свободное место в /tmp
    local tmp_free=$(df /tmp | tail -1 | awk '{print $4}')
    echo "Свободно в /tmp: $(numfmt --to=iec $((tmp_free * 1024)))"
    
    echo
}

# Мониторинг в реальном времени
realtime_monitor() {
    local interval="${1:-2}"
    
    print_message "Запуск мониторинга в реальном времени (интервал: ${interval}с)"
    print_message "Нажмите Ctrl+C для выхода"
    echo
    
    while true; do
        clear
        print_header "STEAM DECK MONITOR - $(date)"
        
        get_cpu_info
        get_memory_info
        get_temperature_info
        get_battery_info
        
        sleep "$interval"
    done
}

# Экспорт в файл
export_to_file() {
    local output_file="$1"
    
    if [[ -z "$output_file" ]]; then
        output_file="steamdeck_monitor_$(date +%Y%m%d_%H%M%S).txt"
    fi
    
    print_message "Экспорт в файл: $output_file"
    
    {
        echo "Steam Deck System Monitor Report"
        echo "Generated: $(date)"
        echo "=================================="
        echo
        
        get_system_info
        get_cpu_info
        get_gpu_info
        get_memory_info
        get_disk_info
        get_temperature_info
        get_battery_info
        get_network_info
        get_process_info
        get_steam_info
        
    } > "$output_file"
    
    print_success "Отчет сохранен в: $output_file"
}

# Показать справку
show_help() {
    echo "Steam Deck Monitor Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТ]"
    echo
    echo "ОПЦИИ:"
    echo "  all                       - Показать всю информацию (по умолчанию)"
    echo "  cpu                       - Информация о CPU"
    echo "  gpu                       - Информация о GPU"
    echo "  memory                    - Информация о памяти"
    echo "  disk                      - Информация о дисках"
    echo "  temp                      - Информация о температуре"
    echo "  battery                   - Информация о батарее"
    echo "  network                   - Информация о сети"
    echo "  processes                 - Информация о процессах"
    echo "  steam                     - Информация о Steam"
    echo "  system                    - Информация о системе"
    echo "  realtime [интервал]       - Мониторинг в реальном времени"
    echo "  export [файл]             - Экспорт в файл"
    echo "  help                      - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0                        # Показать всю информацию"
    echo "  $0 cpu                    # Только CPU"
    echo "  $0 realtime 5             # Мониторинг каждые 5 секунд"
    echo "  $0 export report.txt      # Экспорт в файл"
}

# Основная функция
main() {
    case "${1:-all}" in
        "all")
            get_system_info
            get_cpu_info
            get_gpu_info
            get_memory_info
            get_disk_info
            get_temperature_info
            get_battery_info
            get_network_info
            get_process_info
            get_steam_info
            ;;
        "cpu")
            get_cpu_info
            ;;
        "gpu")
            get_gpu_info
            ;;
        "memory")
            get_memory_info
            ;;
        "disk")
            get_disk_info
            ;;
        "temp")
            get_temperature_info
            ;;
        "battery")
            get_battery_info
            ;;
        "network")
            get_network_info
            ;;
        "processes")
            get_process_info
            ;;
        "steam")
            get_steam_info
            ;;
        "system")
            get_system_info
            ;;
        "realtime")
            realtime_monitor "$2"
            ;;
        "export")
            export_to_file "$2"
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
