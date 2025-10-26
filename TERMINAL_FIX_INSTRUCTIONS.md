# ✅ Финальная инструкция по исправлению терминала Cursor

## 📋 Что уже сделано:

1. ✅ Проверен путь к bash: `/usr/bin/bash`
2. ✅ Создан файл `~/.config/cursor/User/settings.json` с настройками

## 🔧 Что нужно сделать СЕЙЧАС:

### Шаг 1: Перезапустите Cursor
```
1. Закройте Cursor полностью (File → Exit или Alt+F4)
2. Дождитесь полного закрытия процесса
3. Запустите Cursor заново
```

### Шаг 2: Проверьте настройки в Cursor UI

1. Откройте настройки: `Ctrl+,` (или Help → Settings)
2. В поиске введите: `automation profile`
3. Найдите `Terminal > Integrated > Automation Profile: Linux`
4. Убедитесь что указан путь: `/usr/bin/bash`

### Шаг 3: Проверьте работу терминала

После перезапуска Cursor попробуйте:
1. Открыть терминал в Cursor: `Ctrl+`` ` 
2. Выполнить команду: `echo $SHELL`
3. Должно показать: `/bin/bash` или `/usr/bin/bash`

## 🎯 Если не поможет:

### Вариант 1: Проверьте файл настроек

```bash
cat ~/.config/cursor/User/settings.json
```

Должен содержать:
```json
{
  "terminal.integrated.automationProfile.linux": {
    "path": "/usr/bin/bash"
  }
}
```

Если файл пустой или неправильный, исправьте:
```bash
cat > ~/.config/cursor/User/settings.json << 'EOF'
{
  "terminal.integrated.automationProfile.linux": {
    "path": "/usr/bin/bash"
  },
  "terminal.integrated.profiles.linux": {
    "bash": {
      "path": "/usr/bin/bash",
      "args": []
    }
  }
}
EOF
```

### Вариант 2: Проверьте настройки проекта

Убедитесь что `.vscode/settings.json` и `.cursor/settings.json` содержат правильные настройки.

### Вариант 3: Полная переустановка настроек

```bash
# Удалите настройки терминала
rm -rf ~/.config/cursor/User/settings.json

# Перезапустите Cursor
# Cursor создаст новый файл с настройками по умолчанию
# Затем добавьте настройки вручную через UI
```

## 📝 Проверка успешности

После перезапуска Cursor AI должно успешно использовать `run_terminal_cmd` без ошибки `ENOENT`.

Попробуйте попросить AI выполнить простую команду, например:
- "Выполни команду `pwd`"
- "Покажи содержимое папки scripts"

Если работает - проблема решена! ✅

---

*Создано: Декабрь 2024*

