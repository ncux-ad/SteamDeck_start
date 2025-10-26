#!/bin/bash

# Launch script for Steam Deck Enhancement Pack GUI
# Author: @ncux11

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Check if Python 3 is installed
if ! command -v python3 &> /dev/null; then
    echo "Error: python3 not found"
    exit 1
fi

# Check if PyQt6 is installed
if ! python3 -c "import PyQt6" 2>/dev/null; then
    echo "Error: PyQt6 not installed"
    echo "Install it with: pip3 install PyQt6"
    exit 1
fi

# Run the GUI
cd gui
python3 main.py "$@"
