#!/bin/bash

# Steam Deck Artwork Creator
# Скрипт для создания красивых обложек для утилиты и игр
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
ARTWORK_DIR="$HOME/SteamDeck/artwork"
TEMPLATES_DIR="$ARTWORK_DIR/templates"
UTILS_DIR="$ARTWORK_DIR/utils"

# Функция для создания обложки утилиты
create_utils_artwork() {
    print_header "СОЗДАНИЕ ОБЛОЖЕК ДЛЯ УТИЛИТЫ"
    
    local utils_name="Steam Deck Enhancement Pack"
    local utils_dir="$UTILS_DIR"
    
    # Создаем директории
    mkdir -p "$utils_dir"/{grid,hero,logo,icon}
    
    print_message "Создание обложек для '$utils_name'..."
    
    # Grid обложка (460x215)
    print_message "Создание grid обложки (460x215)..."
    cat > "$utils_dir/grid/create_grid.sh" << 'EOF'
#!/bin/bash
# Скрипт для создания grid обложки Steam Deck Enhancement Pack
# Размер: 460x215 пикселей

# Создаем базовое изображение с градиентом
convert -size 460x215 \
    -gradient '#1e3c72,#2a5298' \
    -fill '#ffffff' \
    -pointsize 24 \
    -gravity Center \
    -annotate +0+0 'Steam Deck\nEnhancement Pack' \
    -fill '#ffd700' \
    -pointsize 16 \
    -gravity South \
    -annotate +0+20 'v0.1 - @ncux11' \
    steamdeck_enhancement_pack_grid.png

echo "Grid обложка создана: steamdeck_enhancement_pack_grid.png"
EOF
    
    chmod +x "$utils_dir/grid/create_grid.sh"
    
    # Hero обложка (3840x1240)
    print_message "Создание hero обложки (3840x1240)..."
    cat > "$utils_dir/hero/create_hero.sh" << 'EOF'
#!/bin/bash
# Скрипт для создания hero обложки Steam Deck Enhancement Pack
# Размер: 3840x1240 пикселей

# Создаем широкоформатную обложку
convert -size 3840x1240 \
    -gradient '#1e3c72,#2a5298,#1e3c72' \
    -fill '#ffffff' \
    -pointsize 72 \
    -gravity Center \
    -annotate +0+0 'Steam Deck\nEnhancement Pack' \
    -fill '#ffd700' \
    -pointsize 36 \
    -gravity South \
    -annotate +0+50 'v0.1 - @ncux11' \
    steamdeck_enhancement_pack_hero.png

echo "Hero обложка создана: steamdeck_enhancement_pack_hero.png"
EOF
    
    chmod +x "$utils_dir/hero/create_hero.sh"
    
    # Logo (512x512)
    print_message "Создание logo (512x512)..."
    cat > "$utils_dir/logo/create_logo.sh" << 'EOF'
#!/bin/bash
# Скрипт для создания logo Steam Deck Enhancement Pack
# Размер: 512x512 пикселей

# Создаем квадратный логотип
convert -size 512x512 \
    -gradient '#1e3c72,#2a5298' \
    -fill '#ffffff' \
    -pointsize 32 \
    -gravity Center \
    -annotate +0+0 'SD\nEP' \
    -fill '#ffd700' \
    -pointsize 16 \
    -gravity South \
    -annotate +0+20 'v0.1' \
    steamdeck_enhancement_pack_logo.png

echo "Logo создан: steamdeck_enhancement_pack_logo.png"
EOF
    
    chmod +x "$utils_dir/logo/create_logo.sh"
    
    # Icon (256x256)
    print_message "Создание icon (256x256)..."
    cat > "$utils_dir/icon/create_icon.sh" << 'EOF'
#!/bin/bash
# Скрипт для создания icon Steam Deck Enhancement Pack
# Размер: 256x256 пикселей

# Создаем иконку
convert -size 256x256 \
    -gradient '#1e3c72,#2a5298' \
    -fill '#ffffff' \
    -pointsize 20 \
    -gravity Center \
    -annotate +0+0 'SD\nEP' \
    -fill '#ffd700' \
    -pointsize 12 \
    -gravity South \
    -annotate +0+15 'v0.1' \
    steamdeck_enhancement_pack_icon.png

echo "Icon создан: steamdeck_enhancement_pack_icon.png"
EOF
    
    chmod +x "$utils_dir/icon/create_icon.sh"
    
    # Создаем общий скрипт
    cat > "$utils_dir/create_all.sh" << 'EOF'
#!/bin/bash
# Создание всех обложек для Steam Deck Enhancement Pack

echo "🎨 Создание обложек для Steam Deck Enhancement Pack..."
echo

# Проверяем ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick не найден. Установите: sudo pacman -S imagemagick"
    exit 1
fi

# Создаем все обложки
echo "📐 Создание grid обложки..."
cd grid && ./create_grid.sh && cd ..

echo "📐 Создание hero обложки..."
cd hero && ./create_hero.sh && cd ..

echo "📐 Создание logo..."
cd logo && ./create_logo.sh && cd ..

echo "📐 Создание icon..."
cd icon && ./create_icon.sh && cd ..

echo
echo "✅ Все обложки созданы!"
echo "📁 Файлы находятся в соответствующих папках"
EOF
    
    chmod +x "$utils_dir/create_all.sh"
    
    print_success "Скрипты для создания обложек утилиты созданы"
    print_info "Запустите: $utils_dir/create_all.sh"
}

# Функция для создания шаблонов обложек
create_artwork_templates() {
    print_header "СОЗДАНИЕ ШАБЛОНОВ ОБЛОЖЕК"
    
    mkdir -p "$TEMPLATES_DIR"
    
    # Создаем README с инструкциями
    cat > "$TEMPLATES_DIR/README.md" << 'EOF'
# Шаблоны обложек Steam Deck

## 🎨 Размеры обложек

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

## 🛠️ Инструменты

### ImageMagick (рекомендуется)
```bash
# Установка
sudo pacman -S imagemagick

# Создание обложки
convert -size 460x215 -gradient '#1e3c72,#2a5298' output.png
```

### GIMP (бесплатный)
- Откройте GIMP
- Создайте новое изображение с нужными размерами
- Используйте инструменты для создания обложки
- Экспортируйте в PNG

### Photoshop (профессиональный)
- Создайте новый документ с нужными размерами
- Используйте слои и эффекты
- Сохраните в PNG

### Canva (онлайн)
- Перейдите на canva.com
- Выберите размер 460x215 (Grid) или другой
- Создайте дизайн
- Скачайте в PNG

## 🎯 Рекомендации

1. **Используйте высокое качество** изображений
2. **Избегайте текста** на обложках (Steam добавит название)
3. **Используйте контрастные цвета** для лучшей видимости
4. **Сохраняйте в PNG** для прозрачности (logo, icon)
5. **Оптимизируйте размер** файлов для быстрой загрузки
6. **Используйте Steam-стиль** дизайна

## 🎨 Цветовые схемы

### Steam Deck (официальная)
- **Основной:** #1e3c72 (темно-синий)
- **Акцент:** #2a5298 (синий)
- **Текст:** #ffffff (белый)
- **Подсветка:** #ffd700 (золотой)

### Темная тема
- **Основной:** #2d2d2d (темно-серый)
- **Акцент:** #404040 (серый)
- **Текст:** #ffffff (белый)
- **Подсветка:** #00d4ff (голубой)

### Светлая тема
- **Основной:** #f0f0f0 (светло-серый)
- **Акцент:** #d0d0d0 (серый)
- **Текст:** #000000 (черный)
- **Подсветка:** #0078d4 (синий)

## 📁 Структура файлов

```
artwork/
├── templates/          # Шаблоны и инструкции
├── utils/             # Обложки для утилиты
│   ├── grid/          # Grid обложки
│   ├── hero/          # Hero обложки
│   ├── logo/          # Logo обложки
│   └── icon/          # Icon обложки
├── games/             # Обложки для игр
│   ├── grid/          # Grid обложки
│   ├── hero/          # Hero обложки
│   ├── logo/          # Logo обложки
│   └── icon/          # Icon обложки
└── emulators/         # Обложки для эмуляторов
    ├── grid/          # Grid обложки
    ├── hero/          # Hero обложки
    ├── logo/          # Logo обложки
    └── icon/          # Icon обложки
```

## 🚀 Быстрый старт

1. **Установите ImageMagick:**
   ```bash
   sudo pacman -S imagemagick
   ```

2. **Создайте обложки для утилиты:**
   ```bash
   cd ~/SteamDeck/artwork/utils
   ./create_all.sh
   ```

3. **Добавьте обложки в Steam:**
   - Откройте Steam
   - Перейдите в библиотеку
   - Найдите ваше приложение
   - Щелкните правой кнопкой → "Управление" → "Настроить обложку"
   - Выберите созданную обложку

## 📚 Дополнительные ресурсы

- [Steam Grid DB](https://www.steamgriddb.com/) - База данных обложек
- [Steam Artwork Guide](https://steamcommunity.com/sharedfiles/filedetails/?id=2411804454) - Руководство по обложкам
- [ImageMagick Documentation](https://imagemagick.org/script/command-line-processing.php) - Документация ImageMagick
- [GIMP Tutorials](https://www.gimp.org/tutorials/) - Уроки по GIMP

---
*Steam Deck Enhancement Pack v0.1*
*Автор: @ncux11*
EOF
    
    # Создаем базовые шаблоны
    create_basic_templates
    
    print_success "Шаблоны обложек созданы в $TEMPLATES_DIR"
}

# Функция для создания базовых шаблонов
create_basic_templates() {
    print_message "Создание базовых шаблонов..."
    
    # Grid шаблон
    cat > "$TEMPLATES_DIR/grid_template.sh" << 'EOF'
#!/bin/bash
# Шаблон для создания grid обложки (460x215)

GAME_NAME="$1"
if [[ -z "$GAME_NAME" ]]; then
    echo "Использование: $0 <название_игры>"
    exit 1
fi

# Создаем grid обложку
convert -size 460x215 \
    -gradient '#1e3c72,#2a5298' \
    -fill '#ffffff' \
    -pointsize 24 \
    -gravity Center \
    -annotate +0+0 "$GAME_NAME" \
    "${GAME_NAME// /_}_grid.png"

echo "Grid обложка создана: ${GAME_NAME// /_}_grid.png"
EOF
    
    chmod +x "$TEMPLATES_DIR/grid_template.sh"
    
    # Hero шаблон
    cat > "$TEMPLATES_DIR/hero_template.sh" << 'EOF'
#!/bin/bash
# Шаблон для создания hero обложки (3840x1240)

GAME_NAME="$1"
if [[ -z "$GAME_NAME" ]]; then
    echo "Использование: $0 <название_игры>"
    exit 1
fi

# Создаем hero обложку
convert -size 3840x1240 \
    -gradient '#1e3c72,#2a5298,#1e3c72' \
    -fill '#ffffff' \
    -pointsize 72 \
    -gravity Center \
    -annotate +0+0 "$GAME_NAME" \
    "${GAME_NAME// /_}_hero.png"

echo "Hero обложка создана: ${GAME_NAME// /_}_hero.png"
EOF
    
    chmod +x "$TEMPLATES_DIR/hero_template.sh"
    
    # Logo шаблон
    cat > "$TEMPLATES_DIR/logo_template.sh" << 'EOF'
#!/bin/bash
# Шаблон для создания logo (512x512)

GAME_NAME="$1"
if [[ -z "$GAME_NAME" ]]; then
    echo "Использование: $0 <название_игры>"
    exit 1
fi

# Создаем logo
convert -size 512x512 \
    -gradient '#1e3c72,#2a5298' \
    -fill '#ffffff' \
    -pointsize 32 \
    -gravity Center \
    -annotate +0+0 "$GAME_NAME" \
    "${GAME_NAME// /_}_logo.png"

echo "Logo создан: ${GAME_NAME// /_}_logo.png"
EOF
    
    chmod +x "$TEMPLATES_DIR/logo_template.sh"
    
    # Icon шаблон
    cat > "$TEMPLATES_DIR/icon_template.sh" << 'EOF'
#!/bin/bash
# Шаблон для создания icon (256x256)

GAME_NAME="$1"
if [[ -z "$GAME_NAME" ]]; then
    echo "Использование: $0 <название_игры>"
    exit 1
fi

# Создаем icon
convert -size 256x256 \
    -gradient '#1e3c72,#2a5298' \
    -fill '#ffffff' \
    -pointsize 20 \
    -gravity Center \
    -annotate +0+0 "$GAME_NAME" \
    "${GAME_NAME// /_}_icon.png"

echo "Icon создан: ${GAME_NAME// /_}_icon.png"
EOF
    
    chmod +x "$TEMPLATES_DIR/icon_template.sh"
    
    # Общий шаблон
    cat > "$TEMPLATES_DIR/create_all_templates.sh" << 'EOF'
#!/bin/bash
# Создание всех типов обложек для игры

GAME_NAME="$1"
if [[ -z "$GAME_NAME" ]]; then
    echo "Использование: $0 <название_игры>"
    exit 1
fi

echo "🎨 Создание обложек для: $GAME_NAME"
echo

# Проверяем ImageMagick
if ! command -v convert &> /dev/null; then
    echo "❌ ImageMagick не найден. Установите: sudo pacman -S imagemagick"
    exit 1
fi

# Создаем все обложки
echo "📐 Создание grid обложки..."
./grid_template.sh "$GAME_NAME"

echo "📐 Создание hero обложки..."
./hero_template.sh "$GAME_NAME"

echo "📐 Создание logo..."
./logo_template.sh "$GAME_NAME"

echo "📐 Создание icon..."
./icon_template.sh "$GAME_NAME"

echo
echo "✅ Все обложки созданы для: $GAME_NAME"
echo "📁 Файлы находятся в текущей директории"
EOF
    
    chmod +x "$TEMPLATES_DIR/create_all_templates.sh"
    
    print_success "Базовые шаблоны созданы"
}

# Функция для показа справки
show_help() {
    echo "Steam Deck Artwork Creator v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ] [АРГУМЕНТЫ]"
    echo
    echo "ОПЦИИ:"
    echo "  create-utils              - Создать обложки для утилиты"
    echo "  create-templates          - Создать шаблоны обложек"
    echo "  create-game <name>        - Создать обложки для игры"
    echo "  help                      - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0 create-utils                    # Обложки для утилиты"
    echo "  $0 create-templates                # Создать шаблоны"
    echo "  $0 create-game \"Cyberpunk 2077\"   # Обложки для игры"
    echo
    echo "ТРЕБОВАНИЯ:"
    echo "  - ImageMagick для создания обложек"
    echo "  - Установка: sudo pacman -S imagemagick"
}

# Функция для создания обложек игры
create_game_artwork() {
    local game_name="$1"
    
    if [[ -z "$game_name" ]]; then
        print_error "Название игры не указано"
        return 1
    fi
    
    print_header "СОЗДАНИЕ ОБЛОЖЕК ДЛЯ ИГРЫ: $game_name"
    
    # Создаем директории
    local game_dir="$ARTWORK_DIR/games"
    mkdir -p "$game_dir"/{grid,hero,logo,icon}
    
    # Переходим в директорию шаблонов
    cd "$TEMPLATES_DIR"
    
    # Создаем все обложки
    if ./create_all_templates.sh "$game_name"; then
        # Перемещаем файлы в соответствующие папки
        mv "${game_name// /_}_grid.png" "$game_dir/grid/"
        mv "${game_name// /_}_hero.png" "$game_dir/hero/"
        mv "${game_name// /_}_logo.png" "$game_dir/logo/"
        mv "${game_name// /_}_icon.png" "$game_dir/icon/"
        
        print_success "Обложки для '$game_name' созданы"
        print_info "Файлы находятся в $game_dir/"
    else
        print_error "Ошибка при создании обложек"
        return 1
    fi
}

# Основная функция
main() {
    case "${1:-help}" in
        "create-utils")
            create_utils_artwork
            ;;
        "create-templates")
            create_artwork_templates
            ;;
        "create-game")
            create_game_artwork "$2"
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
