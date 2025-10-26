#!/usr/bin/env python3
"""
Theme module for Steam Deck Enhancement Pack GUI
Author: @ncux11
Version: 1.0
"""

class Theme:
    """Theme manager for the GUI"""
    
    # Темная тема (по умолчанию для Steam Deck)
    dark_theme = {
        "bg_primary": "#1a1a1a",
        "bg_secondary": "#2d2d2d",
        "bg_tertiary": "#3d3d3d",
        "fg_primary": "#ffffff",
        "fg_secondary": "#b0b0b0",
        "fg_disabled": "#666666",
        "accent": "#1e90ff",
        "success": "#00c853",
        "warning": "#ff9800",
        "error": "#f44336",
        "border": "#404040",
        "hover": "#3d5afe",
        "selected": "#2196f3",
    }
    
    # Светлая тема (для тестирования)
    light_theme = {
        "bg_primary": "#ffffff",
        "bg_secondary": "#f5f5f5",
        "bg_tertiary": "#e0e0e0",
        "fg_primary": "#000000",
        "fg_secondary": "#424242",
        "fg_disabled": "#9e9e9e",
        "accent": "#1976d2",
        "success": "#388e3c",
        "warning": "#f57c00",
        "error": "#d32f2f",
        "border": "#e0e0e0",
        "hover": "#1565c0",
        "selected": "#0d47a1",
    }
    
    def __init__(self, theme_name="dark"):
        self.theme_name = theme_name
        self.colors = self.dark_theme if theme_name == "dark" else self.light_theme
    
    def get_stylesheet(self):
        """Get Qt stylesheet for the theme"""
        colors = self.colors
        
        return f"""
        QMainWindow {{
            background-color: {colors['bg_primary']};
            color: {colors['fg_primary']};
        }}
        
        QWidget {{
            background-color: {colors['bg_primary']};
            color: {colors['fg_primary']};
            font-family: 'Segoe UI', Arial, sans-serif;
            font-size: 12pt;
        }}
        
        QTabWidget::pane {{
            border: 1px solid {colors['border']};
            background-color: {colors['bg_secondary']};
        }}
        
        QTabBar::tab {{
            background-color: {colors['bg_tertiary']};
            color: {colors['fg_secondary']};
            padding: 10px 20px;
            border: none;
            border-bottom: 2px solid transparent;
        }}
        
        QTabBar::tab:hover {{
            background-color: {colors['bg_primary']};
            color: {colors['fg_primary']};
        }}
        
        QTabBar::tab:selected {{
            background-color: {colors['bg_primary']};
            color: {colors['fg_primary']};
            border-bottom: 2px solid {colors['accent']};
        }}
        
        QPushButton {{
            background-color: {colors['accent']};
            color: white;
            border: none;
            padding: 8px 16px;
            border-radius: 4px;
            font-weight: bold;
        }}
        
        QPushButton:hover {{
            background-color: {colors['hover']};
        }}
        
        QPushButton:pressed {{
            background-color: {colors['selected']};
        }}
        
        QPushButton:disabled {{
            background-color: {colors['bg_tertiary']};
            color: {colors['fg_disabled']};
        }}
        
        QLabel {{
            color: {colors['fg_primary']};
        }}
        
        QLineEdit, QTextEdit, QPlainTextEdit {{
            background-color: {colors['bg_secondary']};
            color: {colors['fg_primary']};
            border: 1px solid {colors['border']};
            border-radius: 4px;
            padding: 4px;
        }}
        
        QProgressBar {{
            border: 1px solid {colors['border']};
            border-radius: 4px;
            text-align: center;
            background-color: {colors['bg_secondary']};
        }}
        
        QProgressBar::chunk {{
            background-color: {colors['accent']};
            border-radius: 3px;
        }}
        
        QScrollBar:vertical {{
            background-color: {colors['bg_secondary']};
            width: 12px;
        }}
        
        QScrollBar::handle:vertical {{
            background-color: {colors['bg_tertiary']};
            min-height: 20px;
            border-radius: 6px;
        }}
        
        QScrollBar::handle:vertical:hover {{
            background-color: {colors['accent']};
        }}
        
        QListWidget, QTreeWidget {{
            background-color: {colors['bg_secondary']};
            border: 1px solid {colors['border']};
            border-radius: 4px;
        }}
        
        QFrame {{
            background-color: {colors['bg_secondary']};
            border: 1px solid {colors['border']};
            border-radius: 4px;
        }}
        """
    
    def color(self, name):
        """Get color by name"""
        return self.colors.get(name, "#ffffff")
    
    def apply_to_app(self, app):
        """Apply theme to QApplication"""
        app.setStyleSheet(self.get_stylesheet())

# Глобальный экземпляр темы
default_theme = Theme("dark")
