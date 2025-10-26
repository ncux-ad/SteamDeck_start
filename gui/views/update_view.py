#!/usr/bin/env python3
"""
Update View for Steam Deck Enhancement Pack GUI
Author: @ncux11
Version: 1.0
"""

from PyQt6.QtWidgets import (
    QWidget, QVBoxLayout, QHBoxLayout, QLabel, 
    QPushButton, QTextEdit, QProgressBar, QMessageBox
)
from PyQt6.QtCore import Qt, QThread, pyqtSignal
from pathlib import Path
import subprocess
import threading


class UpdateWorker(QThread):
    """Worker thread for update operations"""
    finished = pyqtSignal(bool, str)
    output = pyqtSignal(str)
    
    def __init__(self, script_path, args):
        super().__init__()
        self.script_path = script_path
        self.args = args
    
    def run(self):
        """Run the update script"""
        try:
            process = subprocess.Popen(
                ["bash", str(self.script_path)] + self.args,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            output_lines = []
            for line in process.stdout:
                line = line.rstrip()
                output_lines.append(line)
                self.output.emit(line)
            
            return_code = process.wait()
            output = "\n".join(output_lines)
            
            self.finished.emit(return_code == 0, output)
            
        except Exception as e:
            self.finished.emit(False, str(e))


class UpdateView(QWidget):
    """Update management view"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self.project_root = Path(__file__).parent.parent.parent
        self.worker = None
        self._setup_ui()
    
    def _setup_ui(self):
        """Setup the UI"""
        layout = QVBoxLayout(self)
        layout.setSpacing(20)
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Title
        title = QLabel("Обновления")
        title.setStyleSheet("font-size: 24pt; font-weight: bold;")
        layout.addWidget(title)
        
        # Description
        desc = QLabel("Проверьте наличие обновлений и установите их")
        desc.setStyleSheet("font-size: 12pt; color: #b0b0b0;")
        layout.addWidget(desc)
        
        # Buttons
        buttons_layout = QHBoxLayout()
        buttons_layout.setSpacing(15)
        
        # Check updates button
        self.check_btn = QPushButton("🔍 Проверить обновления")
        self.check_btn.setMinimumHeight(50)
        self.check_btn.setStyleSheet("font-size: 14pt;")
        self.check_btn.clicked.connect(self.check_updates)
        buttons_layout.addWidget(self.check_btn)
        
        # Update button
        self.update_btn = QPushButton("⬇️ Установить обновление")
        self.update_btn.setMinimumHeight(50)
        self.update_btn.setStyleSheet("font-size: 14pt;")
        self.update_btn.clicked.connect(self.apply_update)
        self.update_btn.setEnabled(False)
        buttons_layout.addWidget(self.update_btn)
        
        layout.addLayout(buttons_layout)
        
        # Progress bar
        self.progress = QProgressBar()
        self.progress.setVisible(False)
        layout.addWidget(self.progress)
        
        # Output area
        self.output = QTextEdit()
        self.output.setReadOnly(True)
        self.output.setPlaceholderText("Вывод команд будет здесь...")
        layout.addWidget(self.output)
    
    def check_updates(self):
        """Check for updates"""
        self.output.clear()
        self.output.append("=== Проверка обновлений ===")
        
        script_path = self.project_root / "scripts" / "steamdeck_update.sh"
        
        if not script_path.exists():
            self.output.append("❌ Скрипт обновления не найден!")
            return
        
        # Disable buttons
        self.check_btn.setEnabled(False)
        self.update_btn.setEnabled(False)
        self.progress.setVisible(True)
        
        # Run in thread
        self.worker = UpdateWorker(script_path, ["check"])
        self.worker.output.connect(self.on_output)
        self.worker.finished.connect(self.on_check_finished)
        self.worker.start()
    
    def apply_update(self):
        """Apply updates"""
        reply = QMessageBox.question(
            self,
            "Подтверждение",
            "Установить обновление? Приложение будет перезапущено.",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        
        if reply != QMessageBox.StandardButton.Yes:
            return
        
        self.output.clear()
        self.output.append("=== Установка обновления ===")
        
        script_path = self.project_root / "scripts" / "steamdeck_update.sh"
        
        # Disable buttons
        self.check_btn.setEnabled(False)
        self.update_btn.setEnabled(False)
        self.progress.setVisible(True)
        
        # Run in thread
        self.worker = UpdateWorker(script_path, ["update"])
        self.worker.output.connect(self.on_output)
        self.worker.finished.connect(self.on_update_finished)
        self.worker.start()
    
    def on_output(self, line):
        """Handle output line"""
        self.output.append(line)
    
    def on_check_finished(self, success, output):
        """Handle check finished"""
        self.progress.setVisible(False)
        self.check_btn.setEnabled(True)
        
        if success:
            if "Доступно обновление" in output or "update available" in output.lower():
                self.update_btn.setEnabled(True)
                self.output.append("\n✅ Обновление доступно!")
            else:
                self.output.append("\n✅ Установлена последняя версия")
        else:
            self.output.append("\n❌ Ошибка проверки обновлений")
    
    def on_update_finished(self, success, output):
        """Handle update finished"""
        self.progress.setVisible(False)
        self.check_btn.setEnabled(True)
        
        if success:
            self.output.append("\n✅ Обновление установлено!")
            QMessageBox.information(self, "Успех", "Обновление установлено! Перезапустите приложение.")
        else:
            self.output.append("\n❌ Ошибка установки обновления")
