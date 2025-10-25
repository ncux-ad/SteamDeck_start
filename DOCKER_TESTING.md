# Docker Тестирование Steam Deck Enhancement Pack

## 🐳 Обзор

Этот документ описывает, как использовать Docker для тестирования Steam Deck Enhancement Pack в эмулированной среде SteamOS.

---

## 📋 Содержание

1. [Требования](#требования)
2. [Быстрый старт](#быстрый-старт)
3. [Сборка и запуск](#сборка-и-запуск)
4. [Тестирование](#тестирование)
5. [Отладка](#отладка)
6. [Устранение проблем](#устранение-проблем)

---

## 🔧 Требования

### Системные требования
- **Docker** 20.10+
- **Docker Compose** 2.0+
- **Git** (для клонирования)
- **X11** (для GUI тестирования, опционально)

### Проверка установки
```bash
# Проверка Docker
docker --version
docker-compose --version

# Проверка доступности
docker run hello-world
```

---

## 🚀 Быстрый старт

### 1. Клонирование и подготовка
```bash
# Клонируем репозиторий
git clone <repository-url>
cd SteamDeck

# Делаем скрипты исполняемыми
chmod +x scripts/*.sh
chmod +x test_steamdeck.sh
chmod +x docker-entrypoint.sh
```

### 2. Сборка Docker образа
```bash
# Сборка образа SteamOS эмуляции
docker-compose build steamdeck-emu
```

### 3. Запуск тестирования
```bash
# Автоматическое тестирование
docker-compose run --rm steamdeck-test

# Или интерактивный режим
docker-compose run --rm steamdeck-emu
```

---

## 🏗️ Сборка и запуск

### Сборка образа
```bash
# Сборка основного образа
docker build -t steamdeck-enhancement .

# Сборка через docker-compose
docker-compose build
```

### Запуск контейнеров

#### Интерактивный режим
```bash
# Запуск с интерактивным shell
docker-compose run --rm steamdeck-emu

# Доступные команды в контейнере:
# test     - Запустить тесты
# gui      - Запустить GUI
# setup    - Запустить setup
# shell    - Открыть shell
# exit     - Выход
```

#### GUI режим
```bash
# Запуск GUI (требует X11)
docker-compose run --rm steamdeck-gui

# Или с профилем
docker-compose --profile gui up steamdeck-gui
```

#### Автоматическое тестирование
```bash
# Запуск всех тестов
docker-compose run --rm steamdeck-test

# Или с профилем
docker-compose --profile test up steamdeck-test
```

---

## 🧪 Тестирование

### Локальное тестирование
```bash
# Запуск тестов на хосте
./test_steamdeck.sh
```

### Docker тестирование
```bash
# Полное тестирование в контейнере
docker-compose run --rm steamdeck-test

# Тестирование конкретного скрипта
docker-compose run --rm steamdeck-emu test
```

### Типы тестов

#### 1. **Синтаксические тесты**
- Проверка синтаксиса bash скриптов
- Проверка синтаксиса Python скриптов
- Проверка прав доступа

#### 2. **Функциональные тесты**
- Тестирование help команд
- Тестирование status команд
- Тестирование основных функций

#### 3. **Интеграционные тесты**
- Тестирование взаимодействия скриптов
- Тестирование GUI
- Тестирование в SteamOS окружении

#### 4. **Тесты безопасности**
- Проверка валидации входных данных
- Проверка безопасного выполнения команд
- Проверка прав доступа

---

## 🔍 Отладка

### Просмотр логов
```bash
# Логи контейнера
docker-compose logs steamdeck-emu

# Логи в реальном времени
docker-compose logs -f steamdeck-emu
```

### Вход в контейнер
```bash
# Интерактивный shell
docker-compose run --rm steamdeck-emu shell

# Или через docker exec
docker exec -it steamdeck-enhancement-test bash
```

### Отладка GUI
```bash
# Запуск с X11 forwarding
xhost +local:docker
docker-compose run --rm steamdeck-gui

# Проверка X11
docker-compose run --rm steamdeck-emu bash -c "echo \$DISPLAY"
```

---

## 🛠️ Устранение проблем

### Частые проблемы

#### 1. **GUI не запускается**
```bash
# Проблема: X11 не настроен
# Решение:
xhost +local:docker
export DISPLAY=:0
docker-compose run --rm steamdeck-gui
```

#### 2. **Ошибки прав доступа**
```bash
# Проблема: Файлы не исполняемые
# Решение:
chmod +x scripts/*.sh
chmod +x test_steamdeck.sh
chmod +x docker-entrypoint.sh
```

#### 3. **Контейнер не запускается**
```bash
# Проблема: Ошибки сборки
# Решение:
docker-compose down
docker-compose build --no-cache
docker-compose up
```

#### 4. **Тесты падают**
```bash
# Проблема: Зависимости не установлены
# Решение:
docker-compose run --rm steamdeck-emu bash -c "pip install --user psutil"
```

### Отладка Dockerfile
```bash
# Сборка с подробным выводом
docker build --progress=plain -t steamdeck-enhancement .

# Сборка без кэша
docker build --no-cache -t steamdeck-enhancement .
```

### Отладка docker-compose
```bash
# Проверка конфигурации
docker-compose config

# Подробный вывод
docker-compose up --verbose
```

---

## 📊 Результаты тестирования

### Пример успешного тестирования
```
=== STEAM DECK ENHANCEMENT PACK - АВТОМАТИЧЕСКОЕ ТЕСТИРОВАНИЕ ===

[TEST] Начало тестирования...

=== Проверка синтаксиса bash скриптов ===
[PASS] Синтаксис steamdeck_setup.sh
[PASS] Синтаксис steamdeck_backup.sh
[PASS] Синтаксис steamdeck_cleanup.sh
...

=== РЕЗУЛЬТАТЫ ТЕСТИРОВАНИЯ ===
[TEST] Всего тестов: 25
[PASS] Пройдено: 23
[WARN] Предупреждения: 2
[FAIL] Провалено: 0
[TEST] Процент успеха: 92%

[SUCCESS] ВСЕ ТЕСТЫ ПРОЙДЕНЫ УСПЕШНО! 🎉
```

### Интерпретация результатов
- **PASS** - Тест пройден успешно
- **WARN** - Тест пройден с предупреждениями (обычно для GUI в headless режиме)
- **FAIL** - Тест провален, требует исправления

---

## 🔧 Настройка окружения

### Переменные окружения
```bash
# В docker-compose.yml
environment:
  - STEAM_DECK=1
  - STEAMOS=1
  - DISPLAY=:0
  - HOME=/home/deck
  - USER=deck
```

### Монтирование томов
```yaml
volumes:
  - .:/home/deck/SteamDeck  # Исходный код
  - ./test-data:/home/deck/test-data  # Тестовые данные
  - ./test-results:/home/deck/test-results  # Результаты тестов
```

---

## 📚 Дополнительные ресурсы

### Полезные команды Docker
```bash
# Очистка контейнеров
docker-compose down --volumes --remove-orphans

# Пересборка образов
docker-compose build --no-cache

# Просмотр образов
docker images | grep steamdeck

# Удаление неиспользуемых образов
docker image prune -f
```

### Полезные команды тестирования
```bash
# Запуск конкретного теста
docker-compose run --rm steamdeck-emu bash -c "./scripts/steamdeck_setup.sh status"

# Проверка зависимостей
docker-compose run --rm steamdeck-emu bash -c "python3 -c 'import tkinter, psutil'"

# Тестирование GUI
docker-compose run --rm steamdeck-gui
```

---

*Документация обновлена: Октябрь 2025*
