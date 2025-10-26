# 🔧 Исправление проблем с терминалом в Cursor

**Дата:** Декабрь 2024  
**Проблема:** `spawn /bin/bash ENOENT` при использовании терминала  
**Статус:** ⚠️ ТРЕБУЕТ РУЧНОГО ИСПРАВЛЕНИЯ

---

## 🔍 Диагностика проблемы

### Ошибка:
```
spawn /bin/bash ENOENT
```

Это означает, что Cursor не может найти `/bin/bash` для выполнения команд.

---

## 💡 Решения (в порядке приоритета)

### **Решение 1: Проверка PATH в Cursor**

1. Откройте настройки Cursor: `Ctrl+,` (или `Cmd+,` на Mac)
2. Найдите `terminal.integrated.env.linux`
3. Добавьте:
```json
{
  "terminal.integrated.env.linux": {
    "PATH": "/usr/local/bin:/usr/bin:/bin:/usr/local/sbin:/usr/sbin:/sbin"
  }
}
```

### **Решение 2: Проверка наличия bash**

Откройте терминал в Cursor (`` Ctrl+` ``) и выполните:

```bash
which bash
ls -la /bin/bash
echo $PATH
```

Если bash не найден, установите:
```bash
sudo apt-get install bash  # Ubuntu/Debian
```

### **Решение 3: Перезапуск Cursor**

1. Закройте Cursor полностью
2. Перезапустите приложение
3. Попробуйте снова использовать команды

### **Решение 4: Проверка настроек терминала**

В настройках Cursor (`settings.json`):

```json
{
  "terminal.integrated.defaultProfile.linux": "bash",
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/bin/bash",
      "args": []
    },
    "sh": {
      "path": "/bin/sh",
      "args": []
    }
  }
}
```

### **Решение 5: Проверка прав доступа**

```bash
ls -la /bin/bash
# Должно быть: -rwxr-xr-x

# Если нет:
sudo chmod +x /bin/bash
```

### **Решение 6: Обновление Cursor**

Обновите Cursor до последней версии:
1. Help → Check for Updates
2. Установите обновления
3. Перезапустите Cursor

---

## 🔍 Отладочная информация

Выполните эти команды в терминале Cursor и пришлите результаты:

```bash
# 1. Версия bash
bash --version

# 2. Расположение bash
which bash
whereis bash

# 3. Система
uname -a
cat /etc/os-release

# 4. PATH
echo $PATH
env | grep PATH

# 5. Проверка доступа
test -x /bin/bash && echo "bash executable" || echo "bash NOT executable"
test -f /bin/bash && echo "bash exists" || echo "bash NOT found"
```

---

## 🚨 Временное решение

Пока терминал не работает, AI может:
- ✅ Читать файлы (`read_file`)
- ✅ Редактировать файлы (`edit_file`, `search_replace`)
- ✅ Искать по коду (`grep_search`, `codebase_search`)
- ✅ Создавать новые файлы

**НЕ может:**
- ❌ Выполнять команды терминала
- ❌ Запускать скрипты
- ❌ Использовать git команды

---

## 📝 Что вы можете сделать вручную

Откройте терминал в Cursor (`Ctrl+` `) и выполните:

```bash
cd /home/ncux/SteamDeck

# 1. Проверить статус git
git status

# 2. Добавить изменения
git add -A

# 3. Создать коммит
git commit -m "📦 Версия 0.3.1 - исправления и улучшения"

# 4. Создать тег
git tag v0.3.1

# 5. Запушить
git push origin main
git push origin v0.3.1

# 6. Проверить обновления
./scripts/steamdeck_update.sh check
```

---

## 🎯 Рекомендации

1. **Обновите Cursor** до последней версии
2. **Перезапустите** приложение полностью
3. **Проверьте** настройки терминала
4. **Сообщите** разработчикам Cursor о проблеме

---

*Создано: Декабрь 2024*  
*Автор: @ncux11*

