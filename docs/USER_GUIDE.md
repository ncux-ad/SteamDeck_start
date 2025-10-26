# Руководство пользователя Steam Deck Enhancement Pack

## Быстрый старт

### 1. Установка

```bash
# Склонировать репозиторий
git clone https://github.com/ncux-ad/SteamDeck_start.git
cd SteamDeck_start

# Установить зависимости
sudo pacman -S python-pyqt6 unrar p7zip wine
```

### 2. Запуск GUI

```bash
./run_gui.sh
```

## Основные функции

### Система

Вкладка **Система** показывает:
- Текущую версию утилиты
- Информацию об ОС
- Использование диска
- Статус сети

### Игры

Вкладка **Игры** позволяет:

#### Установка SH игр (Linux)
1. Нажмите кнопку "📋 SH игры (Linux)"
2. Выберите .sh скрипт игры
3. Игра будет установлена и добавлена в Steam

#### Установка RAR игр (Windows)
1. Нажмите кнопку "📦 RAR игры (Windows)"
2. Выберите .rar архив
3. Выберите директорию для распаковки
4. Игра будет распакована через Proton/Wine

### Обновления

Вкладка **Обновления**:
- Проверка наличия обновлений
- Установка обновлений
- Просмотр changelog

## CLI интерфейс

### Обновление

```bash
# Проверить обновления
./scripts/steamdeck_update.sh check

# Установить обновление
./scripts/steamdeck_update.sh update
```

### Установка игр

```bash
# SH игры
./scripts/steamdeck_native_games.sh interactive

# RAR игры
./scripts/steamdeck_steamrip.sh interactive
```

## Требования

- Steam Deck / Arch Linux
- Python 3.10+
- PyQt6
- unrar, p7zip
- Wine или Proton

## Решение проблем

### GUI не запускается

```bash
# Проверить PyQt6
python3 -c "import PyQt6"

# Установить если отсутствует
pip3 install PyQt6
```

### Игры не запускаются

1. Убедитесь, что Proton установлен
2. Проверьте логи в `~/.steamdeck_logs/`
3. Попробуйте запустить игру через Steam

### Проблемы с правами

```bash
# Исправить права
sudo chown -R deck:deck /home/deck/utils/SteamDeck
```
