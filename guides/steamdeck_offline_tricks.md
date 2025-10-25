# Steam Deck Offline Tricks & Cheats Guide

## 🎮 Обзор Offline-оптимизации

**Дата создания:** 25 октября 2025  
**Версия:** 2.0  
**Фокус:** Offline-режим и продвинутые трюки

---

## 📋 Содержание

1. [Offline-оптимизация Steam](#offline-оптимизация-steam)
2. [Управление играми без интернета](#управление-играми-без-интернета)
3. [Системные трюки](#системные-трюки)
4. [Производительность в offline](#производительность-в-offline)
5. [Резервное копирование для offline](#резервное-копирование-для-offline)
6. [Эмуляция и ретро-игры](#эмуляция-и-ретро-игры)
7. [Медиа и развлечения](#медиа-и-развлечения)
8. [Продвинутые настройки](#продвинутые-настройки)

---

## 🌐 Offline-оптимизация Steam

### Настройка Steam для offline-режима

#### **1. Предварительная подготовка**
```bash
# Скачивание всех обновлений перед offline
steam://open/console
# В консоли Steam:
download_depot <appid> <depotid> <manifestid>
```

#### **2. Настройка Steam для offline**
```bash
# Отключение автоматических обновлений
echo "AutoUpdateBehavior=0" >> ~/.steam/steam/config/config.vdf

# Отключение облачных сохранений (опционально)
echo "CloudEnabled=0" >> ~/.steam/steam/config/config.vdf

# Настройка кэширования
echo "DownloadThrottleKbps=0" >> ~/.steam/steam/config/config.vdf
```

#### **3. Создание offline-профиля**
```bash
# Скрипт для создания offline-профиля
cat > ~/steamdeck_offline_profile.sh << 'EOF'
#!/bin/bash
# Steam Deck Offline Profile Setup

# Создание профиля для offline-игры
PROFILE_NAME="Offline Gaming"
PROFILE_DIR="$HOME/.steam/steam/userdata/*/7/remote/sharedconfig.vdf"

# Настройки для offline-режима
steam --offline &
sleep 5
steam --shutdown

# Применение настроек
echo "Offline профиль создан: $PROFILE_NAME"
EOF

chmod +x ~/steamdeck_offline_profile.sh
```

### Управление играми в offline

#### **1. Массовое скачивание игр**
```bash
# Скрипт для скачивания всех игр из библиотеки
cat > ~/download_all_games.sh << 'EOF'
#!/bin/bash
# Download All Games Script

echo "Начинаем скачивание всех игр..."
steam --login <username> --password <password> --silent

# Получение списка игр
steam --list-games | while read appid name; do
    echo "Скачивание: $name ($appid)"
    steam --app-update $appid
done

echo "Скачивание завершено!"
EOF
```

#### **2. Синхронизация сохранений offline**
```bash
# Создание локального бэкапа сохранений
cat > ~/backup_saves_offline.sh << 'EOF'
#!/bin/bash
# Offline Save Backup Script

BACKUP_DIR="$HOME/SteamDeck_Offline_Backup/$(date +%Y%m%d)"
mkdir -p "$BACKUP_DIR"

# Поиск всех сохранений
find ~/.steam/steam/userdata -name "remote" -type d | while read save_dir; do
    game_id=$(echo "$save_dir" | cut -d'/' -f6)
    echo "Копирование сохранений игры: $game_id"
    cp -r "$save_dir" "$BACKUP_DIR/game_$game_id"
done

echo "Сохранения скопированы в: $BACKUP_DIR"
EOF
```

---

## 🎯 Управление играми без интернета

### Создание портативной библиотеки

#### **1. Экспорт библиотеки игр**
```bash
# Скрипт экспорта библиотеки
cat > ~/export_game_library.sh << 'EOF'
#!/bin/bash
# Export Game Library Script

LIBRARY_FILE="$HOME/steam_library_offline.txt"
echo "Экспорт библиотеки игр..."

# Получение списка установленных игр
steam --list-installed > "$LIBRARY_FILE"

# Создание детального отчета
echo "=== STEAM DECK OFFLINE LIBRARY ===" > "$LIBRARY_FILE"
echo "Дата создания: $(date)" >> "$LIBRARY_FILE"
echo "Пользователь: $(whoami)" >> "$LIBRARY_FILE"
echo "" >> "$LIBRARY_FILE"

# Список игр с размерами
steam --list-installed | while read appid name; do
    size=$(du -sh ~/.steam/steam/steamapps/common/* 2>/dev/null | grep "$name" | cut -f1)
    echo "$appid | $name | $size" >> "$LIBRARY_FILE"
done

echo "Библиотека экспортирована: $LIBRARY_FILE"
EOF
```

#### **2. Создание ярлыков для offline-игр**
```bash
# Скрипт создания ярлыков
cat > ~/create_offline_shortcuts.sh << 'EOF'
#!/bin/bash
# Create Offline Game Shortcuts

GAMES_DIR="$HOME/Games/Offline"
mkdir -p "$GAMES_DIR"

# Создание ярлыков для каждой игры
steam --list-installed | while read appid name; do
    shortcut_file="$GAMES_DIR/${name// /_}.sh"
    
    cat > "$shortcut_file" << GAME_EOF
#!/bin/bash
# Offline Game Launcher: $name
# App ID: $appid

# Запуск игры в offline-режиме
steam --offline --applaunch $appid
GAME_EOF
    
    chmod +x "$shortcut_file"
    echo "Создан ярлык: $shortcut_file"
done

echo "Ярлыки созданы в: $GAMES_DIR"
EOF
```

### Управление DLC и модами

#### **1. Офлайн-установка модов**
```bash
# Скрипт для установки модов без интернета
cat > ~/install_mods_offline.sh << 'EOF'
#!/bin/bash
# Offline Mod Installation Script

MODS_DIR="$HOME/SteamDeck_Mods"
GAME_MODS_DIR="$HOME/.steam/steam/steamapps/common"

# Создание структуры для модов
mkdir -p "$MODS_DIR/ready_to_install"
mkdir -p "$MODS_DIR/installed"

echo "=== OFFLINE MOD MANAGER ==="
echo "1. Поместите .zip/.rar моды в: $MODS_DIR/ready_to_install"
echo "2. Запустите скрипт для установки"
echo "3. Установленные моды будут в: $MODS_DIR/installed"

# Функция установки мода
install_mod() {
    local mod_file="$1"
    local game_name="$2"
    
    echo "Установка мода: $(basename "$mod_file")"
    
    # Создание временной директории
    local temp_dir=$(mktemp -d)
    
    # Распаковка мода
    if [[ "$mod_file" == *.zip ]]; then
        unzip -q "$mod_file" -d "$temp_dir"
    elif [[ "$mod_file" == *.rar ]]; then
        unrar x "$mod_file" "$temp_dir" 2>/dev/null
    fi
    
    # Поиск игры
    local game_dir=$(find "$GAME_MODS_DIR" -name "*$game_name*" -type d | head -1)
    
    if [[ -n "$game_dir" ]]; then
        # Копирование файлов мода
        cp -r "$temp_dir"/* "$game_dir/"
        echo "Мод установлен в: $game_dir"
        
        # Перемещение в установленные
        mv "$mod_file" "$MODS_DIR/installed/"
    else
        echo "Игра не найдена: $game_name"
    fi
    
    # Очистка
    rm -rf "$temp_dir"
}

# Автоматическая установка всех модов
for mod_file in "$MODS_DIR/ready_to_install"/*; do
    if [[ -f "$mod_file" ]]; then
        # Попытка определить игру по имени файла
        game_name=$(basename "$mod_file" | cut -d'_' -f1)
        install_mod "$mod_file" "$game_name"
    fi
done
EOF
```

---

## ⚙️ Системные трюки

### Оптимизация для offline-режима

#### **1. Отключение ненужных сервисов**
```bash
# Скрипт отключения онлайн-сервисов
cat > ~/disable_online_services.sh << 'EOF'
#!/bin/bash
# Disable Online Services for Offline Mode

echo "Отключение онлайн-сервисов..."

# Отключение systemd-resolved (если не нужен)
sudo systemctl disable systemd-resolved 2>/dev/null || true

# Отключение NetworkManager (опционально)
# sudo systemctl disable NetworkManager 2>/dev/null || true

# Отключение автоматических обновлений
sudo systemctl disable pacman.timer 2>/dev/null || true

# Настройка Steam для offline
echo "AutoUpdateBehavior=0" >> ~/.steam/steam/config/config.vdf
echo "CloudEnabled=0" >> ~/.steam/steam/config/config.vdf

echo "Онлайн-сервисы отключены для offline-режима"
EOF
```

#### **2. Оптимизация батареи для offline**
```bash
# Скрипт оптимизации батареи
cat > ~/optimize_battery_offline.sh << 'EOF'
#!/bin/bash
# Battery Optimization for Offline Mode

echo "Оптимизация батареи для offline-режима..."

# Установка минимального TDP
echo 3 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true

# Отключение Wi-Fi для экономии батареи
sudo rfkill block wifi 2>/dev/null || true

# Отключение Bluetooth
sudo rfkill block bluetooth 2>/dev/null || true

# Настройка CPU governor для экономии
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Уменьшение яркости экрана
echo 50 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

echo "Батарея оптимизирована для offline-режима"
EOF
```

### Управление памятью

#### **1. Очистка памяти для игр**
```bash
# Скрипт очистки памяти
cat > ~/free_memory.sh << 'EOF'
#!/bin/bash
# Free Memory Script

echo "Очистка памяти перед запуском игры..."

# Очистка кэша страниц
sudo sync
echo 3 | sudo tee /proc/sys/vm/drop_caches

# Очистка swap
sudo swapoff -a
sudo swapon -a

# Очистка временных файлов
rm -rf /tmp/*
rm -rf ~/.cache/*

# Показ свободной памяти
echo "Свободная память:"
free -h

echo "Память очищена!"
EOF
```

---

## 🚀 Производительность в offline

### Настройки для максимальной производительности

#### **1. Профили производительности**
```bash
# Создание профилей производительности
cat > ~/steamdeck_performance_profiles.sh << 'EOF'
#!/bin/bash
# Steam Deck Performance Profiles

# Профиль "Максимальная производительность"
max_performance() {
    echo "Активация профиля: Максимальная производительность"
    
    # TDP на максимум
    echo 15 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
    
    # CPU governor на performance
    echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    
    # Отключение энергосбережения
    echo 0 | sudo tee /sys/devices/system/cpu/cpufreq/boost 2>/dev/null || true
    
    # Настройка GPU
    echo high | sudo tee /sys/class/drm/card0/device/power_dpm_force_performance_level 2>/dev/null || true
}

# Профиль "Баланс"
balanced() {
    echo "Активация профиля: Баланс"
    
    # TDP средний
    echo 10 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
    
    # CPU governor на schedutil
    echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
}

# Профиль "Экономия батареи"
battery_saver() {
    echo "Активация профиля: Экономия батареи"
    
    # TDP минимальный
    echo 3 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
    
    # CPU governor на powersave
    echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
    
    # Уменьшение яркости
    echo 30 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true
}

# Меню выбора профиля
case "${1:-menu}" in
    "max"|"performance")
        max_performance
        ;;
    "balanced"|"balance")
        balanced
        ;;
    "battery"|"saver")
        battery_saver
        ;;
    *)
        echo "Использование: $0 [max|balanced|battery]"
        echo "  max       - Максимальная производительность"
        echo "  balanced  - Баланс"
        echo "  battery   - Экономия батареи"
        ;;
esac
EOF
```

#### **2. Автоматическая оптимизация для игр**
```bash
# Скрипт автоматической оптимизации
cat > ~/auto_optimize_game.sh << 'EOF'
#!/bin/bash
# Auto Game Optimization Script

GAME_NAME="$1"
if [[ -z "$GAME_NAME" ]]; then
    echo "Использование: $0 <имя_игры>"
    exit 1
fi

echo "Оптимизация для игры: $GAME_NAME"

# Определение типа игры и применение настроек
case "$GAME_NAME" in
    *"Cyberpunk"*|*"Witcher"*|*"Elden Ring"*)
        echo "AAA игра - максимальная производительность"
        ~/steamdeck_performance_profiles.sh max
        ;;
    *"Indie"*|*"Pixel"*|*"Retro"*)
        echo "Инди игра - экономия батареи"
        ~/steamdeck_performance_profiles.sh battery
        ;;
    *)
        echo "Неизвестная игра - баланс"
        ~/steamdeck_performance_profiles.sh balanced
        ;;
esac

# Очистка памяти
~/free_memory.sh

echo "Оптимизация завершена!"
EOF
```

---

## 💾 Резервное копирование для offline

### Полное резервное копирование системы

#### **1. Создание полного бэкапа**
```bash
# Скрипт полного резервного копирования
cat > ~/full_offline_backup.sh << 'EOF'
#!/bin/bash
# Full Offline Backup Script

BACKUP_DIR="/run/media/mmcblk0p1/SteamDeck_Backup_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$BACKUP_DIR"

echo "Создание полного бэкапа Steam Deck..."

# 1. Бэкап Steam
echo "Копирование Steam..."
cp -r ~/.steam "$BACKUP_DIR/"

# 2. Бэкап игр
echo "Копирование игр..."
cp -r ~/.steam/steam/steamapps "$BACKUP_DIR/"

# 3. Бэкап сохранений
echo "Копирование сохранений..."
find ~/.steam/steam/userdata -name "remote" -type d | while read save_dir; do
    game_id=$(echo "$save_dir" | cut -d'/' -f6)
    cp -r "$save_dir" "$BACKUP_DIR/saves/game_$game_id"
done

# 4. Бэкап конфигураций
echo "Копирование конфигураций..."
cp -r ~/.config "$BACKUP_DIR/"
cp -r ~/.local "$BACKUP_DIR/"

# 5. Бэкап системы
echo "Копирование системных настроек..."
sudo cp -r /etc "$BACKUP_DIR/system/"

# 6. Создание архива
echo "Создание архива..."
cd "$BACKUP_DIR/.."
tar -czf "SteamDeck_Full_Backup_$(date +%Y%m%d).tar.gz" "$(basename "$BACKUP_DIR")"

echo "Бэкап создан: $BACKUP_DIR"
echo "Архив: SteamDeck_Full_Backup_$(date +%Y%m%d).tar.gz"
EOF
```

#### **2. Восстановление из бэкапа**
```bash
# Скрипт восстановления
cat > ~/restore_offline_backup.sh << 'EOF'
#!/bin/bash
# Restore Offline Backup Script

BACKUP_FILE="$1"
if [[ -z "$BACKUP_FILE" ]]; then
    echo "Использование: $0 <путь_к_архиву>"
    exit 1
fi

echo "Восстановление из бэкапа: $BACKUP_FILE"

# Создание временной директории
TEMP_DIR=$(mktemp -d)

# Распаковка архива
echo "Распаковка архива..."
tar -xzf "$BACKUP_FILE" -C "$TEMP_DIR"

# Восстановление Steam
echo "Восстановление Steam..."
rm -rf ~/.steam
cp -r "$TEMP_DIR"/*/steam ~/.steam

# Восстановление конфигураций
echo "Восстановление конфигураций..."
cp -r "$TEMP_DIR"/*/config ~/.config
cp -r "$TEMP_DIR"/*/local ~/.local

# Восстановление сохранений
echo "Восстановление сохранений..."
if [[ -d "$TEMP_DIR"/*/saves ]]; then
    cp -r "$TEMP_DIR"/*/saves/* ~/.steam/steam/userdata/
fi

# Очистка
rm -rf "$TEMP_DIR"

echo "Восстановление завершено!"
EOF
```

---

## 🎮 Эмуляция и ретро-игры

### Настройка эмуляторов для offline

#### **1. Установка RetroArch**
```bash
# Скрипт установки RetroArch
cat > ~/install_retroarch_offline.sh << 'EOF'
#!/bin/bash
# Install RetroArch for Offline Gaming

echo "Установка RetroArch для offline-игр..."

# Установка через pacman
sudo pacman -S retroarch --noconfirm

# Создание директорий
mkdir -p ~/RetroArch/roms
mkdir -p ~/RetroArch/saves
mkdir -p ~/RetroArch/screenshots

# Скачивание ядер (если есть интернет)
echo "Скачивание ядер эмуляторов..."
retroarch --list-cores > ~/RetroArch/available_cores.txt

# Настройка для Steam Deck
cat > ~/.config/retroarch/retroarch.cfg << 'RETROARCH_EOF'
# Steam Deck Optimized RetroArch Config
input_joypad_driver = sdl2
video_driver = vulkan
audio_driver = pulse
video_fullscreen = true
video_windowed_fullscreen = true
input_remapping_directory = ~/.config/retroarch/remaps
savefile_directory = ~/RetroArch/saves
screenshot_directory = ~/RetroArch/screenshots
system_directory = ~/RetroArch/system
EOF

echo "RetroArch установлен и настроен!"
EOF
```

#### **2. Управление ROM-ами**
```bash
# Скрипт управления ROM-ами
cat > ~/manage_roms.sh << 'EOF'
#!/bin/bash
# ROM Management Script

ROMS_DIR="$HOME/RetroArch/roms"
BACKUP_DIR="/run/media/mmcblk0p1/ROMs_Backup"

case "${1:-help}" in
    "backup")
        echo "Создание бэкапа ROM-ов..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$ROMS_DIR"/* "$BACKUP_DIR/"
        echo "ROM-ы скопированы в: $BACKUP_DIR"
        ;;
    "restore")
        echo "Восстановление ROM-ов..."
        if [[ -d "$BACKUP_DIR" ]]; then
            cp -r "$BACKUP_DIR"/* "$ROMS_DIR/"
            echo "ROM-ы восстановлены"
        else
            echo "Бэкап не найден: $BACKUP_DIR"
        fi
        ;;
    "organize")
        echo "Организация ROM-ов по системам..."
        for rom_file in "$ROMS_DIR"/*; do
            if [[ -f "$rom_file" ]]; then
                ext="${rom_file##*.}"
                case "$ext" in
                    "nes") system="NES" ;;
                    "snes") system="SNES" ;;
                    "gb") system="GameBoy" ;;
                    "gba") system="GameBoyAdvance" ;;
                    "psx") system="PlayStation" ;;
                    "n64") system="Nintendo64" ;;
                    *) system="Other" ;;
                esac
                mkdir -p "$ROMS_DIR/$system"
                mv "$rom_file" "$ROMS_DIR/$system/"
            fi
        done
        echo "ROM-ы организованы по системам"
        ;;
    *)
        echo "Использование: $0 [backup|restore|organize]"
        echo "  backup   - Создать бэкап ROM-ов"
        echo "  restore  - Восстановить ROM-ы"
        echo "  organize - Организовать ROM-ы по системам"
        ;;
esac
EOF
```

---

## 🎬 Медиа и развлечения

### Настройка медиа-плеера для offline

#### **1. Установка VLC**
```bash
# Скрипт установки медиа-плеера
cat > ~/install_media_player.sh << 'EOF'
#!/bin/bash
# Install Media Player for Offline Entertainment

echo "Установка медиа-плеера для offline-развлечений..."

# Установка VLC
sudo pacman -S vlc --noconfirm

# Создание медиа-библиотеки
MEDIA_DIR="$HOME/Media"
mkdir -p "$MEDIA_DIR"/{Movies,TV_Shows,Music,Podcasts,Books}

# Настройка VLC для Steam Deck
cat > ~/.config/vlc/vlcrc << 'VLC_EOF'
# Steam Deck VLC Configuration
[main]
intf=qt
qt-system-tray=0
qt-fs-controller=1
qt-minimal-view=1

[video]
fullscreen=1
video-on-top=0
video-deco=0

[audio]
volume=80
mute=0

[playlist]
playlist-tree-view=0
VLC_EOF

echo "Медиа-плеер установлен и настроен!"
echo "Медиа-библиотека: $MEDIA_DIR"
EOF
```

#### **2. Управление медиа-библиотекой**
```bash
# Скрипт управления медиа
cat > ~/manage_media.sh << 'EOF'
#!/bin/bash
# Media Library Management Script

MEDIA_DIR="$HOME/Media"
BACKUP_DIR="/run/media/mmcblk0p1/Media_Backup"

case "${1:-help}" in
    "scan")
        echo "Сканирование медиа-библиотеки..."
        find "$MEDIA_DIR" -type f \( -name "*.mp4" -o -name "*.mkv" -o -name "*.avi" -o -name "*.mp3" -o -name "*.flac" \) | while read file; do
            echo "Найден файл: $(basename "$file")"
        done
        ;;
    "backup")
        echo "Создание бэкапа медиа..."
        mkdir -p "$BACKUP_DIR"
        cp -r "$MEDIA_DIR"/* "$BACKUP_DIR/"
        echo "Медиа скопированы в: $BACKUP_DIR"
        ;;
    "restore")
        echo "Восстановление медиа..."
        if [[ -d "$BACKUP_DIR" ]]; then
            cp -r "$BACKUP_DIR"/* "$MEDIA_DIR/"
            echo "Медиа восстановлены"
        else
            echo "Бэкап не найден: $BACKUP_DIR"
        fi
        ;;
    "organize")
        echo "Организация медиа по типам..."
        find "$MEDIA_DIR" -type f | while read file; do
            ext="${file##*.}"
            case "$ext" in
                "mp4"|"mkv"|"avi"|"mov") 
                    mv "$file" "$MEDIA_DIR/Movies/"
                    ;;
                "mp3"|"flac"|"wav"|"ogg")
                    mv "$file" "$MEDIA_DIR/Music/"
                    ;;
                "pdf"|"epub"|"mobi")
                    mv "$file" "$MEDIA_DIR/Books/"
                    ;;
            esac
        done
        echo "Медиа организованы по типам"
        ;;
    *)
        echo "Использование: $0 [scan|backup|restore|organize]"
        echo "  scan     - Сканировать медиа-библиотеку"
        echo "  backup   - Создать бэкап медиа"
        echo "  restore  - Восстановить медиа"
        echo "  organize - Организовать медиа по типам"
        ;;
esac
EOF
```

---

## 🔧 Продвинутые настройки

### Создание пользовательских профилей

#### **1. Профили для разных сценариев**
```bash
# Скрипт создания профилей
cat > ~/create_gaming_profiles.sh << 'EOF'
#!/bin/bash
# Create Gaming Profiles Script

PROFILES_DIR="$HOME/.steamdeck_profiles"
mkdir -p "$PROFILES_DIR"

# Профиль "Домашний"
cat > "$PROFILES_DIR/home_profile.sh" << 'HOME_EOF'
#!/bin/bash
# Home Gaming Profile

echo "Активация домашнего профиля..."

# Максимальная производительность
echo 15 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Яркость на максимум
echo 100 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

# Включение Wi-Fi
sudo rfkill unblock wifi 2>/dev/null || true

echo "Домашний профиль активирован"
HOME_EOF

# Профиль "Путешествие"
cat > "$PROFILES_DIR/travel_profile.sh" << 'TRAVEL_EOF'
#!/bin/bash
# Travel Gaming Profile

echo "Активация профиля для путешествий..."

# Экономия батареи
echo 5 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
echo powersave | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Яркость средняя
echo 60 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

# Отключение Wi-Fi для экономии
sudo rfkill block wifi 2>/dev/null || true

echo "Профиль для путешествий активирован"
TRAVEL_EOF

# Профиль "Offline"
cat > "$PROFILES_DIR/offline_profile.sh" << 'OFFLINE_EOF'
#!/bin/bash
# Offline Gaming Profile

echo "Активация offline-профиля..."

# Баланс производительности и батареи
echo 10 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true

# Яркость средняя
echo 70 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness 2>/dev/null || true

# Отключение всех сетевых интерфейсов
sudo rfkill block wifi 2>/dev/null || true
sudo rfkill block bluetooth 2>/dev/null || true

# Запуск Steam в offline-режиме
steam --offline &

echo "Offline-профиль активирован"
OFFLINE_EOF

# Делаем профили исполняемыми
chmod +x "$PROFILES_DIR"/*.sh

echo "Профили созданы в: $PROFILES_DIR"
echo "Использование:"
echo "  $PROFILES_DIR/home_profile.sh    - Домашний"
echo "  $PROFILES_DIR/travel_profile.sh  - Путешествие"
echo "  $PROFILES_DIR/offline_profile.sh - Offline"
EOF
```

#### **2. Автоматическое переключение профилей**
```bash
# Скрипт автоматического переключения
cat > ~/auto_profile_switch.sh << 'EOF'
#!/bin/bash
# Auto Profile Switch Script

# Проверка подключения к сети
check_network() {
    if ping -c 1 8.8.8.8 &> /dev/null; then
        echo "online"
    else
        echo "offline"
    fi
}

# Проверка уровня батареи
check_battery() {
    local battery_level=$(cat /sys/class/power_supply/BAT0/capacity 2>/dev/null || echo "100")
    echo "$battery_level"
}

# Автоматический выбор профиля
auto_select_profile() {
    local network_status=$(check_network)
    local battery_level=$(check_battery)
    
    if [[ "$network_status" == "offline" ]]; then
        echo "Сеть недоступна - активация offline-профиля"
        ~/.steamdeck_profiles/offline_profile.sh
    elif [[ "$battery_level" -lt 30 ]]; then
        echo "Низкий заряд батареи - активация профиля для путешествий"
        ~/.steamdeck_profiles/travel_profile.sh
    else
        echo "Оптимальные условия - активация домашнего профиля"
        ~/.steamdeck_profiles/home_profile.sh
    fi
}

# Запуск автоматического выбора
auto_select_profile
EOF
```

---

## 🎯 Полезные чит-коды и трюки

### Секретные функции Steam Deck

#### **1. Скрытые настройки Steam**
```bash
# Скрипт активации скрытых функций
cat > ~/enable_hidden_features.sh << 'EOF'
#!/bin/bash
# Enable Hidden Steam Deck Features

echo "Активация скрытых функций Steam Deck..."

# Включение Developer Mode
echo "Включение Developer Mode..."
sudo steamos-readonly disable
sudo pacman-key --init
sudo pacman-key --populate archlinux

# Включение консоли Steam
echo "Включение консоли Steam..."
echo "EnableDevConsole=1" >> ~/.steam/steam/config/config.vdf

# Включение отладочной информации
echo "Включение отладочной информации..."
echo "EnableDebugMenu=1" >> ~/.steam/steam/config/config.vdf

# Включение экспериментальных функций
echo "Включение экспериментальных функций..."
echo "EnableExperimentalFeatures=1" >> ~/.steam/steam/config/config.vdf

# Настройка для разработчиков
echo "Настройка для разработчиков..."
echo "DeveloperMode=1" >> ~/.steam/steam/config/config.vdf

echo "Скрытые функции активированы!"
echo "Перезапустите Steam для применения изменений"
EOF
```

#### **2. Оптимизация для конкретных игр**
```bash
# Скрипт оптимизации для игр
cat > ~/optimize_specific_games.sh << 'EOF'
#!/bin/bash
# Optimize for Specific Games

GAME_NAME="$1"
if [[ -z "$GAME_NAME" ]]; then
    echo "Использование: $0 <имя_игры>"
    echo "Примеры:"
    echo "  $0 'Cyberpunk 2077'"
    echo "  $0 'Elden Ring'"
    echo "  $0 'The Witcher 3'"
    exit 1
fi

echo "Оптимизация для игры: $GAME_NAME"

case "$GAME_NAME" in
    *"Cyberpunk"*)
        echo "Настройка для Cyberpunk 2077..."
        # Специальные настройки для Cyberpunk
        echo 15 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
        echo performance | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        echo "Настройки Cyberpunk применены"
        ;;
    *"Elden Ring"*)
        echo "Настройка для Elden Ring..."
        # Специальные настройки для Elden Ring
        echo 12 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
        echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        echo "Настройки Elden Ring применены"
        ;;
    *"Witcher"*)
        echo "Настройка для The Witcher 3..."
        # Специальные настройки для Witcher
        echo 10 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
        echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        echo "Настройки Witcher применены"
        ;;
    *)
        echo "Неизвестная игра - применение стандартных настроек"
        echo 10 | sudo tee /sys/devices/platform/steamos-fan/hwmon/hwmon*/fan1_target 2>/dev/null || true
        echo schedutil | sudo tee /sys/devices/system/cpu/cpu*/cpufreq/scaling_governor 2>/dev/null || true
        ;;
esac

echo "Оптимизация завершена!"
EOF
```

---

## 📚 Заключение

### Ключевые преимущества offline-режима:

1. **Экономия батареи** - отключение сетевых интерфейсов
2. **Максимальная производительность** - фокус на играх
3. **Независимость от интернета** - полная автономность
4. **Безопасность** - отсутствие сетевых угроз
5. **Стабильность** - меньше системных процессов

### Рекомендации по использованию:

1. **Подготовка** - скачайте все игры и обновления заранее
2. **Резервное копирование** - создавайте бэкапы регулярно
3. **Профили** - используйте разные профили для разных сценариев
4. **Мониторинг** - следите за состоянием батареи и температуры
5. **Тестирование** - проверяйте настройки перед длительным offline-использованием

---

*Руководство создано: 25 октября 2025*
