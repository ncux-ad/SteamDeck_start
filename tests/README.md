# 🧪 Steam Deck Enhancement Pack - Тесты

Полное покрытие тестами проекта Steam Deck Enhancement Pack.

## 📁 Структура тестов

```
tests/
├── __init__.py           # Python package init
├── conftest.py           # Pytest конфигурация
├── README.md             # Документация
├── bash/                 # Bash тесты
│   ├── test_steamdeck_setup.sh
│   ├── test_steamdeck_update.sh
│   ├── test_steamdeck_gui_install.sh
│   └── test_helpers.sh
├── python/               # Python тесты
│   ├── test_steamdeck_gui.py
│   ├── test_steamdeck_logger.py
│   └── test_helpers.py
├── integration/          # Интеграционные тесты
│   ├── test_full_setup.sh
│   ├── test_update_flow.sh
│   └── test_flash_drive.sh
└── helpers/              # Вспомогательные функции
    ├── test_helpers.sh
    ├── test_helpers.py
    └── mock_functions.sh
```

## 🚀 Запуск тестов

### Bash тесты
```bash
cd tests/bash
./run_all_tests.sh
```

### Python тесты
```bash
cd tests/python
pytest -v
# или с покрытием:
pytest --cov=../.. --cov-report=html
```

### Интеграционные тесты
```bash
cd tests/integration
./test_full_setup.sh
```

### Все тесты
```bash
./run_all_tests.sh
```

## 📊 Покрытие кода

### Текущее покрытие:
- ✅ Bash скрипты: 0% → Цель: 80%
- ✅ Python скрипты: 0% → Цель: 90%
- ✅ Интеграционные тесты: 0% → Цель: 70%

### Метрики:
```bash
# Проверка покрытия
./scripts/check_coverage.sh
```

## 🧪 Типы тестов

### Unit тесты
- Тестирование отдельных функций
- Мокирование внешних зависимостей
- Быстрое выполнение (< 1 сек каждый)

### Integration тесты
- Тестирование взаимодействия компонентов
- Реальные сценарии использования
- Проверка всего workflow

### E2E тесты
- Полные пользовательские сценарии
- Симуляция реального использования
- Проверка GUI

## 📝 Правила написания тестов

### Bash тесты
- Используйте `set -e` в начале
- Проверяйте возвращаемые коды
- Используйте временные директории
- Очищайте после себя

### Python тесты
- Следуйте PEP 8
- Используйте pytest fixtures
- Мокируйте внешние зависимости
- Тестируйте граничные случаи

## 🎯 Приоритет тестирования

### Высокий приоритет (делаем первыми):
1. ✅ `steamdeck_update.sh` - основная функциональность обновлений
2. ✅ `steamdeck_gui.py` - GUI интерфейс
3. ✅ `steamdeck_setup.sh` - установка и настройка

### Средний приоритет:
4. `steamdeck_cleanup.sh` - очистка системы
5. `steamdeck_backup.sh` - резервное копирование
6. `steamdeck_logger.py` - логирование

### Низкий приоритет:
7. Вспомогательные скрипты
8. Утилиты для работы с Steam
9. Scripts для artwork

## 🔧 CI/CD интеграция

Тесты автоматически запускаются при:
- Push в main
- Pull Request
- Теги релизов

## 📚 Дополнительная документация

- [Bash Testing Best Practices](./docs/bash_testing.md)
- [Python Testing Guide](./docs/python_testing.md)
- [Integration Tests Guide](./docs/integration_tests.md) 