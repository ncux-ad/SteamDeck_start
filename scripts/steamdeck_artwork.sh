#!/bin/bash

# Steam Deck Artwork Manager
# Скрипт для управления обложками утилиты и игр
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

# Переменные
STEAM_USER_DATA="$HOME/.steam/steam/userdata"
STEAM_APPS="$HOME/.steam/steam/steamapps"
ARTWORK_DIR="$HOME/SteamDeck/artwork"
GRID_DB_API="https://www.steamgriddb.com/api/v2"

# Функция для создания директорий
create_directories() {
    print_info "Создание директорий для обложек..."
    
    mkdir -p "$ARTWORK_DIR"/{utils,games,emulators,custom}
    mkdir -p "$ARTWORK_DIR/utils"/{grid,hero,logo,icon}
    mkdir -p "$ARTWORK_DIR/games"/{grid,hero,logo,icon}
    mkdir -p "$ARTWORK_DIR/emulators"/{grid,hero,logo,icon}
    
    print_success "Директории созданы"
}

# Функция для установки обложек утилиты
install_utils_artwork() {
    print_header "УСТАНОВКА ОБЛОЖЕК ДЛЯ УТИЛИТЫ"
    
    # Временно отключаем set -e для этой функции
    set +e
    
    local utils_dir="$ARTWORK_DIR/utils"
    local current_dir=$(dirname "$(readlink -f "$0")")
    local source_artwork_dir="$current_dir/../artwork/utils"
    
    # Создаем директории (если не существуют)
    mkdir -p "$utils_dir"/{grid,hero,logo,icon} 2>/dev/null || true
    
    # Проверяем наличие готовых обложек
    print_info "Проверка готовых обложек утилиты..."
    
    local artwork_files=(
        "grid/steamdeck_enhancement_pack.png"
        "hero/steamdeck_enhancement_pack.png"
        "logo/steamdeck_enhancement_pack.png"
        "icon/steamdeck_enhancement_pack.png"
    )
    
    local found_artwork=0
    
    for artwork_file in "${artwork_files[@]}"; do
        local source_file="$source_artwork_dir/$artwork_file"
        local dest_file="$utils_dir/$artwork_file"
        
        if [[ -f "$source_file" ]]; then
            print_info "Копирование $artwork_file..."
            cp "$source_file" "$dest_file" 2>/dev/null || true
            chown deck:deck "$dest_file" 2>/dev/null || true
            ((found_artwork++))
        else
            print_warning "Обложка не найдена: $artwork_file"
        fi
    done
    
    if [[ $found_artwork -gt 0 ]]; then
        print_success "Установлено обложек: $found_artwork/4"
        print_info "Обложки утилиты готовы к использованию в Steam"
    else
        print_warning "Готовые обложки не найдены"
        print_info "Создайте обложки вручную или используйте steamdeck_create_artwork.sh"
    fi
    
    # Включаем обратно set -e
    set -e
}

# Функция для поиска Steam приложений
find_steam_apps() {
    print_header "ПОИСК STEAM ПРИЛОЖЕНИЙ"
    
    local apps_found=0
    
    # Ищем в steamapps
    if [[ -d "$STEAM_APPS" ]]; then
        print_message "Поиск в $STEAM_APPS..."
        
        for app_dir in "$STEAM_APPS"/appmanifest_*.acf; do
            if [[ -f "$app_dir" ]]; then
                local app_id=$(basename "$app_dir" .acf | sed 's/appmanifest_//')
                local app_name=$(grep '"name"' "$app_dir" | cut -d'"' -f4)
                
                if [[ -n "$app_name" ]]; then
                    echo "  $app_id - $app_name"
                    ((apps_found++))
                fi
            fi
        done
    fi
    
    # Ищем в userdata
    if [[ -d "$STEAM_USER_DATA" ]]; then
        print_message "Поиск в $STEAM_USER_DATA..."
        
        for user_dir in "$STEAM_USER_DATA"/*; do
            if [[ -d "$user_dir" ]]; then
                local config_dir="$user_dir/config"
                if [[ -d "$config_dir" ]]; then
                    local shortcuts_file="$config_dir/shortcuts.vdf"
                    if [[ -f "$shortcuts_file" ]]; then
                        print_message "Найдены пользовательские ярлыки в $user_dir"
                    fi
                fi
            fi
        done
    fi
    
    print_success "Найдено приложений: $apps_found"
}

# Функция для скачивания обложек с Steam Grid DB
download_from_steamgriddb() {
    local app_name="$1"
    local app_id="$2"
    
    if [[ -z "$app_name" ]]; then
        print_error "Название приложения не указано"
        return 1
    fi
    
    print_message "Поиск обложек для '$app_name' в Steam Grid DB..."
    
    # Здесь можно добавить API запросы к Steam Grid DB
    # Пока что заглушка
    print_warning "Steam Grid DB API не реализован (требуется API ключ)"
    print_info "Рекомендуется использовать Steam Grid DB вручную"
}

# Функция для установки обложек игры
install_game_artwork() {
    local app_name="$1"
    local app_id="$2"
    local artwork_type="${3:-grid}"
    
    if [[ -z "$app_name" ]]; then
        print_error "Название игры не указано"
        return 1
    fi
    
    print_header "УСТАНОВКА ОБЛОЖЕК ДЛЯ ИГРЫ: $app_name"
    
    local game_dir="$ARTWORK_DIR/games/$artwork_type"
    local artwork_file="$game_dir/${app_name// /_}.png"
    
    # Проверяем, есть ли уже обложка
    if [[ -f "$artwork_file" ]]; then
        print_warning "Обложка уже существует: $artwork_file"
        read -p "Перезаписать? (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            print_info "Установка отменена"
            return 0
        fi
    fi
    
    # Создаем директорию если не существует
    mkdir -p "$game_dir"
    
    print_message "Установка обложки $artwork_type для '$app_name'..."
    print_info "Ожидается файл: $artwork_file"
    print_info "Размеры для $artwork_type:"
    
    case "$artwork_type" in
        "grid")
            print_info "  Grid: 460x215 пикселей"
            ;;
        "hero")
            print_info "  Hero: 3840x1240 пикселей"
            ;;
        "logo")
            print_info "  Logo: 512x512 пикселей"
            ;;
        "icon")
            print_info "  Icon: 256x256 пикселей"
            ;;
    esac
    
    print_warning "Поместите файл обложки в: $artwork_file"
    print_info "Или используйте Steam Grid DB для автоматического скачивания"
}

# Функция для создания шаблонов обложек
create_artwork_templates() {
    print_header "СОЗДАНИЕ ШАБЛОНОВ ОБЛОЖЕК"
    
    local templates_dir="$ARTWORK_DIR/templates"
    mkdir -p "$templates_dir"
    
    print_info "Создание шаблонов для разных типов обложек..."
    
    # Создаем README с инструкциями
    cat > "$templates_dir/README.md" << 'EOF'
# Шаблоны обложек Steam Deck

## Размеры обложек

### Grid (460x215)
- **Назначение:** Главная обложка в библиотеке Steam
- **Размер:** 460x215 пикселей
- **Формат:** PNG, JPG
- **Соотношение:** 2.14:1

### Hero (3840x1240)
- **Назначение:** Широкоформатная обложка в детальном виде
- **Размер:** 3840x1240 пикселей
- **Формат:** PNG, JPG
- **Соотношение:** 3.1:1

### Logo (512x512)
- **Назначение:** Логотип приложения
- **Размер:** 512x512 пикселей
- **Формат:** PNG (прозрачный фон)
- **Соотношение:** 1:1

### Icon (256x256)
- **Назначение:** Иконка в списке
- **Размер:** 256x256 пикселей
- **Формат:** PNG (прозрачный фон)
- **Соотношение:** 1:1

## Рекомендации

1. **Используйте высокое качество** изображений
2. **Избегайте текста** на обложках (Steam добавит название)
3. **Используйте контрастные цвета** для лучшей видимости
4. **Сохраняйте в PNG** для прозрачности (logo, icon)
5. **Оптимизируйте размер** файлов для быстрой загрузки

## Инструменты

- **GIMP** - бесплатный редактор изображений
- **Photoshop** - профессиональный редактор
- **Canva** - онлайн-редактор с шаблонами
- **Steam Grid DB** - база данных обложек
EOF
    
    print_success "Шаблоны созданы в $templates_dir"
}

# Функция для установки обложек эмуляторов
install_emulator_artwork() {
    print_header "УСТАНОВКА ОБЛОЖЕК ДЛЯ ЭМУЛЯТОРОВ"
    
    local emulators=(
        "RetroArch:retroarch"
        "Yuzu:yuzu"
        "Dolphin:dolphin"
        "PCSX2:pcsx2"
        "RPCS3:rpcs3"
        "Cemu:cemu"
        "Citra:citra"
        "PPSSPP:ppsspp"
    )
    
    for emulator in "${emulators[@]}"; do
        local name="${emulator%%:*}"
        local id="${emulator##*:}"
        
        print_info "Установка обложек для $name..."
        
        # Создаем директории
        local emu_dir="$ARTWORK_DIR/emulators"
        mkdir -p "$emu_dir"/{grid,hero,logo,icon}
        
        # Создаем placeholder файлы
        touch "$emu_dir/grid/${id}.png"
        touch "$emu_dir/hero/${id}.png"
        touch "$emu_dir/logo/${id}.png"
        touch "$emu_dir/icon/${id}.png"
        
        print_info "  Созданы placeholder файлы для $name"
    done
    
    print_success "Обложки для эмуляторов подготовлены"
}

# Функция для автоматической установки обложек
auto_install_artwork() {
    print_header "АВТОМАТИЧЕСКАЯ УСТАНОВКА ОБЛОЖЕК"
    
    # Создаем директории
    create_directories
    
    # Устанавливаем обложки утилиты (используем готовые)
    install_utils_artwork
    
    # Устанавливаем обложки эмуляторов
    install_emulator_artwork
    
    # Создаем шаблоны
    create_artwork_templates
    
    print_success "Автоматическая установка завершена"
    print_info "Готовые обложки утилиты установлены"
    print_info "Добавьте свои обложки для игр в соответствующие папки"
}

# Функция для показа справки
show_help() {
    echo "Steam Deck Artwork Manager v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТЫ]"
    echo
    echo "ОПЦИИ:"
    echo "  auto-install              - Автоматическая установка обложек"
    echo "  create-dirs               - Создать директории для обложек"
    echo "  install-utils             - Установить обложки для утилиты"
    echo "  install-game <name> [id]  - Установить обложки для игры"
    echo "  install-emulators         - Установить обложки для эмуляторов"
    echo "  find-apps                 - Найти Steam приложения"
    echo "  create-templates          - Создать шаблоны обложек"
    echo "  help                      - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 auto-install                    # Автоматическая установка"
    echo "  $0 install-game \"Cyberpunk 2077\"  # Обложки для игры"
    echo "  $0 install-game \"Witcher 3\" 292030 # Обложки с ID"
    echo "  $0 find-apps                       # Найти приложения"
    echo "  $0 create-templates                # Создать шаблоны"
    echo
    echo "РАЗМЕРЫ ОБЛОЖЕК:"
    echo "  Grid:  460x215  (главная обложка)"
    echo "  Hero:  3840x1240 (широкоформатная)"
    echo "  Logo:  512x512   (логотип)"
    echo "  Icon:  256x256   (иконка)"
}

# Основная функция
main() {
    case "${1:-auto-install}" in
        "auto-install")
            auto_install_artwork
            ;;
        "create-dirs")
            create_directories
            ;;
        "install-utils")
            install_utils_artwork
            ;;
        "install-game")
            install_game_artwork "$2" "$3"
            ;;
        "install-emulators")
            install_emulator_artwork
            ;;
        "find-apps")
            find_steam_apps
            ;;
        "create-templates")
            create_artwork_templates
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
