#!/usr/bin/env python3
"""
Configuration module for Steam Deck Enhancement Pack GUI
Author: @ncux11
Version: 1.0
"""

import os
import json
from pathlib import Path

class Config:
    """Configuration manager for the GUI"""
    
    def __init__(self):
        self.project_root = Path(__file__).parent.parent.parent
        self.config_dir = Path.home() / ".steamdeck_gui"
        self.config_file = self.config_dir / "config.json"
        
        # Создаем директорию конфига если не существует
        self.config_dir.mkdir(exist_ok=True)
        
        # Значения по умолчанию
        self.defaults = {
            "theme": "dark",
            "auto_check_updates": True,
            "log_level": "INFO",
            "install_dir": str(Path.home() / "utils" / "SteamDeck"),
            "games_dir": str(Path.home() / "Games"),
            "language": "ru",
        }
        
        # Загружаем конфиг
        self.config = self.load_config()
    
    def load_config(self):
        """Load configuration from file"""
        if self.config_file.exists():
            try:
                with open(self.config_file, 'r', encoding='utf-8') as f:
                    config = json.load(f)
                # Объединяем с defaults для новых ключей
                return {**self.defaults, **config}
            except Exception as e:
                print(f"Error loading config: {e}")
                return self.defaults.copy()
        return self.defaults.copy()
    
    def save_config(self):
        """Save configuration to file"""
        try:
            with open(self.config_file, 'w', encoding='utf-8') as f:
                json.dump(self.config, f, indent=2, ensure_ascii=False)
            return True
        except Exception as e:
            print(f"Error saving config: {e}")
            return False
    
    def get(self, key, default=None):
        """Get configuration value"""
        return self.config.get(key, default)
    
    def set(self, key, value):
        """Set configuration value"""
        self.config[key] = value
        return self.save_config()
    
    def __getitem__(self, key):
        """Allow config['key'] syntax"""
        return self.config.get(key)
    
    def __setitem__(self, key, value):
        """Allow config['key'] = value syntax"""
        self.config[key] = value
        self.save_config()

# Глобальный экземпляр конфига
config = Config()
