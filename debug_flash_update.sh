#!/bin/bash

# Диагностический скрипт для проверки обновления с флешки
# Автор: @ncux11

echo "🔍 ДИАГНОСТИКА ОБНОВЛЕНИЯ С ФЛЕШКИ"
echo "=================================="

# Определяем пути
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}")"
SCRIPT_DIR="$(dirname "$SCRIPT_PATH")"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"

echo "📁 Пути:"
echo "  SCRIPT_PATH: $SCRIPT_PATH"
echo "  SCRIPT_DIR: $SCRIPT_DIR"
echo "  PROJECT_ROOT: $PROJECT_ROOT"
echo

# Проверяем файл VERSION
echo "📄 Файл VERSION:"
if [[ -f "$PROJECT_ROOT/VERSION" ]]; then
    echo "  ✅ Найден: $PROJECT_ROOT/VERSION"
    echo "  📋 Содержимое: $(cat "$PROJECT_ROOT/VERSION")"
else
    echo "  ❌ Не найден: $PROJECT_ROOT/VERSION"
fi
echo

# Проверяем права доступа
echo "🔐 Права доступа:"
echo "  PROJECT_ROOT существует: $([[ -d "$PROJECT_ROOT" ]] && echo "✅ Да" || echo "❌ Нет")"
echo "  PROJECT_ROOT доступен для записи: $([[ -w "$PROJECT_ROOT" ]] && echo "✅ Да" || echo "❌ Нет")"
echo "  Текущий пользователь: $(whoami)"
echo "  UID: $(id -u)"
echo "  GID: $(id -g)"
echo

# Проверяем sudo
echo "🔑 Sudo:"
if sudo -n true 2>/dev/null; then
    echo "  ✅ Sudo доступен без пароля"
else
    echo "  ❌ Sudo требует пароль"
fi
echo

# Проверяем монтирование
echo "💾 Монтирование:"
echo "  Точка монтирования: $(df "$PROJECT_ROOT" | tail -1 | awk '{print $6}')"
echo "  Тип файловой системы: $(df "$PROJECT_ROOT" | tail -1 | awk '{print $1}')"
echo "  Права монтирования: $(mount | grep "$(df "$PROJECT_ROOT" | tail -1 | awk '{print $6}')" | awk '{print $6}')"
echo

# Проверяем файлы проекта
echo "📂 Файлы проекта:"
echo "  README.md: $([[ -f "$PROJECT_ROOT/README.md" ]] && echo "✅" || echo "❌")"
echo "  scripts/: $([[ -d "$PROJECT_ROOT/scripts" ]] && echo "✅" || echo "❌")"
echo "  scripts/steamdeck_update.sh: $([[ -f "$PROJECT_ROOT/scripts/steamdeck_update.sh" ]] && echo "✅" || echo "❌")"
echo "  scripts/steamdeck_gui.py: $([[ -f "$PROJECT_ROOT/scripts/steamdeck_gui.py" ]] && echo "✅" || echo "❌")"
echo

# Проверяем git
echo "🌐 Git:"
if command -v git >/dev/null 2>&1; then
    echo "  ✅ Git установлен"
    echo "  📍 Версия: $(git --version)"
else
    echo "  ❌ Git не установлен"
fi
echo

# Проверяем интернет
echo "🌍 Интернет:"
if ping -c 1 github.com >/dev/null 2>&1; then
    echo "  ✅ GitHub доступен"
else
    echo "  ❌ GitHub недоступен"
fi
echo

# Проверяем временную директорию
echo "📁 Временная директория:"
TEMP_DIR="/tmp/steamdeck_update"
echo "  TEMP_DIR: $TEMP_DIR"
echo "  Существует: $([[ -d "$TEMP_DIR" ]] && echo "✅ Да" || echo "❌ Нет")"
echo "  Доступна для записи: $([[ -w "$TEMP_DIR" ]] && echo "✅ Да" || echo "❌ Нет")"
echo

echo "🏁 Диагностика завершена"
