#!/usr/bin/env python3
"""
System View for Steam Deck Enhancement Pack GUI
Author: @ncux11
Version: 1.0
"""

from PyQt6.QtWidgets import QWidget, QVBoxLayout, QHBoxLayout, QGridLayout, QLabel
from PyQt6.QtCore import Qt
import sys
import subprocess
from pathlib import Path

# Import our widgets
import sys
from pathlib import Path
sys.path.insert(0, str(Path(__file__).parent.parent))
from widgets.status_card import StatusCard


class SystemView(QWidget):
    """System information view"""
    
    def __init__(self, parent=None):
        super().__init__(parent)
        self._setup_ui()
        self._load_system_info()
    
    def _setup_ui(self):
        """Setup the UI"""
        layout = QVBoxLayout(self)
        layout.setSpacing(20)
        layout.setContentsMargins(20, 20, 20, 20)
        
        # Title
        title = QLabel("Системная информация")
        title.setStyleSheet("font-size: 24pt; font-weight: bold;")
        layout.addWidget(title)
        
        # Cards grid
        cards_layout = QGridLayout()
        cards_layout.setSpacing(15)
        
        # Version card
        self.version_card = StatusCard("Версия", "📦", "Загрузка...", "info")
        cards_layout.addWidget(self.version_card, 0, 0)
        
        # OS card
        self.os_card = StatusCard("ОС", "🐧", "Загрузка...", "info")
        cards_layout.addWidget(self.os_card, 0, 1)
        
        # Storage card
        self.storage_card = StatusCard("Память", "💾", "Загрузка...", "info")
        cards_layout.addWidget(self.storage_card, 1, 0)
        
        # Network card
        self.network_card = StatusCard("Сеть", "🌐", "Загрузка...", "info")
        cards_layout.addWidget(self.network_card, 1, 1)
        
        layout.addLayout(cards_layout)
        layout.addStretch()
    
    def _load_system_info(self):
        """Load system information"""
        # Version
        project_root = Path(__file__).parent.parent.parent
        version_file = project_root / "VERSION"
        if version_file.exists():
            version = version_file.read_text().strip()
            self.version_card.set_value(version)
        
        # OS
        try:
            result = subprocess.run(
                ["cat", "/etc/os-release"],
                capture_output=True,
                text=True,
                timeout=5
            )
            for line in result.stdout.split('\n'):
                if line.startswith("PRETTY_NAME="):
                    os_name = line.split('=')[1].strip('"')
                    self.os_card.set_value(os_name)
                    break
        except:
            self.os_card.set_value("Unknown")
        
        # Storage
        try:
            result = subprocess.run(
                ["df", "-h", "/"],
                capture_output=True,
                text=True,
                timeout=5
            )
            lines = result.stdout.split('\n')
            if len(lines) > 1:
                parts = lines[1].split()
                if len(parts) >= 5:
                    used = parts[2]
                    total = parts[1]
                    self.storage_card.set_value(f"{used} / {total}")
        except:
            self.storage_card.set_value("N/A")
        
        # Network
        try:
            result = subprocess.run(
                ["ping", "-c", "1", "-W", "2", "8.8.8.8"],
                capture_output=True,
                text=True,
                timeout=5
            )
            if result.returncode == 0:
                self.network_card.set_value("Online", "success")
            else:
                self.network_card.set_value("Offline", "error")
        except:
            self.network_card.set_value("Unknown", "warning")
