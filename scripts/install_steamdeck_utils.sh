#!/bin/bash

# Steam Deck Utils Installer
# Скрипт для установки Steam Deck Enhancement Pack в основную память
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

# Определяем текущую директорию скрипта (глобально)
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

# Загружаем конфигурацию если существует
CONFIG_FILE="$PROJECT_ROOT/config.env"
if [[ -f "$CONFIG_FILE" ]]; then
    source "$CONFIG_FILE"
    print_message "Загружена конфигурация из $CONFIG_FILE"
fi

# Определяем пользователя и пути установки
DECK_USER="${STEAMDECK_USER:-deck}"
DECK_HOME="${STEAMDECK_HOME:-/home/$DECK_USER}"
INSTALL_DIR="${STEAMDECK_INSTALL_DIR:-$DECK_HOME/SteamDeck}"

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

# Функция для проверки прав
check_permissions() {
    if [[ $EUID -ne 0 ]]; then
        print_error "Этот скрипт должен быть запущен с правами root"
        print_info "Используйте: sudo $0"
        exit 1
    fi
}

# Функция для установки утилиты
install_steamdeck_utils() {
    print_header "УСТАНОВКА STEAM DECK ENHANCEMENT PACK"
    
    local utils_dir="$INSTALL_DIR"
    local current_dir="$PROJECT_ROOT"
    
    print_info "Текущая директория: $current_dir"
    print_info "Целевая директория: $utils_dir"
    
    # Создаем директорию для утилит
    if [[ ! -d "$utils_dir" ]]; then
        print_message "Создание директории $utils_dir..."
        mkdir -p "$utils_dir"
        chown $DECK_USER:$DECK_USER "$utils_dir"
    else
        print_warning "Директория $utils_dir уже существует"
        read -p "Перезаписать существующие файлы? (y/N): " overwrite
        if [[ ! "$overwrite" =~ ^[Yy]$ ]]; then
            print_info "Установка отменена пользователем"
            exit 0
        fi
    fi
    
    # Копируем все файлы проекта
    print_message "Копирование файлов утилиты..."
    if cp -r "$current_dir"/* "$utils_dir/" 2>/dev/null; then
        print_success "Файлы скопированы успешно"
    else
        print_warning "Не удалось скопировать все файлы"
        print_message "Попытка копирования основных компонентов..."
        
        # Копируем основные скрипты
        mkdir -p "$utils_dir/scripts"
        cp "$current_dir"/*.sh "$utils_dir/scripts/" 2>/dev/null || true
        cp "$current_dir"/*.py "$utils_dir/scripts/" 2>/dev/null || true
        
        # Копируем руководства
        if [[ -d "$current_dir/guides" ]]; then
            mkdir -p "$utils_dir/guides"
            cp "$current_dir/guides"/*.md "$utils_dir/guides/" 2>/dev/null || true
        fi
        
        # Копируем конфигурационные файлы
        cp "$current_dir"/*.md "$utils_dir/" 2>/dev/null || true
        cp "$current_dir"/*.yml "$utils_dir/" 2>/dev/null || true
        cp "$current_dir"/*.sh "$utils_dir/" 2>/dev/null || true
        
        print_success "Основные компоненты скопированы"
    fi
    
    # Устанавливаем права доступа
    print_message "Установка прав доступа..."
    chown -R deck:deck "$utils_dir"
    chmod -R 755 "$utils_dir"
    chmod +x "$utils_dir/scripts"/*.sh 2>/dev/null || true
    chmod +x "$utils_dir"/*.sh 2>/dev/null || true
    
    # Создаем символические ссылки для быстрого доступа
    print_message "Создание символических ссылок..."
    
    # Ссылка на главный скрипт настройки
    ln -sf "$utils_dir/scripts/steamdeck_setup.sh" "$DECK_HOME/steamdeck-setup" 2>/dev/null || true
    print_info "Создана ссылка: ~/steamdeck-setup"
    
    # Ссылка на GUI
    ln -sf "$utils_dir/scripts/steamdeck_gui.py" "$DECK_HOME/steamdeck-gui" 2>/dev/null || true
    print_info "Создана ссылка: ~/steamdeck-gui"
    
    # Ссылка на скрипт бэкапа
    ln -sf "$utils_dir/scripts/steamdeck_backup.sh" "$DECK_HOME/steamdeck-backup" 2>/dev/null || true
    print_info "Создана ссылка: ~/steamdeck-backup"
    
    # Ссылка на скрипт очистки
    ln -sf "$utils_dir/scripts/steamdeck_cleanup.sh" "$DECK_HOME/steamdeck-cleanup" 2>/dev/null || true
    print_info "Создана ссылка: ~/steamdeck-cleanup"
    
    # Ссылка на скрипт оптимизации
    ln -sf "$utils_dir/scripts/steamdeck_optimizer.sh" "$DECK_HOME/steamdeck-optimizer" 2>/dev/null || true
    print_info "Создана ссылка: ~/steamdeck-optimizer"
    
    # Ссылка на скрипт MicroSD
    ln -sf "$utils_dir/scripts/steamdeck_microsd.sh" "$DECK_HOME/steamdeck-microsd" 2>/dev/null || true
    print_info "Создана ссылка: ~/steamdeck-microsd"
    
    # Создаем desktop файл для GUI
    print_message "Создание desktop файла для GUI..."
    cat > "$DECK_HOME/.local/share/applications/steamdeck-enhancement-pack.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Steam Deck Enhancement Pack
Comment=Утилиты для управления Steam Deck
Exec=python3 $INSTALL_DIR/scripts/steamdeck_gui.py
Icon=steam
Terminal=false
Categories=Utility;System;
StartupNotify=true
EOF
    
    chmod +x "$DECK_HOME/.local/share/applications/steamdeck-enhancement-pack.desktop"
    chown $DECK_USER:$DECK_USER "$DECK_HOME/.local/share/applications/steamdeck-enhancement-pack.desktop"
    print_success "Desktop файл создан"
    
    # Обновляем desktop базу
    print_message "Обновление desktop базы..."
    if command -v update-desktop-database &> /dev/null; then
        update-desktop-database "$DECK_HOME/.local/share/applications" 2>/dev/null || true
        print_success "Desktop база обновлена"
    else
        print_warning "update-desktop-database не найден, пропускаем"
    fi
    
    # Создаем скрипт быстрого запуска
    print_message "Создание скрипта быстрого запуска..."
    cat > "$DECK_HOME/steamdeck-utils" << EOF
#!/bin/bash
# Steam Deck Enhancement Pack - Быстрый запуск
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

echo "🎮 Steam Deck Enhancement Pack v0.1"
echo "=================================="
echo
echo "Доступные команды:"
echo "  steamdeck-setup     - Настройка системы"
echo "  steamdeck-gui       - Графический интерфейс"
echo "  steamdeck-backup    - Резервное копирование"
echo "  steamdeck-cleanup   - Очистка системы"
echo "  steamdeck-optimizer - Оптимизация"
echo "  steamdeck-microsd   - Управление MicroSD"
echo
echo "Или запустите GUI: python3 $INSTALL_DIR/scripts/steamdeck_gui.py"
echo
EOF
    
    chmod +x "$DECK_HOME/steamdeck-utils"
    chown $DECK_USER:$DECK_USER "$DECK_HOME/steamdeck-utils"
    print_success "Скрипт быстрого запуска создан"
    
    # Копируем готовые обложки утилиты
    print_message "Копирование обложек утилиты..."
    local artwork_source_dir="$current_dir/../artwork/utils"
    local artwork_dest_dir="$utils_dir/artwork/utils"
    
    if [[ -d "$artwork_source_dir" ]]; then
        mkdir -p "$artwork_dest_dir"
        cp -r "$artwork_source_dir"/* "$artwork_dest_dir/" 2>/dev/null || true
        chown -R deck:deck "$artwork_dest_dir" 2>/dev/null || true
        print_success "Обложки утилиты скопированы"
    else
        print_warning "Папка с обложками не найдена: $artwork_source_dir"
    fi
    
    # Создаем README для пользователя
    print_message "Создание пользовательского README..."
    cat > "$INSTALL_DIR/QUICK_START.md" << EOF
# Steam Deck Enhancement Pack - Быстрый старт

## 🚀 Быстрый запуск

### Графический интерфейс:
```bash
python3 ~/SteamDeck/scripts/steamdeck_gui.py
```

### Командная строка:
```bash
# Настройка системы
~/steamdeck-setup

# Резервное копирование
~/steamdeck-backup

# Очистка системы
~/steamdeck-cleanup

# Оптимизация
~/steamdeck-optimizer

# Управление MicroSD
~/steamdeck-microsd

# Показать все команды
~/steamdeck-utils
```

## 📁 Расположение файлов

- **Скрипты:** `~/SteamDeck/scripts/`
- **Руководства:** `~/SteamDeck/guides/`
- **Символические ссылки:** `~/steamdeck-*`

## 🎯 Первый запуск

1. Запустите GUI: `python3 ~/SteamDeck/scripts/steamdeck_gui.py`
2. Нажмите "Настройка системы" для первоначальной настройки
3. Используйте другие функции по необходимости

## 📚 Документация

Все руководства находятся в папке `~/SteamDeck/guides/`

---
*Steam Deck Enhancement Pack v0.1*
*Автор: @ncux11*
EOF
    
    chown $DECK_USER:$DECK_USER "$INSTALL_DIR/QUICK_START.md"
    print_success "README создан"
    
    print_success "Steam Deck Enhancement Pack установлен в $utils_dir"
    print_message "Созданы символические ссылки для быстрого доступа"
    print_message "Desktop файл создан для запуска из меню приложений"
    print_message "Быстрый старт: ~/steamdeck-utils"
    
    echo
    print_header "УСТАНОВКА ЗАВЕРШЕНА"
    echo
    print_info "Для запуска GUI используйте:"
    print_info "  python3 ~/SteamDeck/scripts/steamdeck_gui.py"
    echo
    print_info "Или запустите:"
    print_info "  ~/steamdeck-utils"
    echo
}

# Функция для показа справки
show_help() {
    echo "Steam Deck Utils Installer v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ]"
    echo
    echo "ОПЦИИ:"
    echo "  install     - Установить утилиты (по умолчанию)"
    echo "  help        - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  sudo $0 install    # Установить утилиты"
    echo "  sudo $0            # Установить утилиты"
    echo
    echo "После установки утилиты будут доступны по командам:"
    echo "  ~/steamdeck-setup     - Настройка системы"
    echo "  ~/steamdeck-gui       - Графический интерфейс"
    echo "  ~/steamdeck-backup    - Резервное копирование"
    echo "  ~/steamdeck-cleanup   - Очистка системы"
    echo "  ~/steamdeck-optimizer - Оптимизация"
    echo "  ~/steamdeck-microsd   - Управление MicroSD"
    echo "  ~/steamdeck-utils     - Показать все команды"
}

# Основная функция
main() {
    case "${1:-install}" in
        "install")
            check_permissions
            install_steamdeck_utils
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
