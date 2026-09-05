#!/usr/bin/env python3
"""Gemini Web CDP adapter, including Spark."""
from __future__ import annotations
import argparse
import os
import re
import subprocess
import sys
import time
from pathlib import Path

AB = os.environ.get("AGENT_BROWSER", str(Path.home() / ".local/share/mise/installs/node/26.8.1/lib/node_modules/agent-browser/bin/agent-browser-linux-x64"))
CDP = os.environ.get("GEMINI_CDP_PORT", "9222")
PROMPT = "Enter a prompt for Gemini"


def run(*args: str) -> str:
    p = subprocess.run([AB, "--cdp", CDP, *args], text=True, capture_output=True)
    out = (p.stdout or p.stderr).strip()
    if p.returncode:
        raise RuntimeError(out)
    return out


def snapshot() -> str:
    return run("snapshot", "-c")


def ensure_gemini_tab() -> None:
    if "gemini.google.com" not in run("tab", "list").lower():
        raise RuntimeError("No Gemini tab found on CDP endpoint")


def select_notebook(name: str) -> str:
    js = f"""(()=>{{const a=[...document.querySelectorAll('a[href*=\"/notebook/\"]')].find(x=>x.textContent?.trim()==={name!r});if(!a)return 'NOT_FOUND';a.click();return a.href}})()"""
    out = run("eval", js)
    if not out or out == "NOT_FOUND":
        raise RuntimeError(f"Gemini notebook not found: {name}")
    time.sleep(1.0)
    return run("get", "url")


def open_spark() -> str:
    js = """(()=>{const buttons=[...document.querySelectorAll('button')];const b=buttons.find(x=>x.textContent?.trim()==='Spark');if(!b)return 'NOT_FOUND';b.click();return location.href})()"""
    out = run("eval", js)
    if out == "NOT_FOUND":
        # Spark may already be the active route.
        url = run("get", "url")
        if "/spark/" not in url:
            raise RuntimeError("Gemini Spark control not found")
        return url
    time.sleep(1.0)
    return run("get", "url")


def attach_files(paths: list[str]) -> None:
    if not paths:
        return
    for path in paths:
        if not Path(path).is_file():
            raise FileNotFoundError(path)
    run("find", "role", "button", "click", "--name", "Upload & tools")
    time.sleep(0.4)
    run("find", "role", "menuitem", "click", "--name", "Upload files. Documents, data, code files")
    time.sleep(0.4)
    run("upload", 'input[type="file"]', *paths)
    time.sleep(0.7)


def send_prompt(text: str) -> str:
    before = snapshot()
    run("find", "role", "textbox", "fill", "--name", PROMPT, text)
    run("press", "Enter")
    deadline = time.time() + 120
    while time.time() < deadline:
        time.sleep(1.2)
        current = snapshot()
        if current == before:
            continue
        if "Thinking it through" in current or 'button "Stop"' in current:
            continue
        matches = re.findall(r'Gemini said[\s\S]*?\n\s*- (?:paragraph|StaticText) "([^"]+)', current)
        if matches:
            return matches[-1].strip()
        if "Gemini said" in current:
            lines = [x.strip() for x in current.splitlines()]
            marker = next((i for i, line in enumerate(lines) if line.startswith('- heading "Gemini said"')), None)
            if marker is not None:
                for nxt in lines[marker + 1 : marker + 50]:
                    m = re.search(r'(?:StaticText|paragraph) "(.*)"', nxt)
                    if m and m.group(1).strip():
                        return m.group(1).strip()
    raise TimeoutError("Timed out waiting for Gemini response")


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--notebook")
    ap.add_argument("--project")
    ap.add_argument("--spark", action="store_true")
    ap.add_argument("--attach", action="append", default=[])
    ns = ap.parse_args()
    try:
        ensure_gemini_tab()
        if ns.spark:
            open_spark()
        if ns.notebook or ns.project:
            select_notebook(ns.notebook or ns.project)
        if ns.check:
            print("ok")
            return 0
        if not ns.prompt:
            ap.error("prompt required unless --check")
        if ns.attach:
            attach_files(ns.attach)
        print(send_prompt(ns.prompt))
        return 0
    except Exception as exc:
        print(f"gemini-cdp: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
