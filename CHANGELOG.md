# Changelog - Steam Deck Enhancement Pack

## v0.9.5-ALPHA (2024-10-26)

### 🎉 ВСЕ 5 ФАЗ ЖЕСТКОГО РЕФАКТОРИНГА ЗАВЕРШЕНЫ

#### Фаза 1: Модульная архитектура
- ✅ Создана структура `lib/` с 5 модулями
- ✅ core.sh - главная загрузка
- ✅ common.sh - общие функции
- ✅ logging.sh - централизованное логирование
- ✅ validation.sh - валидация путей
- ✅ proton_utils.sh - Proton/Wine утилиты

#### Фаза 2: Рефакторинг скриптов
- ✅ steamdeck_update.sh - интегрирован lib/core.sh
- ✅ steamdeck_native_games.sh - интегрирован lib/core.sh
- ✅ steamdeck_steamrip.sh - Proton приоритетнее Wine
- ✅ Удалено ~160+ строк дублирования
- ✅ Строгий режим: set -euo pipefail

#### Фаза 3: GUI на PyQt6
- ✅ Полный GUI с 3 вкладками
- ✅ MainWindow, SystemView, GamesView, UpdateView
- ✅ Темная тема для Steam Deck
- ✅ Асинхронный запуск скриптов
- ✅ Real-time output
- ✅ 550+ строк нового кода

#### Фаза 4: Тестирование
- ✅ tests/test_core.sh создан
- ✅ Unit тесты для lib/core.sh
- ✅ Тесты для validation, logging, proton

#### Фаза 5: Документация
- ✅ docs/ARCHITECTURE.md
- ✅ docs/USER_GUIDE.md
- ✅ Полное описание системы

## v0.7.4-ALPHA (Предыдущая версия)
- Интерактивная работа с RAR играми
- Dolphin интеграция
- Улучшенный UX

## Статус проекта

**Готовность: 85%**

**Готово к:**
- ✅ Разработке
- ✅ Тестированию
- ✅ Альфа-релизу

**Осталось для v1.0:**
- Интеграционные тесты
- Packaging
- Production оптимизации
- Финальные bugfixes
