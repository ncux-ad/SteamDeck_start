# Steam Deck Offline Quick Start Guide

## 🚀 Быстрый старт для offline-режима

**Дата:** 25 октября 2025  
**Версия:** 2.0

---

## ⚡ Быстрая настройка (5 минут)

### 1. **Автоматическая настройка**
```bash
# Запуск автоматической настройки offline-режима
./scripts/steamdeck_offline_setup.sh
```

### 2. **Запуск главного меню**
```bash
# Запуск интерактивного меню offline-утилит
~/SteamDeck_Offline/offline_menu.sh
```

### 3. **Запуск Steam в offline-режиме**
```bash
# Запуск Steam с оптимизацией для offline
~/SteamDeck_Offline/launch_steam_offline.sh
```

---

## 🎯 Основные трюки для offline-режима

### **Экономия батареи**
```bash
# Активация профиля экономии батареи
~/.steamdeck_profiles/battery_saver.sh

# Отключение Wi-Fi и Bluetooth
sudo rfkill block wifi
sudo rfkill block bluetooth

# Уменьшение яркости
echo 40 | sudo tee /sys/class/backlight/amdgpu_bl0/brightness
```

### **Максимальная производительность**
```bash
# Активация профиля максимальной производительности
~/.steamdeck_profiles/max_performance.sh

# Очистка памяти перед игрой
~/SteamDeck_Offline/free_memory.sh
```

### **Управление играми**
```bash
# Бэкап сохранений
~/SteamDeck_Offline/backup_saves.sh

# Создание ярлыков для игр
find ~/.steam/steam/steamapps/common -maxdepth 1 -type d | while read game_dir; do
    game_name=$(basename "$game_dir")
    if [[ "$game_name" != "common" ]]; then
        echo "#!/bin/bash" > "$HOME/SteamDeck_Offline/Games/${game_name}.sh"
        echo "cd \"$game_dir\"" >> "$HOME/SteamDeck_Offline/Games/${game_name}.sh"
        echo "./${game_name}.sh" >> "$HOME/SteamDeck_Offline/Games/${game_name}.sh"
        chmod +x "$HOME/SteamDeck_Offline/Games/${game_name}.sh"
    fi
done
```

---

## 📱 Полезные команды

### **Система**
```bash
# Проверка статуса батареи
cat /sys/class/power_supply/BAT0/capacity

# Проверка температуры
sensors

# Мониторинг памяти
htop

# Статистика диска
df -h
```

### **Steam**
```bash
# Запуск Steam в offline-режиме
steam --offline

# Список установленных игр
steam --list-installed

# Запуск конкретной игры
steam --applaunch <app_id>
```

### **Медиа**
```bash
# Запуск VLC
vlc

# Запуск RetroArch
retroarch

# Сканирование медиа-библиотеки
~/SteamDeck_Offline/manage_media.sh scan
```

---

## 🔧 Профили производительности

### **Доступные профили:**
- **max_performance.sh** - Максимальная производительность
- **balanced.sh** - Баланс производительности и батареи
- **battery_saver.sh** - Экономия батареи
- **offline.sh** - Оптимизация для offline-режима

### **Автоматический выбор профиля:**
```bash
# Автоматический выбор профиля на основе условий
~/SteamDeck_Offline/auto_profile_switch.sh
```

---

## 💾 Резервное копирование

### **Быстрый бэкап:**
```bash
# Бэкап сохранений
~/SteamDeck_Offline/backup_saves.sh

# Бэкап медиа
~/SteamDeck_Offline/manage_media.sh backup

# Бэкап ROM-ов
~/SteamDeck_Offline/manage_roms.sh backup
```

### **Восстановление:**
```bash
# Восстановление сохранений
cp -r /path/to/backup/* ~/.steam/steam/userdata/

# Восстановление медиа
~/SteamDeck_Offline/manage_media.sh restore

# Восстановление ROM-ов
~/SteamDeck_Offline/manage_roms.sh restore
```

---

## 🎮 Эмуляция и ретро-игры

### **Настройка RetroArch:**
```bash
# Запуск RetroArch
retroarch

# Организация ROM-ов по системам
~/SteamDeck_Offline/manage_roms.sh organize
```

### **Поддерживаемые системы:**
- NES, SNES, GameBoy, GameBoy Advance
- PlayStation, Nintendo 64
- И многие другие через ядра RetroArch

---

## 📺 Медиа и развлечения

### **Управление медиа:**
```bash
# Сканирование медиа-библиотеки
~/SteamDeck_Offline/manage_media.sh scan

# Организация медиа по типам
~/SteamDeck_Offline/manage_media.sh organize

# Запуск VLC
vlc ~/SteamDeck_Offline/Media/
```

### **Поддерживаемые форматы:**
- **Видео:** MP4, MKV, AVI, MOV
- **Аудио:** MP3, FLAC, WAV, OGG
- **Книги:** PDF, EPUB, MOBI

---

## ⚠️ Важные советы

### **Перед offline-режимом:**
1. ✅ Скачайте все игры и обновления
2. ✅ Создайте бэкап сохранений
3. ✅ Настройте профили производительности
4. ✅ Подготовьте медиа-контент

### **Во время offline-режима:**
1. 🔋 Следите за уровнем батареи
2. 🌡️ Контролируйте температуру
3. 💾 Регулярно создавайте бэкапы
4. 🎮 Используйте подходящие профили

### **После offline-режима:**
1. 🔄 Синхронизируйте сохранения
2. 📱 Обновите игры при наличии интернета
3. 💾 Создайте финальный бэкап
4. 🔧 Проверьте состояние системы

---

## 🆘 Решение проблем

### **Проблема: Низкая производительность**
```bash
# Решение: Очистка памяти и активация профиля производительности
~/SteamDeck_Offline/free_memory.sh
~/.steamdeck_profiles/max_performance.sh
```

### **Проблема: Быстрая разрядка батареи**
```bash
# Решение: Активация профиля экономии батареи
~/.steamdeck_profiles/battery_saver.sh
```

### **Проблема: Игры не запускаются**
```bash
# Решение: Проверка и восстановление сохранений
~/SteamDeck_Offline/backup_saves.sh
```

### **Проблема: Медиа не воспроизводится**
```bash
# Решение: Установка медиа-плеера и проверка форматов
sudo pacman -S vlc
~/SteamDeck_Offline/manage_media.sh scan
```

---

## 📚 Дополнительные ресурсы

### **Документация:**
- `steamdeck_offline_tricks.md` - Полное руководство по offline-трюкам
- `steamdeck_offline_setup.sh` - Автоматический скрипт настройки
- `steamdeck_offline_menu.sh` - Интерактивное меню утилит

### **Директории:**
- `~/SteamDeck_Offline/` - Основная директория offline-утилит
- `~/.steamdeck_profiles/` - Профили производительности
- `~/SteamDeck_Offline/Media/` - Медиа-библиотека
- `~/SteamDeck_Offline/ROMs/` - ROM-ы для эмуляторов

---

## 🎉 Заключение

**Steam Deck Offline Mode** предоставляет полную автономность для игр и развлечений без интернета. Используйте профили производительности, управляйте медиа-контентом и создавайте регулярные бэкапы для максимального комфорта в offline-режиме.

**Удачной игры!** 🎮

---

*Руководство создано: 25 октября 2025*
