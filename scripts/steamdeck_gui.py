#!/usr/bin/env python3
"""
Steam Deck Enhancement Pack GUI
Графический интерфейс для управления скриптами Steam Deck
Автор: @ncux11
Версия: 0.1 (Октябрь 2025)
"""

import tkinter as tk
from tkinter import ttk, messagebox, filedialog, scrolledtext, simpledialog
import subprocess
import threading
import os
import sys
import time
import queue
import getpass
from pathlib import Path

class SteamDeckGUI:
    def __init__(self, root):
        self.root = root
        self.root.title("Steam Deck Enhancement Pack")
        self.root.geometry("800x600")
        self.root.configure(bg='#2b2b2b')
        
        # Стили
        self.style = ttk.Style()
        self.style.theme_use('clam')
        self.style.configure('TNotebook', background='#2b2b2b')
        self.style.configure('TNotebook.Tab', background='#3c3c3c', foreground='white')
        self.style.configure('TFrame', background='#2b2b2b')
        self.style.configure('TLabel', background='#2b2b2b', foreground='white')
        self.style.configure('TButton', background='#4a4a4a', foreground='white')
        
        # Переменные
        self.scripts_dir = Path(__file__).parent
        self.output_text = None
        self.running_process = None
        self.progress_queue = queue.Queue()
        self.progress_bar = None
        self.progress_label = None
        self.sudo_password = None
        self.sudo_authenticated = False
        
        self.create_widgets()
        
        # Запускаем обработчик прогресса
        self.root.after(100, self.process_progress_queue)
        
    def create_widgets(self):
        # Главное меню
        self.create_menu()
        
        # Создание вкладок
        notebook = ttk.Notebook(self.root)
        notebook.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Вкладка "Система"
        self.create_system_tab(notebook)
        
        # Вкладка "Игры"
        self.create_games_tab(notebook)
        
        # Вкладка "Оптимизация"
        self.create_optimization_tab(notebook)
        
        # Вкладка "Утилиты"
        self.create_utilities_tab(notebook)
        
        # Вкладка "Offline"
        self.create_offline_tab(notebook)
        
        # Вкладка "Обложки"
        self.create_artwork_tab(notebook)
        
        # Вкладка "Логи"
        self.create_logs_tab(notebook)
        
    def create_menu(self):
        menubar = tk.Menu(self.root)
        self.root.config(menu=menubar)
        
        # Файл
        file_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Файл", menu=file_menu)
        file_menu.add_command(label="Выход", command=self.root.quit)
        
        # Помощь
        help_menu = tk.Menu(menubar, tearoff=0)
        menubar.add_cascade(label="Помощь", menu=help_menu)
        help_menu.add_command(label="О программе", command=self.show_about)
        help_menu.add_command(label="Документация", command=self.open_documentation)
        
    def create_system_tab(self, notebook):
        # Вкладка "Система"
        system_frame = ttk.Frame(notebook)
        notebook.add(system_frame, text="Система")
        
        # Заголовок
        title_label = ttk.Label(system_frame, text="Управление системой Steam Deck", 
                               font=('Arial', 16, 'bold'))
        title_label.pack(pady=10)
        
        # Кнопки системы
        buttons_frame = ttk.Frame(system_frame)
        buttons_frame.pack(pady=20)
        
        # Первая строка кнопок
        row1 = ttk.Frame(buttons_frame)
        row1.pack(pady=5)
        
        ttk.Button(row1, text="Настройка системы", 
                  command=lambda: self.run_script_with_sudo("steamdeck_setup.sh", "setup"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Резервная копия", 
                  command=lambda: self.run_script_with_sudo("steamdeck_backup.sh", "backup"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Очистка системы", 
                  command=lambda: self.run_script_with_sudo("steamdeck_cleanup.sh", "safe"),
                  width=20).pack(side='left', padx=5)
        
        # Вторая строка кнопок
        row2 = ttk.Frame(buttons_frame)
        row2.pack(pady=5)
        
        ttk.Button(row2, text="Мониторинг", 
                  command=lambda: self.run_script("steamdeck_monitor.sh", "all"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Статус системы", 
                  command=lambda: self.run_script("steamdeck_setup.sh", "status"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Сброс sudo", 
                  command=self.reset_sudo_auth,
                  width=20).pack(side='left', padx=5)
        
        # Третья строка кнопок - обновления
        row3 = ttk.Frame(buttons_frame)
        row3.pack(pady=5)
        
        ttk.Button(row3, text="Проверить обновления", 
                  command=self.check_updates,
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Обновить утилиту", 
                  command=self.update_utility,
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Откат обновления", 
                  command=self.rollback_update,
                  width=20).pack(side='left', padx=5)
        
        # Четвертая строка кнопок - дополнительные функции
        row4 = ttk.Frame(buttons_frame)
        row4.pack(pady=5)
        
        ttk.Button(row4, text="MicroSD", 
                  command=self.open_microsd_menu,
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row4, text="Восстановить бэкап", 
                  command=self.restore_backup,
                  width=20).pack(side='left', padx=5)
        
        # Информация о системе
        info_frame = ttk.LabelFrame(system_frame, text="Информация о системе")
        info_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.system_info = scrolledtext.ScrolledText(info_frame, height=10, 
                                                   bg='#1e1e1e', fg='white')
        self.system_info.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Загружаем информацию о системе
        self.load_system_info()
        
    def create_games_tab(self, notebook):
        # Вкладка "Игры"
        games_frame = ttk.Frame(notebook)
        notebook.add(games_frame, text="Игры")
        
        # Заголовок
        title_label = ttk.Label(games_frame, text="Управление играми", 
                               font=('Arial', 16, 'bold'))
        title_label.pack(pady=10)
        
        # Кнопки игр
        buttons_frame = ttk.Frame(games_frame)
        buttons_frame.pack(pady=20)
        
        # Первая строка - установка приложений
        row1 = ttk.Frame(buttons_frame)
        row1.pack(pady=5)
        
        ttk.Button(row1, text="Установить приложения", 
                  command=lambda: self.run_script("steamdeck_install_apps.sh", "interactive"),
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Быстрая установка", 
                  command=lambda: self.run_script("steamdeck_install_apps.sh", "quick"),
                  width=25).pack(side='left', padx=5)
        
        # Вторая строка - ярлыки
        row2 = ttk.Frame(buttons_frame)
        row2.pack(pady=5)
        
        ttk.Button(row2, text="Управление ярлыками", 
                  command=lambda: self.run_script("steamdeck_shortcuts.sh", "interactive"),
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Добавить в Steam", 
                  command=self.add_to_steam_dialog,
                  width=25).pack(side='left', padx=5)
        
        # Третья строка - Native Linux игры
        row3 = ttk.Frame(buttons_frame)
        row3.pack(pady=5)
        
        ttk.Button(row3, text="Найти .sh игры", 
                  command=lambda: self.run_script("steamdeck_native_games.sh", "find"),
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Добавить .sh игры", 
                  command=lambda: self.run_script("steamdeck_native_games.sh", "batch"),
                  width=25).pack(side='left', padx=5)
        
        # Четвертая строка - эмуляторы и лаунчеры
        row4 = ttk.Frame(buttons_frame)
        row4.pack(pady=5)
        
        ttk.Button(row4, text="Эмуляторы", 
                  command=lambda: self.run_script("steamdeck_shortcuts.sh", "emulators"),
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row4, text="Лаунчеры", 
                  command=lambda: self.run_script("steamdeck_shortcuts.sh", "launchers"),
                  width=25).pack(side='left', padx=5)
        
        # Пятая строка - совместимость
        row5 = ttk.Frame(buttons_frame)
        row5.pack(pady=5)
        
        ttk.Button(row5, text="Запуск с Sniper", 
                  command=self.run_game_with_sniper,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row5, text="Диагностика игры", 
                  command=self.diagnose_game,
                  width=25).pack(side='left', padx=5)
        
        # Шестая строка - SteamRip
        row6 = ttk.Frame(buttons_frame)
        row6.pack(pady=5)
        
        ttk.Button(row6, text="SteamRip RAR", 
                  command=self.run_steamrip_handler,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row6, text="Найти RAR файлы", 
                  command=self.find_steamrip_rar,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row6, text="Массовая обработка", 
                  command=self.batch_process_steamrip,
                  width=25).pack(side='left', padx=5)
        
        # Седьмая строка - дополнительные функции SteamRip
        row7 = ttk.Frame(buttons_frame)
        row7.pack(pady=5)
        
        ttk.Button(row7, text="Анализ RAR файла", 
                  command=self.analyze_steamrip_rar,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row7, text="Распаковать RAR", 
                  command=self.extract_steamrip_rar,
                  width=25).pack(side='left', padx=5)
        
        # Информация о играх
        info_frame = ttk.LabelFrame(games_frame, text="Информация о играх")
        info_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.games_info = scrolledtext.ScrolledText(info_frame, height=8, 
                                                  bg='#1e1e1e', fg='white')
        self.games_info.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Загружаем информацию о играх
        self.load_games_info()
        
    def create_optimization_tab(self, notebook):
        # Вкладка "Оптимизация"
        opt_frame = ttk.Frame(notebook)
        notebook.add(opt_frame, text="Оптимизация")
        
        # Заголовок
        title_label = ttk.Label(opt_frame, text="Оптимизация производительности", 
                               font=('Arial', 16, 'bold'))
        title_label.pack(pady=10)
        
        # Профили производительности
        profiles_frame = ttk.LabelFrame(opt_frame, text="Профили производительности")
        profiles_frame.pack(fill='x', padx=10, pady=10)
        
        profiles_buttons = ttk.Frame(profiles_frame)
        profiles_buttons.pack(pady=10)
        
        ttk.Button(profiles_buttons, text="Производительность", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "performance"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(profiles_buttons, text="Баланс", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "profile BALANCED"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(profiles_buttons, text="Экономия батареи", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "battery"),
                  width=20).pack(side='left', padx=5)
        
        # Настройки TDP
        tdp_frame = ttk.LabelFrame(opt_frame, text="Настройка TDP")
        tdp_frame.pack(fill='x', padx=10, pady=10)
        
        tdp_buttons = ttk.Frame(tdp_frame)
        tdp_buttons.pack(pady=10)
        
        ttk.Button(tdp_buttons, text="3W (Макс. батарея)", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "profile BATTERY_SAVER"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(tdp_buttons, text="10W (Баланс)", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "profile BALANCED"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(tdp_buttons, text="15W (Макс. производительность)", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "profile PERFORMANCE"),
                  width=20).pack(side='left', padx=5)
        
        # Оптимизация для игр
        games_opt_frame = ttk.LabelFrame(opt_frame, text="Оптимизация для игр")
        games_opt_frame.pack(fill='x', padx=10, pady=10)
        
        games_opt_buttons = ttk.Frame(games_opt_frame)
        games_opt_buttons.pack(pady=10)
        
        ttk.Button(games_opt_buttons, text="Cyberpunk 2077", 
                  command=lambda: self.run_script("steamdeck_optimizer.sh", "game cyberpunk"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(games_opt_buttons, text="Elden Ring", 
                  command=lambda: self.run_script("steamdeck_optimizer.sh", "game elden"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(games_opt_buttons, text="Инди-игры", 
                  command=lambda: self.run_script("steamdeck_optimizer.sh", "game indie"),
                  width=20).pack(side='left', padx=5)
        
        # Мониторинг
        monitor_frame = ttk.LabelFrame(opt_frame, text="Мониторинг")
        monitor_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        monitor_buttons = ttk.Frame(monitor_frame)
        monitor_buttons.pack(pady=10)
        
        ttk.Button(monitor_buttons, text="Показать статус", 
                  command=lambda: self.run_script("steamdeck_optimizer.sh", "status"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(monitor_buttons, text="Мониторинг в реальном времени", 
                  command=lambda: self.run_script("steamdeck_monitor.sh", "realtime 2"),
                  width=30).pack(side='left', padx=5)
        
        # Область вывода
        self.opt_output = scrolledtext.ScrolledText(monitor_frame, height=8, 
                                                  bg='#1e1e1e', fg='white')
        self.opt_output.pack(fill='both', expand=True, padx=5, pady=5)
        
    def create_utilities_tab(self, notebook):
        # Вкладка "Утилиты"
        utils_frame = ttk.Frame(notebook)
        notebook.add(utils_frame, text="Утилиты")
        
        # Заголовок
        title_label = ttk.Label(utils_frame, text="Дополнительные утилиты", 
                               font=('Arial', 16, 'bold'))
        title_label.pack(pady=10)
        
        # Кнопки утилит
        buttons_frame = ttk.Frame(utils_frame)
        buttons_frame.pack(pady=20)
        
        # Первая строка
        row1 = ttk.Frame(buttons_frame)
        row1.pack(pady=5)
        
        ttk.Button(row1, text="Очистка кэша", 
                  command=lambda: self.run_script("steamdeck_cleanup.sh", "safe"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Полная очистка", 
                  command=lambda: self.run_script("steamdeck_cleanup.sh", "full"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Очистка Steam", 
                  command=lambda: self.run_script("steamdeck_cleanup.sh", "steam"),
                  width=20).pack(side='left', padx=5)
        
        # Вторая строка
        row2 = ttk.Frame(buttons_frame)
        row2.pack(pady=5)
        
        ttk.Button(row2, text="Статистика диска", 
                  command=lambda: self.run_script("steamdeck_cleanup.sh", "disk"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Поиск дубликатов", 
                  command=lambda: self.run_script("steamdeck_cleanup.sh", "duplicates"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Создать бэкап", 
                  command=lambda: self.run_script("steamdeck_backup.sh", "backup"),
                  width=20).pack(side='left', padx=5)
        
        # Третья строка
        row3 = ttk.Frame(buttons_frame)
        row3.pack(pady=5)
        
        ttk.Button(row3, text="Список бэкапов", 
                  command=lambda: self.run_script("steamdeck_backup.sh", "list"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Настроить профили", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "setup"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Сброс настроек", 
                  command=lambda: self.run_script_with_sudo("steamdeck_optimizer.sh", "reset"),
                  width=20).pack(side='left', padx=5)
        
        # Область вывода
        output_frame = ttk.LabelFrame(utils_frame, text="Вывод команд")
        output_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Прогресс-бар
        progress_frame = ttk.Frame(output_frame)
        progress_frame.pack(fill='x', padx=5, pady=5)
        
        self.progress_label = ttk.Label(progress_frame, text="Готов к работе")
        self.progress_label.pack(side='left')
        
        self.progress_bar = ttk.Progressbar(progress_frame, mode='indeterminate')
        self.progress_bar.pack(side='right', fill='x', expand=True, padx=(10, 0))
        
        self.utils_output = scrolledtext.ScrolledText(output_frame, height=10, 
                                                    bg='#1e1e1e', fg='white')
        self.utils_output.pack(fill='both', expand=True, padx=5, pady=5)
        
    def create_offline_tab(self, notebook):
        # Вкладка "Offline"
        offline_frame = ttk.Frame(notebook)
        notebook.add(offline_frame, text="Offline")
        
        # Заголовок
        title_label = ttk.Label(offline_frame, text="Offline-режим и трюки", 
                               font=('Arial', 16, 'bold'))
        title_label.pack(pady=10)
        
        # Кнопки offline-режима
        buttons_frame = ttk.Frame(offline_frame)
        buttons_frame.pack(pady=20)
        
        # Первая строка - настройка offline
        row1 = ttk.Frame(buttons_frame)
        row1.pack(pady=5)
        
        ttk.Button(row1, text="Настройка Offline", 
                  command=lambda: self.run_script("steamdeck_offline_setup.sh", "setup"),
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Offline Меню", 
                  command=self.run_offline_menu,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Запуск Steam Offline", 
                  command=self.run_steam_offline,
                  width=25).pack(side='left', padx=5)
        
        # Вторая строка - профили производительности
        row2 = ttk.Frame(buttons_frame)
        row2.pack(pady=5)
        
        ttk.Button(row2, text="Макс. Производительность", 
                  command=self.run_max_performance,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Баланс", 
                  command=self.run_balanced_profile,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Экономия Батареи", 
                  command=self.run_battery_saver,
                  width=25).pack(side='left', padx=5)
        
        # Третья строка - утилиты offline
        row3 = ttk.Frame(buttons_frame)
        row3.pack(pady=5)
        
        ttk.Button(row3, text="Очистка Памяти", 
                  command=self.run_free_memory,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Бэкап Сохранений", 
                  command=self.run_backup_saves,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Управление Медиа", 
                  command=self.run_media_manager,
                  width=25).pack(side='left', padx=5)
        
        # Четвертая строка - эмуляция и ROM-ы
        row4 = ttk.Frame(buttons_frame)
        row4.pack(pady=5)
        
        ttk.Button(row4, text="RetroArch", 
                  command=self.run_retroarch,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row4, text="Управление ROM-ами", 
                  command=self.run_roms_manager,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row4, text="VLC Медиа-плеер", 
                  command=self.run_vlc,
                  width=25).pack(side='left', padx=5)
        
        # Пятая строка - системные трюки
        row5 = ttk.Frame(buttons_frame)
        row5.pack(pady=5)
        
        ttk.Button(row5, text="Отключить Wi-Fi", 
                  command=self.disable_wifi,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row5, text="Включить Wi-Fi", 
                  command=self.enable_wifi,
                  width=25).pack(side='left', padx=5)
        
        ttk.Button(row5, text="Авто-Профиль", 
                  command=self.run_auto_profile,
                  width=25).pack(side='left', padx=5)
        
        # Информация о offline-режиме
        info_frame = ttk.LabelFrame(offline_frame, text="Информация о Offline-режиме")
        info_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        self.offline_info = scrolledtext.ScrolledText(info_frame, height=8, 
                                                    bg='#1e1e1e', fg='white')
        self.offline_info.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Загружаем информацию о offline-режиме
        self.load_offline_info()
        
    def create_logs_tab(self, notebook):
        # Вкладка "Логи"
        logs_frame = ttk.Frame(notebook)
        notebook.add(logs_frame, text="Логи")
        
        # Заголовок
        title_label = ttk.Label(logs_frame, text="Логи и мониторинг", 
                               font=('Arial', 16, 'bold'))
        title_label.pack(pady=10)
        
        # Кнопки логов
        buttons_frame = ttk.Frame(logs_frame)
        buttons_frame.pack(pady=10)
        
        ttk.Button(buttons_frame, text="Обновить логи", 
                  command=self.refresh_logs,
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(buttons_frame, text="Очистить логи", 
                  command=self.clear_logs,
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(buttons_frame, text="Сохранить логи", 
                  command=self.save_logs,
                  width=20).pack(side='left', padx=5)
        
        # Область логов
        self.logs_text = scrolledtext.ScrolledText(logs_frame, height=20, 
                                                  bg='#1e1e1e', fg='white')
        self.logs_text.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Загружаем начальные логи
        self.refresh_logs()
        
    def run_script(self, script_name, args=""):
        """Запуск скрипта в отдельном потоке"""
        def run():
            try:
                script_path = self.scripts_dir / script_name
                if not script_path.exists():
                    self.append_output(f"Ошибка: Скрипт {script_name} не найден")
                    return
                
                # Делаем скрипт исполняемым
                os.chmod(script_path, 0o755)
                
                # Формируем команду
                if args:
                    cmd = [str(script_path), args]
                else:
                    cmd = [str(script_path)]
                
                self.append_output(f"Запуск: {' '.join(cmd)}")
                
                # Определяем, нужен ли прогресс-бар для этой операции
                long_operations = [
                    "steamdeck_setup.sh setup",
                    "steamdeck_steamrip.sh extract",
                    "steamdeck_steamrip.sh batch",
                    "steamdeck_install_apps.sh quick",
                    "steamdeck_cleanup.sh full",
                    "steamdeck_backup.sh backup"
                ]
                
                operation_key = f"{script_name} {args}".strip()
                show_progress = any(op in operation_key for op in long_operations)
                
                if show_progress:
                    self.progress_queue.put("SHOW_PROGRESS")
                    self.progress_queue.put(f"UPDATE:Выполняется {script_name}...")
                
                # Запускаем процесс
                process = subprocess.Popen(
                    cmd,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )
                
                self.running_process = process
                
                # Читаем вывод в реальном времени
                for line in iter(process.stdout.readline, ''):
                    if line:
                        self.append_output(line.rstrip())
                        # Обновляем прогресс для длительных операций
                        if show_progress and "установка" in line.lower():
                            self.progress_queue.put(f"UPDATE:Установка пакетов...")
                        elif show_progress and "распаковка" in line.lower():
                            self.progress_queue.put(f"UPDATE:Распаковка файлов...")
                        elif show_progress and "очистка" in line.lower():
                            self.progress_queue.put(f"UPDATE:Очистка системы...")
                
                process.wait()
                self.append_output(f"Команда завершена с кодом: {process.returncode}")
                
                if show_progress:
                    self.progress_queue.put("HIDE_PROGRESS")
                
            except Exception as e:
                self.append_output(f"Ошибка: {str(e)}")
                if show_progress:
                    self.progress_queue.put("HIDE_PROGRESS")
            finally:
                self.running_process = None
        
        # Запускаем в отдельном потоке
        thread = threading.Thread(target=run)
        thread.daemon = True
        thread.start()
        
    def append_output(self, text):
        """Добавление текста в область вывода"""
        def update():
            # Находим активную вкладку и добавляем текст
            for widget in [self.system_info, self.games_info, self.opt_output, 
                          self.utils_output, self.logs_text]:
                if widget.winfo_exists():
                    widget.insert(tk.END, text + "\n")
                    widget.see(tk.END)
        
        # Обновляем UI в главном потоке
        self.root.after(0, update)
    
    def show_progress(self, message="Выполняется операция..."):
        """Показать прогресс-бар"""
        if self.progress_bar and self.progress_label:
            self.progress_label.config(text=message)
            self.progress_bar.start(10)
    
    def hide_progress(self, message="Готов к работе"):
        """Скрыть прогресс-бар"""
        if self.progress_bar and self.progress_label:
            self.progress_bar.stop()
            self.progress_label.config(text=message)
    
    def update_progress(self, message):
        """Обновить сообщение прогресса"""
        if self.progress_label:
            self.progress_label.config(text=message)
    
    def process_progress_queue(self):
        """Обработка очереди прогресса"""
        try:
            while True:
                message = self.progress_queue.get_nowait()
                if message == "SHOW_PROGRESS":
                    self.show_progress()
                elif message == "HIDE_PROGRESS":
                    self.hide_progress()
                elif message.startswith("UPDATE:"):
                    self.update_progress(message[7:])
        except queue.Empty:
            pass
        finally:
            self.root.after(100, self.process_progress_queue)
    
    def request_sudo_password(self):
        """Запрос пароля sudo у пользователя"""
        if self.sudo_authenticated and self.sudo_password:
            return True
            
        # Показываем диалог ввода пароля
        password = simpledialog.askstring(
            "Требуется пароль sudo",
            "Введите пароль для выполнения административных команд:",
            show='*'
        )
        
        if not password:
            self.append_output("❌ Пароль не введен. Операция отменена.")
            return False
            
        # Проверяем пароль
        if self.verify_sudo_password(password):
            self.sudo_password = password
            self.sudo_authenticated = True
            self.append_output("✅ Пароль sudo принят")
            return True
        else:
            self.append_output("❌ Неверный пароль sudo")
            return False
    
    def verify_sudo_password(self, password):
        """Проверка пароля sudo"""
        try:
            # Создаем временный процесс для проверки пароля
            process = subprocess.Popen(
                ['sudo', '-S', 'echo', 'test'],
                stdin=subprocess.PIPE,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
                text=True
            )
            
            stdout, stderr = process.communicate(input=password + '\n')
            return process.returncode == 0
        except Exception as e:
            self.append_output(f"❌ Ошибка проверки пароля: {e}")
            return False
    
    def run_script_with_sudo(self, script_name, args=""):
        """Запуск скрипта с sudo"""
        if not self.request_sudo_password():
            return
            
        def run():
            try:
                script_path = self.scripts_dir / script_name
                if not script_path.exists():
                    self.append_output(f"Ошибка: Скрипт {script_name} не найден")
                    return
                
                # Делаем скрипт исполняемым
                os.chmod(script_path, 0o755)
                
                # Формируем команду с sudo
                if args:
                    cmd = ['sudo', '-S', str(script_path), args]
                else:
                    cmd = ['sudo', '-S', str(script_path)]
                
                self.append_output(f"Запуск с sudo: {' '.join(cmd)}")
                
                # Запускаем процесс
                process = subprocess.Popen(
                    cmd,
                    stdin=subprocess.PIPE,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )
                
                self.running_process = process
                
                # Отправляем пароль в stdin
                process.stdin.write(self.sudo_password + '\n')
                process.stdin.flush()
                
                # Читаем вывод в реальном времени
                for line in iter(process.stdout.readline, ''):
                    if line:
                        self.append_output(line.rstrip())
                
                process.wait()
                self.append_output(f"Команда завершена с кодом: {process.returncode}")
                
            except Exception as e:
                self.append_output(f"Ошибка: {str(e)}")
            finally:
                self.running_process = None
        
        # Запускаем в отдельном потоке
        thread = threading.Thread(target=run)
        thread.daemon = True
        thread.start()
    
    def reset_sudo_auth(self):
        """Сброс sudo аутентификации"""
        self.sudo_password = None
        self.sudo_authenticated = False
        self.append_output("🔐 Sudo аутентификация сброшена")
    
    def open_microsd_menu(self):
        """Открыть меню управления MicroSD"""
        # Создаем диалог MicroSD
        dialog = tk.Toplevel(self.root)
        dialog.title("Управление MicroSD")
        dialog.geometry("500x400")
        dialog.configure(bg='#2b2b2b')
        
        # Заголовок
        ttk.Label(dialog, text="Управление MicroSD картами", 
                 font=('Arial', 12, 'bold')).pack(pady=10)
        
        # Кнопки управления
        buttons_frame = ttk.Frame(dialog)
        buttons_frame.pack(pady=10)
        
        # Первая строка
        row1 = ttk.Frame(buttons_frame)
        row1.pack(pady=5)
        
        ttk.Button(row1, text="Проверить карты", 
                  command=lambda: self.run_script("steamdeck_microsd.sh", "check"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row1, text="Информация о монтировании", 
                  command=lambda: self.run_script("steamdeck_microsd.sh", "mount-info"),
                  width=20).pack(side='left', padx=5)
        
        # Вторая строка
        row2 = ttk.Frame(buttons_frame)
        row2.pack(pady=5)
        
        ttk.Button(row2, text="Диагностика UI", 
                  command=lambda: self.run_script("steamdeck_microsd.sh", "diagnose"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row2, text="Обновить UI", 
                  command=lambda: self.run_script_with_sudo("steamdeck_microsd.sh", "refresh"),
                  width=20).pack(side='left', padx=5)
        
        # Третья строка
        row3 = ttk.Frame(buttons_frame)
        row3.pack(pady=5)
        
        ttk.Button(row3, text="Исправить проблемы", 
                  command=lambda: self.run_script_with_sudo("steamdeck_microsd.sh", "fix"),
                  width=20).pack(side='left', padx=5)
        
        ttk.Button(row3, text="Безопасно извлечь", 
                  command=lambda: self.run_script_with_sudo("steamdeck_microsd.sh", "safely-remove"),
                  width=20).pack(side='left', padx=5)
        
        # Четвертая строка
        row4 = ttk.Frame(buttons_frame)
        row4.pack(pady=5)
        
        ttk.Button(row4, text="Тестирование", 
                  command=lambda: self.run_script("steamdeck_microsd.sh", "test"),
                  width=20).pack(side='left', padx=5)
        
        # Область вывода
        output_frame = ttk.LabelFrame(dialog, text="Вывод команд")
        output_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        microsd_output = scrolledtext.ScrolledText(output_frame, height=10, 
                                                  bg='#1e1e1e', fg='white')
        microsd_output.pack(fill='both', expand=True, padx=5, pady=5)
        
        # Кнопка закрытия
        ttk.Button(dialog, text="Закрыть", command=dialog.destroy).pack(pady=10)
        
        # Сохраняем ссылку на область вывода для этого диалога
        dialog.microsd_output = microsd_output
        
    def load_system_info(self):
        """Загрузка информации о системе"""
        try:
            # Получаем информацию о системе
            import platform
            import psutil
            
            info = f"Система: {platform.system()} {platform.release()}\n"
            info += f"Процессор: {platform.processor()}\n"
            info += f"Память: {psutil.virtual_memory().total // (1024**3)} GB\n"
            info += f"Диск: {psutil.disk_usage('/').total // (1024**3)} GB\n"
            
            self.system_info.insert(tk.END, info)
            
        except ImportError:
            self.system_info.insert(tk.END, "psutil не установлен. Установите: pip install psutil")
        except Exception as e:
            self.system_info.insert(tk.END, f"Ошибка загрузки информации: {e}")
            
    def load_games_info(self):
        """Загрузка информации о играх"""
        try:
            # Проверяем установленные Flatpak приложения
            result = subprocess.run(['flatpak', 'list', '--app'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                apps = result.stdout.strip().split('\n')
                self.games_info.insert(tk.END, f"Установлено Flatpak приложений: {len(apps)}\n")
            else:
                self.games_info.insert(tk.END, "Flatpak не доступен\n")
                
        except Exception as e:
            self.games_info.insert(tk.END, f"Ошибка загрузки информации о играх: {e}")
            
    def restore_backup(self):
        """Диалог восстановления из резервной копии"""
        file_path = filedialog.askopenfilename(
            title="Выберите файл резервной копии",
            filetypes=[("Tar archives", "*.tar.gz"), ("All files", "*.*")]
        )
        
        if file_path:
            self.run_script("steamdeck_backup.sh", f"restore {file_path}")
    
    def check_updates(self):
        """Проверка обновлений утилиты"""
        import subprocess
        import threading
        
        def check_updates_thread():
            try:
                # Запускаем проверку обновлений
                result = subprocess.run(
                    ["bash", "scripts/steamdeck_update.sh", "check"],
                    capture_output=True,
                    text=True,
                    cwd=os.path.expanduser("~/SteamDeck")
                )
                
                # Создаем диалог с результатом
                self.root.after(0, lambda: self.show_update_result(result))
                
            except Exception as e:
                self.root.after(0, lambda: self.show_update_error(str(e)))
        
        # Запускаем в отдельном потоке
        thread = threading.Thread(target=check_updates_thread)
        thread.daemon = True
        thread.start()
        
        # Показываем индикатор загрузки
        self.show_progress("Проверка обновлений...")
    
    def show_update_result(self, result):
        """Показать результат проверки обновлений"""
        self.hide_progress()
        
        dialog = tk.Toplevel(self.root)
        dialog.title("Результат проверки обновлений")
        dialog.geometry("600x400")
        dialog.configure(bg='#2b2b2b')
        
        # Заголовок
        title_label = tk.Label(dialog, text="Проверка обновлений Steam Deck Enhancement Pack", 
                              font=('Arial', 14, 'bold'), fg='white', bg='#2b2b2b')
        title_label.pack(pady=10)
        
        # Область вывода
        output_frame = tk.Frame(dialog, bg='#2b2b2b')
        output_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        text_widget = scrolledtext.ScrolledText(output_frame, height=15, width=70, 
                                               bg='#1e1e1e', fg='white', 
                                               font=('Consolas', 10))
        text_widget.pack(fill='both', expand=True)
        
        # Выводим результат
        text_widget.insert(tk.END, "=== ВЫВОД СКРИПТА ===\n")
        text_widget.insert(tk.END, f"Код возврата: {result.returncode}\n\n")
        
        if result.stdout:
            text_widget.insert(tk.END, "STDOUT:\n")
            text_widget.insert(tk.END, result.stdout)
            text_widget.insert(tk.END, "\n")
        
        if result.stderr:
            text_widget.insert(tk.END, "\nSTDERR:\n")
            text_widget.insert(tk.END, result.stderr)
        
        # Анализируем результат
        text_widget.insert(tk.END, "\n=== АНАЛИЗ РЕЗУЛЬТАТА ===\n")
        
        if result.returncode == 0:
            if "Доступно обновление" in result.stdout:
                text_widget.insert(tk.END, "✅ Доступно обновление!\n")
                text_widget.insert(tk.END, "Нажмите 'Обновить утилиту' для установки.\n")
            elif "последняя версия" in result.stdout:
                text_widget.insert(tk.END, "✅ У вас установлена последняя версия.\n")
            else:
                text_widget.insert(tk.END, "ℹ️ Проверка завершена.\n")
        else:
            text_widget.insert(tk.END, "❌ Ошибка при проверке обновлений.\n")
            text_widget.insert(tk.END, "Проверьте подключение к интернету.\n")
        
        text_widget.config(state=tk.DISABLED)
        
        # Кнопки
        button_frame = tk.Frame(dialog, bg='#2b2b2b')
        button_frame.pack(pady=10)
        
        if result.returncode == 0 and "Доступно обновление" in result.stdout:
            tk.Button(button_frame, text="Обновить сейчас", 
                     command=lambda: [dialog.destroy(), self.update_utility()],
                     bg='#4CAF50', fg='white', font=('Arial', 10, 'bold')).pack(side='left', padx=5)
        
        tk.Button(button_frame, text="Закрыть", 
                 command=dialog.destroy,
                 bg='#666666', fg='white').pack(side='left', padx=5)
    
    def show_update_error(self, error_msg):
        """Показать ошибку проверки обновлений"""
        self.hide_progress()
        messagebox.showerror("Ошибка проверки обновлений", 
                           f"Не удалось проверить обновления:\n\n{error_msg}")
    
    def update_utility(self):
        """Обновление утилиты"""
        result = messagebox.askyesno(
            "Обновление утилиты",
            "Обновить Steam Deck Enhancement Pack до последней версии?\n\n"
            "Будет создана резервная копия текущей версии."
        )
        
        if result:
            self.run_script_with_progress("steamdeck_update.sh", "update", "Обновление утилиты...")
    
    def rollback_update(self):
        """Откат последнего обновления"""
        result = messagebox.askyesno(
            "Откат обновления",
            "Откатить последнее обновление утилиты?\n\n"
            "Восстановится предыдущая версия из резервной копии."
        )
        
        if result:
            self.run_script("steamdeck_update.sh", "rollback", "Откат обновления...")
    
    def run_script_with_progress(self, script_name, args="", message=""):
        """Запуск скрипта с прогресс-баром и детальным выводом"""
        import subprocess
        import threading
        
        def run_with_progress():
            try:
                script_path = self.scripts_dir / script_name
                if not script_path.exists():
                    self.root.after(0, lambda: self.append_output(f"Ошибка: Скрипт {script_name} не найден"))
                    return
                
                # Показываем прогресс
                self.root.after(0, lambda: self.show_progress(message or f"Выполнение {script_name}..."))
                
                # Запускаем скрипт
                process = subprocess.Popen(
                    ["bash", str(script_path), args] if args else ["bash", str(script_path)],
                    stdout=subprocess.PIPE,
                    stderr=subprocess.STDOUT,
                    text=True,
                    bufsize=1,
                    universal_newlines=True
                )
                
                # Читаем вывод в реальном времени
                while True:
                    output = process.stdout.readline()
                    if output == '' and process.poll() is not None:
                        break
                    if output:
                        self.root.after(0, lambda o=output: self.append_output(o.strip()))
                
                # Получаем код возврата
                return_code = process.poll()
                
                # Скрываем прогресс
                self.root.after(0, self.hide_progress)
                
                # Показываем результат
                if return_code == 0:
                    self.root.after(0, lambda: self.append_output(f"✅ {script_name} выполнен успешно"))
                else:
                    self.root.after(0, lambda: self.append_output(f"❌ {script_name} завершился с ошибкой (код: {return_code})"))
                
            except Exception as e:
                self.root.after(0, self.hide_progress)
                self.root.after(0, lambda: self.append_output(f"Ошибка выполнения {script_name}: {e}"))
        
        # Запускаем в отдельном потоке
        thread = threading.Thread(target=run_with_progress)
        thread.daemon = True
        thread.start()
            
    def add_to_steam_dialog(self):
        """Диалог добавления приложения в Steam"""
        dialog = tk.Toplevel(self.root)
        dialog.title("Добавить в Steam")
        dialog.geometry("400x200")
        dialog.configure(bg='#2b2b2b')
        
        # Название
        ttk.Label(dialog, text="Название приложения:").pack(pady=5)
        name_entry = ttk.Entry(dialog, width=40)
        name_entry.pack(pady=5)
        
        # Путь к файлу
        ttk.Label(dialog, text="Путь к исполняемому файлу:").pack(pady=5)
        path_frame = ttk.Frame(dialog)
        path_frame.pack(pady=5)
        
        path_entry = ttk.Entry(path_frame, width=30)
        path_entry.pack(side='left', padx=5)
        
        def browse_file():
            file_path = filedialog.askopenfilename()
            if file_path:
                path_entry.delete(0, tk.END)
                path_entry.insert(0, file_path)
        
        ttk.Button(path_frame, text="Обзор", command=browse_file).pack(side='left')
        
        # Кнопки
        button_frame = ttk.Frame(dialog)
        button_frame.pack(pady=20)
        
        def add_to_steam():
            name = name_entry.get()
            path = path_entry.get()
            
            if name and path:
                self.run_script("steamdeck_shortcuts.sh", f'create "{name}" "{path}"')
                dialog.destroy()
            else:
                messagebox.showerror("Ошибка", "Заполните все поля")
        
        ttk.Button(button_frame, text="Добавить", command=add_to_steam).pack(side='left', padx=5)
        ttk.Button(button_frame, text="Отмена", command=dialog.destroy).pack(side='left', padx=5)
        
    def refresh_logs(self):
        """Обновление логов"""
        self.logs_text.delete(1.0, tk.END)
        
        # Получаем логи системы
        try:
            result = subprocess.run(['journalctl', '--no-pager', '-n', '50'], 
                                  capture_output=True, text=True)
            if result.returncode == 0:
                self.logs_text.insert(tk.END, result.stdout)
            else:
                self.logs_text.insert(tk.END, "Не удалось получить логи системы\n")
        except Exception as e:
            self.logs_text.insert(tk.END, f"Ошибка получения логов: {e}\n")
            
    def clear_logs(self):
        """Очистка логов"""
        self.logs_text.delete(1.0, tk.END)
        
    def save_logs(self):
        """Сохранение логов в файл"""
        file_path = filedialog.asksaveasfilename(
            title="Сохранить логи",
            defaultextension=".txt",
            filetypes=[("Text files", "*.txt"), ("All files", "*.*")]
        )
        
        if file_path:
            try:
                with open(file_path, 'w', encoding='utf-8') as f:
                    f.write(self.logs_text.get(1.0, tk.END))
                messagebox.showinfo("Успех", f"Логи сохранены в {file_path}")
            except Exception as e:
                messagebox.showerror("Ошибка", f"Не удалось сохранить логи: {e}")
                
    def show_about(self):
        """Окно 'О программе'"""
        about_text = """
Steam Deck Enhancement Pack GUI v0.1

Графический интерфейс для управления скриптами Steam Deck.

Возможности:
• Управление системой Steam Deck
• Установка и настройка игр
• Оптимизация производительности
• Резервное копирование
• Мониторинг системы
• Offline-режим и трюки
• Профили производительности
• Управление медиа и ROM-ами

Автор: @ncux11
Версия: 0.1 (Октябрь 2025)
        """
        
        messagebox.showinfo("О программе", about_text)
        
    def open_documentation(self):
        """Открытие документации"""
        docs_path = self.scripts_dir.parent / "README.md"
        if docs_path.exists():
            try:
                subprocess.run(['xdg-open', str(docs_path)])
            except:
                messagebox.showinfo("Документация", 
                                  f"Документация находится в: {docs_path}")
        else:
            messagebox.showerror("Ошибка", "Документация не найдена")
    
    def load_offline_info(self):
        """Загрузка информации о offline-режиме"""
        try:
            info = "=== OFFLINE-РЕЖИМ STEAM DECK ===\n\n"
            
            # Проверяем наличие offline-утилит
            offline_dir = Path.home() / "SteamDeck_Offline"
            if offline_dir.exists():
                info += "✅ Offline-утилиты установлены\n"
                
                # Проверяем профили
                profiles_dir = Path.home() / ".steamdeck_profiles"
                if profiles_dir.exists():
                    profiles = list(profiles_dir.glob("*.sh"))
                    info += f"✅ Профили производительности: {len(profiles)}\n"
                else:
                    info += "❌ Профили производительности не найдены\n"
                
                # Проверяем медиа-библиотеку
                media_dir = offline_dir / "Media"
                if media_dir.exists():
                    media_files = list(media_dir.rglob("*"))
                    info += f"✅ Медиа-файлы: {len(media_files)}\n"
                else:
                    info += "❌ Медиа-библиотека не настроена\n"
                
                # Проверяем ROM-ы
                roms_dir = offline_dir / "ROMs"
                if roms_dir.exists():
                    rom_files = list(roms_dir.rglob("*"))
                    info += f"✅ ROM-файлы: {len(rom_files)}\n"
                else:
                    info += "❌ ROM-библиотека не настроена\n"
                    
            else:
                info += "❌ Offline-утилиты не установлены\n"
                info += "Нажмите 'Настройка Offline' для установки\n"
            
            # Проверяем Steam
            steam_config = Path.home() / ".steam" / "steam" / "config" / "config.vdf"
            if steam_config.exists():
                with open(steam_config, 'r') as f:
                    content = f.read()
                    if "AutoUpdateBehavior=0" in content:
                        info += "✅ Steam настроен для offline-режима\n"
                    else:
                        info += "⚠️ Steam не настроен для offline-режима\n"
            else:
                info += "❌ Steam не найден\n"
            
            # Проверяем сетевые интерфейсы
            try:
                result = subprocess.run(['rfkill', 'list'], capture_output=True, text=True)
                if 'wifi' in result.stdout.lower():
                    if 'blocked' in result.stdout.lower():
                        info += "📶 Wi-Fi отключен (экономия батареи)\n"
                    else:
                        info += "📶 Wi-Fi включен\n"
            except:
                info += "❓ Статус Wi-Fi неизвестен\n"
            
            self.offline_info.insert(tk.END, info)
            
        except Exception as e:
            self.offline_info.insert(tk.END, f"Ошибка загрузки информации: {e}")
    
    def run_offline_menu(self):
        """Запуск главного меню offline-утилит"""
        menu_path = Path.home() / "SteamDeck_Offline" / "offline_menu.sh"
        if menu_path.exists():
            self.run_script(str(menu_path))
        else:
            messagebox.showerror("Ошибка", "Offline-меню не найдено. Сначала выполните настройку offline-режима.")
    
    def run_steam_offline(self):
        """Запуск Steam в offline-режиме"""
        steam_offline_path = Path.home() / "SteamDeck_Offline" / "launch_steam_offline.sh"
        if steam_offline_path.exists():
            self.run_script(str(steam_offline_path))
        else:
            # Запуск Steam с параметром offline
            self.run_script("steam", "--offline")
    
    def run_max_performance(self):
        """Запуск профиля максимальной производительности"""
        profile_path = Path.home() / ".steamdeck_profiles" / "max_performance.sh"
        if profile_path.exists():
            self.run_script(str(profile_path))
        else:
            messagebox.showerror("Ошибка", "Профиль максимальной производительности не найден.")
    
    def run_balanced_profile(self):
        """Запуск профиля баланса"""
        profile_path = Path.home() / ".steamdeck_profiles" / "balanced.sh"
        if profile_path.exists():
            self.run_script(str(profile_path))
        else:
            messagebox.showerror("Ошибка", "Профиль баланса не найден.")
    
    def run_battery_saver(self):
        """Запуск профиля экономии батареи"""
        profile_path = Path.home() / ".steamdeck_profiles" / "battery_saver.sh"
        if profile_path.exists():
            self.run_script(str(profile_path))
        else:
            messagebox.showerror("Ошибка", "Профиль экономии батареи не найден.")
    
    def run_free_memory(self):
        """Очистка памяти"""
        memory_script = Path.home() / "SteamDeck_Offline" / "free_memory.sh"
        if memory_script.exists():
            self.run_script(str(memory_script))
        else:
            # Выполняем очистку памяти напрямую
            self.run_script("sudo", "sync")
            self.run_script("sudo", "sh", "-c", "echo 3 > /proc/sys/vm/drop_caches")
    
    def run_backup_saves(self):
        """Бэкап сохранений игр"""
        backup_script = Path.home() / "SteamDeck_Offline" / "backup_saves.sh"
        if backup_script.exists():
            self.run_script(str(backup_script))
        else:
            messagebox.showerror("Ошибка", "Скрипт бэкапа сохранений не найден.")
    
    def run_media_manager(self):
        """Управление медиа-библиотекой"""
        media_script = Path.home() / "SteamDeck_Offline" / "manage_media.sh"
        if media_script.exists():
            # Создаем диалог выбора действия
            dialog = tk.Toplevel(self.root)
            dialog.title("Управление Медиа")
            dialog.geometry("300x200")
            dialog.configure(bg='#2b2b2b')
            
            ttk.Label(dialog, text="Выберите действие:", font=('Arial', 12, 'bold')).pack(pady=10)
            
            actions = [
                ("Сканировать библиотеку", "scan"),
                ("Создать бэкап", "backup"),
                ("Восстановить медиа", "restore"),
                ("Организовать файлы", "organize")
            ]
            
            for text, action in actions:
                ttk.Button(dialog, text=text, 
                          command=lambda a=action: self.run_script(str(media_script), a)).pack(pady=5)
            
            ttk.Button(dialog, text="Отмена", command=dialog.destroy).pack(pady=10)
        else:
            messagebox.showerror("Ошибка", "Скрипт управления медиа не найден.")
    
    def run_retroarch(self):
        """Запуск RetroArch"""
        self.run_script("retroarch")
    
    def run_roms_manager(self):
        """Управление ROM-ами"""
        roms_script = Path.home() / "SteamDeck_Offline" / "manage_roms.sh"
        if roms_script.exists():
            # Создаем диалог выбора действия
            dialog = tk.Toplevel(self.root)
            dialog.title("Управление ROM-ами")
            dialog.geometry("300x200")
            dialog.configure(bg='#2b2b2b')
            
            ttk.Label(dialog, text="Выберите действие:", font=('Arial', 12, 'bold')).pack(pady=10)
            
            actions = [
                ("Создать бэкап ROM-ов", "backup"),
                ("Восстановить ROM-ы", "restore"),
                ("Организовать ROM-ы", "organize")
            ]
            
            for text, action in actions:
                ttk.Button(dialog, text=text, 
                          command=lambda a=action: self.run_script(str(roms_script), a)).pack(pady=5)
            
            ttk.Button(dialog, text="Отмена", command=dialog.destroy).pack(pady=10)
        else:
            messagebox.showerror("Ошибка", "Скрипт управления ROM-ами не найден.")
    
    def run_vlc(self):
        """Запуск VLC медиа-плеера"""
        self.run_script("vlc")
    
    def disable_wifi(self):
        """Отключение Wi-Fi"""
        self.run_script("sudo", "rfkill", "block", "wifi")
        messagebox.showinfo("Wi-Fi", "Wi-Fi отключен для экономии батареи")
    
    def enable_wifi(self):
        """Включение Wi-Fi"""
        self.run_script("sudo", "rfkill", "unblock", "wifi")
        messagebox.showinfo("Wi-Fi", "Wi-Fi включен")
    
    def run_auto_profile(self):
        """Автоматический выбор профиля"""
        auto_script = Path.home() / "SteamDeck_Offline" / "auto_profile_switch.sh"
        if auto_script.exists():
            self.run_script(str(auto_script))
        else:
            messagebox.showerror("Ошибка", "Скрипт автоматического выбора профиля не найден.")
    
    def run_game_with_sniper(self):
        """Запуск игры через SteamLinuxRuntime - Sniper"""
        game_path = filedialog.askopenfilename(
            title="Выберите игру для запуска через Sniper",
            filetypes=[("Executable files", "*.sh *.x86_64 *.bin"), ("All files", "*.*")]
        )
        
        if game_path:
            sniper_dir = Path.home() / ".steam/steam/steamapps/common/SteamLinuxRuntime_sniper"
            sniper_run = sniper_dir / "run"
            
            if sniper_run.exists():
                self.run_script(str(sniper_run), f"-- \"{game_path}\"")
            else:
                messagebox.showerror("Ошибка", 
                                   "SteamLinuxRuntime - Sniper не найден.\n"
                                   "Установите через Steam: steam steam://install/1628350")
    
    def diagnose_game(self):
        """Диагностика проблем с игрой"""
        game_path = filedialog.askopenfilename(
            title="Выберите игру для диагностики",
            filetypes=[("Executable files", "*.sh *.x86_64 *.bin"), ("All files", "*.*")]
        )
        
        if game_path:
            # Создаем диалог диагностики
            dialog = tk.Toplevel(self.root)
            dialog.title("Диагностика игры")
            dialog.geometry("600x400")
            dialog.configure(bg='#2b2b2b')
            
            # Заголовок
            ttk.Label(dialog, text=f"Диагностика: {Path(game_path).name}", 
                     font=('Arial', 12, 'bold')).pack(pady=10)
            
            # Область вывода
            output_frame = ttk.LabelFrame(dialog, text="Результаты диагностики")
            output_frame.pack(fill='both', expand=True, padx=10, pady=10)
            
            output_text = scrolledtext.ScrolledText(output_frame, height=15, 
                                                  bg='#1e1e1e', fg='white')
            output_text.pack(fill='both', expand=True, padx=5, pady=5)
            
            def run_diagnosis():
                output_text.insert(tk.END, f"🔍 Диагностика игры: {game_path}\n\n")
                
                # Проверка зависимостей
                output_text.insert(tk.END, "📋 Проверка зависимостей:\n")
                try:
                    result = subprocess.run(['ldd', game_path], capture_output=True, text=True)
                    if result.returncode == 0:
                        missing = [line for line in result.stdout.split('\n') if 'not found' in line]
                        if missing:
                            output_text.insert(tk.END, "❌ Отсутствующие зависимости:\n")
                            for dep in missing:
                                output_text.insert(tk.END, f"  {dep}\n")
                        else:
                            output_text.insert(tk.END, "✅ Все зависимости найдены\n")
                    else:
                        output_text.insert(tk.END, "⚠️ Не удалось проверить зависимости\n")
                except Exception as e:
                    output_text.insert(tk.END, f"❌ Ошибка проверки зависимостей: {e}\n")
                
                output_text.insert(tk.END, "\n")
                
                # Проверка архитектуры
                output_text.insert(tk.END, "🏗️ Архитектура:\n")
                try:
                    result = subprocess.run(['file', game_path], capture_output=True, text=True)
                    if result.returncode == 0:
                        output_text.insert(tk.END, f"  {result.stdout.strip()}\n")
                    else:
                        output_text.insert(tk.END, "⚠️ Не удалось определить архитектуру\n")
                except Exception as e:
                    output_text.insert(tk.END, f"❌ Ошибка определения архитектуры: {e}\n")
                
                output_text.insert(tk.END, "\n")
                
                # Проверка прав доступа
                output_text.insert(tk.END, "🔐 Права доступа:\n")
                try:
                    result = subprocess.run(['ls', '-la', game_path], capture_output=True, text=True)
                    if result.returncode == 0:
                        output_text.insert(tk.END, f"  {result.stdout.strip()}\n")
                    else:
                        output_text.insert(tk.END, "⚠️ Не удалось проверить права доступа\n")
                except Exception as e:
                    output_text.insert(tk.END, f"❌ Ошибка проверки прав: {e}\n")
                
                output_text.insert(tk.END, "\n")
                
                # Проверка Sniper
                sniper_dir = Path.home() / ".steam/steam/steamapps/common/SteamLinuxRuntime_sniper"
                if sniper_dir.exists():
                    output_text.insert(tk.END, "✅ SteamLinuxRuntime - Sniper найден\n")
                    output_text.insert(tk.END, "💡 Рекомендация: Попробуйте запустить игру через Sniper\n")
                else:
                    output_text.insert(tk.END, "❌ SteamLinuxRuntime - Sniper не найден\n")
                    output_text.insert(tk.END, "💡 Рекомендация: Установите Sniper для решения проблем совместимости\n")
                
                output_text.see(tk.END)
            
            # Запуск диагностики в отдельном потоке
            threading.Thread(target=run_diagnosis, daemon=True).start()
            
            # Кнопка закрытия
            ttk.Button(dialog, text="Закрыть", command=dialog.destroy).pack(pady=10)
    
    def run_steamrip_handler(self):
        """Запуск обработчика SteamRip RAR"""
        self.show_progress("Настройка SteamRip...")
        self.run_script("steamdeck_steamrip.sh", "setup")
    
    def find_steamrip_rar(self):
        """Поиск RAR файлов SteamRip"""
        self.show_progress("Поиск RAR файлов...")
        self.run_script("steamdeck_steamrip.sh", "find")
    
    def batch_process_steamrip(self):
        """Массовая обработка SteamRip RAR"""
        self.show_progress("Массовая обработка RAR файлов...")
        self.run_script("steamdeck_steamrip.sh", "batch")
    
    def extract_steamrip_rar(self):
        """Диалог распаковки RAR файла SteamRip"""
        rar_file = filedialog.askopenfilename(
            title="Выберите RAR файл SteamRip для распаковки",
            filetypes=[("RAR files", "*.rar"), ("All files", "*.*")]
        )
        
        if rar_file:
            self.show_progress(f"Распаковка {os.path.basename(rar_file)}...")
            self.run_script("steamdeck_steamrip.sh", f"extract \"{rar_file}\"")
    
    def analyze_steamrip_rar(self):
        """Диалог анализа RAR файла SteamRip"""
        rar_file = filedialog.askopenfilename(
            title="Выберите RAR файл SteamRip для анализа",
            filetypes=[("RAR files", "*.rar"), ("All files", "*.*")]
        )
        
        if rar_file:
            self.show_progress(f"Анализ {os.path.basename(rar_file)}...")
            self.run_script("steamdeck_steamrip.sh", f"analyze \"{rar_file}\"")

    def create_artwork_tab(self, notebook):
        """Создание вкладки 'Обложки'"""
        artwork_frame = ttk.Frame(notebook)
        notebook.add(artwork_frame, text="🎨 Обложки")
        
        # Заголовок
        title_label = ttk.Label(artwork_frame, text="Управление обложками Steam Deck", 
                               font=('Arial', 16, 'bold'))
        title_label.pack(pady=10)
        
        # Основной фрейм
        main_frame = ttk.Frame(artwork_frame)
        main_frame.pack(fill='both', expand=True, padx=10, pady=10)
        
        # Левая панель - кнопки
        left_frame = ttk.Frame(main_frame)
        left_frame.pack(side='left', fill='y', padx=(0, 10))
        
        # Кнопки для утилиты
        utils_frame = ttk.LabelFrame(left_frame, text="Обложки утилиты", padding=10)
        utils_frame.pack(fill='x', pady=(0, 10))
        
        ttk.Button(utils_frame, text="Создать обложки утилиты", 
                  command=self.create_utils_artwork).pack(fill='x', pady=2)
        
        ttk.Button(utils_frame, text="Установить обложки утилиты", 
                  command=self.install_utils_artwork).pack(fill='x', pady=2)
        
        # Кнопки для игр
        games_frame = ttk.LabelFrame(left_frame, text="Обложки игр", padding=10)
        games_frame.pack(fill='x', pady=(0, 10))
        
        ttk.Button(games_frame, text="Создать обложки игры", 
                  command=self.create_game_artwork).pack(fill='x', pady=2)
        
        ttk.Button(games_frame, text="Скачать с Steam Grid DB", 
                  command=self.download_from_steamgriddb).pack(fill='x', pady=2)
        
        ttk.Button(games_frame, text="Массовая установка", 
                  command=self.batch_install_artwork).pack(fill='x', pady=2)
        
        # Кнопки для эмуляторов
        emulators_frame = ttk.LabelFrame(left_frame, text="Обложки эмуляторов", padding=10)
        emulators_frame.pack(fill='x', pady=(0, 10))
        
        ttk.Button(emulators_frame, text="Установить обложки эмуляторов", 
                  command=self.install_emulator_artwork).pack(fill='x', pady=2)
        
        # Кнопки для шаблонов
        templates_frame = ttk.LabelFrame(left_frame, text="Шаблоны", padding=10)
        templates_frame.pack(fill='x', pady=(0, 10))
        
        ttk.Button(templates_frame, text="Создать шаблоны", 
                  command=self.create_artwork_templates).pack(fill='x', pady=2)
        
        ttk.Button(templates_frame, text="Открыть папку обложек", 
                  command=self.open_artwork_folder).pack(fill='x', pady=2)
        
        # Правая панель - информация и вывод
        right_frame = ttk.Frame(main_frame)
        right_frame.pack(side='right', fill='both', expand=True)
        
        # Информационная панель
        info_frame = ttk.LabelFrame(right_frame, text="Информация", padding=10)
        info_frame.pack(fill='x', pady=(0, 10))
        
        info_text = """
🎨 Управление обложками Steam Deck

📐 Размеры обложек:
• Grid: 460x215 (главная обложка)
• Hero: 3840x1240 (широкоформатная)
• Logo: 512x512 (логотип)
• Icon: 256x256 (иконка)

🛠️ Инструменты:
• ImageMagick - создание обложек
• Steam Grid DB - скачивание обложек
• GIMP/Photoshop - редактирование

📁 Папки:
• ~/SteamDeck/artwork/ - все обложки
• ~/SteamDeck/artwork/utils/ - обложки утилиты
• ~/SteamDeck/artwork/games/ - обложки игр
• ~/SteamDeck/artwork/emulators/ - обложки эмуляторов
        """
        
        info_label = ttk.Label(info_frame, text=info_text, justify='left')
        info_label.pack(anchor='w')
        
        # Панель вывода
        output_frame = ttk.LabelFrame(right_frame, text="Вывод", padding=10)
        output_frame.pack(fill='both', expand=True)
        
        self.artwork_output = scrolledtext.ScrolledText(output_frame, height=15, width=60)
        self.artwork_output.pack(fill='both', expand=True)
        
        # Прогресс-бар для обложек
        self.artwork_progress = ttk.Progressbar(output_frame, mode='indeterminate')
        self.artwork_progress.pack(fill='x', pady=(5, 0))
        
        self.artwork_progress_label = ttk.Label(output_frame, text="")
        self.artwork_progress_label.pack(pady=(2, 0))

    def create_utils_artwork(self):
        """Создание обложек для утилиты"""
        self.run_script("steamdeck_create_artwork.sh", "create-utils", 
                       "Создание обложек для утилиты...")

    def install_utils_artwork(self):
        """Установка обложек для утилиты"""
        self.run_script("steamdeck_artwork.sh", "install-utils", 
                       "Установка обложек для утилиты...")

    def create_game_artwork(self):
        """Создание обложек для игры"""
        game_name = simpledialog.askstring("Создание обложек", "Введите название игры:")
        if game_name:
            self.run_script("steamdeck_create_artwork.sh", f"create-game \"{game_name}\"", 
                           f"Создание обложек для игры '{game_name}'...")

    def download_from_steamgriddb(self):
        """Скачивание обложек с Steam Grid DB"""
        game_name = simpledialog.askstring("Steam Grid DB", "Введите название игры:")
        if game_name:
            self.run_script("steamdeck_steamgriddb.sh", f"install \"{game_name}\"", 
                           f"Скачивание обложек для '{game_name}' с Steam Grid DB...")

    def batch_install_artwork(self):
        """Массовая установка обложек"""
        self.run_script("steamdeck_steamgriddb.sh", "batch", 
                       "Массовая установка обложек...")

    def install_emulator_artwork(self):
        """Установка обложек для эмуляторов"""
        self.run_script("steamdeck_artwork.sh", "install-emulators", 
                       "Установка обложек для эмуляторов...")

    def create_artwork_templates(self):
        """Создание шаблонов обложек"""
        self.run_script("steamdeck_create_artwork.sh", "create-templates", 
                       "Создание шаблонов обложек...")

    def open_artwork_folder(self):
        """Открытие папки с обложками"""
        artwork_dir = os.path.expanduser("~/SteamDeck/artwork")
        if os.path.exists(artwork_dir):
            subprocess.Popen(["dolphin", artwork_dir])
        else:
            messagebox.showinfo("Информация", "Папка с обложками не найдена.\nСначала создайте обложки.")

def main():
    # Проверяем, что мы в правильной директории
    if not Path(__file__).parent.name == "scripts":
        print("Ошибка: Запустите скрипт из директории scripts/")
        sys.exit(1)
    
    # Создаем главное окно
    root = tk.Tk()
    app = SteamDeckGUI(root)
    
    # Запускаем GUI
    root.mainloop()

if __name__ == "__main__":
    main()
