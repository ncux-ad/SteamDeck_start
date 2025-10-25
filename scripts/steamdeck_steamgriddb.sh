#!/bin/bash

# Steam Deck Steam Grid DB Integration
# Скрипт для автоматического скачивания обложек с Steam Grid DB
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
GRID_DB_API="https://www.steamgriddb.com/api/v2"
API_KEY_FILE="$HOME/.steamdeck_steamgriddb_api_key"
ARTWORK_DIR="$HOME/SteamDeck/artwork"

# Функция для проверки API ключа
check_api_key() {
    if [[ ! -f "$API_KEY_FILE" ]]; then
        print_warning "API ключ Steam Grid DB не найден"
        print_info "Получите API ключ на: https://www.steamgriddb.com/api"
        print_info "Сохраните ключ в файл: $API_KEY_FILE"
        return 1
    fi
    
    local api_key=$(cat "$API_KEY_FILE" 2>/dev/null)
    if [[ -z "$api_key" ]]; then
        print_error "API ключ пустой"
        return 1
    fi
    
    print_success "API ключ найден"
    return 0
}

# Функция для поиска игры в Steam Grid DB
search_game() {
    local game_name="$1"
    
    if [[ -z "$game_name" ]]; then
        print_error "Название игры не указано"
        return 1
    fi
    
    if ! check_api_key; then
        return 1
    fi
    
    local api_key=$(cat "$API_KEY_FILE")
    
    print_message "Поиск игры '$game_name' в Steam Grid DB..."
    
    # URL encode название игры
    local encoded_name=$(echo "$game_name" | sed 's/ /%20/g')
    
    # Запрос к API
    local response=$(curl -s -H "Authorization: Bearer $api_key" \
        "$GRID_DB_API/search/autocomplete/$encoded_name" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        print_error "Ошибка при запросе к Steam Grid DB"
        return 1
    fi
    
    # Парсим ответ
    local game_id=$(echo "$response" | grep -o '"id":[0-9]*' | head -1 | cut -d':' -f2)
    
    if [[ -z "$game_id" ]]; then
        print_warning "Игра '$game_name' не найдена в Steam Grid DB"
        return 1
    fi
    
    print_success "Игра найдена: ID $game_id"
    echo "$game_id"
}

# Функция для скачивания обложек
download_artwork() {
    local game_id="$1"
    local artwork_type="$2"
    local output_dir="$3"
    
    if [[ -z "$game_id" ]] || [[ -z "$artwork_type" ]] || [[ -z "$output_dir" ]]; then
        print_error "Не все параметры указаны"
        return 1
    fi
    
    if ! check_api_key; then
        return 1
    fi
    
    local api_key=$(cat "$API_KEY_FILE")
    
    print_message "Скачивание $artwork_type обложки для игры ID $game_id..."
    
    # Определяем endpoint в зависимости от типа
    local endpoint=""
    case "$artwork_type" in
        "grid")
            endpoint="grids"
            ;;
        "hero")
            endpoint="heroes"
            ;;
        "logo")
            endpoint="logos"
            ;;
        "icon")
            endpoint="icons"
            ;;
        *)
            print_error "Неизвестный тип обложки: $artwork_type"
            return 1
            ;;
    esac
    
    # Запрос к API
    local response=$(curl -s -H "Authorization: Bearer $api_key" \
        "$GRID_DB_API/$endpoint/game/$game_id" 2>/dev/null)
    
    if [[ $? -ne 0 ]]; then
        print_error "Ошибка при запросе обложек"
        return 1
    fi
    
    # Парсим URL изображения
    local image_url=$(echo "$response" | grep -o '"url":"[^"]*"' | head -1 | cut -d'"' -f4)
    
    if [[ -z "$image_url" ]]; then
        print_warning "Обложка $artwork_type не найдена"
        return 1
    fi
    
    # Скачиваем изображение
    local filename="$output_dir/${game_id}_${artwork_type}.png"
    
    print_message "Скачивание: $image_url"
    
    if curl -s -o "$filename" "$image_url"; then
        print_success "Обложка сохранена: $filename"
        return 0
    else
        print_error "Ошибка при скачивании обложки"
        return 1
    fi
}

# Функция для установки обложек игры
install_game_artwork() {
    local game_name="$1"
    local game_id="$2"
    
    if [[ -z "$game_name" ]]; then
        print_error "Название игры не указано"
        return 1
    fi
    
    # Если ID не указан, ищем в Steam Grid DB
    if [[ -z "$game_id" ]]; then
        game_id=$(search_game "$game_name")
        if [[ -z "$game_id" ]]; then
            return 1
        fi
    fi
    
    print_header "УСТАНОВКА ОБЛОЖЕК ДЛЯ: $game_name (ID: $game_id)"
    
    # Создаем директории
    local game_dir="$ARTWORK_DIR/games"
    mkdir -p "$game_dir"/{grid,hero,logo,icon}
    
    # Скачиваем все типы обложек
    local success_count=0
    
    for artwork_type in grid hero logo icon; do
        if download_artwork "$game_id" "$artwork_type" "$game_dir/$artwork_type"; then
            ((success_count++))
        fi
    done
    
    print_success "Установлено обложек: $success_count/4"
}

# Функция для массовой установки обложек
batch_install_artwork() {
    local games_file="$1"
    
    if [[ -z "$games_file" ]] || [[ ! -f "$games_file" ]]; then
        print_error "Файл со списком игр не найден: $games_file"
        print_info "Создайте файл со списком игр (по одной на строку)"
        return 1
    fi
    
    print_header "МАССОВАЯ УСТАНОВКА ОБЛОЖЕК"
    
    local total_games=0
    local success_games=0
    
    while IFS= read -r game_name; do
        # Пропускаем пустые строки и комментарии
        if [[ -z "$game_name" ]] || [[ "$game_name" =~ ^# ]]; then
            continue
        fi
        
        ((total_games++))
        print_message "Обработка игры $total_games: $game_name"
        
        if install_game_artwork "$game_name"; then
            ((success_games++))
        fi
        
        # Небольшая пауза между запросами
        sleep 1
    done < "$games_file"
    
    print_success "Обработано игр: $success_games/$total_games"
}

# Функция для создания списка игр
create_games_list() {
    local output_file="$1"
    
    if [[ -z "$output_file" ]]; then
        output_file="$HOME/SteamDeck/games_list.txt"
    fi
    
    print_header "СОЗДАНИЕ СПИСКА ИГР"
    
    cat > "$output_file" << 'EOF'
# Список игр для установки обложек
# Добавьте названия игр по одной на строку
# Строки, начинающиеся с #, игнорируются

# Популярные игры
Cyberpunk 2077
The Witcher 3: Wild Hunt
Elden Ring
God of War
Horizon Zero Dawn
Red Dead Redemption 2
GTA V
Fallout 4
Skyrim
Minecraft

# Инди игры
Hades
Celeste
Hollow Knight
Stardew Valley
Terraria
Among Us
Fall Guys
Valheim

# Эмуляторы
RetroArch
Yuzu
Dolphin
PCSX2
RPCS3
EOF
    
    print_success "Список игр создан: $output_file"
    print_info "Отредактируйте файл и запустите массовую установку"
}

# Функция для показа справки
show_help() {
    echo "Steam Deck Steam Grid DB Integration v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТЫ]"
    echo
    echo "ОПЦИИ:"
    echo "  install <game_name> [id]     - Установить обложки для игры"
    echo "  batch <games_file>           - Массовая установка обложек"
    echo "  create-list [file]           - Создать список игр"
    echo "  search <game_name>           - Найти игру в Steam Grid DB"
    echo "  setup-api                    - Настроить API ключ"
    echo "  help                         - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 install \"Cyberpunk 2077\"           # Установить обложки"
    echo "  $0 install \"Witcher 3\" 292030         # Установить с ID"
    echo "  $0 batch games_list.txt                # Массовая установка"
    echo "  $0 create-list                         # Создать список игр"
    echo "  $0 search \"Elden Ring\"                # Найти игру"
    echo "  $0 setup-api                           # Настроить API"
    echo
    echo "ТРЕБОВАНИЯ:"
    echo "  - API ключ Steam Grid DB"
    echo "  - curl для скачивания"
    echo "  - Интернет соединение"
}

# Функция для настройки API ключа
setup_api_key() {
    print_header "НАСТРОЙКА API КЛЮЧА STEAM GRID DB"
    
    print_info "1. Перейдите на https://www.steamgriddb.com/api"
    print_info "2. Зарегистрируйтесь или войдите в аккаунт"
    print_info "3. Создайте новый API ключ"
    print_info "4. Скопируйте ключ"
    echo
    
    read -p "Введите API ключ: " api_key
    
    if [[ -z "$api_key" ]]; then
        print_error "API ключ не может быть пустым"
        return 1
    fi
    
    # Сохраняем ключ
    echo "$api_key" > "$API_KEY_FILE"
    chmod 600 "$API_KEY_FILE"
    
    print_success "API ключ сохранен в $API_KEY_FILE"
    
    # Тестируем ключ
    print_message "Тестирование API ключа..."
    if check_api_key; then
        print_success "API ключ работает"
    else
        print_error "API ключ не работает"
        return 1
    fi
}

# Основная функция
main() {
    case "${1:-help}" in
        "install")
            install_game_artwork "$2" "$3"
            ;;
        "batch")
            batch_install_artwork "$2"
            ;;
        "create-list")
            create_games_list "$2"
            ;;
        "search")
            search_game "$2"
            ;;
        "setup-api")
            setup_api_key
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
