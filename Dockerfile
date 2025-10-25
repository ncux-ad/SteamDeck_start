# Dockerfile для эмуляции SteamOS
# Основан на Arch Linux (как SteamOS)
# Автор: @ncux11
# Версия: 0.1 (Октябрь 2025)

FROM archlinux:latest

# Устанавливаем метаданные
LABEL maintainer="Steam Deck Enhancement Pack"
LABEL description="Эмуляция SteamOS для тестирования скриптов"
LABEL version="0.1"

# Обновляем систему и устанавливаем базовые пакеты
RUN pacman -Syu --noconfirm && \
    pacman -S --noconfirm \
    base-devel \
    git \
    sudo \
    bash \
    python \
    python-pip \
    python-tkinter \
    htop \
    neofetch \
    nano \
    vim \
    curl \
    wget \
    unzip \
    tar \
    gzip \
    bzip2 \
    xz \
    p7zip \
    unrar \
    flatpak \
    pacman-contrib \
    systemd \
    dbus \
    polkit \
    && pacman -Scc --noconfirm

# Создаем пользователя deck (как в SteamOS)
RUN useradd -m -s /bin/bash deck && \
    echo "deck:deck" | chpasswd && \
    usermod -aG wheel deck && \
    echo "deck ALL=(ALL) NOPASSWD: ALL" >> /etc/sudoers

# Устанавливаем SteamOS-специфичные пакеты (эмуляция)
RUN pacman -S --noconfirm \
    mesa \
    vulkan-radeon \
    vulkan-tools \
    vulkan-headers \
    lib32-mesa \
    lib32-vulkan-radeon \
    lib32-vulkan-tools \
    steam \
    steam-native-runtime \
    && pacman -Scc --noconfirm

# Создаем директории SteamOS
RUN mkdir -p /home/deck/.steam/steam && \
    mkdir -p /home/deck/.local/share/Steam && \
    mkdir -p /home/deck/.config/steam && \
    mkdir -p /run/media/mmcblk0p1 && \
    chown -R deck:deck /home/deck

# Устанавливаем Python зависимости
RUN pip install --user psutil

# Создаем эмуляцию steamos-readonly
RUN echo '#!/bin/bash\n\
case "$1" in\n\
    "disable")\n\
        echo "SteamOS readonly mode disabled (emulated)"\n\
        ;;\n\
    "enable")\n\
        echo "SteamOS readonly mode enabled (emulated)"\n\
        ;;\n\
    "status")\n\
        echo "SteamOS readonly mode disabled (emulated)"\n\
        ;;\n\
    *)\n\
        echo "Usage: steamos-readonly {disable|enable|status}"\n\
        exit 1\n\
        ;;\n\
esac' > /usr/local/bin/steamos-readonly && \
    chmod +x /usr/local/bin/steamos-readonly

# Создаем эмуляцию Steam Deck специфичных команд
RUN echo '#!/bin/bash\n\
echo "Steam Deck hardware detected (emulated)"\n\
echo "CPU: AMD Custom APU (emulated)"\n\
echo "GPU: AMD RDNA 2 (emulated)"\n\
echo "Memory: 16GB (emulated)"\n\
echo "Storage: 64GB eMMC (emulated)"' > /usr/local/bin/steamdeck-info && \
    chmod +x /usr/local/bin/steamdeck-info

# Создаем эмуляцию Steam Deck контроллера
RUN echo '#!/bin/bash\n\
echo "Steam Deck controller connected (emulated)"\n\
echo "Buttons: A, B, X, Y, L1, R1, L2, R2, Select, Start, Steam, Menu"\n\
echo "D-pad: Up, Down, Left, Right"\n\
echo "Sticks: Left stick, Right stick"\n\
echo "Triggers: L2, R2"' > /usr/local/bin/steamdeck-controller && \
    chmod +x /usr/local/bin/steamdeck-controller

# Настраиваем окружение для тестирования
ENV STEAM_DECK=1
ENV STEAMOS=1
ENV DISPLAY=:0
ENV HOME=/home/deck
ENV USER=deck

# Создаем рабочую директорию
WORKDIR /home/deck/SteamDeck

# Копируем скрипты для тестирования
COPY scripts/ /home/deck/SteamDeck/scripts/
COPY guides/ /home/deck/SteamDeck/guides/
COPY README.md /home/deck/SteamDeck/
COPY code_review_report.md /home/deck/SteamDeck/

# Устанавливаем права доступа
RUN chmod +x /home/deck/SteamDeck/scripts/*.sh && \
    chmod +x /home/deck/SteamDeck/scripts/*.py && \
    chown -R deck:deck /home/deck/SteamDeck

# Создаем тестовые данные
RUN mkdir -p /home/deck/Downloads/test_games && \
    mkdir -p /home/deck/Games && \
    mkdir -p /run/media/mmcblk0p1/Games && \
    chown -R deck:deck /home/deck/Downloads /home/deck/Games /run/media/mmcblk0p1

# Создаем тестовые .sh игры
RUN echo '#!/bin/bash\n\
echo "Test Game 1 - Native Linux Game"\n\
echo "This is a test game for Steam Deck"\n\
echo "Game started successfully!"\n\
sleep 2\n\
echo "Game finished"' > /home/deck/Downloads/test_games/test_game_1.sh && \
    chmod +x /home/deck/Downloads/test_games/test_game_1.sh

RUN echo '#!/bin/bash\n\
echo "Test Game 2 - Another Native Linux Game"\n\
echo "This is another test game"\n\
echo "Installing dependencies..."\n\
sleep 1\n\
echo "Game installed and ready to play!"' > /home/deck/Downloads/test_games/test_game_2.sh && \
    chmod +x /home/deck/Downloads/test_games/test_game_2.sh

# Создаем тестовый скрипт установки
RUN echo '#!/bin/bash\n\
echo "Test Installation Script"\n\
echo "Installing test application..."\n\
echo "Creating desktop entry..."\n\
echo "Installation completed successfully!"' > /home/deck/Downloads/test_install.sh && \
    chmod +x /home/deck/Downloads/test_install.sh

# Настраиваем systemd для тестирования
RUN systemctl enable dbus && \
    systemctl enable systemd-resolved

# Создаем точку входа
COPY docker-entrypoint.sh /usr/local/bin/
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

# Переключаемся на пользователя deck
USER deck

# Устанавливаем переменные окружения
ENV PATH="/home/deck/.local/bin:$PATH"

# Открываем порт для X11 (если нужно)
EXPOSE 6000

# Точка входа
ENTRYPOINT ["/usr/local/bin/docker-entrypoint.sh"]
