#!/usr/bin/env python3
"""Claude.ai worker using named persistent agent-browser sessions."""
from __future__ import annotations
import argparse, os, re, subprocess, sys, time
from pathlib import Path

AB = os.environ.get("AGENT_BROWSER", "agent-browser")
CDP_PORT = os.environ.get("CLAUDE_CDP_PORT", "9222")
PROMPT = "Write your prompt to Claude"
QUOTA = "You are out of free messages"
TOTAL_TIMEOUT = 90.0
BASE_SESSION = os.environ.get("CLAUDE_AGENT_BROWSER_SESSION", "claude-account")


def session_name(account: str | None) -> str:
    return f"{BASE_SESSION}-{account.strip()}" if account else BASE_SESSION


def run(session: str, *args: str, check: bool = True) -> str:
    cmd = [AB, "--cdp", CDP_PORT, "--session", session, "--restore", *args]
    p = subprocess.run(cmd, text=True, capture_output=True)
    if check and p.returncode:
        raise RuntimeError((p.stderr or p.stdout).strip())
    return (p.stdout or p.stderr).strip()


def tab_list(session: str) -> str:
    return run(session, "tab", "list")


def ensure_claude_tab(session: str) -> None:
    out = tab_list(session)
    if "claude.ai" in out.lower():
        return
    run(session, "open", "https://claude.ai/new")
    time.sleep(2)
    if "claude.ai" not in tab_list(session).lower():
        raise RuntimeError("Unable to open Claude.ai")


def snapshot(session: str) -> str:
    ensure_claude_tab(session)
    return run(session, "snapshot", "-c")


def select_project(session: str, name: str) -> str:
    js = f"""(()=>{{const spans=[...document.querySelectorAll('span.min-w-0.truncate')];const e=spans.find(x=>x.textContent?.trim()==={name!r});if(!e)return 'NOT_FOUND';const a=e.closest('a');if(!a)return 'NO_LINK';a.click();return a.href}})()"""
    out = run(session, "eval", js)
    if out in {"NOT_FOUND", "NO_LINK", ""}:
        raise RuntimeError(f"Project not found: {name}")
    time.sleep(1)
    return run(session, "get", "url")


def attach_files(session: str, paths: list[str]) -> None:
    for path in paths:
        if not Path(path).is_file():
            raise FileNotFoundError(path)
    run(session, "upload", 'input[type="file"]', *paths)


def extract_response(before: str, current: str, prompt: str) -> str | None:
    if "Currently streaming message" in current:
        return None
    matches = re.findall(r"Claude responded:\s*(.*)", current)
    if not matches or current == before:
        return None
    candidate = matches[-1].strip()
    if not candidate or candidate.replace(" ", "").lower() == prompt.replace(" ", "").lower():
        return None
    return candidate


def send_prompt(session: str, text: str, attachments: list[str]) -> str:
    before = snapshot(session)
    if attachments:
        run(session, "click", "Add files, connectors, and more")
        time.sleep(0.3)
        attach_files(session, attachments)
        time.sleep(0.5)
    run(session, "find", "label", PROMPT, "fill", text)
    run(session, "press", "Enter")
    deadline = time.monotonic() + TOTAL_TIMEOUT
    while time.monotonic() < deadline:
        current = snapshot(session)
        if QUOTA in current:
            raise RuntimeError("CLAUDE_QUOTA_EXHAUSTED")
        answer = extract_response(before, current, text)
        if answer:
            return answer
        time.sleep(0.8)
    raise TimeoutError("Timed out waiting for Claude response")


def ensure_login(account: str) -> None:
    """Interactive one-time login: open the named persistent session if needed."""
    s = session_name(account)
    ensure_claude_tab(s)
    current = snapshot(s)
    if "Sign in" in current or "Log in" in current:
        print(f"claude-cdp: login required in persistent session '{s}'", file=sys.stderr)
        print(f"claude-cdp: complete login interactively, then rerun this command", file=sys.stderr)
        return
    print(f"claude-cdp: session '{s}' is ready", file=sys.stderr)


def main() -> int:
    ap = argparse.ArgumentParser()
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--account", help="Persistent account/session name")
    ap.add_argument("--login", action="store_true", help="Open/check the named persistent account session for interactive login")
    ap.add_argument("--check", action="store_true")
    ap.add_argument("--project")
    ap.add_argument("--attach", action="append", default=[])
    ns = ap.parse_args()
    try:
        if not ns.account and (ns.login or ns.prompt):
            ap.error("--account is required for persistent Claude sessions")
        if ns.account:
            ensure_login(ns.account)
        s = session_name(ns.account)
        if ns.login:
            return 0
        if ns.check:
            print("ok")
            return 0
        if ns.project:
            select_project(s, ns.project)
        if not ns.prompt:
            ap.error("prompt required unless --check or --login")
        try:
            print(send_prompt(s, ns.prompt, ns.attach))
        except RuntimeError as exc:
            if str(exc) != "CLAUDE_QUOTA_EXHAUSTED":
                raise
            raise RuntimeError("Claude account quota exhausted; use the next persistent --account session")
        return 0
    except Exception as exc:
        print(f"claude-cdp: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
