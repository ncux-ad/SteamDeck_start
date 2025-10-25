#!/bin/bash

# Steam Deck Install Apps Script
# Скрипт для быстрой установки популярных приложений
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

# Функции для вывода
print_message() { echo -e "${BLUE}[INFO]${NC} $1"; }
print_success() { echo -e "${GREEN}[SUCCESS]${NC} $1"; }
print_warning() { echo -e "${YELLOW}[WARNING]${NC} $1"; }
print_error() { echo -e "${RED}[ERROR]${NC} $1"; }
print_header() { echo -e "${CYAN}=== $1 ===${NC}"; }

# Массивы приложений
declare -A EMULATORS
declare -A LAUNCHERS
declare -A MEDIA
declare -A UTILITIES
declare -A ARCHIVERS

# Эмуляторы
EMULATORS=(
    ["RetroArch"]="flatpak install flathub org.libretro.RetroArch"
    ["Yuzu"]="flatpak install flathub org.yuzu_emu.yuzu"
    ["Dolphin"]="flatpak install flathub org.DolphinEmu.DolphinEmu"
    ["PCSX2"]="flatpak install flathub net.pcsx2.PCSX2"
    ["PPSSPP"]="flatpak install flathub org.ppsspp.PPSSPP"
    ["Citra"]="flatpak install flathub org.citra_emu.citra"
    ["Ryujinx"]="flatpak install flathub org.ryujinx.Ryujinx"
    ["Cemu"]="yay -S cemu"
    ["RPCS3"]="flatpak install flathub net.rpcs3.RPCS3"
    ["MAME"]="flatpak install flathub org.mamedev.MAME"
)

# Лаунчеры
LAUNCHERS=(
    ["Heroic Games Launcher"]="flatpak install flathub com.heroicgameslauncher.hgl"
    ["Lutris"]="flatpak install flathub net.lutris.Lutris"
    ["Bottles"]="flatpak install flathub com.usebottles.bottles"
    ["ProtonUp-Qt"]="flatpak install flathub net.davidotek.pupgui2"
    ["ProtonTricks"]="flatpak install flathub com.github.Matoking.protontricks"
    ["SteamTinkerLaunch"]="yay -S steamtinkerlaunch"
    ["NonSteamLaunchers"]="yay -S non-steam-launchers"
)

# Медиа
MEDIA=(
    ["VLC"]="flatpak install flathub org.videolan.VLC"
    ["MPV"]="flatpak install flathub io.mpv.Mpv"
    ["Kodi"]="flatpak install flathub tv.kodi.Kodi"
    ["OBS Studio"]="flatpak install flathub com.obsproject.Studio"
    ["Audacity"]="flatpak install flathub org.audacityteam.Audacity"
    ["GIMP"]="flatpak install flathub org.gimp.GIMP"
    ["Krita"]="flatpak install flathub org.kde.krita"
    ["Blender"]="flatpak install flathub org.blender.Blender"
    ["HandBrake"]="flatpak install flathub fr.handbrake.ghb"
    ["Shotcut"]="flatpak install flathub org.shotcut.Shotcut"
)

# Утилиты
UTILITIES=(
    ["Firefox"]="flatpak install flathub org.mozilla.firefox"
    ["Chrome"]="flatpak install flathub com.google.Chrome"
    ["Discord"]="flatpak install flathub com.discordapp.Discord"
    ["Telegram"]="flatpak install flathub org.telegram.desktop"
    ["Spotify"]="flatpak install flathub com.spotify.Client"
    ["FileZilla"]="flatpak install flathub org.filezillaproject.FileZilla"
    ["GParted"]="flatpak install flathub org.gparted.GParted"
    ["Wireshark"]="flatpak install flathub org.wireshark.Wireshark"
    ["VirtualBox"]="flatpak install flathub org.virtualbox.VirtualBox"
    ["TeamViewer"]="flatpak install flathub com.teamviewer.TeamViewer"
    ["AnyDesk"]="flatpak install flathub com.anydesk.AnyDesk"
    ["Remmina"]="flatpak install flathub org.remmina.Remmina"
)

# Архиваторы
ARCHIVERS=(
    ["Ark"]="flatpak install flathub org.kde.ark"
    ["7-Zip"]="flatpak install flathub org.7zip.7zip"
    ["PeaZip"]="flatpak install flathub io.github.peazip.PeaZip"
    ["unrar"]="sudo pacman -S unrar"
    ["p7zip"]="sudo pacman -S p7zip"
    ["zip"]="sudo pacman -S zip"
    ["unzip"]="sudo pacman -S unzip"
    ["tar"]="sudo pacman -S tar"
)

# Функция для отображения меню
show_menu() {
    local category="$1"
    local -n apps_ref="$2"
    
    print_header "$category"
    echo
    
    local i=1
    for app in "${!apps_ref[@]}"; do
        echo "  $i) $app"
        ((i++))
    done
    
    echo "  0) Назад"
    echo
}

# Функция для установки приложения
install_app() {
    local app_name="$1"
    local -n apps_ref="$2"
    
    if [[ -n "${apps_ref[$app_name]}" ]]; then
        print_message "Установка: $app_name"
        
        if eval "${apps_ref[$app_name]}"; then
            print_success "$app_name установлен успешно"
        else
            print_error "Не удалось установить $app_name"
        fi
    else
        print_error "Приложение '$app_name' не найдено"
    fi
}

# Функция для массовой установки
install_multiple() {
    local -n apps_ref="$1"
    local selected_apps=("${@:2}")
    
    for app in "${selected_apps[@]}"; do
        if [[ -n "${apps_ref[$app]}" ]]; then
            install_app "$app" apps_ref
        fi
    done
}

# Функция для проверки установки
check_installation() {
    local app_name="$1"
    local -n apps_ref="$2"
    
    # Простая проверка по имени процесса или команде
    case "$app_name" in
        "Firefox")
            command -v firefox &> /dev/null
            ;;
        "Chrome")
            command -v google-chrome &> /dev/null
            ;;
        "Discord")
            command -v discord &> /dev/null
            ;;
        "VLC")
            command -v vlc &> /dev/null
            ;;
        "RetroArch")
            command -v retroarch &> /dev/null
            ;;
        *)
            # Для Flatpak приложений
            flatpak list | grep -i "$app_name" &> /dev/null
            ;;
    esac
}

# Функция для удаления приложения
uninstall_app() {
    local app_name="$1"
    
    if ! check_installation "$app_name" apps_ref; then
        print_warning "$app_name не установлен"
        return 0
    fi
    
    print_message "Удаление $app_name..."
    
    case "$app_name" in
        "Firefox")
            sudo pacman -R firefox --noconfirm
            ;;
        "Chrome")
            sudo pacman -R google-chrome --noconfirm
            ;;
        "Discord")
            sudo pacman -R discord --noconfirm
            ;;
        "VLC")
            sudo pacman -R vlc --noconfirm
            ;;
        "RetroArch")
            sudo pacman -R retroarch --noconfirm
            ;;
        "unrar")
            sudo pacman -R unrar --noconfirm
            ;;
        "7-Zip")
            sudo pacman -R p7zip --noconfirm
            ;;
        "WinRAR")
            sudo pacman -R rar --noconfirm
            ;;
        "Cemu")
            yay -R cemu --noconfirm
            ;;
        *)
            # Для Flatpak приложений
            local flatpak_id=$(flatpak list | grep -i "$app_name" | head -1 | awk '{print $2}')
            if [[ -n "$flatpak_id" ]]; then
                flatpak uninstall "$flatpak_id" -y
            else
                print_warning "Не удалось найти Flatpak ID для $app_name"
                return 1
            fi
            ;;
    esac
    
    if [[ $? -eq 0 ]]; then
        print_success "$app_name удален"
        return 0
    else
        print_error "Не удалось удалить $app_name"
        return 1
    fi
}

# Функция для удаления всех приложений из категории
uninstall_category() {
    local category_name="$1"
    local -n apps_ref="$2"
    
    print_header "УДАЛЕНИЕ $category_name"
    
    local uninstalled=0
    local failed=0
    
    for app_name in "${!apps_ref[@]}"; do
        if check_installation "$app_name" apps_ref; then
            if uninstall_app "$app_name"; then
                ((uninstalled++))
            else
                ((failed++))
            fi
        else
            print_message "$app_name не установлен, пропускаем"
        fi
    done
    
    echo
    print_success "Удалено приложений: $uninstalled"
    if [[ $failed -gt 0 ]]; then
        print_warning "Не удалось удалить: $failed"
    fi
}

# Функция для удаления всех приложений
uninstall_all() {
    print_header "УДАЛЕНИЕ ВСЕХ ПРИЛОЖЕНИЙ"
    print_warning "Это удалит ВСЕ приложения, установленные через этот скрипт!"
    read -p "Вы уверены? (y/N): " confirm
    
    if [[ "$confirm" != "y" && "$confirm" != "Y" ]]; then
        print_message "Отмена удаления"
        return 0
    fi
    
    local total_uninstalled=0
    local total_failed=0
    
    # Удаление по категориям
    print_message "Удаление эмуляторов..."
    uninstall_category "ЭМУЛЯТОРЫ" EMULATORS
    ((total_uninstalled += uninstalled))
    ((total_failed += failed))
    
    print_message "Удаление лаунчеров..."
    uninstall_category "ЛАУНЧЕРЫ ИГР" LAUNCHERS
    ((total_uninstalled += uninstalled))
    ((total_failed += failed))
    
    print_message "Удаление медиа приложений..."
    uninstall_category "МЕДИА ПРИЛОЖЕНИЯ" MEDIA
    ((total_uninstalled += uninstalled))
    ((total_failed += failed))
    
    print_message "Удаление утилит..."
    uninstall_category "УТИЛИТЫ" UTILITIES
    ((total_uninstalled += uninstalled))
    ((total_failed += failed))
    
    print_message "Удаление архиваторов..."
    uninstall_category "АРХИВАТОРЫ" ARCHIVERS
    ((total_uninstalled += uninstalled))
    ((total_failed += failed))
    
    echo
    print_success "=== УДАЛЕНИЕ ЗАВЕРШЕНО ==="
    print_success "Всего удалено: $total_uninstalled"
    if [[ $total_failed -gt 0 ]]; then
        print_warning "Не удалось удалить: $total_failed"
    fi
}

# Меню удаления приложений
uninstall_menu() {
    while true; do
        clear
        print_header "УДАЛЕНИЕ ПРИЛОЖЕНИЙ"
        echo
        echo "  1) Удалить эмуляторы"
        echo "  2) Удалить лаунчеры игр"
        echo "  3) Удалить медиа приложения"
        echo "  4) Удалить утилиты"
        echo "  5) Удалить архиваторы"
        echo "  6) Удалить конкретное приложение"
        echo "  0) Назад"
        echo
        
        read -p "Выберите категорию для удаления: " choice
        
        case $choice in
            1) uninstall_category "ЭМУЛЯТОРЫ" EMULATORS ;;
            2) uninstall_category "ЛАУНЧЕРЫ ИГР" LAUNCHERS ;;
            3) uninstall_category "МЕДИА ПРИЛОЖЕНИЯ" MEDIA ;;
            4) uninstall_category "УТИЛИТЫ" UTILITIES ;;
            5) uninstall_category "АРХИВАТОРЫ" ARCHIVERS ;;
            6) uninstall_specific_app ;;
            0) return ;;
            *) print_error "Неверный выбор" ;;
        esac
        
        echo
        read -p "Нажмите Enter для продолжения..."
    done
}

# Функция для удаления конкретного приложения
uninstall_specific_app() {
    print_header "УДАЛЕНИЕ КОНКРЕТНОГО ПРИЛОЖЕНИЯ"
    echo
    
    # Создаем список всех приложений
    local all_apps=()
    for app in "${!EMULATORS[@]}"; do all_apps+=("$app"); done
    for app in "${!LAUNCHERS[@]}"; do all_apps+=("$app"); done
    for app in "${!MEDIA[@]}"; do all_apps+=("$app"); done
    for app in "${!UTILITIES[@]}"; do all_apps+=("$app"); done
    for app in "${!ARCHIVERS[@]}"; do all_apps+=("$app"); done
    
    # Показываем установленные приложения
    local installed_apps=()
    for app in "${all_apps[@]}"; do
        if check_installation "$app" apps_ref; then
            installed_apps+=("$app")
        fi
    done
    
    if [[ ${#installed_apps[@]} -eq 0 ]]; then
        print_warning "Нет установленных приложений для удаления"
        return 0
    fi
    
    echo "Установленные приложения:"
    for i in "${!installed_apps[@]}"; do
        echo "  $((i+1))) ${installed_apps[$i]}"
    done
    echo "  0) Назад"
    echo
    
    read -p "Выберите приложение для удаления: " choice
    
    if [[ "$choice" == "0" ]]; then
        return 0
    fi
    
    if [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#installed_apps[@]}" ]]; then
        local selected_app="${installed_apps[$((choice-1))]}"
        uninstall_app "$selected_app"
    else
        print_error "Неверный выбор"
    fi
}

# Главное меню
main_menu() {
    while true; do
        clear
        print_header "STEAM DECK APP INSTALLER"
        echo
        echo "  1) Эмуляторы"
        echo "  2) Лаунчеры игр"
        echo "  3) Медиа приложения"
        echo "  4) Утилиты"
        echo "  5) Архиваторы"
        echo "  6) Быстрая установка (все популярные)"
        echo "  7) Проверить установленные приложения"
        echo "  8) Удалить приложения"
        echo "  9) Удалить все приложения"
        echo "  0) Выход"
        echo
        
        read -p "Выберите категорию: " choice
        
        case $choice in
            1) category_menu "ЭМУЛЯТОРЫ" EMULATORS ;;
            2) category_menu "ЛАУНЧЕРЫ ИГР" LAUNCHERS ;;
            3) category_menu "МЕДИА ПРИЛОЖЕНИЯ" MEDIA ;;
            4) category_menu "УТИЛИТЫ" UTILITIES ;;
            5) category_menu "АРХИВАТОРЫ" ARCHIVERS ;;
            6) quick_install ;;
            7) check_installed_apps ;;
            8) uninstall_menu ;;
            9) uninstall_all ;;
            0) exit 0 ;;
            *) print_error "Неверный выбор" ;;
        esac
    done
}

# Меню категории
category_menu() {
    local category="$1"
    local -n apps_ref="$2"
    
    while true; do
        clear
        show_menu "$category" apps_ref
        
        read -p "Выберите приложение (или 0 для возврата): " choice
        
        if [[ "$choice" == "0" ]]; then
            return
        elif [[ "$choice" =~ ^[0-9]+$ ]] && [[ "$choice" -ge 1 ]] && [[ "$choice" -le "${#apps_ref[@]}" ]]; then
            local app_names=("${!apps_ref[@]}")
            local selected_app="${app_names[$((choice-1))]}"
            
            print_message "Выбрано: $selected_app"
            read -p "Установить? (y/n): " confirm
            
            if [[ "$confirm" =~ ^[Yy]$ ]]; then
                install_app "$selected_app" apps_ref
                read -p "Нажмите Enter для продолжения..."
            fi
        else
            print_error "Неверный выбор"
            sleep 2
        fi
    done
}

# Быстрая установка популярных приложений
quick_install() {
    print_header "БЫСТРАЯ УСТАНОВКА"
    echo
    echo "Будут установлены следующие популярные приложения:"
    echo "  - ProtonUp-Qt (управление Proton)"
    echo "  - ProtonTricks (настройка совместимости)"
    echo "  - Heroic Games Launcher (Epic/GOG)"
    echo "  - Lutris (универсальный лаунчер)"
    echo "  - Bottles (Wine-контейнеры)"
    echo "  - VLC (медиаплеер)"
    echo "  - Firefox (браузер)"
    echo "  - Discord (чат)"
    echo "  - Ark (архиватор)"
    echo "  - unrar (распаковка RAR)"
    echo
    
    read -p "Продолжить установку? (y/n): " confirm
    
    if [[ "$confirm" =~ ^[Yy]$ ]]; then
        print_message "Начинаем быструю установку..."
        
        # Установка через Flatpak
        local flatpak_apps=(
            "ProtonUp-Qt"
            "ProtonTricks"
            "Heroic Games Launcher"
            "Lutris"
            "Bottles"
            "VLC"
            "Firefox"
            "Discord"
        )
        
        for app in "${flatpak_apps[@]}"; do
            install_app "$app" LAUNCHERS
        done
        
        # Установка через pacman
        print_message "Установка системных пакетов..."
        sudo pacman -S unrar p7zip zip unzip --noconfirm
        
        print_success "Быстрая установка завершена!"
        read -p "Нажмите Enter для продолжения..."
    fi
}

# Проверка установленных приложений
check_installed_apps() {
    print_header "УСТАНОВЛЕННЫЕ ПРИЛОЖЕНИЯ"
    echo
    
    local all_apps=()
    all_apps+=("${!EMULATORS[@]}")
    all_apps+=("${!LAUNCHERS[@]}")
    all_apps+=("${!MEDIA[@]}")
    all_apps+=("${!UTILITIES[@]}")
    all_apps+=("${!ARCHIVERS[@]}")
    
    local installed_count=0
    local total_count=${#all_apps[@]}
    
    for app in "${all_apps[@]}"; do
        if check_installation "$app" all_apps; then
            print_success "✓ $app"
            ((installed_count++))
        else
            print_warning "✗ $app"
        fi
    done
    
    echo
    print_message "Установлено: $installed_count из $total_count приложений"
    read -p "Нажмите Enter для продолжения..."
}

# Установка архиваторов (специальная функция)
install_archivers() {
    print_header "УСТАНОВКА АРХИВАТОРОВ"
    echo
    echo "Рекомендуемые архиваторы для работы с RAR:"
    echo "  1) unrar (командная строка)"
    echo "  2) Ark (графический интерфейс)"
    echo "  3) 7-Zip (универсальный)"
    echo "  4) Все архиваторы"
    echo "  0) Назад"
    echo
    
    read -p "Выберите архиватор: " choice
    
    case $choice in
        1)
            print_message "Установка unrar..."
            sudo pacman -S unrar --noconfirm
            print_success "unrar установлен. Использование: unrar x archive.rar"
            ;;
        2)
            print_message "Установка Ark..."
            flatpak install flathub org.kde.ark -y
            print_success "Ark установлен"
            ;;
        3)
            print_message "Установка 7-Zip..."
            flatpak install flathub org.7zip.7zip -y
            print_success "7-Zip установлен"
            ;;
        4)
            print_message "Установка всех архиваторов..."
            sudo pacman -S unrar p7zip zip unzip --noconfirm
            flatpak install flathub org.kde.ark org.7zip.7zip -y
            print_success "Все архиваторы установлены"
            ;;
        0)
            return
            ;;
        *)
            print_error "Неверный выбор"
            ;;
    esac
    
    read -p "Нажмите Enter для продолжения..."
}

# Показать справку
show_help() {
    echo "Steam Deck Install Apps Script v0.1"
    echo
    echo "Использование: $0 [ОПЦИЯ]"
    echo
    echo "ОПЦИИ:"
    echo "  interactive                - Интерактивное меню (по умолчанию)"
    echo "  emulators                  - Установить эмуляторы"
    echo "  launchers                  - Установить лаунчеры"
    echo "  media                      - Установить медиа приложения"
    echo "  utilities                  - Установить утилиты"
    echo "  archivers                  - Установить архиваторы"
    echo "  quick                      - Быстрая установка популярных"
    echo "  check                      - Проверить установленные приложения"
    echo "  uninstall                  - Удалить приложения"
    echo "  uninstall-all              - Удалить все приложения"
    echo "  help                       - Показать эту справку"
    echo
    echo "ПРИМЕРЫ:"
    echo "  $0                         # Интерактивное меню"
    echo "  $0 quick                   # Быстрая установка"
    echo "  $0 archivers               # Установить архиваторы"
    echo "  $0 check                   # Проверить установленные"
    echo "  $0 uninstall               # Удалить приложения"
    echo "  $0 uninstall-all           # Удалить все приложения"
}

# Основная функция
main() {
    case "${1:-interactive}" in
        "interactive")
            main_menu
            ;;
        "emulators")
            category_menu "ЭМУЛЯТОРЫ" EMULATORS
            ;;
        "launchers")
            category_menu "ЛАУНЧЕРЫ ИГР" LAUNCHERS
            ;;
        "media")
            category_menu "МЕДИА ПРИЛОЖЕНИЯ" MEDIA
            ;;
        "utilities")
            category_menu "УТИЛИТЫ" UTILITIES
            ;;
        "archivers")
            install_archivers
            ;;
        "quick")
            quick_install
            ;;
        "check")
            check_installed_apps
            ;;
        "uninstall")
            uninstall_menu
            ;;
        "uninstall-all")
            uninstall_all
            ;;
        "help"|"-h"|"--help")
            show_help
            ;;
        *)
            print_error "Неизвестная опция: $1"
            show_help
            exit 1
            ;;
    esac
}

# Запуск
main "$@"
