#!/usr/bin/env python3
"""
Steam Deck Enhancement Pack GUI
Main entry point
Author: @ncux11
Version: 1.0
"""

import sys
from pathlib import Path
from PyQt6.QtWidgets import QApplication, QMainWindow, QTabWidget, QMessageBox

# Import views
sys.path.insert(0, str(Path(__file__).parent))
from views.system_view import SystemView
from views.games_view import GamesView
from views.update_view import UpdateView
from core.theme import Theme

# Import core modules
from core.config import config


class MainWindow(QMainWindow):
    """Main application window"""
    
    def __init__(self):
        super().__init__()
        self.setWindowTitle("Steam Deck Enhancement Pack v1.0 - ALPHA")
        self.setMinimumSize(1024, 768)
        
        # Create theme
        self.theme = Theme(config.get("theme", "dark"))
        
        # Setup UI
        self._setup_ui()
        
        # Apply theme
        self.theme.apply_to_app(QApplication.instance())
        
        # Auto-check updates if enabled
        if config.get("auto_check_updates", True):
            self._check_updates_on_startup()
    
    def _setup_ui(self):
        """Setup the user interface"""
        # Create tab widget
        self.tabs = QTabWidget()
        self.tabs.setTabPosition(QTabWidget.TabPosition.North)
        
        # Add tabs
        self.tabs.addTab(SystemView(), "💻 Система")
        self.tabs.addTab(GamesView(), "🎮 Игры")
        self.tabs.addTab(UpdateView(), "⬆️ Обновления")
        
        # Set central widget
        self.setCentralWidget(self.tabs)
    
    def _check_updates_on_startup(self):
        """Check for updates on startup (non-blocking)"""
        # This will be implemented later with proper async
        pass
    
    def closeEvent(self, event):
        """Handle close event"""
        reply = QMessageBox.question(
            self,
            "Подтверждение",
            "Закрыть приложение?",
            QMessageBox.StandardButton.Yes | QMessageBox.StandardButton.No
        )
        
        if reply == QMessageBox.StandardButton.Yes:
            event.accept()
        else:
            event.ignore()


def main():
    """Main entry point"""
    app = QApplication(sys.argv)
    app.setApplicationName("Steam Deck Enhancement Pack")
    
    # Create and show main window
    window = MainWindow()
    window.show()
    
    # Run application
    sys.exit(app.exec())


if __name__ == "__main__":
    main()
