#!/usr/bin/env python3
"""
Status Card Widget for Steam Deck Enhancement Pack GUI
Author: @ncux11
Version: 1.0
"""

from PyQt6.QtWidgets import QFrame, QVBoxLayout, QLabel, QHBoxLayout
from PyQt6.QtCore import Qt
from PyQt6.QtGui import QColor, QPalette


class StatusCard(QFrame):
    """Card widget for displaying status information"""
    
    def __init__(self, title, icon="", value="", status="info", parent=None):
        super().__init__(parent)
        
        self.title = title
        self.icon = icon
        self.value = value
        self.status = status
        
        self._setup_ui()
    
    def _setup_ui(self):
        """Setup the UI"""
        self.setObjectName("statusCard")
        self.setFixedHeight(100)
        
        # Layout
        layout = QVBoxLayout(self)
        layout.setContentsMargins(20, 15, 20, 15)
        layout.setSpacing(5)
        
        # Title
        self.title_label = QLabel(self.title)
        self.title_label.setObjectName("cardTitle")
        self.title_label.setStyleSheet("font-size: 11pt; color: #b0b0b0;")
        layout.addWidget(self.title_label)
        
        # Value with icon
        value_layout = QHBoxLayout()
        
        if self.icon:
            icon_label = QLabel(self.icon)
            icon_label.setStyleSheet("font-size: 24pt;")
            value_layout.addWidget(icon_label)
        
        self.value_label = QLabel(self.value)
        self.value_label.setObjectName("cardValue")
        self.value_label.setStyleSheet("font-size: 24pt; font-weight: bold;")
        value_layout.addWidget(self.value_label)
        value_layout.addStretch()
        
        layout.addLayout(value_layout)
        
        # Apply status color
        self.set_status(self.status)
    
    def set_status(self, status):
        """Set status and update colors"""
        self.status = status
        
        # Color mapping
        colors = {
            "info": "#1e90ff",
            "success": "#00c853",
            "warning": "#ff9800",
            "error": "#f44336",
        }
        
        color = colors.get(status, colors["info"])
        
        # Update border color
        self.setStyleSheet(f"""
            QFrame#statusCard {{
                border: 2px solid {color};
                border-radius: 8px;
                background-color: #2d2d2d;
            }}
        """)
        
        # Update value color
        self.value_label.setStyleSheet(f"""
            font-size: 24pt; 
            font-weight: bold; 
            color: {color};
        """)
    
    def set_value(self, value):
        """Update the value"""
        self.value = value
        self.value_label.setText(str(value))
    
    def set_title(self, title):
        """Update the title"""
        self.title = title
        self.title_label.setText(title)
