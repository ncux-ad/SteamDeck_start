#!/bin/bash

# Steam Deck GUI Steam Integration
# Добавление GUI приложения в Steam
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Функции для вывода
print_message() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }

# Пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GUI_SCRIPT="$SCRIPT_DIR/steamdeck_gui.py"
STEAM_DIR="$HOME/.steam/steam"
USER_DATA_DIR="$STEAM_DIR/userdata"

print_message "Добавление Steam Deck GUI в Steam..."

# Проверяем существование GUI скрипта
if [[ ! -f "$GUI_SCRIPT" ]]; then
    print_error "GUI скрипт не найден: $GUI_SCRIPT"
    exit 1
fi

# Делаем GUI скрипт исполняемым
chmod +x "$GUI_SCRIPT"
print_success "GUI скрипт сделан исполняемым"

# Создаем обертку для запуска
WRAPPER_SCRIPT="$SCRIPT_DIR/steamdeck_gui_wrapper.sh"
cat > "$WRAPPER_SCRIPT" << 'EOF'
#!/bin/bash
# Steam Deck GUI Wrapper
# Обертка для запуска GUI через Steam

cd "$(dirname "$0")"
exec python3 steamdeck_gui.py "$@"
EOF

chmod +x "$WRAPPER_SCRIPT"
print_success "Создана обертка для запуска"

# Создаем .desktop файл
DESKTOP_FILE="$SCRIPT_DIR/steamdeck-gui.desktop"
cat > "$DESKTOP_FILE" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Steam Deck Enhancement Pack
Comment=GUI для управления Steam Deck скриптами
Exec=$WRAPPER_SCRIPT
Icon=applications-games
Terminal=false
Categories=Game;Utility;
StartupWMClass=steamdeck-gui
EOF

print_success "Создан .desktop файл"

# Добавляем в Steam через Steam CLI
if command -v steam &> /dev/null; then
    print_message "Добавление в Steam через CLI..."
    
    if steam steam://addnonsteamgame/"$WRAPPER_SCRIPT"; then
        print_success "GUI добавлен в Steam через CLI"
    else
        print_warning "Не удалось добавить через CLI, попробуйте вручную"
    fi
else
    print_warning "Steam CLI не найден"
fi

# Создаем обложку для Steam
create_steam_cover() {
    local user_id=$(ls "$USER_DATA_DIR" 2>/dev/null | head -1)
    if [[ -n "$user_id" ]]; then
        local grid_dir="$USER_DATA_DIR/$user_id/config/grid"
        mkdir -p "$grid_dir"
        
        # Создаем простую обложку (текстовую)
        local cover_file="$grid_dir/steamdeck_gui_cover.jpg"
        
        # Используем convert из ImageMagick если доступен
        if command -v convert &> /dev/null; then
            convert -size 600x900 xc:'#2b2b2b' \
                    -pointsize 48 -fill white -gravity center \
                    -annotate +0-100 "Steam Deck\nEnhancement Pack" \
                    -pointsize 24 -fill '#888888' -gravity center \
                    -annotate +0+50 "GUI для управления\nSteam Deck скриптами" \
                    "$cover_file" 2>/dev/null || true
        fi
        
        if [[ -f "$cover_file" ]]; then
            print_success "Создана обложка для Steam"
        else
            print_warning "Не удалось создать обложку (ImageMagick не установлен)"
        fi
    fi
}

create_steam_cover

print_success "GUI успешно добавлен в Steam!"
print_message ""
print_message "Инструкции:"
print_message "1. Перезапустите Steam"
print_message "2. Найдите 'Steam Deck Enhancement Pack' в библиотеке"
print_message "3. Запустите приложение"
print_message ""
print_message "Альтернативный запуск:"
print_message "  $WRAPPER_SCRIPT"
print_message "  или"
print_message "  python3 $GUI_SCRIPT"
