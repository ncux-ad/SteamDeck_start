# Команды для восстановления флешки arkane на Steam Deck

## Шаг 1: Найти флешку

```bash
lsblk
```

**Поиск arkane:**
```bash
lsblk | grep -i "arkane"
blkid | grep -i "arkane"
```

## Шаг 2: Размонтировать (если смонтирована)

```bash
# Если это USB флешка (sda1, sdb1)
sudo umount /dev/sdb1

# ИЛИ через mount point
sudo umount /media/deck/arkane1

# ИЛИ через UUID (если знаете)
sudo umount UUID=<ваш-uuid>
```

## Шаг 3: Проверить файловую систему

```bash
sudo fsck.ext4 -f -y /dev/sdb1
```

**Если другое устройство (SD карта):**
```bash
# Для SD карты (mmcblk0p1, mmcblk1p1)
sudo fsck.ext4 -f -y /dev/mmcblk1p1
```

## Шаг 4: Перемонтировать

```bash
# Должно произойти автоматически при подключении
# ИЛИ вручную
sudo mount /dev/sdb1 /media/deck/arkane1
```

## Если НЕ помогло: Форматирование (ВСЕ ДАННЫЕ УДАЛЯТСЯ!)

```bash
# 1. Размонтировать
sudo umount /dev/sdb1

# 2. Форматировать (ВСЕ УДАЛИТСЯ!)
sudo mkfs.ext4 -F /dev/sdb1

# 3. Перемонтировать
sudo mount /dev/sdb1 /media/deck/arkane1
```

## Проверка после восстановления

```bash
# Проверить монтирование
mount | grep arkane

# Проверить здоровье
df -h | grep arkane

# Проверить права
ls -la /media/deck/arkane1
```

---

## Важно:

**НЕ форматируйте на Ubuntu 22.04!**
**Форматируйте ТОЛЬКО на Steam Deck!**

