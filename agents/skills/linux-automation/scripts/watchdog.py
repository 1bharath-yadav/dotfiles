#!/usr/bin/env python3
"""
watchdog.py - Timeout monitoring, hung-process detection, and popup dismissal recovery.
"""
import os
import sys
import json
import subprocess
import time
from typing import Dict, Any

def check_process_alive(pid: int) -> bool:
    """Check if process ID is still active."""
    try:
        os.kill(pid, 0)
        return True
    except OSError:
        return False

def recover_hung_window(app_class: str) -> bool:
    """Attempt automated window recovery (refocusing via hyprctl or ESC key)."""
    input_script = os.path.join(os.path.dirname(__file__), "../../linux-control/scripts/input.py")
    if os.path.exists(input_script):
        # 1. Send Escape key to dismiss modals/popups
        subprocess.run([sys.executable, input_script, "type", "\x1b"], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        time.sleep(0.1)
        # 2. Refocus app window
        res = subprocess.run([sys.executable, input_script, "dispatch", f'hl.dsp.exec_cmd("{app_class}")'], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return res.returncode == 0
    return False

def main():
    if len(sys.argv) < 2:
        print("Usage: watchdog.py <check_pid|recover_app> [pid/app_class]")
        sys.exit(1)
    
    action = sys.argv[1]
    if action == "check_pid":
        pid = int(sys.argv[2])
        alive = check_process_alive(pid)
        print(json.dumps({"status": "success", "pid": pid, "alive": alive}))
    elif action == "recover_app":
        app_class = sys.argv[2]
        ok = recover_hung_window(app_class)
        print(json.dumps({"status": "success" if ok else "failed", "app_class": app_class}))

if __name__ == "__main__":
    main()
