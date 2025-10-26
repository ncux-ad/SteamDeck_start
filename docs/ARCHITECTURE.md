# Архитектура Steam Deck Enhancement Pack

## Обзор

Steam Deck Enhancement Pack - это комплексная утилита для управления и настройки Steam Deck, состоящая из модульных bash-скриптов и PyQt6 GUI.

## Структура проекта

```
SteamDeck/
├── lib/                    # Модульная библиотека
│   ├── core.sh            # Главная загрузка модулей
│   ├── common.sh          # Общие функции
│   ├── logging.sh         # Логирование
│   ├── validation.sh      # Валидация
│   └── proton_utils.sh    # Proton/Wine утилиты
├── scripts/               # Executable скрипты
│   ├── steamdeck_update.sh
│   ├── steamdeck_native_games.sh
│   └── steamdeck_steamrip.sh
├── gui/                   # PyQt6 GUI
│   ├── core/             # Core модули
│   ├── widgets/          # Виджеты
│   ├── views/            # Вкладки
│   └── utils/            # Утилиты
└── tests/                # Тесты
```

## Архитектурные принципы

### 1. Модульность

Каждый модуль в `lib/` отвечает за определенную область:
- **core.sh**: Загрузка всех модулей
- **common.sh**: Общие функции (print, paths)
- **logging.sh**: Централизованное логирование
- **validation.sh**: Валидация путей, окружения
- **proton_utils.sh**: Работа с Proton и Wine

### 2. Separation of Concerns

- **Lib**: Бизнес-логика, независимая от UI
- **Scripts**: CLI интерфейс
- **GUI**: Визуальный интерфейс

### 3. Dependency Injection

Все скрипты загружают `lib/core.sh`, который предоставляет доступ ко всем модулям.

## Потоки данных

### Обновление

```
GUI → UpdateView → ScriptRunner → steamdeck_update.sh
                                    ↓
                                 lib/core.sh
                                    ↓
                               GitHub API
```

### Установка игр

```
GUI → GamesView → ScriptRunner → steamdeck_native_games.sh
                                       ↓
                                    lib/core.sh
                                       ↓
                                Файловая система
```

## Обработка ошибок

1. **Строгий режим**: `set -euo pipefail`
2. **Логирование**: Все ошибки в `~/.steamdeck_logs/`
3. **Rollback**: Автоматический откат при ошибках
4. **Graceful degradation**: Fallback на альтернативные методы

## Безопасность

- Валидация всех путей
- Проверка прав доступа
- Проверка чек-сумм при обновлениях
- Изоляция процессов
