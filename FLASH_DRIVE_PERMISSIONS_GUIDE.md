# 🔧 Руководство: Правильные права доступа при копировании на Steam Deck

**Проблема:** При копировании файлов с флешки на Steam Deck возникают ошибки прав доступа при автообновлении.

---

## 🔍 Анализ проблемы

### **Текущая ситуация:**

1. **На локальной машине (ncux):**
   - Файлы принадлежат пользователю `ncux`
   - Права: `rwxr-xr-x` (755)

2. **При копировании на Steam Deck:**
   - Файлы сохраняют владельца `ncux`
   - На Steam Deck нет пользователя `ncux`
   - Права могут быть неправильными

3. **При обновлении:**
   - Скрипт пытается создать/удалить `/tmp/steamdeck_update`
   - Временная директория создается от имени `deck`
   - Попытка удалить без sudo = ошибка прав доступа

---

## ✅ Решение

### **Метод 1: Копирование через `steamdeck_setup.sh` (рекомендуется)**

Когда вы копируете утилиту на Steam Deck, используйте команду установки:

```bash
# На Steam Deck после подключения флешки:
./scripts/steamdeck_setup.sh install-utils
```

Скрипт автоматически:
- Установит правильные права доступа
- Создаст симлинки
- Настроит desktop файл

### **Метод 2: Ручное исправление прав**

Если копируете вручную:

```bash
# 1. Копируем файлы
cp -r /media/*/system_start/SteamDeck ~/SteamDeck

# 2. Исправляем права
cd ~/SteamDeck
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod +x scripts/*.sh
chmod +x scripts/*.py

# 3. Устанавливаем правильного владельца
sudo chown -R deck:deck ~/SteamDeck
```

### **Метод 3: Автоматический скрипт**

Создайте скрипт `fix_permissions.sh` на флешке:

```bash
#!/bin/bash
# Исправление прав доступа на Steam Deck

cd ~/SteamDeck

# Проверяем что мы в правильной директории
if [[ ! -f "README.md" ]]; then
    echo "Ошибка: Запустите скрипт из директории SteamDeck"
    exit 1
fi

echo "Исправление прав доступа..."
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod +x scripts/*.sh scripts/*.py

echo "Установка владельца..."
sudo chown -R deck:deck .

echo "Готово!"
```

---

## 🔧 Исправление уже установленной утилиты

Если утилита уже установлена с неправильными правами:

```bash
# На Steam Deck выполните:

# 1. Определяем место установки
INSTALL_DIR="$HOME/SteamDeck"

# 2. Исправляем права
cd "$INSTALL_DIR"
find . -type d -exec chmod 755 {} \;
find . -type f -exec chmod 644 {} \;
chmod +x scripts/*.sh scripts/*.py

# 3. Устанавливаем владельца
sudo chown -R deck:deck "$INSTALL_DIR"

# 4. Проверяем права
ls -la scripts/ | head -10
```

---

## 🧪 Проверка правильности прав

```bash
# Проверяем владельца
ls -la ~/SteamDeck/scripts/steamdeck_update.sh
# Должно быть: -rwxr-xr-x 1 deck deck ...

# Проверяем права на директории
ls -la ~/SteamDeck/
# Должно быть: drwxr-xr-x ... deck deck

# Тестируем обновление
~/SteamDeck/scripts/steamdeck_update.sh check
```

---

## 📝 Добавление в автоматическую установку

Добавьте проверку прав в `steamdeck_setup.sh`:

```bash
# В функции install_steamdeck_utils() добавить:

# Исправляем права после копирования
print_message "Исправление прав доступа..."
run_sudo find "$utils_dir" -type d -exec chmod 755 {} \;
run_sudo find "$utils_dir" -type f -exec chmod 644 {} \;
run_sudo chmod +x "$utils_dir"/scripts/*.sh
run_sudo chmod +x "$utils_dir"/scripts/*.py
run_sudo chown -R $DECK_USER:$DECK_USER "$utils_dir"
```

---

## 🎯 Рекомендации

1. **Всегда используйте `steamdeck_setup.sh install-utils`** для установки
2. **Проверяйте права** после копирования вручную
3. **Не копируйте `.git`** директорию на Steam Deck (экономит место)
4. **Используйте rsync** для синхронизации:

```bash
rsync -av --chown=deck:deck \
  /media/*/system_start/SteamDeck/ \
  ~/SteamDeck/ \
  --exclude='.git' \
  --exclude='__pycache__'
```

---

*Создано: Декабрь 2024*  
*Статус: ✅ РЕШЕНО*
