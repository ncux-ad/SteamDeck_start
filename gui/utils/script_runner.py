#!/usr/bin/env python3
"""
Script Runner utility for Steam Deck Enhancement Pack GUI
Author: @ncux11
Version: 1.0
"""

import subprocess
import threading
from pathlib import Path
from typing import Callable, Optional, List


class ScriptRunner:
    """Utility for running bash scripts with progress tracking"""
    
    def __init__(self):
        self.processes = {}
        self.running = False
    
    def run_script(
        self,
        script_path: str,
        args: List[str] = None,
        callback: Optional[Callable] = None,
        output_callback: Optional[Callable] = None
    ):
        """Run a bash script and return output"""
        if not Path(script_path).exists():
            if callback:
                callback(False, f"Script not found: {script_path}")
            return False, f"Script not found: {script_path}"
        
        if args is None:
            args = []
        
        self.running = True
        
        try:
            # Run script and capture output
            process = subprocess.Popen(
                ["bash", script_path] + args,
                stdout=subprocess.PIPE,
                stderr=subprocess.STDOUT,
                text=True,
                bufsize=1,
                universal_newlines=True
            )
            
            # Read output line by line
            output_lines = []
            for line in process.stdout:
                line = line.rstrip()
                output_lines.append(line)
                
                # Call output callback if provided
                if output_callback:
                    output_callback(line)
            
            # Wait for process to complete
            return_code = process.wait()
            
            # Call completion callback if provided
            success = return_code == 0
            output = "\n".join(output_lines)
            
            if callback:
                callback(success, output)
            
            return success, output
            
        except Exception as e:
            error_msg = f"Error running script: {str(e)}"
            if callback:
                callback(False, error_msg)
            return False, error_msg
        finally:
            self.running = False
    
    def run_script_async(
        self,
        script_path: str,
        args: List[str] = None,
        callback: Optional[Callable] = None,
        output_callback: Optional[Callable] = None
    ):
        """Run a bash script asynchronously in a separate thread"""
        def _run():
            self.run_script(script_path, args, callback, output_callback)
        
        thread = threading.Thread(target=_run, daemon=True)
        thread.start()
        return thread
    
    def get_version(self, project_root: Path):
        """Get current version from VERSION file"""
        version_file = project_root / "VERSION"
        if version_file.exists():
            return version_file.read_text().strip()
        return "unknown"
    
    def check_updates(self, project_root: Path, callback: Optional[Callable] = None):
        """Check for updates using steamdeck_update.sh"""
        update_script = project_root / "scripts" / "steamdeck_update.sh"
        
        def _callback(success, output):
            if callback:
                callback(success, output)
        
        return self.run_script_async(
            str(update_script),
            ["check"],
            callback=_callback
        )
    
    def apply_update(self, project_root: Path, callback: Optional[Callable] = None):
        """Apply updates using steamdeck_update.sh"""
        update_script = project_root / "scripts" / "steamdeck_update.sh"
        
        def _callback(success, output):
            if callback:
                callback(success, output)
        
        return self.run_script_async(
            str(update_script),
            ["update"],
            callback=_callback
        )
