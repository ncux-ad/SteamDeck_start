# Руководство по Native Linux играм для Steam Deck

## 🎮 Обзор Native Linux игр

Native Linux игры - это игры, которые изначально разработаны для Linux и не требуют эмуляции Windows. Многие из них поставляются в виде .sh скриптов, которые автоматически устанавливают и настраивают игру.

---

## 📋 Содержание

1. [Что такое Native Linux игры](#что-такое-native-linux-игры)
2. [Типы .sh скриптов](#типы-sh-скриптов)
3. [Автоматическая установка](#автоматическая-установка)
4. [Ручная установка](#ручная-установка)
5. [Добавление в Steam](#добавление-в-steam)
6. [Решение проблем](#решение-проблем)
7. [Популярные Native Linux игры](#популярные-native-linux-игры)

---

## 🎯 Что такое Native Linux игры

### Преимущества Native Linux игр

- **Лучшая производительность** - нет накладных расходов на эмуляцию
- **Нативная поддержка контроллеров** - работают без дополнительной настройки
- **Стабильность** - меньше проблем с совместимостью
- **Оптимизация для Linux** - используют системные библиотеки

### Типичные форматы

- **.sh скрипты** - автоматическая установка
- **AppImage** - портативные приложения
- **Flatpak** - через Discover
- **Скомпилированные бинарники** - готовые к запуску

---

## 📝 Типы .sh скриптов

### Установочные скрипты

**Характеристики:**
- Скачивают и устанавливают игру
- Настраивают зависимости
- Создают ярлыки запуска
- Обычно называются: `install.sh`, `setup.sh`

**Пример содержимого:**
```bash
#!/bin/bash
# Установка игры MyGame

echo "Установка MyGame..."

# Скачивание файлов
wget https://example.com/game.tar.gz

# Распаковка
tar -xzf game.tar.gz

# Установка зависимостей
sudo apt install libsdl2-2.0

# Создание ярлыка
ln -s /path/to/game/run.sh /usr/local/bin/mygame
```

### Запускающие скрипты

**Характеристики:**
- Запускают уже установленную игру
- Настраивают переменные окружения
- Обычно называются: `run.sh`, `start.sh`, `game.sh`

**Пример содержимого:**
```bash
#!/bin/bash
# Запуск игры MyGame

cd /path/to/game
export LD_LIBRARY_PATH=/path/to/game/libs:$LD_LIBRARY_PATH
./game.x86_64 "$@"
```

### Гибридные скрипты

**Характеристики:**
- Сначала проверяют установку
- Устанавливают при необходимости
- Запускают игру
- Обычно называются по имени игры

---

## 🚀 Автоматическая установка

### Использование скрипта Native Games

**Найти все .sh игры:**
```bash
./scripts/steamdeck_native_games.sh find
```

**Массовое добавление:**
```bash
./scripts/steamdeck_native_games.sh batch
```

**Анализ скрипта:**
```bash
./scripts/steamdeck_native_games.sh analyze /path/to/game.sh
```

**Установка конкретной игры:**
```bash
./scripts/steamdeck_native_games.sh install "My Game" /path/to/game.sh
```

### Настройка директорий

**Создание структуры:**
```bash
./scripts/steamdeck_native_games.sh setup
```

**Создаст:**
```
~/Games/
├── Native/     # Для .sh игр
├── Windows/    # Для Windows игр
├── Emulators/  # Для эмуляторов
└── Launchers/  # Для лаунчеров
```

### Через Steam Shortcuts

**Интерактивное меню:**
```bash
./scripts/steamdeck_shortcuts.sh
# Выберите "6) Найти Native Linux игры (.sh)"
```

**Прямое добавление:**
```bash
./scripts/steamdeck_shortcuts.sh native-games
```

---

## 🔧 Ручная установка

### Подготовка

1. **Создайте директорию для игры:**
   ```bash
   mkdir -p ~/Games/Native/MyGame
   cd ~/Games/Native/MyGame
   ```

2. **Скачайте .sh скрипт:**
   ```bash
   wget https://example.com/game.sh
   chmod +x game.sh
   ```

3. **Проанализируйте скрипт:**
   ```bash
   cat game.sh | head -20
   ```

### Установка

1. **Запустите скрипт:**
   ```bash
   ./game.sh
   ```

2. **Следуйте инструкциям:**
   - Введите пароль при необходимости
   - Выберите опции установки
   - Дождитесь завершения

3. **Проверьте результат:**
   ```bash
   ls -la
   find . -name "*.x86_64" -o -name "*.bin" -o -name "*.run"
   ```

### Настройка для Steam

1. **Найдите исполняемый файл:**
   ```bash
   find . -type f -executable | grep -v ".sh"
   ```

2. **Создайте обертку (если нужно):**
   ```bash
   cat > steam_wrapper.sh << 'EOF'
   #!/bin/bash
   cd /home/deck/Games/Native/MyGame
   exec ./game.x86_64 "$@"
   EOF
   chmod +x steam_wrapper.sh
   ```

---

## 🎯 Добавление в Steam

### Через Steam UI

1. **Откройте Steam в режиме рабочего стола**
2. **Games → Add a Non-Steam Game to My Library**
3. **Browse → выберите .sh файл или исполняемый файл**
4. **Настройте параметры:**
   - Название игры
   - Обложка (опционально)
   - Параметры запуска

### Через скрипт

**Добавить конкретную игру:**
```bash
./scripts/steamdeck_shortcuts.sh create "My Game" "/path/to/game.sh"
```

**Добавить исполняемый файл:**
```bash
./scripts/steamdeck_shortcuts.sh create "My Game" "/path/to/game.x86_64"
```

### Настройка параметров запуска

**Для .sh скриптов:**
```
%command%
```

**Для исполняемых файлов:**
```
%command% --fullscreen --windowed
```

**С переменными окружения:**
```
LD_LIBRARY_PATH=/path/to/libs:%command%
```

---

## 🔧 Решение проблем

### Игра не запускается

**Проверьте права:**
```bash
chmod +x game.sh
chmod +x game.x86_64
```

**Проверьте зависимости:**
```bash
ldd game.x86_64
```

**Установите недостающие библиотеки:**
```bash
sudo pacman -S lib32-sdl2 lib32-opengl
```

### Ошибки при установке

**Проверьте скрипт:**
```bash
bash -x game.sh
```

**Установите зависимости вручную:**
```bash
sudo pacman -S base-devel git
```

**Проверьте свободное место:**
```bash
df -h
```

### Проблемы с контроллером

**Включите Steam Input:**
1. Правый клик на игре в Steam
2. **Properties → Controller**
3. **Enable Steam Input**

**Настройте раскладку:**
1. Запустите игру
2. Нажмите Steam + X
3. Настройте кнопки

### Проблемы с производительностью

**Настройте TDP:**
```bash
./scripts/steamdeck_optimizer.sh game indie
```

**Проверьте использование ресурсов:**
```bash
./scripts/steamdeck_monitor.sh realtime 2
```

---

## 🎮 Популярные Native Linux игры

### Бесплатные игры

**SuperTuxKart:**
```bash
# Установка через pacman
sudo pacman -S supertuxkart

# Или через Flatpak
flatpak install flathub net.supertuxkart.SuperTuxKart
```

**0 A.D.:**
```bash
# Установка через pacman
sudo pacman -S 0ad

# Или через Flatpak
flatpak install flathub com.play0ad.zeroad
```

**OpenTTD:**
```bash
# Установка через pacman
sudo pacman -S openttd

# Или через Flatpak
flatpak install flathub org.openttd.OpenTTD
```

### Коммерческие игры

**Hollow Knight:**
- Доступен в Steam
- Отличная производительность на Steam Deck
- Поддержка контроллеров

**Celeste:**
- Доступен в Steam
- Идеально подходит для портативного геймплея
- Низкое потребление батареи

**Stardew Valley:**
- Доступен в Steam
- Отлично работает с сенсорным экраном
- Долгое время работы от батареи

### Инди-игры

**A Hat in Time:**
- Доступен в Steam
- Хорошая производительность
- Поддержка модов

**Cuphead:**
- Доступен в Steam
- Отличная графика
- Сложный геймплей

---

## 📚 Полезные ресурсы

### Официальные сайты
- [Steam Linux Games](https://store.steampowered.com/linux/)
- [GOG Linux](https://www.gog.com/games?system=linux)
- [Humble Bundle](https://www.humblebundle.com/)

### Сообщество
- [r/linux_gaming](https://reddit.com/r/linux_gaming)
- [Steam Deck Reddit](https://reddit.com/r/SteamDeck)
- [Linux Gaming Discord](https://discord.gg/linuxgaming)

### Инструменты
- **Steam Deck Native Games Script** - автоматизация
- **Steam ROM Manager** - управление играми
- **ProtonDB** - совместимость игр

---

## ⚖️ Правовая информация

### Лицензии

**Бесплатные игры:**
- Обычно с открытым исходным кодом
- Можно свободно распространять
- Могут требовать атрибуции

**Коммерческие игры:**
- Требуют покупки лицензии
- Ограничения на распространение
- Соблюдение EULA

### Рекомендации

- **Покупайте игры легально** - поддерживайте разработчиков
- **Читайте лицензии** - соблюдайте условия использования
- **Делайте резервные копии** - сохраняйте установочные файлы

---

## 💡 Советы и рекомендации

### Оптимизация производительности

1. **Используйте профили производительности:**
   ```bash
   ./scripts/steamdeck_optimizer.sh profile BALANCED
   ```

2. **Настройте TDP под игру:**
   - Инди-игры: 5W
   - Современные игры: 10W
   - AAA игры: 15W

3. **Используйте FSR для масштабирования:**
   - Включите в настройках Steam Deck
   - Выберите подходящий уровень качества

### Управление играми

1. **Организуйте по папкам:**
   ```
   ~/Games/
   ├── Native/
   │   ├── Indie/
   │   ├── AAA/
   │   └── Retro/
   ```

2. **Создавайте резервные копии:**
   ```bash
   ./scripts/steamdeck_backup.sh
   ```

3. **Используйте обложки:**
   - Скачивайте с Steam Grid DB
   - Создавайте собственные

### Устранение неполадок

1. **Проверяйте логи:**
   ```bash
   journalctl -f
   ```

2. **Тестируйте в терминале:**
   ```bash
   ./game.sh 2>&1 | tee game.log
   ```

3. **Используйте мониторинг:**
   ```bash
   ./scripts/steamdeck_monitor.sh realtime 5
   ```

---

*Руководство обновлено: Октябрь 2025*
