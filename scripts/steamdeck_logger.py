#!/usr/bin/env python3
"""
Steam Deck Enhancement Pack - Система логирования
Автор: @ncux11
Версия: динамическая (читается из VERSION)
"""

import os
import logging
from datetime import datetime
from pathlib import Path
from typing import Optional


def get_version():
    """Получение версии из файла VERSION"""
    try:
        # Определяем путь к файлу VERSION относительно этого скрипта
        script_dir = Path(__file__).parent
        project_root = script_dir.parent
        version_file = project_root / "VERSION"
        
        if version_file.exists():
            with open(version_file, 'r') as f:
                return f.read().strip()
        else:
            return "0.1.3"  # Fallback версия
    except:
        return "0.1.3"  # Fallback версия


class SteamDeckLogger:
    """Класс для логирования операций Steam Deck Enhancement Pack"""
    
    def __init__(self, log_dir: Optional[str] = None):
        """
        Инициализация логгера
        
        Args:
            log_dir: Директория для логов (по умолчанию ~/.steamdeck_logs)
        """
        if log_dir is None:
            self.log_dir = Path.home() / ".steamdeck_logs"
        else:
            self.log_dir = Path(log_dir)
        
        # Создаем директорию для логов если не существует
        self.log_dir.mkdir(parents=True, exist_ok=True)
        
        # Имя файла лога с текущей датой
        self.log_file = self.log_dir / f"steamdeck_{datetime.now().strftime('%Y%m%d')}.log"
        
        # Настройка логгера
        self.logger = logging.getLogger('steamdeck_enhancement')
        self.logger.setLevel(logging.INFO)
        
        # Удаляем существующие обработчики чтобы избежать дублирования
        for handler in self.logger.handlers[:]:
            self.logger.removeHandler(handler)
        
        # Обработчик для записи в файл
        file_handler = logging.FileHandler(self.log_file, encoding='utf-8')
        file_handler.setLevel(logging.INFO)
        
        # Обработчик для вывода в консоль
        console_handler = logging.StreamHandler()
        console_handler.setLevel(logging.WARNING)
        
        # Формат логов
        formatter = logging.Formatter(
            '%(asctime)s - %(levelname)s - %(message)s',
            datefmt='%Y-%m-%d %H:%M:%S'
        )
        
        file_handler.setFormatter(formatter)
        console_handler.setFormatter(formatter)
        
        self.logger.addHandler(file_handler)
        self.logger.addHandler(console_handler)
    
    def log_operation(self, operation: str, status: str, details: str = ""):
        """
        Логирование операции
        
        Args:
            operation: Название операции
            status: Статус (success, error, warning, info)
            details: Дополнительные детали
        """
        timestamp = datetime.now().strftime('%Y-%m-%d %H:%M:%S')
        
        if status == "success":
            level = logging.INFO
            status_icon = "✅"
        elif status == "error":
            level = logging.ERROR
            status_icon = "❌"
        elif status == "warning":
            level = logging.WARNING
            status_icon = "⚠️"
        else:  # info
            level = logging.INFO
            status_icon = "ℹ️"
        
        message = f"{status_icon} {operation}"
        if details:
            message += f" - {details}"
        
        self.logger.log(level, message)
    
    def log_success(self, operation: str, details: str = ""):
        """Логирование успешной операции"""
        self.log_operation(operation, "success", details)
    
    def log_error(self, operation: str, details: str = ""):
        """Логирование ошибки"""
        self.log_operation(operation, "error", details)
    
    def log_warning(self, operation: str, details: str = ""):
        """Логирование предупреждения"""
        self.log_operation(operation, "warning", details)
    
    def log_info(self, operation: str, details: str = ""):
        """Логирование информационного сообщения"""
        self.log_operation(operation, "info", details)
    
    def get_log_path(self) -> str:
        """Получить путь к текущему файлу лога"""
        return str(self.log_file)
    
    def get_log_dir(self) -> str:
        """Получить путь к директории логов"""
        return str(self.log_dir)
    
    def get_recent_logs(self, lines: int = 50) -> str:
        """
        Получить последние строки из лога
        
        Args:
            lines: Количество строк для чтения
            
        Returns:
            Последние строки лога
        """
        try:
            with open(self.log_file, 'r', encoding='utf-8') as f:
                all_lines = f.readlines()
                return ''.join(all_lines[-lines:])
        except FileNotFoundError:
            return "Лог файл не найден"
        except Exception as e:
            return f"Ошибка чтения лога: {e}"
    
    def export_logs(self, export_path: str) -> bool:
        """
        Экспорт логов в указанный файл
        
        Args:
            export_path: Путь для экспорта
            
        Returns:
            True если успешно, False если ошибка
        """
        try:
            import shutil
            shutil.copy2(self.log_file, export_path)
            self.log_success("Log Export", f"Экспортировано в {export_path}")
            return True
        except Exception as e:
            self.log_error("Log Export", f"Ошибка экспорта: {e}")
            return False
    
    def clear_old_logs(self, days: int = 30):
        """
        Удаление старых логов
        
        Args:
            days: Количество дней для хранения логов
        """
        try:
            import time
            current_time = time.time()
            cutoff_time = current_time - (days * 24 * 60 * 60)
            
            deleted_count = 0
            for log_file in self.log_dir.glob("steamdeck_*.log"):
                if log_file.stat().st_mtime < cutoff_time:
                    log_file.unlink()
                    deleted_count += 1
            
            if deleted_count > 0:
                self.log_info("Log Cleanup", f"Удалено {deleted_count} старых логов")
        except Exception as e:
            self.log_error("Log Cleanup", f"Ошибка очистки: {e}")


# Глобальный экземпляр логгера для использования в других модулях
logger = SteamDeckLogger()


if __name__ == "__main__":
    # Тестирование логгера
    test_logger = SteamDeckLogger()
    
    test_logger.log_success("Test Operation", "Тестовая операция выполнена успешно")
    test_logger.log_error("Test Error", "Тестовая ошибка")
    test_logger.log_warning("Test Warning", "Тестовое предупреждение")
    test_logger.log_info("Test Info", "Тестовая информация")
    
    print(f"Лог сохранен в: {test_logger.get_log_path()}")
    print("\nПоследние записи:")
    print(test_logger.get_recent_logs(10))
