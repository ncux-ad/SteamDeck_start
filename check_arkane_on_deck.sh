#!/bin/bash

# Скрипт для проверки и восстановления флешки arkane на Steam Deck
# Использование: ./check_arkane_on_deck.sh

echo "=== Проверка флешки arkane на Steam Deck ==="
echo ""

# 1. Найти флешку или SD карту
echo "1. Поиск флешки/SD карты arkane..."
ARKANE_PARTITION=$(lsblk -n -o NAME,LABEL,FSTYPE | grep -i "arkane" | awk '{print $1}' | tr -d '├─└─│ ')

# Попробуем найти по LABEL или UUID
if [[ -z "$ARKANE_PARTITION" ]]; then
    # Поиск по другим параметрам
    ARKANE_PARTITION=$(blkid | grep -i "arkane" | cut -d: -f1 | sed 's/\/dev\///')
fi

if [[ -z "$ARKANE_PARTITION" ]]; then
    echo "❌ Флешка/SD карта arkane не найдена!"
    echo ""
    echo "Доступные устройства:"
    lsblk -o NAME,LABEL,FSTYPE,UUID | grep -v "^NAME"
    echo ""
    echo "На Steam Deck:"
    echo "- mmcblk0p1, mmcblk1p1 - SD карты"
    echo "- sda1, sdb1 - USB флешки"
    echo "- nvme0n1p1 - внутренний SSD"
    exit 1
fi

ARKANE_PARTITION="/dev/${ARKANE_PARTITION}"
echo "✅ Найдено устройство arkane: $ARKANE_PARTITION"

# Определить тип устройства
if echo "$ARKANE_PARTITION" | grep -q "mmcblk"; then
    DEVICE_TYPE="SD карта"
elif echo "$ARKANE_PARTITION" | grep -q "sda\|sdb"; then
    DEVICE_TYPE="USB флешка"
else
    DEVICE_TYPE="Внешнее устройство"
fi
echo "Тип устройства: $DEVICE_TYPE"
echo ""

# 2. Проверить монтирование
echo "2. Проверка монтирования..."
if mount | grep -q "$ARKANE_PARTITION"; then
    MOUNT_POINT=$(mount | grep "$ARKANE_PARTITION" | awk '{print $3}')
    echo "✅ Флешка монтирована в: $MOUNT_POINT"
    
    # Проверить права доступа
    if [[ -w "$MOUNT_POINT" ]]; then
        echo "✅ Запись разрешена"
    else
        echo "⚠️ Только чтение (Read-only)"
    fi
else
    echo "⚠️ Флешка не монтирована"
fi
echo ""

# 3. Проверить файловую систему
echo "3. Проверка файловой системы..."
if sudo fsck.ext4 -n "$ARKANE_PARTITION" 2>&1 | grep -q "contains a file system"; then
    echo "✅ Файловая система обнаружена (ext4)"
    
    # Проверить версию e2fsck
    E2FSCK_VERSION=$(e2fsck -V 2>&1 | head -1)
    echo "Версия e2fsck: $E2FSCK_VERSION"
else
    echo "❌ Проблема с файловой системой"
    FSCK_OUTPUT=$(sudo fsck.ext4 -n "$ARKANE_PARTITION" 2>&1)
    echo "$FSCK_OUTPUT"
fi
echo ""

# 4. Проверить логи
echo "4. Проверка логов ядра..."
RECENT_ERRORS=$(dmesg | grep -i "$ARKANE_DEVICE.*error" | tail -5)
if [[ -n "$RECENT_ERRORS" ]]; then
    echo "⚠️ Обнаружены ошибки в логах:"
    echo "$RECENT_ERRORS"
else
    echo "✅ Ошибок в логах не найдено"
fi
echo ""

# 5. Проверить использование пространства
if mount | grep -q "$ARKANE_PARTITION"; then
    MOUNT_POINT=$(mount | grep "$ARKANE_PARTITION" | awk '{print $3}')
    echo "5. Использование пространства:"
    df -h "$MOUNT_POINT"
fi
echo ""

# 6. Рекомендации
echo "=== РЕКОМЕНДАЦИИ ==="
echo ""

# Проверить ошибки
if [[ -n "$RECENT_ERRORS" ]]; then
    echo "⚠️ Обнаружены ошибки файловой системы!"
    echo ""
    echo "Для восстановления выполните на Steam Deck:"
    echo ""
    echo "1. Размонтировать флешку:"
    echo "   sudo umount $ARKANE_PARTITION"
    echo "   # На Steam Deck нужен sudo для umount"
    echo ""
    echo "2. Проверить файловую систему:"
    echo "   sudo fsck.ext4 -f -y $ARKANE_PARTITION"
    echo ""
    echo "3. Перемонтировать (должно произойти автоматически)"
    echo ""
elif mount | grep "$ARKANE_PARTITION" | grep -q "ro,"; then
    echo "⚠️ Флешка смонтирована только для чтения!"
    echo ""
    echo "Для восстановления выполните на Steam Deck:"
    echo ""
    echo "1. Размонтировать:"
    echo "   sudo umount $ARKANE_PARTITION"
    echo ""
    echo "2. Проверить файловую систему:"
    echo "   sudo fsck.ext4 -f -y $ARKANE_PARTITION"
    echo ""
    echo "3. Перемонтировать:"
    echo "   sudo mount $ARKANE_PARTITION /media/deck/arkane"
    echo ""
else
    echo "✅ Флешка в нормальном состоянии"
    echo ""
    echo "Если возникли проблемы с монтированием на Steam Deck:"
    echo "1. Проверьте, что установлена последняя версия SteamOS"
    echo "2. Попробуйте форматировать флешку на Steam Deck:"
    echo "   sudo umount $ARKANE_PARTITION"
    echo "   sudo mkfs.ext4 -F $ARKANE_PARTITION"
fi
echo ""

# 7. Информация о текущем окружении
echo "=== ИНФОРМАЦИЯ О СИСТЕМЕ ==="
echo "Система: $(uname -s)"
echo "Версия ядра: $(uname -r)"
echo "Версия e2fsck: $(e2fsck -V 2>&1 | head -1)"
echo ""

echo "=== ГОТОВО ==="
echo "Скопируйте эти команды и выполните их на Steam Deck для восстановления флешки."

