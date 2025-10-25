# Steam Deck Enhancement Pack

## 🎮 Полный набор инструментов для Steam Deck

Этот пакет содержит все необходимые скрипты, руководства и утилиты для максимального использования возможностей Steam Deck. От базовой настройки до продвинутой оптимизации - все в одном месте.

---

## 📦 Что включено

### 🛠️ Скрипты автоматизации
- **steamdeck_setup.sh** - Подготовка системы к установке ПО
- **steamdeck_backup.sh** - Резервное копирование данных
- **steamdeck_cleanup.sh** - Очистка системы
- **steamdeck_monitor.sh** - Мониторинг производительности
- **steamdeck_optimizer.sh** - Оптимизация системы
- **steamdeck_install_apps.sh** - Установка приложений
- **steamdeck_shortcuts.sh** - Создание ярлыков в Steam
- **steamdeck_native_games.sh** - Работа с Native Linux играми (.sh)
- **steamdeck_offline_setup.sh** - Настройка для offline-режима
- **steamdeck_steamrip.sh** - Обработчик SteamRip-pack в RAR-файлах
- **steamdeck_gui.py** - Графический интерфейс для всех скриптов

### 📚 Подробные руководства
- **steamdeck_setup_guide.md** - Подготовка к установке ПО
- **steamdeck_windows_games_guide.md** - Запуск Windows-игр
- **steamdeck_native_games_guide.md** - Native Linux игры (.sh скрипты)
- **steamdeck_offline_tricks.md** - Offline-трюки и оптимизация
- **steamdeck_offline_quickstart.md** - Быстрый старт для offline-режима
- **steamdeck_gui_guide.md** - Графический интерфейс
- **steamdeck_emulators_guide.md** - Эмуляторы и ретро-игры
- **steamdeck_launchers_guide.md** - Альтернативные лаунчеры
- **steamdeck_performance_guide.md** - Оптимизация производительности
- **steamdeck_battery_guide.md** - Оптимизация батареи

---

## 🚀 Быстрый старт

### 1. Первоначальная настройка

```bash
# Сделайте скрипты исполняемыми
chmod +x scripts/*.sh

# Запустите первоначальную настройку
./scripts/steamdeck_setup.sh
```

### 2. Установка GUI (рекомендуется)

```bash
# Установка зависимостей для GUI
./scripts/install_gui_deps.sh

# Запуск графического интерфейса
python3 scripts/steamdeck_gui.py

# Добавление GUI в Steam
./scripts/add_gui_to_steam.sh
```

### 3. Установка популярных приложений

```bash
# Интерактивная установка
./scripts/steamdeck_install_apps.sh

# Быстрая установка популярных
./scripts/steamdeck_install_apps.sh quick
```

### 3. Оптимизация системы

```bash
# Настройка профилей производительности
./scripts/steamdeck_optimizer.sh setup

# Применение профиля для батареи
./scripts/steamdeck_optimizer.sh battery
```

### 4. Работа с Native Linux играми

```bash
# Найти все .sh игры
./scripts/steamdeck_native_games.sh find

# Массовое добавление игр
./scripts/steamdeck_native_games.sh batch

# Анализ скрипта игры
./scripts/steamdeck_native_games.sh analyze /path/to/game.sh
```

### 5. Настройка offline-режима

```bash
# Автоматическая настройка offline-режима
./scripts/steamdeck_offline_setup.sh

# Запуск главного меню offline-утилит
~/SteamDeck_Offline/offline_menu.sh

# Запуск Steam в offline-режиме
~/SteamDeck_Offline/launch_steam_offline.sh
```

### 6. Создание резервной копии

```bash
# Создание полного бэкапа
./scripts/steamdeck_backup.sh

# Просмотр существующих бэкапов
./scripts/steamdeck_backup.sh list
```

---

## 📁 Структура проекта

```
SteamDeck/
├── README.md                           # Этот файл
├── scripts/                            # Скрипты автоматизации
│   ├── steamdeck_setup.sh             # Подготовка системы
│   ├── steamdeck_backup.sh            # Резервное копирование
│   ├── steamdeck_cleanup.sh           # Очистка системы
│   ├── steamdeck_monitor.sh           # Мониторинг
│   ├── steamdeck_optimizer.sh         # Оптимизация
│   ├── steamdeck_install_apps.sh      # Установка приложений
│   ├── steamdeck_shortcuts.sh         # Ярлыки Steam
│   ├── steamdeck_native_games.sh      # Native Linux игры
│   ├── steamdeck_gui.py               # Графический интерфейс
│   ├── install_gui_deps.sh            # Установка зависимостей GUI
│   └── add_gui_to_steam.sh            # Добавление GUI в Steam
├── guides/                             # Подробные руководства
│   ├── steamdeck_setup_guide.md       # Подготовка к установке ПО
│   ├── steamdeck_windows_games_guide.md # Windows-игры
│   ├── steamdeck_native_games_guide.md # Native Linux игры
│   ├── steamdeck_emulators_guide.md   # Эмуляторы
│   ├── steamdeck_launchers_guide.md   # Лаунчеры
│   ├── steamdeck_performance_guide.md # Производительность
│   └── steamdeck_battery_guide.md     # Батарея
└── configs/                           # Конфигурационные файлы
    └── (создаются автоматически)
```

---

## 🎯 Основные возможности

### 🔧 Автоматизация
- **Полная настройка системы** одним скриптом
- **Резервное копирование** важных данных
- **Очистка системы** для освобождения места
- **Мониторинг** производительности в реальном времени

### ⚡ Оптимизация
- **Профили производительности** для разных типов игр
- **Настройка TDP** и частот GPU/CPU
- **Оптимизация батареи** для максимального времени работы
- **Автоматическая настройка** для популярных игр

### 🎮 Игры и приложения
- **Установка эмуляторов** (RetroArch, Yuzu, Dolphin)
- **Альтернативные лаунчеры** (Heroic, Lutris, Bottles)
- **Windows-игры** через Proton и Wine
- **Архиваторы** для работы с RAR-файлами

### 📊 Мониторинг
- **Температура** CPU и GPU
- **Использование** памяти и диска
- **Состояние батареи** и время работы
- **Производительность** в реальном времени

---

## 🛠️ Скрипты по категориям

### Системные скрипты

**steamdeck_setup.sh** - Подготовка системы
```bash
./scripts/steamdeck_setup.sh          # Полная настройка
./scripts/steamdeck_setup.sh disable  # Отключить readonly
./scripts/steamdeck_setup.sh enable   # Включить readonly
./scripts/steamdeck_setup.sh status   # Показать статус
```

**steamdeck_backup.sh** - Резервное копирование
```bash
./scripts/steamdeck_backup.sh                    # Создать бэкап
./scripts/steamdeck_backup.sh restore backup.tar.gz # Восстановить
./scripts/steamdeck_backup.sh list               # Список бэкапов
./scripts/steamdeck_backup.sh cleanup 7          # Очистка старых
```

**steamdeck_cleanup.sh** - Очистка системы
```bash
./scripts/steamdeck_cleanup.sh full    # Полная очистка
./scripts/steamdeck_cleanup.sh safe    # Безопасная очистка
./scripts/steamdeck_cleanup.sh steam   # Очистка Steam
./scripts/steamdeck_cleanup.sh disk    # Статистика диска
```

### Скрипты оптимизации

**steamdeck_optimizer.sh** - Оптимизация системы
```bash
./scripts/steamdeck_optimizer.sh setup                    # Настройка
./scripts/steamdeck_optimizer.sh profile PERFORMANCE      # Профиль
./scripts/steamdeck_optimizer.sh game cyberpunk          # Для игры
./scripts/steamdeck_optimizer.sh battery                 # Для батареи
./scripts/steamdeck_optimizer.sh status                  # Статус
```

**steamdeck_monitor.sh** - Мониторинг
```bash
./scripts/steamdeck_monitor.sh                    # Вся информация
./scripts/steamdeck_monitor.sh realtime 5         # Реальное время
./scripts/steamdeck_monitor.sh export report.txt  # Экспорт
./scripts/steamdeck_monitor.sh battery            # Батарея
```

### Скрипты приложений

**steamdeck_install_apps.sh** - Установка приложений
```bash
./scripts/steamdeck_install_apps.sh              # Интерактивное меню
./scripts/steamdeck_install_apps.sh quick        # Быстрая установка
./scripts/steamdeck_install_apps.sh emulators    # Эмуляторы
./scripts/steamdeck_install_apps.sh archivers    # Архиваторы
./scripts/steamdeck_install_apps.sh check        # Проверка
```

**steamdeck_shortcuts.sh** - Ярлыки Steam
```bash
./scripts/steamdeck_shortcuts.sh                    # Интерактивное меню
./scripts/steamdeck_shortcuts.sh popular            # Популярные
./scripts/steamdeck_shortcuts.sh create "App" "/path" # Создать
./scripts/steamdeck_shortcuts.sh backup             # Резервная копия
```

### Offline-режим

**steamdeck_offline_setup.sh** - Настройка offline-режима
```bash
./scripts/steamdeck_offline_setup.sh                # Полная настройка
./scripts/steamdeck_offline_setup.sh menu           # Главное меню
./scripts/steamdeck_offline_setup.sh steam          # Запуск Steam offline
```

### SteamRip-pack

**steamdeck_steamrip.sh** - Обработчик SteamRip-pack в RAR-файлах
```bash
./scripts/steamdeck_steamrip.sh setup               # Настройка и установка зависимостей
./scripts/steamdeck_steamrip.sh find                # Поиск RAR файлов SteamRip
./scripts/steamdeck_steamrip.sh analyze game.rar    # Анализ RAR файла
./scripts/steamdeck_steamrip.sh extract game.rar    # Распаковка RAR файла
./scripts/steamdeck_steamrip.sh batch               # Массовая обработка RAR файлов
```

**Offline-утилиты**
```bash
~/SteamDeck_Offline/offline_menu.sh                 # Главное меню
~/SteamDeck_Offline/launch_steam_offline.sh         # Запуск Steam
~/.steamdeck_profiles/max_performance.sh            # Максимальная производительность
~/.steamdeck_profiles/battery_saver.sh              # Экономия батареи
~/SteamDeck_Offline/free_memory.sh                  # Очистка памяти
~/SteamDeck_Offline/backup_saves.sh                 # Бэкап сохранений
```

---

## 📚 Руководства

### Базовые руководства

**[steamdeck_setup_guide.md](guides/steamdeck_setup_guide.md)**
- Подготовка системы к установке ПО
- Современные безопасные методы (Flatpak, Discover)
- Традиционные методы (pacman, AUR)
- Установка Wine, ProtonTricks, ProtonUp-Qt

**[steamdeck_windows_games_guide.md](guides/steamdeck_windows_games_guide.md)**
- Запуск Windows-игр через Proton
- Настройка совместимости
- Использование Wine и Bottles
- Решение проблем

**[steamdeck_offline_tricks.md](guides/steamdeck_offline_tricks.md)**
- Полное руководство по offline-режиму
- Offline-оптимизация Steam
- Управление играми без интернета
- Системные трюки и оптимизация
- Резервное копирование для offline
- Эмуляция и ретро-игры
- Медиа и развлечения

**[steamdeck_offline_quickstart.md](guides/steamdeck_offline_quickstart.md)**
- Быстрый старт для offline-режима
- Основные команды и трюки
- Профили производительности
- Решение проблем

### Специализированные руководства

**[steamdeck_emulators_guide.md](guides/steamdeck_emulators_guide.md)**
- EmuDeck - автоматическая настройка
- RetroArch - универсальный эмулятор
- Современные консоли (Switch, PS2, GameCube)
- Настройка BIOS и ROM-ов

**[steamdeck_launchers_guide.md](guides/steamdeck_launchers_guide.md)**
- Heroic Games Launcher (Epic/GOG)
- Lutris - универсальный менеджер
- Bottles - Wine-контейнеры
- NonSteamLaunchers - автоматическая установка

### Руководства по оптимизации

**[steamdeck_performance_guide.md](guides/steamdeck_performance_guide.md)**
- Настройка TDP и частот
- Управление FPS и разрешением
- FSR и масштабирование
- Профили производительности

**[steamdeck_battery_guide.md](guides/steamdeck_battery_guide.md)**
- Настройки энергосбережения
- Профили энергопотребления
- Уход за батареей
- Мониторинг батареи

---

## 🔧 Установка и настройка

### Требования
- Steam Deck с SteamOS 3.0+
- Доступ к режиму рабочего стола
- Интернет-соединение
- Минимум 1GB свободного места

### Первоначальная установка

1. **Скачивание:**
   ```bash
   git clone https://github.com/your-repo/steamdeck-enhancement-pack.git
   cd steamdeck-enhancement-pack
   ```

2. **Установка прав:**
   ```bash
   chmod +x scripts/*.sh
   ```

3. **Первоначальная настройка:**
   ```bash
   ./scripts/steamdeck_setup.sh
   ```

4. **Установка приложений:**
   ```bash
   ./scripts/steamdeck_install_apps.sh quick
   ```

### Обновление

```bash
git pull origin main
chmod +x scripts/*.sh
```

---

## 🎮 Популярные сценарии использования

### Для новичков
1. Запустите `./scripts/steamdeck_setup.sh`
2. Установите приложения через `./scripts/steamdeck_install_apps.sh`
3. Создайте резервную копию `./scripts/steamdeck_backup.sh`
4. Изучите руководства в папке `guides/`

### Для геймеров
1. Настройте профили производительности
2. Установите эмуляторы и лаунчеры
3. Оптимизируйте для конкретных игр
4. Настройте мониторинг производительности

### Для продвинутых пользователей
1. Настройте автоматические бэкапы
2. Создайте собственные профили оптимизации
3. Настройте мониторинг в реальном времени
4. Интегрируйте с внешними инструментами

---

## 🆘 Поддержка и помощь

### Часто задаваемые вопросы

**Q: Безопасно ли использовать эти скрипты?**
A: Да, все скрипты созданы с учетом безопасности и включают проверки. Рекомендуется сначала изучить код.

**Q: Можно ли отменить изменения?**
A: Да, большинство скриптов поддерживают откат изменений. Создавайте резервные копии перед изменениями.

**Q: Совместимо ли с обновлениями SteamOS?**
A: Да, скрипты обновляются для совместимости с новыми версиями SteamOS.

### Получение помощи

1. **Изучите руководства** в папке `guides/`
2. **Проверьте логи** скриптов
3. **Создайте резервную копию** перед изменениями
4. **Обратитесь к сообществу** Steam Deck

### Сообщение об ошибках

При обнаружении ошибок:
1. Сохраните логи выполнения скрипта
2. Опишите шаги для воспроизведения
3. Укажите версию SteamOS
4. Создайте issue в репозитории

---

## ⚖️ Правовая информация

### Лицензия
Этот проект распространяется под лицензией MIT. См. файл LICENSE для подробностей.

### Отказ от ответственности
- Используйте на свой страх и риск
- Создавайте резервные копии перед изменениями
- Автор не несет ответственности за потерю данных
- Соблюдайте законы вашей страны

### Соблюдение авторских прав
- Используйте только легальное ПО
- Не нарушайте авторские права
- Соблюдайте условия использования платформ

---

## 🎉 Благодарности

- **Valve** за создание Steam Deck
- **Сообщество Steam Deck** за поддержку и идеи
- **Разработчики Proton** за совместимость с Windows
- **Сообщество Linux** за открытые инструменты

---

## 📝 История изменений

### v1.0 (Октябрь 2025)
- Первоначальный релиз
- Базовые скрипты автоматизации
- Подробные руководства
- Поддержка SteamOS 3.0+

---

## 🔗 Полезные ссылки

- [Steam Deck Official](https://www.steamdeck.com/)
- [Steam Deck Wiki](https://steamdeck.wiki/)
- [ProtonDB](https://www.protondb.com/)
- [Steam Deck Reddit](https://reddit.com/r/SteamDeck)
- [Steam Deck Discord](https://discord.gg/steamdeck)

---

*Steam Deck Enhancement Pack v1.0 - Октябрь 2025*
