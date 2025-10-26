#!/bin/bash

# Steam Deck Native Games Script
# Скрипт для работы с Native Linux играми (.sh скрипты)
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
DOWNLOADS_DIR="$HOME/Downloads"
DESKTOP_DIR="$HOME/Desktop"
SD_CARD_DIR="/run/media/mmcblk0p1"
STEAM_DIR="$HOME/.steam/steam"

# Создание директории для игр
create_games_directory() {
    if [[ ! -d "$GAMES_DIR" ]]; then
        mkdir -p "$GAMES_DIR"
        print_success "Создана директория для игр: $GAMES_DIR"
    fi
}

# Поиск .sh игр
find_sh_games() {
    local search_dirs=(
        "$GAMES_DIR"
        "$DOWNLOADS_DIR"
        "$DESKTOP_DIR"
        "$SD_CARD_DIR/Games"
        "$SD_CARD_DIR"
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
    
    local found_games=()
    
    print_message "Поиск .sh игр в стандартных директориях..."
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_message "Поиск в: $dir"
            
            while IFS= read -r -d '' file; do
                local filename=$(basename "$file")
                local game_name=$(basename "$file" .sh)
                
                # Проверяем, что это может быть игра
                if [[ ! "$filename" =~ ^(setup|install|config|start|run|steamdeck) ]] && 
                   [[ ! "$filename" =~ ^\. ]] &&
                   [[ -f "$file" ]]; then
                    found_games+=("$game_name|$file")
                    print_message "Найдена игра: $game_name ($file)"
                fi
            done < <(find "$dir" -maxdepth 3 -name "*.sh" -type f -print0 2>/dev/null)
        fi
    done
    
    echo "${found_games[@]}"
}

# Анализ .sh скрипта игры
analyze_game_script() {
    local script_path="$1"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Файл не найден: $script_path"
        return 1
    fi
    
    print_header "АНАЛИЗ СКРИПТА ИГРЫ"
    print_message "Файл: $script_path"
    echo
    
    # Проверяем права выполнения
    if [[ -x "$script_path" ]]; then
        print_success "Скрипт исполняемый"
    else
        print_warning "Скрипт не исполняемый, исправляем..."
        chmod +x "$script_path"
        print_success "Права исправлены"
    fi
    
    # Анализируем содержимое
    print_message "Анализ содержимого скрипта:"
    echo
    
    # Проверяем shebang
    local shebang=$(head -1 "$script_path")
    if [[ "$shebang" == \#!/bin/bash ]] || [[ "$shebang" == \#!/bin/sh ]]; then
        print_success "Shebang: $shebang"
    else
        print_warning "Нестандартный shebang: $shebang"
    fi
    
    # Ищем информацию об игре
    local game_info=$(grep -i -E "(game|title|name|version)" "$script_path" | head -5)
    if [[ -n "$game_info" ]]; then
        print_message "Информация об игре:"
        echo "$game_info" | sed 's/^/  /'
    fi
    
    # Ищем зависимости
    local dependencies=$(grep -i -E "(apt|yum|pacman|flatpak|wine|steam)" "$script_path" | head -5)
    if [[ -n "$dependencies" ]]; then
        print_message "Возможные зависимости:"
        echo "$dependencies" | sed 's/^/  /'
    fi
    
    # Ищем исполняемые файлы
    local executables=$(grep -E "\.(exe|bin|app|run)$" "$script_path" | head -5)
    if [[ -n "$executables" ]]; then
        print_message "Исполняемые файлы:"
        echo "$executables" | sed 's/^/  /'
    fi
    
    echo
}

# Установка игры
install_game() {
    local game_name="$1"
    local script_path="$2"
    
    if [[ ! -f "$script_path" ]]; then
        print_error "Файл не найден: $script_path"
        return 1
    fi
    
    print_header "УСТАНОВКА ИГРЫ: $game_name"
    
    # Создаем директорию для игры
    local game_dir="$GAMES_DIR/$game_name"
    if [[ ! -d "$game_dir" ]]; then
        mkdir -p "$game_dir"
        print_success "Создана директория: $game_dir"
    fi
    
    # Копируем скрипт
    local game_script="$game_dir/run.sh"
    cp "$script_path" "$game_script"
    chmod +x "$game_script"
    print_success "Скрипт скопирован: $game_script"
    
    # Запускаем установку
    print_message "Запуск установки игры..."
    cd "$game_dir"
    
    if ./run.sh; then
        print_success "Игра установлена успешно"
    else
        print_warning "Установка завершилась с предупреждениями"
    fi
    
    # Ищем исполняемый файл игры
    local game_executable=$(find "$game_dir" -type f -executable -name "*.bin" -o -name "*.run" -o -name "*.x86_64" | head -1)
    
    if [[ -n "$game_executable" ]]; then
        print_success "Найден исполняемый файл: $game_executable"
        
        # Создаем обертку для Steam
        create_steam_wrapper "$game_name" "$game_executable" "$game_dir"
    else
        print_warning "Исполняемый файл игры не найден"
        print_message "Возможно, игра запускается через скрипт: $game_script"
    fi
}

# Создание обертки для Steam
create_steam_wrapper() {
    local game_name="$1"
    local executable="$2"
    local game_dir="$3"
    
    local wrapper_script="$game_dir/steam_wrapper.sh"
    
    cat > "$wrapper_script" << EOF
#!/bin/bash
# Steam wrapper for $game_name
# Generated by Steam Deck Native Games Script

cd "$game_dir"
exec "$executable" "\$@"
EOF
    
    chmod +x "$wrapper_script"
    print_success "Создана обертка для Steam: $wrapper_script"
    
    # Добавляем в Steam
    add_to_steam "$game_name" "$wrapper_script"
}

# Добавление игры в Steam
add_to_steam() {
    local game_name="$1"
    local script_path="$2"
    
    print_message "Добавление в Steam: $game_name"
    
    # Используем Steam CLI если доступен
    if command -v steam &> /dev/null; then
        if steam steam://addnonsteamgame/"$script_path"; then
            print_success "$game_name добавлена в Steam"
        else
            print_warning "Не удалось добавить через Steam CLI"
            print_message "Добавьте вручную: Steam → Games → Add a Non-Steam Game"
        fi
    else
        print_warning "Steam не найден, добавьте вручную"
    fi
}

# Массовое добавление игр
batch_add_games() {
    print_header "МАССОВОЕ ДОБАВЛЕНИЕ NATIVE LINUX ИГР"
    
    local found_games=($(find_sh_games))
    
    if [[ ${#found_games[@]} -eq 0 ]]; then
        print_warning "Native Linux игры (.sh) не найдены"
        print_message "Поместите .sh файлы игр в одну из директорий:"
        echo "  - $GAMES_DIR"
        echo "  - $DOWNLOADS_DIR"
        echo "  - $DESKTOP_DIR"
        echo "  - $SD_CARD_DIR/Games"
        return 0
    fi
    
    print_message "Найдено игр: ${#found_games[@]}"
    echo
    
    # Показываем найденные игры
    for i in "${!found_games[@]}"; do
        IFS='|' read -r name path <<< "${found_games[$i]}"
        echo "  $((i+1))) $name"
    done
    echo "  0) Назад"
    echo
    
    read -p "Выберите игры для добавления (через запятую, например: 1,3,5): " selection
    
    if [[ "$selection" == "0" ]]; then
        return 0
    fi
    
    # Обработка выбора
    IFS=',' read -ra selected_indices <<< "$selection"
    
    for index in "${selected_indices[@]}"; do
        index=$(echo "$index" | xargs)
        
        if [[ "$index" =~ ^[0-9]+$ ]] && [[ "$index" -ge 1 ]] && [[ "$index" -le ${#found_games[@]} ]]; then
            local array_index=$((index-1))
            IFS='|' read -r name path <<< "${found_games[$array_index]}"
            
            print_message "Обработка игры: $name"
            
            # Анализируем скрипт
            analyze_game_script "$path"
            
            # Спрашиваем, что делать
            echo "Выберите действие:"
            echo "  1) Установить игру"
            echo "  2) Только добавить в Steam"
            echo "  3) Пропустить"
            read -p "Ваш выбор: " action
            
            case $action in
                1)
                    install_game "$name" "$path"
                    ;;
                2)
                    chmod +x "$path"
                    add_to_steam "$name" "$path"
                    ;;
                3)
                    print_message "Пропускаем: $name"
                    ;;
                *)
                    print_warning "Неверный выбор, пропускаем"
                    ;;
            esac
        else
            print_warning "Неверный индекс: $index"
        fi
    done
}

# Создание директории для игр
setup_games_directory() {
    print_header "НАСТРОЙКА ДИРЕКТОРИИ ДЛЯ ИГР"
    
    create_games_directory
    
    # Создаем поддиректории
    local subdirs=("Native" "Windows" "Emulators" "Launchers")
    
    for subdir in "${subdirs[@]}"; do
        local full_path="$GAMES_DIR/$subdir"
        if [[ ! -d "$full_path" ]]; then
            mkdir -p "$full_path"
            print_success "Создана поддиректория: $full_path"
        fi
    done
    
    print_success "Структура директорий создана"
    print_message "Рекомендуется помещать .sh игры в: $GAMES_DIR/Native"
}

# Функция для удаления игры из Steam
remove_from_steam() {
    local game_name="$1"
    
    print_message "Удаление $game_name из Steam..."
    
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
        return 1
    fi
    
    # Создание резервной копии
    cp "$found_shortcuts" "$found_shortcuts.backup.$(date +%Y%m%d_%H%M%S)"
    
    # Удаление записи из shortcuts.vdf (упрощенная версия)
    if grep -q "$game_name" "$found_shortcuts"; then
        # Здесь должна быть более сложная логика для удаления из VDF файла
        print_warning "Ручное удаление из Steam рекомендуется"
        print_message "Найдите игру '$game_name' в Steam и удалите её вручную"
        return 0
    else
        print_warning "Игра '$game_name' не найдена в Steam shortcuts"
        return 1
    fi
}

# Функция для удаления игры
uninstall_game() {
    local game_name="$1"
    local game_path="$2"
    
    print_header "УДАЛЕНИЕ ИГРЫ: $game_name"
    
    # Подтверждение удаления
    read -p "Вы уверены, что хотите удалить '$game_name'? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_message "Отмена удаления"
        return 0
    fi
    
    # Удаление из Steam
    remove_from_steam "$game_name"
    
    # Удаление файлов игры
    if [[ -n "$game_path" ]] && [[ -f "$game_path" ]]; then
        print_message "Удаление файла игры: $game_path"
        rm -f "$game_path"
        print_success "Файл игры удален"
    fi
    
    # Удаление директории игры (если есть)
    local game_dir="$GAMES_DIR/Installed/$game_name"
    if [[ -d "$game_dir" ]]; then
        print_message "Удаление директории игры: $game_dir"
        rm -rf "$game_dir"
        print_success "Директория игры удалена"
    fi
    
    # Удаление из списка установленных игр
    local installed_file="$GAMES_DIR/installed_games.txt"
    if [[ -f "$installed_file" ]]; then
        grep -v "^$game_name|" "$installed_file" > "$installed_file.tmp"
        mv "$installed_file.tmp" "$installed_file"
        print_success "Игра удалена из списка установленных"
    fi
    
    print_success "Игра '$game_name' успешно удалена"
}

# Функция для удаления всех игр
uninstall_all_games() {
    print_header "УДАЛЕНИЕ ВСЕХ ИГР"
    print_warning "Это удалит ВСЕ Native Linux игры!"
    
    read -p "Вы уверены? (y/N): " confirm
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_message "Отмена удаления"
        return 0
    fi
    
    local installed_file="$GAMES_DIR/installed_games.txt"
    if [[ ! -f "$installed_file" ]]; then
        print_warning "Список установленных игр не найден"
        return 0
    fi
    
    local count=0
    while IFS='|' read -r name path; do
        if [[ -n "$name" ]]; then
            uninstall_game "$name" "$path"
            ((count++))
        fi
    done < "$installed_file"
    
    print_success "Удалено игр: $count"
}

# Функция для показа списка установленных игр
list_installed_games() {
    print_header "УСТАНОВЛЕННЫЕ ИГРЫ"
    
    local installed_file="$GAMES_DIR/installed_games.txt"
    if [[ ! -f "$installed_file" ]]; then
        print_warning "Список установленных игр не найден"
        return 0
    fi
    
    local count=0
    while IFS='|' read -r name path; do
        if [[ -n "$name" ]]; then
            echo "  $((++count))) $name"
            echo "      Путь: $path"
            if [[ -f "$path" ]]; then
                echo "      Статус: ✅ Установлена"
            else
                echo "      Статус: ❌ Файл не найден"
            fi
            echo
        fi
    done < "$installed_file"
    
    if [[ $count -eq 0 ]]; then
        print_message "Нет установленных игр"
    else
        print_success "Всего игр: $count"
    fi
}

# Интерактивное меню удаления
uninstall_menu() {
    while true; do
        clear
        print_header "УДАЛЕНИЕ NATIVE LINUX ИГР"
        echo
        echo "  1) Показать установленные игры"
        echo "  2) Удалить конкретную игру"
        echo "  3) Удалить все игры"
        echo "  0) Назад"
        echo
        
        read -p "Выберите действие: " choice
        
        case $choice in
            1)
                list_installed_games
                echo
                read -p "Нажмите Enter для продолжения..."
                ;;
            2)
                list_installed_games
                echo
                read -p "Введите название игры для удаления: " game_name
                if [[ -n "$game_name" ]]; then
                    # Поиск игры в списке
                    local game_path=""
                    while IFS='|' read -r name path; do
                        if [[ "$name" == "$game_name" ]]; then
                            game_path="$path"
                            break
                        fi
                    done < "$GAMES_DIR/installed_games.txt"
                    
                    if [[ -n "$game_path" ]]; then
                        uninstall_game "$game_name" "$game_path"
                    else
                        print_error "Игра '$game_name' не найдена в списке установленных"
                    fi
                fi
                echo
                read -p "Нажмите Enter для продолжения..."
                ;;
            3)
                uninstall_all_games
                echo
                read -p "Нажмите Enter для продолжения..."
                ;;
            0)
                return
                ;;
            *)
                print_error "Неверный выбор"
                ;;
        esac
    done
}

# Показать справку
show_help() {
    echo "Steam Deck Native Games Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТЫ]"
    echo
    echo "ОПЦИИ:"
    echo "  find                       - Найти .sh игры"
    echo "  analyze <script>           - Анализировать скрипт игры"
    echo "  install <name> <script>    - Установить игру"
    echo "  batch                      - Массовое добавление игр"
    echo "  setup                      - Настроить директории"
    echo "  uninstall                  - Удалить игры"
    echo "  list                       - Показать установленные игры"
    echo "  help                       - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 find                    # Найти все .sh игры"
    echo "  $0 analyze game.sh         # Анализировать скрипт"
    echo "  $0 install \"My Game\" game.sh"
    echo "  $0 batch                   # Массовое добавление"
    echo "  $0 setup                   # Настроить директории"
    echo "  $0 uninstall               # Удалить игры"
    echo "  $0 list                    # Показать установленные игры"
}

# Основная функция
main() {
    case "${1:-help}" in
        "find")
            find_sh_games
            ;;
        "analyze")
            if [[ -z "$2" ]]; then
                print_error "Укажите путь к скрипту"
                show_help
                exit 1
            fi
            analyze_game_script "$2"
            ;;
        "install")
            if [[ -z "$2" ]] || [[ -z "$3" ]]; then
                print_error "Укажите название игры и путь к скрипту"
                show_help
                exit 1
            fi
            install_game "$2" "$3"
            ;;
        "batch")
            batch_add_games
            ;;
        "setup")
            setup_games_directory
            ;;
        "uninstall")
            uninstall_menu
            ;;
        "list")
            list_installed_games
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
