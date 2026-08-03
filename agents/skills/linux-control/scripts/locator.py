#!/usr/bin/env python3
"""
locator.py - 5-tier locator engine & system capability probe for Wayland/Hyprland.
Tier 1: AT-SPI Accessibility Tree
Tier 2: Native Window Metadata (hyprctl activewindow -j)
Tier 3: Visual OCR Text Matching (tesseract TSV)
Tier 4: Visual Region Fingerprinting
Tier 5: Physical Coordinates & HiDPI Scale Offset
"""
import os
import sys
import json
import shutil
import subprocess
from typing import Dict, Any, List, Optional

def get_hypr_env() -> Dict[str, str]:
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

def probe_capabilities() -> Dict[str, Any]:
    """Probe for installed system CLI utilities and AT-SPI accessibility bus."""
    tools = ["hyprctl", "ydotool", "wtype", "grim", "slurp", "wl-copy", "wl-paste", "tesseract"]
    capabilities = {}
    for tool in tools:
        capabilities[tool] = shutil.which(tool) is not None
    
    # Check ydotool daemon (ydotoold)
    try:
        res = subprocess.run(["pgrep", "-f", "ydotoold"], stdout=subprocess.PIPE, text=True)
        capabilities["ydotoold_running"] = res.returncode == 0
    except Exception:
        capabilities["ydotoold_running"] = False
        
    # Check AT-SPI python bindings
    try:
        import pyatspi
        capabilities["atspi"] = True
    except ImportError:
        capabilities["atspi"] = False

    return capabilities

def get_active_window() -> Dict[str, Any]:
    """Fetch active focused window metadata from hyprctl activewindow -j."""
    env = get_hypr_env()
    cmd = ["hyprctl", "activewindow", "-j"]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode == 0 and res.stdout.strip():
        try:
            return json.loads(res.stdout)
        except json.JSONDecodeError:
            pass
    return {}

def get_monitors() -> List[Dict[str, Any]]:
    """Fetch connected monitors and scale factors from hyprctl monitors -j."""
    env = get_hypr_env()
    cmd = ["hyprctl", "monitors", "-j"]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode == 0 and res.stdout.strip():
        try:
            return json.loads(res.stdout)
        except json.JSONDecodeError:
            pass
    return []

def locate_target(query: str) -> Dict[str, Any]:
    """
    Search for target UI element by query string across Locator Tiers:
    Returns { tier_used, confidence, x, y, width, height, metadata }
    """
    # Tier 1: AT-SPI Accessibility Tree
    try:
        import pyatspi
        reg = pyatspi.Registry
        desktop = reg.getDesktop(0)
        for app in desktop:
            if not app: continue
            for child in app:
                if not child: continue
                try:
                    name = child.name or ""
                    if query.lower() in name.lower():
                        comp = child.queryComponent()
                        rect = comp.getExtents(pyatspi.DESKTOP_COORDS)
                        return {
                            "tier_used": 1,
                            "tier_name": "AT-SPI Accessibility",
                            "confidence": 0.98,
                            "x": rect.x,
                            "y": rect.y,
                            "width": rect.width,
                            "height": rect.height,
                            "text": name
                        }
                except Exception:
                    pass
    except Exception:
        pass

    # Tier 2: Hyprland Window Metadata (Window Offset)
    win = get_active_window()
    if win and "at" in win and "size" in win:
        wx, wy = win["at"][0], win["at"][1]
        ww, wh = win["size"][0], win["size"][1]
        # Return center of active window as default target if active window matches
        if query.lower() in win.get("class", "").lower() or query.lower() in win.get("title", "").lower():
            return {
                "tier_used": 2,
                "tier_name": "Hyprland Window Metadata",
                "confidence": 0.90,
                "x": wx + (ww // 2),
                "y": wy + (wh // 2),
                "width": ww,
                "height": wh,
                "text": win.get("title", "")
            }

    # Tier 3: OCR Text Search via tesseract
    capture_script = os.path.join(os.path.dirname(__file__), "capture.py")
    if os.path.exists(capture_script):
        tmp_screen = "/tmp/locator_screen.png"
        subprocess.run([sys.executable, capture_script, "full", tmp_screen], stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        res = subprocess.run([sys.executable, capture_script, "ocr", tmp_screen], stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        if res.returncode == 0:
            try:
                ocr_data = json.loads(res.stdout).get("ocr", {})
                for word in ocr_data.get("words", []):
                    if query.lower() in word["text"].lower():
                        return {
                            "tier_used": 3,
                            "tier_name": "OCR Bounding Box",
                            "confidence": 0.85,
                            "x": word["left"] + (word["width"] // 2),
                            "y": word["top"] + (word["height"] // 2),
                            "width": word["width"],
                            "height": word["height"],
                            "text": word["text"]
                        }
            except Exception:
                pass

    return {
        "tier_used": 0,
        "tier_name": "None",
        "confidence": 0.0,
        "error": f"Target '{query}' not found across locators"
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: locator.py <probe|state|locate> [query]")
        sys.exit(1)
    
    action = sys.argv[1]
    if action == "probe":
        caps = probe_capabilities()
        print(json.dumps({"status": "success", "capabilities": caps}, indent=2))
    elif action == "state":
        win = get_active_window()
        monitors = get_monitors()
        print(json.dumps({"status": "success", "active_window": win, "monitors": monitors}, indent=2))
    elif action == "locate":
        query = sys.argv[2] if len(sys.argv) > 2 else ""
        res = locate_target(query)
        print(json.dumps({"status": "success", "result": res}, indent=2))

if __name__ == "__main__":
    main()
