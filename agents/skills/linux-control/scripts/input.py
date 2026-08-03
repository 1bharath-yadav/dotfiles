#!/usr/bin/env python3
"""
input.py - Wayland hardware input automation CLI for ydotool, wtype, wl-clipboard, and hyprctl dispatches.
"""
import os
import sys
import json
import shutil
import subprocess
import time
from typing import Dict, Any

def get_hypr_env() -> Dict[str, str]:
    """Auto-discover HYPRLAND_INSTANCE_SIGNATURE and XDG_RUNTIME_DIR."""
    env = os.environ.copy()
    uid = str(os.getuid())
    env["XDG_RUNTIME_DIR"] = f"/run/user/{uid}"
    if "HYPRLAND_INSTANCE_SIGNATURE" not in env or not env["HYPRLAND_INSTANCE_SIGNATURE"]:
        hypr_dir = f"/run/user/{uid}/hypr"
        if os.path.exists(hypr_dir):
            sigs = os.listdir(hypr_dir)
            if sigs:
                env["HYPRLAND_INSTANCE_SIGNATURE"] = sigs[0]
    return env

def move_cursor(x: int, y: int) -> bool:
    """Move cursor to absolute coordinates (x, y)."""
    env = get_hypr_env()
    # Primary: ydotool mousemove -a -x X -y Y
    cmd = ["ydotool", "mousemove", "-a", "-x", str(x), "-y", str(y)]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.returncode == 0

def click_cursor(x: Optional[int] = None, y: Optional[int] = None, button: str = "left") -> bool:
    """Click mouse button at current or specified coordinates."""
    if x is not None and y is not None:
        move_cursor(x, y)
        time.sleep(0.05)
    
    env = get_hypr_env()
    btn_code = "0x00"  # left
    if button == "right":
        btn_code = "0x01"
    elif button == "middle":
        btn_code = "0x02"

    cmd = ["ydotool", "click", btn_code]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.returncode == 0

def type_text(text: str) -> bool:
    """Type string into focused application via wtype or ydotool type stdin."""
    env = get_hypr_env()
    # Primary: wtype
    cmd = ["wtype", text]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode == 0:
        return True
    
    # Fallback: ydotool type -f -
    p = subprocess.Popen(["ydotool", "type", "-f", "-"], env=env, stdin=subprocess.PIPE, text=True)
    p.communicate(input=text)
    return p.returncode == 0

def paste_clipboard(text: str) -> bool:
    """Write text to Wayland clipboard using wl-copy with pre-paste verification."""
    env = get_hypr_env()
    # 1. Copy to clipboard
    p = subprocess.Popen(["wl-copy"], env=env, stdin=subprocess.PIPE, text=True)
    p.communicate(input=text)
    time.sleep(0.05)
    
    # 2. Verify clipboard payload before sending Ctrl+V
    check = subprocess.run(["wl-paste"], env=env, stdout=subprocess.PIPE, text=True)
    if check.returncode != 0 or text not in check.stdout:
        # Retry staging once
        p2 = subprocess.Popen(["wl-copy"], env=env, stdin=subprocess.PIPE, text=True)
        p2.communicate(input=text)
        time.sleep(0.05)

    # 3. Trigger paste shortcut Ctrl+V
    cmd = ["wtype", "-M", "ctrl", "-k", "v"]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.returncode == 0

def hypr_dispatch(expression: str) -> bool:
    """Execute native Hyprland compositor dispatch via hyprctl."""
    env = get_hypr_env()
    cmd = ["hyprctl", "dispatch", expression]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    return res.returncode == 0 or "ok" in res.stdout.lower()

def open_url(url: str) -> bool:
    """Launch URL using installed browser or xdg-open (Level 1 Hybrid Engine)."""
    env = get_hypr_env()
    browsers = ["google-chrome-stable", "zen-browser", "firefox", "chromium", "xdg-open"]
    for b in browsers:
        if shutil.which(b):
            cmd = [b, url]
            subprocess.Popen(cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
            return True
    return False

def close_active_window() -> bool:
    """Close active focused window via Hyprland keybind dispatch (SUPER+Q)."""
    return hypr_dispatch("hl.dsp.window.close()")

def kill_active_window() -> bool:
    """Force kill active focused window via hyprctl kill."""
    return hypr_dispatch("exec_cmd hyprctl kill") or hypr_dispatch("killactive")

def toggle_float_window() -> bool:
    """Toggle floating/tiled layout for active window (SUPER+ALT+Space)."""
    return hypr_dispatch("hl.dsp.window.float({ action = \"toggle\" })")

def toggle_fullscreen_window() -> bool:
    """Toggle fullscreen mode for active window (SUPER+F)."""
    return hypr_dispatch("hl.dsp.window.fullscreen({ mode = \"fullscreen\", action = \"toggle\" })")

def open_chrome_cdp(port: int = 9222, url: str = "about:blank") -> bool:
    """Launch Chrome with Remote Debugging CDP enabled on specified port."""
    env = get_hypr_env()
    chrome_bin = shutil.which("google-chrome-stable") or shutil.which("google-chrome") or shutil.which("chromium")
    if chrome_bin:
        profile_dir = f"/tmp/chrome_cdp_profile_{port}"
        cmd = [chrome_bin, f"--remote-debugging-port={port}", f"--user-data-dir={profile_dir}", url]
        subprocess.Popen(cmd, env=env, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        return True
    return False

def main():
    if len(sys.argv) < 2:
        print("Usage: input.py <move|click|type|paste|dispatch|open_url|close|kill|float|fullscreen|chrome_cdp> [args...]")
        sys.exit(1)
    
    action = sys.argv[1]
    if action == "move":
        x, y = int(sys.argv[2]), int(sys.argv[3])
        ok = move_cursor(x, y)
        print(json.dumps({"status": "success" if ok else "failed", "action": "move", "x": x, "y": y}))
    elif action == "click":
        x = int(sys.argv[2]) if len(sys.argv) > 3 else None
        y = int(sys.argv[3]) if len(sys.argv) > 3 else None
        btn = sys.argv[4] if len(sys.argv) > 4 else "left"
        ok = click_cursor(x, y, btn)
        print(json.dumps({"status": "success" if ok else "failed", "action": "click", "btn": btn}))
    elif action == "type":
        text = " ".join(sys.argv[2:])
        ok = type_text(text)
        print(json.dumps({"status": "success" if ok else "failed", "action": "type"}))
    elif action == "paste":
        text = " ".join(sys.argv[2:])
        ok = paste_clipboard(text)
        print(json.dumps({"status": "success" if ok else "failed", "action": "paste"}))
    elif action == "dispatch":
        expr = " ".join(sys.argv[2:])
        ok = hypr_dispatch(expr)
        print(json.dumps({"status": "success" if ok else "failed", "action": "dispatch", "expr": expr}))
    elif action == "open_url":
        url = sys.argv[2]
        ok = open_url(url)
        print(json.dumps({"status": "success" if ok else "failed", "action": "open_url", "url": url}))
    elif action == "close":
        ok = close_active_window()
        print(json.dumps({"status": "success" if ok else "failed", "action": "close"}))
    elif action == "kill":
        ok = kill_active_window()
        print(json.dumps({"status": "success" if ok else "failed", "action": "kill"}))
    elif action == "float":
        ok = toggle_float_window()
        print(json.dumps({"status": "success" if ok else "failed", "action": "float"}))
    elif action == "fullscreen":
        ok = toggle_fullscreen_window()
        print(json.dumps({"status": "success" if ok else "failed", "action": "fullscreen"}))
    elif action == "chrome_cdp":
        port = int(sys.argv[2]) if len(sys.argv) > 2 else 9222
        url = sys.argv[3] if len(sys.argv) > 3 else "about:blank"
        ok = open_chrome_cdp(port, url)
        print(json.dumps({"status": "success" if ok else "failed", "action": "chrome_cdp", "port": port, "url": url}))

if __name__ == "__main__":
    main()


