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
    
    # Добавляем все возможные /run/media/* для флешек и SD карт
    local media_dirs=()
    if [[ -d "/run/media" ]]; then
        while IFS= read -r -d '' dir; do
            media_dirs+=("$dir")
        done < <(find /run/media -maxdepth 1 -type d ! -path /run/media -print0 2>/dev/null)
    fi
    
    # Добавляем в search_dirs
    search_dirs+=("${media_dirs[@]}")
    
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

# Интерактивная функция выбора и распаковки RAR
interactive_rar_extract() {
    print_header "ИНТЕРАКТИВНАЯ РАСПАКОВКА RAR ИГРЫ"
    
    # Выбор RAR файла
    print_message "Найдены RAR файлы:"
    local rar_files=($(find "$DOWNLOADS_DIR" /run/media -maxdepth 3 -name "*.rar" -type f 2>/dev/null))
    
    if [[ ${#rar_files[@]} -eq 0 ]]; then
        print_warning "RAR файлы не найдены"
        print_message "Ищем в: Downloads, флешки, SD карты..."
        return 1
    fi
    
    # Показываем список
    for i in "${!rar_files[@]}"; do
        echo "  $((i+1))) $(basename "${rar_files[$i]}")"
        echo "      $(dirname "${rar_files[$i]}")"
    done
    
    read -p "Выберите архив (1-${#rar_files[@]}): " selection
    if [[ ! "$selection" =~ ^[0-9]+$ ]] || [[ "$selection" -lt 1 ]] || [[ "$selection" -gt ${#rar_files[@]} ]]; then
        print_error "Неверный выбор"
        return 1
    fi
    
    local selected_rar="${rar_files[$((selection-1))]}"
    print_success "Выбран: $(basename "$selected_rar")"
    
    # Выбор директории для распаковки
    echo
    print_message "Выбор директории для распаковки:"
    echo "  1) $GAMES_DIR"
    echo "  2) Указать свой путь"
    echo "  3) Открыть Dolphin для выбора"
    
    read -p "Выбор (1-3): " dir_choice
    
    local extract_dir=""
    case "$dir_choice" in
        1)
            extract_dir="$GAMES_DIR"
            ;;
        2)
            read -p "Введите путь: " extract_dir
            if [[ ! -d "$extract_dir" ]]; then
                print_error "Директория не существует"
                return 1
            fi
            ;;
        3)
            # Открываем Dolphin для выбора директории
            print_message "Открываем Dolphin для выбора директории..."
            extract_dir=$(dolphin --select-directory 2>/dev/null || echo "")
            if [[ -z "$extract_dir" ]]; then
                print_error "Директория не выбрана"
                return 1
            fi
            ;;
        *)
            print_error "Неверный выбор"
            return 1
            ;;
    esac
    
    # Добавляем имя игры к пути
    local game_name=$(basename "$selected_rar" .rar)
    extract_dir="$extract_dir/$game_name"
    
    print_success "Директория для распаковки: $extract_dir"
    
    # Запускаем распаковку
    if extract_steamrip_rar "$selected_rar" "$extract_dir"; then
        # Открываем Dolphin с распакованными файлами
        print_message "Открываем Dolphin с распакованными файлами..."
        dolphin "$extract_dir" &
        
        print_success "Распаковка завершена!"
        print_message "Добавьте игру в Steam вручную через Dolphin"
        print_message "Steam → Games → Add a Non-Steam Game → Найдите .exe файл"
    else
        print_error "Ошибка при распаковке"
        return 1
    fi
}

# Распаковка SteamRip RAR
extract_steamrip_rar() {
    local rar_file="$1"
    local extract_dir="$2"
    
    # Валидация
    if [[ ! -f "$rar_file" ]]; then
        print_error "RAR файл не найден: $rar_file"
        return 1
    fi
    
    if [[ -z "$extract_dir" ]]; then
        extract_dir="$STEAMRIP_DIR/$(basename "$rar_file" .rar)"
    fi
    
    print_header "РАСПАКОВКА STEAMRIP: $(basename "$rar_file")"
    
    # Проверяем Wine
    if ! command -v wine &> /dev/null; then
        print_warning "Wine не установлен"
        read -p "Установить Wine для запуска Windows игр? (y/n): " confirm
        if [[ "$confirm" == "y" || "$confirm" == "Y" ]]; then
            print_message "Установка Wine..."
            sudo pacman -S wine --noconfirm
        else
            print_error "Wine необходим для запуска RAR игр"
            return 1
        fi
    fi
    
    # Создание директории для распаковки
    if ! mkdir -p "$extract_dir"; then
        print_error "Не удалось создать директорию: $extract_dir"
        return 1
    fi
    
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

# Создание ярлыка для Steam (использует универсальную функцию)
create_steam_shortcut() {
    local game_name="$1"
    local exe_path="$2"
    local game_dir="$3"
    
    print_message "Создание ярлыка Steam: $game_name"
    
    # Валидация
    if [[ -z "$game_name" ]] || [[ -z "$exe_path" ]] || [[ -z "$game_dir" ]]; then
        print_error "Некорректные параметры для create_steam_shortcut"
        return 1
    fi
    
    if [[ ! -f "$exe_path" ]]; then
        print_error "Исполняемый файл не найден: $exe_path"
        return 1
    fi
    
    # Создаем обертку для игры с Wine
    local wrapper_script="$game_dir/steam_wrapper.sh"
    
    cat > "$wrapper_script" << 'EOF'
#!/bin/bash
# Steam wrapper for Wine game
# Generated by Steam Deck SteamRip Script

GAME_DIR="$1"
EXE_PATH="$2"

cd "$GAME_DIR"

# Запускаем через Wine
if command -v wine &> /dev/null; then
    wine "$EXE_PATH" "$@"
else
    print_error "Wine не установлен"
    exit 1
fi
EOF
    
    chmod +x "$wrapper_script"
    print_success "Создана обертка: $wrapper_script"
    
    # Создаем .desktop файл
    local desktop_dir="$HOME/.local/share/applications"
    local desktop_file="$desktop_dir/${game_name}.desktop"
    
    # Валидация имени файла
    local safe_name=$(echo "$game_name" | tr '[:space:]/' '_' | tr -d '[](){}')
    desktop_file="$desktop_dir/${safe_name}.desktop"
    
    # Создаем директорию
    mkdir -p "$desktop_dir"
    
    # Создаем .desktop файл
    cat > "$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=$game_name
Comment=SteamRip Game (Wine)
Exec=bash "$wrapper_script" "$game_dir" "$exe_path"
Icon=applications-games
Categories=Game;
StartupNotify=false
EOF
    
    chmod +x "$desktop_file"
    print_success "Создан .desktop файл: $desktop_file"
    print_message "Игра появится в Steam после добавления через Steam UI"
    print_message "Steam → Games → Add a Non-Steam Game → $game_name"
    
    return 0
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
    echo "Steam Deck SteamRip Handler v0.2"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТЫ]"
    echo
    echo "ОПЦИИ:"
    echo "  interactive                - 🎮 Интерактивная распаковка (РЕКОМЕНДУЕТСЯ)"
    echo "  find                       - Найти RAR файлы SteamRip"
    echo "  analyze <rar_file>         - Анализировать RAR файл"
    echo "  extract <rar_file> [dir]   - Распаковать RAR файл"
    echo "  batch                      - Массовая обработка RAR файлов"
    echo "  cleanup                    - Очистить директорию SteamRip"
    echo "  setup                      - Настроить директории"
    echo "  help                       - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 interactive             # 🎮 Интерактивная распаковка"
    echo "  $0 find                    # Найти RAR файлы"
    echo "  $0 extract game.rar        # Распаковать RAR"
}

# Интерактивное меню
show_interactive_menu() {
    print_header "STEAMRIP RAR INSTALLER"
    
    while true; do
        echo "Выберите действие:"
        echo "  1) Интерактивная распаковка RAR игры"
        echo "  2) Найти RAR файлы"
        echo "  3) Массовая обработка"
        echo "  4) Очистить SteamRip директорию"
        echo "  5) Настроить директории"
        echo "  0) Выход"
        echo
        
        read -p "Ваш выбор: " choice
        
        case "$choice" in
            1)
                interactive_rar_extract
                ;;
            2)
                find_steamrip_rar
                ;;
            3)
                batch_process_steamrip
                ;;
            4)
                cleanup_steamrip
                ;;
            5)
                create_steamrip_directory
                check_dependencies
                ;;
            0)
                print_message "Выход..."
                exit 0
                ;;
            *)
                print_error "Неверный выбор"
                ;;
        esac
        
        echo
        read -p "Нажмите Enter для продолжения..."
        clear
    done
}

# Основная функция
main() {
    case "${1:-interactive}" in
        "interactive"|"")
            show_interactive_menu
            ;;
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
