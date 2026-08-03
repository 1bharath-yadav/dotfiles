#!/usr/bin/env python3
"""
capture.py - Desktop visual capture, fingerprinting, and OCR utility.
Uses grim, slurp, tesseract, and hashlib for Wayland desktop vision integration.
"""
import os
import sys
import glob
import subprocess
import hashlib
import json
from typing import Dict, Any, Optional

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

def capture_screen(output_path: str = "/tmp/desktop_screen.png") -> str:
    """Capture full desktop screenshot using grim."""
    env = get_hypr_env()
    cmd = ["grim", output_path]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"grim failed: {res.stderr}")
    return output_path

def capture_region(geometry: str, output_path: str = "/tmp/desktop_region.png") -> str:
    """Capture specific screen region geometry 'X,Y WxH' or slurp geometry string."""
    env = get_hypr_env()
    cmd = ["grim", "-g", geometry, output_path]
    res = subprocess.run(cmd, env=env, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        raise RuntimeError(f"grim region capture failed: {res.stderr}")
    return output_path

def get_image_hash(image_path: str) -> str:
    """Generate SHA256/MD5 fingerprint hash of image for zero-change verification."""
    if not os.path.exists(image_path):
        return ""
    with open(image_path, "rb") as f:
        return hashlib.sha256(f.read()).hexdigest()[:16]

def run_ocr(image_path: str) -> Dict[str, Any]:
    """Perform OCR on an image using tesseract CLI, returning extracted text and boxes."""
    if not os.path.exists(image_path):
        return {"text": "", "words": []}
    
    # Run tesseract to get TSV output with word bounding boxes
    cmd = ["tesseract", image_path, "stdout", "tsv"]
    res = subprocess.run(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
    if res.returncode != 0:
        # Fallback to plain text OCR
        cmd_txt = ["tesseract", image_path, "stdout"]
        res_txt = subprocess.run(cmd_txt, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True)
        return {"text": res_txt.stdout.strip(), "words": []}

    lines = res.stdout.strip().split("\n")
    words = []
    full_text_list = []
    
    if len(lines) > 1:
        headers = lines[0].split("\t")
        for line in lines[1:]:
            parts = line.split("\t")
            if len(parts) >= 12 and parts[11].strip():
                word_str = parts[11].strip()
                full_text_list.append(word_str)
                try:
                    words.append({
                        "text": word_str,
                        "left": int(parts[6]),
                        "top": int(parts[7]),
                        "width": int(parts[8]),
                        "height": int(parts[9]),
                        "confidence": float(parts[10])
                    })
                except ValueError:
                    pass

    return {
        "text": " ".join(full_text_list),
        "words": words
    }

def main():
    if len(sys.argv) < 2:
        print("Usage: capture.py <full|region|ocr|hash> [path/geometry]")
        sys.exit(1)
    
    action = sys.argv[1]
    if action == "full":
        out = sys.argv[2] if len(sys.argv) > 2 else "/tmp/desktop_screen.png"
        path = capture_screen(out)
        h = get_image_hash(path)
        print(json.dumps({"status": "success", "path": path, "hash": h}))
    elif action == "region":
        geom = sys.argv[2] if len(sys.argv) > 2 else "0,0 500x500"
        out = sys.argv[3] if len(sys.argv) > 3 else "/tmp/desktop_region.png"
        path = capture_region(geom, out)
        h = get_image_hash(path)
        print(json.dumps({"status": "success", "path": path, "hash": h}))
    elif action == "ocr":
        path = sys.argv[2] if len(sys.argv) > 2 else "/tmp/desktop_screen.png"
        res = run_ocr(path)
        print(json.dumps({"status": "success", "ocr": res}))
    elif action == "hash":
        path = sys.argv[2] if len(sys.argv) > 2 else "/tmp/desktop_screen.png"
        h = get_image_hash(path)
        print(json.dumps({"status": "success", "hash": h}))

if __name__ == "__main__":
    main()
