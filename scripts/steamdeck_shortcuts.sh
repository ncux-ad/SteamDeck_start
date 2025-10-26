#!/bin/bash

# Steam Deck Shortcuts Script
# Скрипт для добавления приложений в Steam и создания ярлыков
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

# Пути
STEAM_DIR="$HOME/.steam/steam"
SHORTCUTS_FILE="$STEAM_DIR/userdata/*/config/shortcuts.vdf"
GRID_DIR="$STEAM_DIR/userdata/*/config/grid"
CUSTOM_GRID_DIR="$HOME/.steam/steam/userdata/*/config/grid"

# Создание директории для обложек
create_grid_dirs() {
    local user_id=$(ls "$STEAM_DIR/userdata" | head -1)
    local grid_path="$STEAM_DIR/userdata/$user_id/config/grid"
    
    if [[ ! -d "$grid_path" ]]; then
        mkdir -p "$grid_path"
        print_success "Создана директория для обложек: $grid_path"
    fi
}

# Добавление приложения в Steam
add_to_steam() {
    local app_name="$1"
    local app_path="$2"
    local app_args="$3"
    local app_icon="$4"
    
    print_message "Добавление в Steam: $app_name"
    
    # Проверка существования приложения
    if [[ ! -f "$app_path" ]] && ! command -v "$(basename "$app_path")" &> /dev/null; then
        print_error "Приложение не найдено: $app_path"
        return 1
    fi
    
    # Добавление через Steam CLI
    if command -v steam &> /dev/null; then
        if steam steam://addnonsteamgame/"$app_path" "$app_args"; then
            print_success "$app_name добавлен в Steam"
        else
            print_warning "Не удалось добавить через Steam CLI, попробуйте вручную"
        fi
    else
        print_warning "Steam не найден, добавьте приложение вручную"
    fi
}

# Создание пользовательской обложки
create_custom_cover() {
    local app_name="$1"
    local cover_url="$2"
    local user_id=$(ls "$STEAM_DIR/userdata" | head -1)
    local grid_path="$STEAM_DIR/userdata/$user_id/config/grid"
    
    if [[ -n "$cover_url" ]]; then
        local cover_file="$grid_path/${app_name}_cover.jpg"
        
        print_message "Загрузка обложки для $app_name..."
        
        if command -v wget &> /dev/null; then
            wget -O "$cover_file" "$cover_url" 2>/dev/null || true
        elif command -v curl &> /dev/null; then
            curl -o "$cover_file" "$cover_url" 2>/dev/null || true
        fi
        
        if [[ -f "$cover_file" ]]; then
            print_success "Обложка сохранена: $cover_file"
        else
            print_warning "Не удалось загрузить обложку"
        fi
    fi
}

# Добавление популярных приложений
add_popular_apps() {
    print_header "ДОБАВЛЕНИЕ ПОПУЛЯРНЫХ ПРИЛОЖЕНИЙ"
    
    # Создание директорий
    create_grid_dirs
    
    # Список популярных приложений
    local apps=(
        "Heroic Games Launcher|flatpak run com.heroicgameslauncher.hgl||https://cdn.heroicgameslauncher.com/icon.png"
        "Lutris|flatpak run net.lutris.Lutris||https://lutris.net/static/images/logo.png"
        "Bottles|flatpak run com.usebottles.bottles||https://usebottles.com/img/bottles.png"
        "ProtonUp-Qt|flatpak run net.davidotek.pupgui2||https://davidotek.github.io/protonup-qt/img/logo.png"
        "ProtonTricks|flatpak run com.github.Matoking.protontricks||https://github.com/Matoking/protontricks/raw/master/protontricks.png"
        "SteamLinuxRuntime - Sniper|$HOME/.steam/steam/steamapps/common/SteamLinuxRuntime_sniper/run||https://steamcommunity.com/sharedfiles/filedetails/?id=1628350"
        "RetroArch|flatpak run org.libretro.RetroArch||https://www.libretro.com/wp-content/uploads/2020/02/LibretroLogo.png"
        "Yuzu|flatpak run org.yuzu_emu.yuzu||https://yuzu-emu.org/images/logo.png"
        "Dolphin|flatpak run org.DolphinEmu.DolphinEmu||https://dolphin-emu.org/images/dolphin_logo.png"
        "VLC|flatpak run org.videolan.VLC||https://www.videolan.org/images/vlc.png"
        "Firefox|flatpak run org.mozilla.firefox||https://www.mozilla.org/media/img/firefox/favicon.ico"
        "Discord|flatpak run com.discordapp.Discord||https://discord.com/assets/847541504914fd33810e70a0ea73177e.ico"
        "Spotify|flatpak run com.spotify.Client||https://open.spotify.com/favicon.ico"
    )
    
    for app_info in "${apps[@]}"; do
        IFS='|' read -r name path args icon <<< "$app_info"
        
        print_message "Обработка: $name"
        
        # Проверка установки
        if flatpak list | grep -q "$(echo "$path" | cut -d' ' -f3)"; then
            add_to_steam "$name" "$path" "$args" "$icon"
            create_custom_cover "$name" "$icon"
        else
            print_warning "$name не установлен, пропускаем"
        fi
    done
}

# Добавление эмуляторов
add_emulators() {
    print_header "ДОБАВЛЕНИЕ ЭМУЛЯТОРОВ"
    
    local emulators=(
        "RetroArch|flatpak run org.libretro.RetroArch"
        "Yuzu|flatpak run org.yuzu_emu.yuzu"
        "Dolphin|flatpak run org.DolphinEmu.DolphinEmu"
        "PCSX2|flatpak run net.pcsx2.PCSX2"
        "PPSSPP|flatpak run org.ppsspp.PPSSPP"
        "Citra|flatpak run org.citra_emu.citra"
        "Ryujinx|flatpak run org.ryujinx.Ryujinx"
        "RPCS3|flatpak run net.rpcs3.RPCS3"
    )
    
    for emu_info in "${emulators[@]}"; do
        IFS='|' read -r name path <<< "$emu_info"
        
        if flatpak list | grep -q "$(echo "$path" | cut -d' ' -f3)"; then
            add_to_steam "$name" "$path"
        fi
    done
}

# Добавление лаунчеров
add_launchers() {
    print_header "ДОБАВЛЕНИЕ ЛАУНЧЕРОВ"
    
    local launchers=(
        "Heroic Games Launcher|flatpak run com.heroicgameslauncher.hgl"
        "Lutris|flatpak run net.lutris.Lutris"
        "Bottles|flatpak run com.usebottles.bottles"
        "ProtonUp-Qt|flatpak run net.davidotek.pupgui2"
        "ProtonTricks|flatpak run com.github.Matoking.protontricks"
    )
    
    for launcher_info in "${launchers[@]}"; do
        IFS='|' read -r name path <<< "$launcher_info"
        
        if flatpak list | grep -q "$(echo "$path" | cut -d' ' -f3)"; then
            add_to_steam "$name" "$path"
        fi
    done
}

# Добавление медиа приложений
add_media_apps() {
    print_header "ДОБАВЛЕНИЕ МЕДИА ПРИЛОЖЕНИЙ"
    
    local media_apps=(
        "VLC|flatpak run org.videolan.VLC"
        "MPV|flatpak run io.mpv.Mpv"
        "Kodi|flatpak run tv.kodi.Kodi"
        "OBS Studio|flatpak run com.obsproject.Studio"
        "Audacity|flatpak run org.audacityteam.Audacity"
        "GIMP|flatpak run org.gimp.GIMP"
        "Krita|flatpak run org.kde.krita"
        "Blender|flatpak run org.blender.Blender"
    )
    
    for media_info in "${media_apps[@]}"; do
        IFS='|' read -r name path <<< "$media_info"
        
        if flatpak list | grep -q "$(echo "$path" | cut -d' ' -f3)"; then
            add_to_steam "$name" "$path"
        fi
    done
}

# Добавление утилит
add_utilities() {
    print_header "ДОБАВЛЕНИЕ УТИЛИТ"
    
    local utilities=(
        "Firefox|flatpak run org.mozilla.firefox"
        "Chrome|flatpak run com.google.Chrome"
        "Discord|flatpak run com.discordapp.Discord"
        "Telegram|flatpak run org.telegram.desktop"
        "Spotify|flatpak run com.spotify.Client"
        "FileZilla|flatpak run org.filezillaproject.FileZilla"
        "GParted|flatpak run org.gparted.GParted"
        "Wireshark|flatpak run org.wireshark.Wireshark"
    )
    
    for util_info in "${utilities[@]}"; do
        IFS='|' read -r name path <<< "$util_info"
        
        if flatpak list | grep -q "$(echo "$path" | cut -d' ' -f3)"; then
            add_to_steam "$name" "$path"
        fi
    done
}

# Поиск и добавление Native Linux игр (.sh скрипты)
add_native_linux_games() {
    print_header "ПОИСК NATIVE LINUX ИГР (.sh скрипты)"
    
    local search_dirs=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "$HOME/Games"
        "/run/media/mmcblk0p1/Games"
        "/run/media/mmcblk0p1"
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
            
            # Поиск .sh файлов, которые могут быть играми
            while IFS= read -r -d '' file; do
                local filename=$(basename "$file")
                local game_name=$(basename "$file" .sh)
                
                # Проверяем, что это может быть игра (не системный скрипт)
                if [[ ! "$filename" =~ ^(setup|install|config|start|run) ]] && 
                   [[ ! "$filename" =~ ^\. ]] &&
                   [[ -x "$file" ]] || [[ -f "$file" ]]; then
                    found_games+=("$game_name|$file")
                    print_message "Найдена игра: $game_name ($file)"
                fi
            done < <(find "$dir" -maxdepth 3 -name "*.sh" -type f -print0 2>/dev/null)
        fi
    done
    
    if [[ ${#found_games[@]} -eq 0 ]]; then
        print_warning "Native Linux игры (.sh) не найдены"
        print_message "Поместите .sh файлы игр в одну из директорий:"
        for dir in "${search_dirs[@]}"; do
            echo "  - $dir"
        done
        return 0
    fi
    
    print_message "Найдено игр: ${#found_games[@]}"
    echo
    
    # Показываем найденные игры и предлагаем добавить
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
        # Убираем пробелы
        index=$(echo "$index" | xargs)
        
        if [[ "$index" =~ ^[0-9]+$ ]] && [[ "$index" -ge 1 ]] && [[ "$index" -le ${#found_games[@]} ]]; then
            local array_index=$((index-1))
            IFS='|' read -r name path <<< "${found_games[$array_index]}"
            
            print_message "Добавление игры: $name"
            create_single_shortcut "$name" "$path"
        else
            print_warning "Неверный индекс: $index"
        fi
    done
}

# Массовое добавление всех найденных .sh игр
add_all_native_games() {
    print_header "МАССОВОЕ ДОБАВЛЕНИЕ NATIVE LINUX ИГР"
    
    local search_dirs=(
        "$HOME/Downloads"
        "$HOME/Desktop"
        "$HOME/Games"
        "/run/media/mmcblk0p1/Games"
        "/run/media/mmcblk0p1"
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
    
    local added_count=0
    
    for dir in "${search_dirs[@]}"; do
        if [[ -d "$dir" ]]; then
            print_message "Поиск в: $dir"
            
            while IFS= read -r -d '' file; do
                local filename=$(basename "$file")
                local game_name=$(basename "$file" .sh)
                
                # Проверяем, что это может быть игра
                if [[ ! "$filename" =~ ^(setup|install|config|start|run) ]] && 
                   [[ ! "$filename" =~ ^\. ]] &&
                   [[ -f "$file" ]]; then
                    
                    print_message "Добавление: $game_name"
                    create_single_shortcut "$game_name" "$file"
                    ((added_count++))
                fi
            done < <(find "$dir" -maxdepth 3 -name "*.sh" -type f -print0 2>/dev/null)
        fi
    done
    
    print_success "Добавлено игр: $added_count"
}

# Создание ярлыка для конкретного приложения
create_single_shortcut() {
    local app_name="$1"
    local app_path="$2"
    local app_args="$3"
    
    if [[ -z "$app_name" ]] || [[ -z "$app_path" ]]; then
        print_error "Укажите имя и путь к приложению"
        return 1
    fi
    
    # Проверка на .sh скрипт
    if [[ "$app_path" == *.sh ]]; then
        print_message "Обнаружен .sh скрипт, настройка для Linux игры"
        # Делаем скрипт исполняемым
        chmod +x "$app_path"
        # Добавляем в Steam с правильными параметрами
        add_to_steam "$app_name" "$app_path" "$app_args"
    else
        print_message "Создание ярлыка для: $app_name"
        add_to_steam "$app_name" "$app_path" "$app_args"
    fi
}

# Интерактивное создание ярлыка
interactive_shortcut() {
    print_header "СОЗДАНИЕ ЯРЛЫКА"
    
    echo "Введите информацию о приложении:"
    read -p "Название: " app_name
    read -p "Путь к исполняемому файлу: " app_path
    read -p "Аргументы запуска (необязательно): " app_args
    
    if [[ -n "$app_name" ]] && [[ -n "$app_path" ]]; then
        create_single_shortcut "$app_name" "$app_path" "$app_args"
    else
        print_error "Название и путь обязательны"
    fi
}

# Показать существующие ярлыки
list_shortcuts() {
    print_header "СУЩЕСТВУЮЩИЕ ЯРЛЫКИ"
    
    local shortcuts_file=$(find "$STEAM_DIR/userdata" -name "shortcuts.vdf" 2>/dev/null | head -1)
    
    if [[ -f "$shortcuts_file" ]]; then
        print_message "Файл ярлыков: $shortcuts_file"
        
        # Простое извлечение названий приложений
        if command -v strings &> /dev/null; then
            strings "$shortcuts_file" | grep -E "^[A-Za-z]" | head -20
        else
            print_warning "Утилита strings не найдена, не удалось прочитать ярлыки"
        fi
    else
        print_warning "Файл ярлыков не найден"
    fi
}

# Создание резервной копии ярлыков
backup_shortcuts() {
    print_message "Создание резервной копии ярлыков..."
    
    local shortcuts_file=$(find "$STEAM_DIR/userdata" -name "shortcuts.vdf" 2>/dev/null | head -1)
    local backup_file="shortcuts_backup_$(date +%Y%m%d_%H%M%S).vdf"
    
    if [[ -f "$shortcuts_file" ]]; then
        cp "$shortcuts_file" "$backup_file"
        print_success "Резервная копия создана: $backup_file"
    else
        print_warning "Файл ярлыков не найден"
    fi
}

# Восстановление ярлыков
# Функция для создания ярлыка с Sniper
create_sniper_shortcut() {
    local app_name="$1"
    local app_path="$2"
    
    local sniper_dir="$HOME/.steam/steam/steamapps/common/SteamLinuxRuntime_sniper"
    local sniper_run="$sniper_dir/run"
    
    if [[ ! -f "$sniper_run" ]]; then
        print_error "SteamLinuxRuntime - Sniper не найден"
        print_message "Установите через Steam: steam steam://install/1628350"
        return 1
    fi
    
    # Создание ярлыка с Sniper
    local shortcut_name="${app_name} (Sniper)"
    local shortcut_path="$sniper_run -- \"$app_path\""
    
    print_message "Создание ярлыка с Sniper: $shortcut_name"
    
    # Добавление в Steam shortcuts
    add_shortcut_to_steam "$shortcut_name" "$shortcut_path"
}

restore_shortcuts() {
    local backup_file="$1"
    
    if [[ -z "$backup_file" ]]; then
        print_error "Укажите файл для восстановления"
        return 1
    fi
    
    if [[ ! -f "$backup_file" ]]; then
        print_error "Файл не найден: $backup_file"
        return 1
    fi
    
    local shortcuts_file=$(find "$STEAM_DIR/userdata" -name "shortcuts.vdf" 2>/dev/null | head -1)
    
    if [[ -n "$shortcuts_file" ]]; then
        cp "$backup_file" "$shortcuts_file"
        print_success "Ярлыки восстановлены из: $backup_file"
    else
        print_error "Не удалось найти файл ярлыков Steam"
    fi
}

# Главное меню
main_menu() {
    while true; do
        clear
        print_header "STEAM DECK SHORTCUTS MANAGER"
        echo
        echo "  1) Добавить популярные приложения"
        echo "  2) Добавить эмуляторы"
        echo "  3) Добавить лаунчеры игр"
        echo "  4) Добавить медиа приложения"
        echo "  5) Добавить утилиты"
        echo "  6) Найти Native Linux игры (.sh)"
        echo "  7) Добавить все Native Linux игры"
        echo "  8) Создать ярлык вручную"
        echo "  9) Показать существующие ярлыки"
        echo " 10) Резервная копия ярлыков"
        echo " 11) Восстановить ярлыки"
        echo "  0) Выход"
        echo
        
        read -p "Выберите действие: " choice
        
        case $choice in
            1) add_popular_apps ;;
            2) add_emulators ;;
            3) add_launchers ;;
            4) add_media_apps ;;
            5) add_utilities ;;
            6) add_native_linux_games ;;
            7) add_all_native_games ;;
            8) interactive_shortcut ;;
            9) list_shortcuts ;;
            10) backup_shortcuts ;;
            11) 
                read -p "Путь к файлу резервной копии: " backup_file
                restore_shortcuts "$backup_file"
                ;;
            0) exit 0 ;;
            *) print_error "Неверный выбор" ;;
        esac
        
        echo
        read -p "Нажмите Enter для продолжения..."
    done
}

# Показать справку
show_help() {
    echo "Steam Deck Shortcuts Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТЫ]"
    echo
    echo "ОПЦИИ:"
    echo "  interactive                - Интерактивное меню (по умолчанию)"
    echo "  popular                    - Добавить популярные приложения"
    echo "  emulators                  - Добавить эмуляторы"
    echo "  launchers                  - Добавить лаунчеры"
    echo "  media                      - Добавить медиа приложения"
    echo "  utilities                  - Добавить утилиты"
    echo "  native-games               - Найти Native Linux игры (.sh)"
    echo "  add-all-native             - Добавить все Native Linux игры"
    echo "  create <name> <path> [args] - Создать ярлык"
    echo "  list                       - Показать существующие ярлыки"
    echo "  backup                     - Создать резервную копию"
    echo "  restore <file>             - Восстановить из резервной копии"
    echo "  help                       - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0                         # Интерактивное меню"
    echo "  $0 popular                 # Добавить популярные приложения"
    echo "  $0 native-games            # Найти Native Linux игры"
    echo "  $0 add-all-native          # Добавить все .sh игры"
    echo "  $0 create \"My Game\" \"/path/to/game.sh\""
    echo "  $0 backup                  # Создать резервную копию"
    echo "  $0 restore backup.vdf      # Восстановить ярлыки"
}

# Основная функция
main() {
    case "${1:-interactive}" in
        "interactive")
            main_menu
            ;;
        "popular")
            add_popular_apps
            ;;
        "emulators")
            add_emulators
            ;;
        "launchers")
            add_launchers
            ;;
        "media")
            add_media_apps
            ;;
        "utilities")
            add_utilities
            ;;
        "native-games")
            add_native_linux_games
            ;;
        "add-all-native")
            add_all_native_games
            ;;
        "create")
            if [[ -z "$2" ]] || [[ -z "$3" ]]; then
                print_error "Укажите название и путь к приложению"
                show_help
                exit 1
            fi
            create_single_shortcut "$2" "$3" "$4"
            ;;
        "list")
            list_shortcuts
            ;;
        "backup")
            backup_shortcuts
            ;;
        "restore")
            if [[ -z "$2" ]]; then
                print_error "Укажите файл для восстановления"
                show_help
                exit 1
            fi
            restore_shortcuts "$2"
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
