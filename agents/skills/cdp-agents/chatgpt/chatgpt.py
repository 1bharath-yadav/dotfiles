#!/usr/bin/env python3
"""ChatGPT web adapter over an existing authenticated Chrome CDP session."""
from __future__ import annotations

import argparse
import re
import subprocess
import sys
import time
from pathlib import Path

AB = str(Path.home() / ".local/share/mise/installs/node/26.8.1/lib/node_modules/agent-browser/bin/agent-browser-linux-x64")
CDP = "9222"
COMPOSER = "Chat with ChatGPT"

def run(*args: str) -> str:
    p = subprocess.run([AB, "--cdp", CDP, *args], text=True, capture_output=True)
    out = (p.stdout or p.stderr).strip()
    if p.returncode:
        raise RuntimeError(out)
    return out

def snapshot() -> str:
    return run("snapshot", "-c")

def find_chatgpt() -> None:
    if "chatgpt.com" not in run("tab", "list").lower():
        run("open", "https://chatgpt.com/")

def select_project(name: str) -> str:
    js = f"""(()=>{{const s=[...document.querySelectorAll('*')].find(x=>x.textContent?.trim()==={name!r});if(!s)return 'NOT_FOUND';const root=s.closest('li')||s.parentElement;const b=root?.querySelector('button[aria-label=\\\"Open project home\\\"]');if(!b)return 'NO_HOME';b.click();return 'clicked'}})()"""
    out = run("eval", js)
    if out != '"clicked"':
        raise RuntimeError(f"ChatGPT project not found: {name}")
    time.sleep(1)
    if name.lower() not in snapshot().lower():
        raise RuntimeError("Project navigation did not reach requested project")
    return run("get", "url")

def attach(paths: list[str]) -> None:
    for path in paths:
        if not Path(path).is_file():
            raise FileNotFoundError(path)
    run("eval", "(()=>{const b=[...document.querySelectorAll('button')].find(x=>x.getAttribute('aria-label')==='Add files and more');b?.click();return !!b})()")
    time.sleep(.3)
    run("upload", 'input[type="file"]', *paths)
    time.sleep(.5)

def send(prompt: str, attachments: list[str] | None = None) -> str:
    before = snapshot()
    if attachments:
        attach(attachments)
    run("find", "label", COMPOSER, "fill", prompt)
    run("press", "Enter")
    deadline = time.time() + 90
    while time.time() < deadline:
        time.sleep(1.2)
        cur = snapshot()
        if prompt not in cur:
            continue
        # ChatGPT's latest assistant response is represented in the main tree;
        # wait for the composer to return after generation.
        if COMPOSER not in cur:
            continue
        if cur != before and not any(x in cur for x in ("Stop generating", "Generating", "Thinking")):
            blocks = re.findall(r'(?m)^\s*- StaticText "([^"]+)"$', cur)
            if blocks:
                for text in reversed(blocks):
                    if text.strip() and text.strip() != prompt.strip():
                        return text.strip()
    raise TimeoutError("Timed out waiting for ChatGPT response")

def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--project")
    ap.add_argument("--attach", action="append", default=[])
    ap.add_argument("--check", action="store_true")
    ns = ap.parse_args()
    try:
        find_chatgpt()
        if ns.project:
            select_project(ns.project)
        if ns.check:
            print("ok")
        elif ns.prompt:
            print(send(ns.prompt, ns.attach))
        else:
            ap.error("prompt required unless --check")
        return 0
    except Exception as exc:
        print(f"chatgpt-cdp: {exc}", file=sys.stderr)
        return 1

if __name__ == "__main__":
    raise SystemExit(main())
