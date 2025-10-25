#!/bin/bash

# Steam Deck SteamRip Handler Script
# Скрипт для работы с SteamRip-pack в RAR-файлах
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

# Конфигурация
GAMES_DIR="$HOME/Games"
STEAMRIP_DIR="$GAMES_DIR/SteamRip"
DOWNLOADS_DIR="$HOME/Downloads"
STEAM_DIR="$HOME/.steam/steam"

# Создание директории для SteamRip
create_steamrip_directory() {
    if [[ ! -d "$STEAMRIP_DIR" ]]; then
        mkdir -p "$STEAMRIP_DIR"
        print_success "Создана директория SteamRip: $STEAMRIP_DIR"
    fi
}

# Проверка зависимостей
check_dependencies() {
    local missing_deps=()
    
    if ! command -v unrar &> /dev/null; then
        missing_deps+=("unrar")
    fi
    
    if ! command -v 7z &> /dev/null; then
        missing_deps+=("p7zip")
    fi
    
    if ! command -v wine &> /dev/null; then
        missing_deps+=("wine")
    fi
    
    if [[ ${#missing_deps[@]} -gt 0 ]]; then
        print_warning "Отсутствуют зависимости: ${missing_deps[*]}"
        print_message "Установка зависимостей..."
        
        for dep in "${missing_deps[@]}"; do
            case "$dep" in
                "unrar")
                    sudo pacman -S unrar --noconfirm
                    ;;
                "p7zip")
                    sudo pacman -S p7zip --noconfirm
                    ;;
                "wine")
                    sudo pacman -S wine --noconfirm
                    ;;
            esac
        done
        
        print_success "Зависимости установлены"
    else
        print_success "Все зависимости найдены"
    fi
}

# Поиск RAR файлов SteamRip
find_steamrip_rar() {
    local search_dirs=(
        "$DOWNLOADS_DIR"
        "$STEAMRIP_DIR"
        "$GAMES_DIR"
        "/run/media/mmcblk0p1/Downloads"
        "/run/media/mmcblk0p1/Games"
    )
    
    local found_files=()
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            while IFS= read -r -d '' file; do
                found_files+=("$file")
            done < <(find "$dir" -name "*.rar" -type f -print0 2>/dev/null)
        fi
    done
    
    if [[ ${#found_files[@]} -eq 0 ]]; then
        print_warning "RAR файлы SteamRip не найдены"
        return 1
    fi
    
    echo "Найденные RAR файлы:"
    for i in "${!found_files[@]}"; do
        echo "  $((i+1))) $(basename "${found_files[$i]}")"
        echo "      Путь: ${found_files[$i]}"
        echo "      Размер: $(du -h "${found_files[$i]}" | cut -f1)"
        echo
    done
    
    return 0
}

# Анализ RAR файла SteamRip
analyze_steamrip_rar() {
    local rar_file="$1"
    
    if [[ ! -f "$rar_file" ]]; then
        print_error "Файл не найден: $rar_file"
        return 1
    fi
    
    print_header "АНАЛИЗ STEAMRIP RAR: $(basename "$rar_file")"
    
    # Информация о файле
    print_message "Информация о файле:"
    echo "  Путь: $rar_file"
    echo "  Размер: $(du -h "$rar_file" | cut -f1)"
    echo "  Дата: $(stat -c %y "$rar_file")"
    echo
    
    # Список содержимого RAR
    print_message "Содержимое RAR:"
    if unrar l "$rar_file" 2>/dev/null; then
        print_success "RAR файл корректен"
    else
        print_error "Ошибка чтения RAR файла"
        return 1
    fi
    
    # Проверка на SteamRip структуру
    print_message "Проверка структуры SteamRip:"
    local rar_list=$(unrar l "$rar_file" 2>/dev/null | grep -E "\.(exe|bat|sh|bin)$" | head -10)
    if [[ -n "$rar_list" ]]; then
        print_success "Найдены исполняемые файлы (возможно SteamRip):"
        echo "$rar_list"
    else
        print_warning "Исполняемые файлы не найдены"
    fi
}

# Распаковка SteamRip RAR
extract_steamrip_rar() {
    local rar_file="$1"
    local extract_dir="$2"
    
    if [[ -z "$extract_dir" ]]; then
        extract_dir="$STEAMRIP_DIR/$(basename "$rar_file" .rar)"
    fi
    
    print_header "РАСПАКОВКА STEAMRIP: $(basename "$rar_file")"
    
    # Создание директории для распаковки
    mkdir -p "$extract_dir"
    
    # Распаковка RAR
    print_message "Распаковка в: $extract_dir"
    if unrar x "$rar_file" "$extract_dir/"; then
        print_success "RAR файл распакован"
    else
        print_error "Ошибка распаковки RAR файла"
        return 1
    fi
    
    # Поиск исполняемых файлов
    local exe_files=()
    while IFS= read -r -d '' file; do
        exe_files+=("$file")
    done < <(find "$extract_dir" -name "*.exe" -o -name "*.bat" -o -name "*.sh" -o -name "*.bin" -type f -print0 2>/dev/null)
    
    if [[ ${#exe_files[@]} -gt 0 ]]; then
        print_success "Найдены исполняемые файлы:"
        for exe in "${exe_files[@]}"; do
            echo "  - $(basename "$exe")"
            chmod +x "$exe" 2>/dev/null || true
        done
    fi
    
    # Создание ярлыка для Steam
    if [[ ${#exe_files[@]} -gt 0 ]]; then
        local main_exe="${exe_files[0]}"
        local game_name=$(basename "$extract_dir")
        create_steam_shortcut "$game_name" "$main_exe" "$extract_dir"
    fi
    
    print_success "SteamRip распакован: $extract_dir"
}

# Создание ярлыка для Steam
create_steam_shortcut() {
    local game_name="$1"
    local exe_path="$2"
    local game_dir="$3"
    
    print_message "Создание ярлыка Steam: $game_name"
    
    # Поиск файла shortcuts.vdf
    local shortcuts_file="$STEAM_DIR/userdata/*/config/shortcuts.vdf"
    local found_shortcuts=""
    
    for file in $shortcuts_file; do
        if [[ -f "$file" ]]; then
            found_shortcuts="$file"
            break
        fi
    done
    
    if [[ -z "$found_shortcuts" ]]; then
        print_warning "Файл shortcuts.vdf не найден"
        print_message "Создайте ярлык вручную в Steam"
        return 1
    fi
    
    # Создание резервной копии
    cp "$found_shortcuts" "$found_shortcuts.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Создание ярлыка (упрощенная версия)
    print_message "Добавление в Steam shortcuts..."
    print_warning "Ручное добавление в Steam рекомендуется для корректной работы"
    print_message "Путь к игре: $exe_path"
    print_message "Рабочая директория: $game_dir"
    
    # Создание .desktop файла как альтернатива
    local desktop_file="$HOME/Desktop/${game_name}.desktop"
    cat > "$desktop_file" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$game_name
Comment=SteamRip Game
Exec=wine "$exe_path"
Path=$game_dir
Icon=steam
Terminal=false
Categories=Game;
EOF
    
    chmod +x "$desktop_file"
    print_success "Создан .desktop файл: $desktop_file"
}

# Массовая обработка SteamRip RAR
batch_process_steamrip() {
    print_header "МАССОВАЯ ОБРАБОТКА STEAMRIP RAR"
    
    local rar_files=()
    while IFS= read -r -d '' file; do
        rar_files+=("$file")
    done < <(find "$DOWNLOADS_DIR" -name "*.rar" -type f -print0 2>/dev/null)
    
    if [[ ${#rar_files[@]} -eq 0 ]]; then
        print_warning "RAR файлы не найдены в $DOWNLOADS_DIR"
        return 1
    fi
    
    print_message "Найдено RAR файлов: ${#rar_files[@]}"
    
    for rar_file in "${rar_files[@]}"; do
        echo
        print_message "Обработка: $(basename "$rar_file")"
        
        if analyze_steamrip_rar "$rar_file"; then
            read -p "Распаковать этот файл? (y/N): " confirm
            if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
                extract_steamrip_rar "$rar_file"
            fi
        fi
    done
}

# Очистка SteamRip директории
cleanup_steamrip() {
    print_header "ОЧИСТКА STEAMRIP"
    
    if [[ ! -d "$STEAMRIP_DIR" ]]; then
        print_warning "Директория SteamRip не найдена"
        return 0
    fi
    
    print_message "Содержимое директории SteamRip:"
    ls -la "$STEAMRIP_DIR"
    echo
    
    read -p "Удалить все содержимое SteamRip? (y/N): " confirm
    if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
        rm -rf "$STEAMRIP_DIR"/*
        print_success "SteamRip директория очищена"
    else
        print_message "Очистка отменена"
    fi
}

# Показать справку
show_help() {
    echo "Steam Deck SteamRip Handler v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТЫ]"
    echo
    echo "ОПЦИИ:"
    echo "  find                       - Найти RAR файлы SteamRip"
    echo "  analyze <rar_file>         - Анализировать RAR файл"
    echo "  extract <rar_file> [dir]   - Распаковать RAR файл"
    echo "  batch                      - Массовая обработка RAR файлов"
    echo "  cleanup                    - Очистить директорию SteamRip"
    echo "  setup                      - Настроить директории"
    echo "  help                       - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 find                    # Найти RAR файлы"
    echo "  $0 analyze game.rar        # Анализировать RAR"
    echo "  $0 extract game.rar        # Распаковать RAR"
    echo "  $0 batch                   # Массовая обработка"
    echo "  $0 cleanup                 # Очистить SteamRip"
    echo "  $0 setup                   # Настроить директории"
}

# Основная функция
main() {
    case "${1:-help}" in
        "find")
            find_steamrip_rar
            ;;
        "analyze")
            if [[ -z "$2" ]]; then
                print_error "Укажите путь к RAR файлу"
                show_help
                exit 1
            fi
            analyze_steamrip_rar "$2"
            ;;
        "extract")
            if [[ -z "$2" ]]; then
                print_error "Укажите путь к RAR файлу"
                show_help
                exit 1
            fi
            extract_steamrip_rar "$2" "$3"
            ;;
        "batch")
            batch_process_steamrip
            ;;
        "cleanup")
            cleanup_steamrip
            ;;
        "setup")
            create_steamrip_directory
            check_dependencies
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
