#!/usr/bin/env python3
"""
Games View for Steam Deck Enhancement Pack GUI
Author: @ncux11
Version: 1.0
"""

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, 
    QPushButton, QTextEdit, QMessageBox
)
from PyQt6.QtCore import Qt
from pathlib import Path
import subprocess


class GamesView(QWidget):
    """Games installation view"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.project_root = Path(__file__).parent.parent.parent
        self._setup_ui()
    
    def _setup_ui(self):
        """Setup the UI"""
        layout = QVBoxLayout(self)
        layout.setSpacing(20)
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Title
        title = QLabel("Установка игр")
        title.setStyleSheet("font-size: 24pt; font-weight: bold;")
        layout.addWidget(title)
        
        # Description
        desc = QLabel("Выберите тип игры для установки:")
        desc.setStyleSheet("font-size: 12pt; color: #b0b0b0;")
        layout.addWidget(desc)
        
        # Buttons
        buttons_layout = QHBoxLayout()
        buttons_layout.setSpacing(15)
        
        # SH games button
        self.sh_games_btn = QPushButton("📋 SH игры (Linux)")
        self.sh_games_btn.setMinimumHeight(80)
        self.sh_games_btn.setStyleSheet("font-size: 14pt;")
        self.sh_games_btn.clicked.connect(self.install_sh_game)
        buttons_layout.addWidget(self.sh_games_btn)
        
        # RAR games button
        self.rar_games_btn = QPushButton("📦 RAR игры (Windows)")
        self.rar_games_btn.setMinimumHeight(80)
        self.rar_games_btn.setStyleSheet("font-size: 14pt;")
        self.rar_games_btn.clicked.connect(self.install_rar_game)
        buttons_layout.addWidget(self.rar_games_btn)
        
        layout.addLayout(buttons_layout)
        
        # Output area
        self.output = QTextEdit()
        self.output.setReadOnly(True)
        self.output.setPlaceholderText("Вывод команд будет здесь...")
        layout.addWidget(self.output)
    
    def install_sh_game(self):
        """Install SH game"""
        self.output.append("=== Установка SH игры ===")
        
        script_path = self.project_root / "scripts" / "steamdeck_native_games.sh"
        
        if not script_path.exists():
            self.output.append("❌ Скрипт не найден!")
            return
        
        try:
            result = subprocess.run(
                ["bash", str(script_path), "interactive"],
                capture_output=True,
                text=True,
                timeout=300
            )
            
            if result.returncode == 0:
                self.output.append("✅ Игра установлена успешно!")
            else:
                self.output.append(f"❌ Ошибка: {result.stderr}")
                
            self.output.append(result.stdout)
            
        except subprocess.TimeoutExpired:
            self.output.append("❌ Таймаут выполнения")
        except Exception as e:
            self.output.append(f"❌ Ошибка: {str(e)}")
    
    def install_rar_game(self):
        """Install RAR game"""
        self.output.append("=== Установка RAR игры ===")
        
        script_path = self.project_root / "scripts" / "steamdeck_steamrip.sh"
        
        if not script_path.exists():
            self.output.append("❌ Скрипт не найден!")
            return
        
        try:
            result = subprocess.run(
                ["bash", str(script_path), "interactive"],
                capture_output=True,
                text=True,
                timeout=600
            )
            
            if result.returncode == 0:
                self.output.append("✅ Игра установлена успешно!")
            else:
                self.output.append(f"❌ Ошибка: {result.stderr}")
                
            self.output.append(result.stdout)
            
        except subprocess.TimeoutExpired:
            self.output.append("❌ Таймаут выполнения")
        except Exception as e:
            self.output.append(f"❌ Ошибка: {str(e)}")
