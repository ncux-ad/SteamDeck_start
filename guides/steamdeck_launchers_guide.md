# Руководство по альтернативным лаунчерам для Steam Deck

## 🎮 Обзор лаунчеров

Steam Deck поддерживает множество альтернативных лаунчеров, которые позволяют играть в игры из различных магазинов и платформ. В этом руководстве рассмотрены лучшие решения для интеграции с Steam Deck.

---

## 📋 Содержание

1. [Heroic Games Launcher (Epic/GOG)](#heroic-games-launcher-epicgog)
2. [Lutris - универсальный менеджер](#lutris---универсальный-менеджер)
3. [Bottles - Wine-контейнеры](#bottles---wine-контейнеры)
4. [NonSteamLaunchers - автоматическая установка](#nonsteamlaunchers---автоматическая-установка)
5. [Специализированные лаунчеры](#специализированные-лаунчеры)
6. [Интеграция с Steam](#интеграция-с-steam)
7. [Решение проблем](#решение-проблем)

---

## 🏆 Heroic Games Launcher (Epic/GOG)

### Что такое Heroic

**Heroic Games Launcher** - это открытый лаунчер для игр из Epic Games Store и GOG, специально оптимизированный для Linux и Steam Deck.

### Установка

**Через Flatpak (рекомендуется):**
```bash
flatpak install flathub com.heroicgameslauncher.hgl
```

**Через AUR:**
```bash
yay -S heroic-games-launcher-bin
```

### Настройка

1. **Запуск:**
   ```bash
   flatpak run com.heroicgameslauncher.hgl
   ```

2. **Вход в аккаунт:**
   - Нажмите "Login" в правом верхнем углу
   - Выберите Epic Games Store или GOG
   - Войдите через браузер

3. **Настройки:**
   - **Settings → General** - основные настройки
   - **Settings → Wine** - настройка Wine
   - **Settings → Other** - дополнительные опции

### Оптимальные настройки для Steam Deck

**Wine настройки:**
- **Wine Version:** Wine-GE (рекомендуется)
- **DXVK:** Включено
- **VKD3D:** Включено
- **Esync:** Включено

**Производительность:**
- **Preload:** Включено
- **GameMode:** Включено
- **MangoHud:** Включено (опционально)

### Установка игр

1. **Скачивание:**
   - Найдите игру в библиотеке
   - Нажмите "Install"
   - Выберите папку установки

2. **Запуск:**
   - Нажмите "Play" на установленной игре
   - Игра запустится через Wine

### Добавление в Steam

1. **Автоматическое добавление:**
   - В настройках включите "Add games to Steam"
   - Игры автоматически добавятся в Steam

2. **Ручное добавление:**
   - Правый клик на игре → "Add to Steam"
   - Или используйте скрипт shortcuts

---

## 🎯 Lutris - универсальный менеджер

### Что такое Lutris

**Lutris** - это универсальный менеджер игр для Linux, который поддерживает множество платформ и эмуляторов.

### Установка

**Через Flatpak:**
```bash
flatpak install flathub net.lutris.Lutris
```

**Через pacman:**
```bash
sudo pacman -S lutris
```

### Настройка

1. **Запуск:**
   ```bash
   flatpak run net.lutris.Lutris
   ```

2. **Установка Wine:**
   - **Lutris → Preferences → Wine**
   - Скачайте Wine-GE или используйте системный Wine

3. **Настройка DXVK:**
   - **Lutris → Preferences → DXVK**
   - Включите DXVK для лучшей производительности

### Установка игр

1. **Через установщики:**
   - Найдите игру в каталоге Lutris
   - Нажмите "Install"
   - Следуйте инструкциям установщика

2. **Добавление существующих игр:**
   - **+ → Add locally installed game**
   - Укажите путь к исполняемому файлу
   - Настройте Wine-префикс

### Популярные установщики

- **Epic Games Store** - для игр Epic
- **GOG** - для игр GOG
- **Battle.net** - для игр Blizzard
- **Origin** - для игр EA
- **Ubisoft Connect** - для игр Ubisoft

---

## 🍷 Bottles - Wine-контейнеры

### Что такое Bottles

**Bottles** - это современный менеджер Wine-контейнеров с графическим интерфейсом, специально разработанный для удобства использования.

### Установка

**Через Flatpak:**
```bash
flatpak install flathub com.usebottles.bottles
```

**Через AUR:**
```bash
yay -S bottles
```

### Создание контейнера

1. **Запуск:**
   ```bash
   flatpak run com.usebottles.bottles
   ```

2. **Создание бутылки:**
   - Нажмите "Create a new bottle"
   - Выберите тип: **Gaming** (для игр)
   - Укажите имя и настройки

3. **Настройка:**
   - **Dependencies** - установка компонентов
   - **Programs** - управление программами
   - **Settings** - настройки Wine

### Установка игр

1. **Через установщик:**
   - Запустите установщик игры в бутылке
   - Установите игру как обычно

2. **Добавление существующих игр:**
   - Скопируйте папку с игрой в бутылку
   - Создайте ярлык для .exe файла

### Полезные компоненты

- **DirectX** - для графики
- **Visual C++ Redistributable** - для библиотек
- **.NET Framework** - для .NET приложений
- **Media Foundation** - для видео
- **vcredist** - дополнительные библиотеки

---

## 🚀 NonSteamLaunchers - автоматическая установка

### Что такое NonSteamLaunchers

**NonSteamLaunchers** - это скрипт для автоматической установки популярных лаунчеров и их интеграции с Steam.

### Установка

**Через AUR:**
```bash
yay -S non-steam-launchers
```

**Вручную:**
```bash
git clone https://github.com/SteamDeckHomebrew/non-steam-launchers.git
cd non-steam-launchers
./install.sh
```

### Поддерживаемые лаунчеры

- **Epic Games Store**
- **GOG Galaxy**
- **Battle.net**
- **Origin**
- **Ubisoft Connect**
- **EA App**
- **Amazon Games**
- **Itch.io**
- **Rockstar Games Launcher**

### Использование

1. **Запуск установки:**
   ```bash
   non-steam-launchers
   ```

2. **Выбор лаунчеров:**
   - Выберите нужные лаунчеры
   - Подтвердите установку

3. **Интеграция с Steam:**
   - Лаунчеры автоматически добавятся в Steam
   - Запускайте через игровой режим

---

## 🎮 Специализированные лаунчеры

### Battle.net (Blizzard)

**Установка через Lutris:**
1. Откройте Lutris
2. Найдите "Battle.net" в каталоге
3. Установите через установщик

**Настройка:**
- Используйте Wine-GE
- Включите DXVK
- Настройте контроллер через Steam Input

### Origin/EA App

**Установка:**
```bash
# Через Lutris
# Найдите "Origin" в каталоге и установите
```

**Настройка:**
- Используйте последнюю версию Wine
- Включите DXVK и VKD3D
- Настройте антивирусные исключения

### Ubisoft Connect

**Установка через Lutris:**
1. Найдите "Ubisoft Connect" в каталоге
2. Установите через установщик
3. Настройте Wine-префикс

### Rockstar Games Launcher

**Установка:**
```bash
# Через Lutris
# Найдите "Rockstar Games Launcher" и установите
```

**Настройка:**
- Используйте Wine-GE
- Включите DXVK
- Настройте социальные функции

---

## 🎯 Интеграция с Steam

### Автоматическое добавление

**Heroic Games Launcher:**
- Включите "Add games to Steam" в настройках
- Игры автоматически появятся в Steam

**Lutris:**
- Включите "Steam integration" в настройках
- Игры добавятся в Steam при установке

### Ручное добавление

1. **Через Steam:**
   - **Games → Add a Non-Steam Game to My Library**
   - Выберите лаунчер
   - Настройте параметры запуска

2. **Через скрипт shortcuts:**
   ```bash
   ./scripts/steamdeck_shortcuts.sh create "Epic Games" "flatpak run com.heroicgameslauncher.hgl"
   ```

### Настройка обложек

1. **Скачивание обложек:**
   - Используйте Steam Grid DB
   - Или создайте собственные

2. **Размещение:**
   ```
   ~/.steam/steam/userdata/*/config/grid/
   ```

3. **Автоматическое скачивание:**
   - Используйте Steam ROM Manager
   - Или BoilR для автоматизации

---

## 🔧 Решение проблем

### Проблемы с Wine

**Игра не запускается:**
1. Проверьте версию Wine
2. Установите недостающие компоненты
3. Проверьте логи ошибок

**Низкая производительность:**
1. Включите DXVK/VKD3D
2. Настройте Wine-префикс
3. Используйте GameMode

### Проблемы с лаунчерами

**Лаунчер не запускается:**
1. Проверьте зависимости
2. Обновите лаунчер
3. Переустановите Wine

**Игры не скачиваются:**
1. Проверьте свободное место
2. Проверьте права доступа
3. Перезапустите лаунчер

### Проблемы с Steam

**Игры не появляются в Steam:**
1. Перезапустите Steam
2. Проверьте настройки интеграции
3. Добавьте вручную

**Неправильные обложки:**
1. Удалите старые обложки
2. Скачайте новые
3. Перезапустите Steam

---

## 📚 Полезные ресурсы

### Официальные сайты
- [Heroic Games Launcher](https://heroicgameslauncher.com/)
- [Lutris](https://lutris.net/)
- [Bottles](https://usebottles.com/)
- [NonSteamLaunchers](https://github.com/SteamDeckHomebrew/non-steam-launchers)

### Сообщество
- [r/SteamDeck](https://reddit.com/r/SteamDeck)
- [Steam Deck Discord](https://discord.gg/steamdeck)
- [Lutris Discord](https://discord.gg/lutris)

### Инструменты
- **Steam ROM Manager** - управление играми
- **BoilR** - автоматические обложки
- **Steam Grid DB** - база обложек
- **ProtonDB** - совместимость игр

---

## ⚖️ Правовая информация

**Важно:** Убедитесь, что у вас есть лицензии на все игры, которые вы устанавливаете через альтернативные лаунчеры.

**Рекомендации:**
- Используйте только официальные лаунчеры
- Не используйте пиратские версии игр
- Соблюдайте условия использования платформ

---

*Руководство обновлено: Октябрь 2025*
