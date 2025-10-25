# Руководство по эмуляторам для Steam Deck

## 🎮 Обзор эмуляторов

Steam Deck отлично подходит для эмуляции игр различных консолей благодаря своей мощности и портативности. В этом руководстве рассмотрены лучшие эмуляторы и способы их настройки.

---

## 📋 Содержание

1. [Быстрый старт с EmuDeck](#быстрый-старт-с-emudeck)
2. [RetroArch - универсальный эмулятор](#retroarch---универсальный-эмулятор)
3. [Современные консоли](#современные-консоли)
4. [Настройка BIOS и ROM-ов](#настройка-bios-и-rom-ов)
5. [Оптимизация производительности](#оптимизация-производительности)
6. [Добавление игр в Steam](#добавление-игр-в-steam)
7. [Решение проблем](#решение-проблем)

---

## 🚀 Быстрый старт с EmuDeck

### Что такое EmuDeck

**EmuDeck** - это автоматический установщик, который настраивает все популярные эмуляторы и создает единую систему управления играми.

### Установка EmuDeck

1. **Скачивание:**
   ```bash
   # Перейдите в режим рабочего стола
   # Откройте браузер и скачайте EmuDeck с официального сайта
   # Или через терминал:
   wget https://www.emudeck.com/EmuDeck.desktop
   ```

2. **Установка:**
   ```bash
   # Сделайте файл исполняемым
   chmod +x EmuDeck.desktop
   
   # Запустите установку
   ./EmuDeck.desktop
   ```

3. **Настройка:**
   - Выберите место установки (рекомендуется SD-карта)
   - Выберите эмуляторы для установки
   - Настройте Steam ROM Manager

### Преимущества EmuDeck

- ✅ Автоматическая установка всех эмуляторов
- ✅ Единый интерфейс управления
- ✅ Автоматическое добавление игр в Steam
- ✅ Оптимизированные настройки для Steam Deck
- ✅ Поддержка обложек и метаданных

---

## 🎯 RetroArch - универсальный эмулятор

### Установка RetroArch

**Через Flatpak (рекомендуется):**
```bash
flatpak install flathub org.libretro.RetroArch
```

**Через pacman:**
```bash
sudo pacman -S retroarch
```

### Настройка RetroArch

1. **Запуск:**
   ```bash
   flatpak run org.libretro.RetroArch
   ```

2. **Основные настройки:**
   - **Settings → Input → Hotkeys** - настройка горячих клавиш
   - **Settings → Video** - настройка разрешения и масштабирования
   - **Settings → Audio** - настройка звука
   - **Settings → Saving** - настройка сохранений

3. **Загрузка ядер:**
   - **Main Menu → Online Updater → Core Downloader**
   - Выберите нужные ядра для ваших консолей

### Популярные ядра RetroArch

| Консоль | Ядро | Описание |
|---------|------|----------|
| NES | Nestopia UE | Высокая точность эмуляции |
| SNES | bsnes-mercury | Точная эмуляция SNES |
| Genesis | Genesis Plus GX | Лучшее для Sega Genesis |
| PlayStation | Beetle PSX | Точная эмуляция PS1 |
| N64 | Mupen64Plus-Next | Хорошая совместимость |
| Game Boy | Gambatte | Точная эмуляция Game Boy |

---

## 🎮 Современные консоли

### Nintendo Switch - Yuzu

**Установка:**
```bash
flatpak install flathub org.yuzu_emu.yuzu
```

**Настройка:**
1. Запустите Yuzu
2. **File → Open Yuzu Folder** - откройте папку конфигурации
3. Поместите ключи в папку `keys/`
4. Поместите прошивку в папку `nand/system/Contents/registered/`

**Оптимальные настройки для Steam Deck:**
- **Graphics → API:** Vulkan
- **Graphics → Resolution:** 1x (720p)
- **Graphics → Anti-Aliasing:** None
- **Graphics → Anisotropic Filtering:** 1x
- **Graphics → Accuracy Level:** Normal

### Nintendo Switch - Ryujinx

**Установка:**
```bash
flatpak install flathub org.ryujinx.Ryujinx
```

**Настройка:**
1. Запустите Ryujinx
2. **File → Open Ryujinx Folder**
3. Поместите ключи и прошивку аналогично Yuzu

**Оптимальные настройки:**
- **Graphics → Graphics Backend:** Vulkan
- **Graphics → Resolution Scale:** 1x
- **Graphics → Aspect Ratio:** 16:9
- **System → Enable VSync:** Включено

### PlayStation 2 - PCSX2

**Установка:**
```bash
flatpak install flathub net.pcsx2.PCSX2
```

**Настройка BIOS:**
1. Скачайте BIOS для PS2
2. Поместите файлы в `~/.var/app/net.pcsx2.PCSX2/config/PCSX2/bios/`

**Оптимальные настройки:**
- **Graphics → Renderer:** Vulkan
- **Graphics → Internal Resolution:** 1x Native
- **Graphics → Upscaling:** Bilinear (PS2)
- **Graphics → Texture Filtering:** Bilinear (PS2)

### PlayStation Portable - PPSSPP

**Установка:**
```bash
flatpak install flathub org.ppsspp.PPSSPP
```

**Оптимальные настройки:**
- **Graphics → Backend:** Vulkan
- **Graphics → Resolution:** 1x PSP
- **Graphics → Texture Filtering:** Linear
- **Graphics → Anisotropic Filtering:** 1x

### GameCube/Wii - Dolphin

**Установка:**
```bash
flatpak install flathub org.DolphinEmu.DolphinEmu
```

**Оптимальные настройки:**
- **Graphics → Backend:** Vulkan
- **Graphics → Internal Resolution:** 1x Native (480p)
- **Graphics → Anti-Aliasing:** None
- **Graphics → Anisotropic Filtering:** 1x

---

## 💾 Настройка BIOS и ROM-ов

### Структура папок

```
/run/media/mmcblk0p1/Emulation/
├── bios/           # BIOS файлы
├── roms/           # ROM файлы
│   ├── nes/
│   ├── snes/
│   ├── genesis/
│   ├── psx/
│   ├── n64/
│   ├── gba/
│   └── psp/
└── saves/          # Сохранения
```

### BIOS файлы

**Необходимые BIOS для разных консолей:**

| Консоль | Файл BIOS | Описание |
|---------|-----------|----------|
| PlayStation | SCPH-*.bin | Различные регионы |
| PlayStation 2 | *.bin | Различные регионы |
| Sega Saturn | saturn_bios.bin | Для Saturn |
| Dreamcast | dc_boot.bin | Для Dreamcast |

### ROM файлы

**Поддерживаемые форматы:**
- **NES:** .nes, .fds
- **SNES:** .smc, .sfc, .fig
- **Genesis:** .gen, .md, .smd
- **PlayStation:** .iso, .bin/.cue
- **N64:** .n64, .v64, .z64
- **Game Boy:** .gb, .gbc, .gba

---

## ⚡ Оптимизация производительности

### Настройки Steam Deck

1. **TDP и частота GPU:**
   ```bash
   # Используйте скрипт оптимизации
   ./scripts/steamdeck_optimizer.sh game indie
   ```

2. **Профили производительности:**
   - **Retro-игры:** TDP 5W, GPU 800MHz
   - **PS2/GameCube:** TDP 10W, GPU 1200MHz
   - **Switch:** TDP 12W, GPU 1400MHz

### Настройки эмуляторов

**RetroArch:**
- **Settings → Video → Threaded Video:** Включено
- **Settings → Video → Hard GPU Sync:** Включено
- **Settings → Audio → Audio Latency:** 64ms

**Yuzu/Ryujinx:**
- Используйте Vulkan API
- Отключите VSync для лучшей производительности
- Установите разрешение 1x

**PCSX2:**
- Используйте Vulkan рендерер
- Отключите дополнительные эффекты
- Используйте нативные разрешения

---

## 🎯 Добавление игр в Steam

### Через Steam ROM Manager

1. **Установка:**
   ```bash
   flatpak install flathub io.github.steamrommanager.steamrommanager
   ```

2. **Настройка:**
   - Запустите Steam ROM Manager
   - Настройте пути к ROM-ам
   - Выберите эмуляторы
   - Сгенерируйте ярлыки

### Вручную

1. **Добавление через Steam:**
   - Откройте Steam в режиме рабочего стола
   - **Games → Add a Non-Steam Game to My Library**
   - Выберите эмулятор
   - Настройте параметры запуска

2. **Параметры запуска:**
   ```
   /path/to/emulator --fullscreen "/path/to/rom"
   ```

### Создание обложек

1. **Скачивание обложек:**
   - Используйте Steam Grid DB
   - Или создайте собственные обложки

2. **Размещение:**
   ```
   ~/.steam/steam/userdata/*/config/grid/
   ```

---

## 🔧 Решение проблем

### Проблемы с производительностью

**Низкий FPS:**
1. Уменьшите разрешение
2. Отключите дополнительные эффекты
3. Используйте более легкие ядра
4. Настройте TDP Steam Deck

**Задержки ввода:**
1. Включите Hard GPU Sync в RetroArch
2. Уменьшите Audio Latency
3. Используйте проводной контроллер

### Проблемы с совместимостью

**Игра не запускается:**
1. Проверьте BIOS файлы
2. Попробуйте другое ядро
3. Обновите эмулятор
4. Проверьте формат ROM

**Графические артефакты:**
1. Смените рендерер (Vulkan/OpenGL)
2. Отключите шейдеры
3. Сбросьте настройки графики

### Проблемы с контроллерами

**Контроллер не работает:**
1. Проверьте подключение в Steam
2. Настройте контроллер в эмуляторе
3. Используйте Steam Input

**Неправильные кнопки:**
1. Переназначьте кнопки в настройках
2. Используйте готовые профили
3. Создайте собственный маппинг

---

## 📚 Полезные ресурсы

### Официальные сайты
- [RetroArch](https://www.retroarch.com/)
- [Yuzu](https://yuzu-emu.org/)
- [Ryujinx](https://ryujinx.org/)
- [PCSX2](https://pcsx2.net/)
- [Dolphin](https://dolphin-emu.org/)
- [PPSSPP](https://www.ppsspp.org/)

### Сообщество
- [r/EmulationOnSteamDeck](https://reddit.com/r/EmulationOnSteamDeck)
- [EmuDeck Discord](https://discord.gg/emudeck)
- [Steam Deck Emulation Wiki](https://steamdeck.wiki/)

### Инструменты
- **Steam ROM Manager** - управление играми
- **EmuDeck** - автоматическая настройка
- **Steam Grid DB** - обложки для игр
- **RetroAchievements** - достижения для ретро-игр

---

## ⚖️ Правовая информация

**Важно:** Убедитесь, что у вас есть права на игры, которые вы эмулируете. Использование ROM-файлов игр, которыми вы не владеете, может нарушать авторские права.

**Рекомендации:**
- Используйте только собственные копии игр
- Создавайте резервные копии ваших игр
- Соблюдайте законы вашей страны

---

*Руководство обновлено: Октябрь 2025*
