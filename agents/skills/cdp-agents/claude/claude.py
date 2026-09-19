#!/usr/bin/env python3
"""Claude.ai CDP adapter using direct page-socket CDP -- zero focus stealing, zero agent-browser."""
from __future__ import annotations

import argparse
import json
import os
import sys
import time
from pathlib import Path

# Add cdp-agents root to sys.path for direct cdp_page import
AGENT_ROOT = Path(__file__).resolve().parent.parent
if str(AGENT_ROOT) not in sys.path:
    sys.path.insert(0, str(AGENT_ROOT))

from cdp_page import CDPSocket, CDPError, pages, open_page, is_headless


COMPOSER_SELECTOR = 'div.ProseMirror[contenteditable="true"]'
SEND_BUTTON_SELECTOR = 'button[aria-label="Send message"], button[data-testid="send-button"]'
STOP_BUTTON_SELECTOR = 'button[aria-label*="Stop response" i], button[data-testid="stop-button"]'
ATTACHMENT_TRIGGER_SELECTOR = 'button[aria-label*="Add files" i]'
FILE_INPUT_SELECTOR = 'input[type="file"]'


def ensure_claude_page() -> dict:
    """Finds an existing Claude tab or opens one if running headless."""
    tabs = pages("claude.ai")
    if tabs:
        return tabs[0]
    if is_headless():
        return open_page("https://claude.ai/new")
    raise CDPError("No Claude tab found (host: claude.ai). Open https://claude.ai in Chrome or run headless.")


def check() -> bool:
    """Verifies that Claude is reachable, logged in, and composer is ready."""
    p = ensure_claude_page()
    with CDPSocket(p["webSocketDebuggerUrl"]) as s:
        status = s.eval(f"""(() => {{
            const composer = document.querySelector('{COMPOSER_SELECTOR}');
            const login = document.querySelector('a[href*="/login"], button:has-text("Log in"), button:has-text("Sign in")');
            return {{
                composer: !!composer,
                loginNeeded: !!login,
                title: document.title,
                url: location.href
            }};
        }})()""")
        if status.get("loginNeeded"):
            raise CDPError("Claude requires login")
        if not status.get("composer"):
            raise CDPError(f"Claude composer not found on {status.get('url')} (title: {status.get('title')})")
    return True


def list_projects(s: CDPSocket) -> list[dict]:
    """Discovers available projects in Claude sidebar."""
    s.eval("""(() => {
        const expandBtn = document.querySelector('button[aria-label*="Open sidebar" i], button[aria-label*="Expand sidebar" i]');
        if (expandBtn) expandBtn.click();
    })()""")
    time.sleep(0.3)

    return s.eval("""(() => {
        const links = [...document.querySelectorAll('a[href*="/project/"]')];
        return links.map(a => {
            const span = a.querySelector('span.min-w-0.truncate, span.truncate') || a;
            return {
                name: (span.textContent || '').trim(),
                href: a.href
            };
        }).filter(p => p.name);
    })()""") or []


def select_project(s: CDPSocket, name: str, timeout: float = 10.0) -> str:
    """Navigates to the specified Claude project by name or UUID."""
    want = name.strip().lower()
    cur_url = s.eval("location.href")
    if f"/project/{want}" in cur_url.lower():
        return cur_url

    res = s.eval(f"""(() => {{
        const links = [...document.querySelectorAll('a[href*="/project/"]')];
        for (const a of links) {{
            const span = a.querySelector('span.min-w-0.truncate, span.truncate') || a;
            const text = (span.textContent || '').trim().toLowerCase();
            const href = a.href.toLowerCase();
            if (text === {json.dumps(want)} || text.includes({json.dumps(want)}) || href.includes({json.dumps(want)})) {{
                a.click();
                return {{ ok: true, href: a.href, matched: text }};
            }}
        }}
        const available = links.map(a => (a.querySelector('span.min-w-0.truncate, span.truncate') || a).textContent.trim()).filter(Boolean);
        return {{ ok: false, available }};
    }})()""")

    if res.get("ok"):
        time.sleep(1.0)
        return s.eval("location.href")

    avail = ", ".join(res.get("available", [])) or "none"
    raise CDPError(f"Claude project '{name}' not found. Available: {avail}")


def start_new_conversation(s: CDPSocket) -> None:
    """Navigates to a fresh Claude conversation (/new)."""
    s.navigate("https://claude.ai/new")
    deadline = time.time() + 10.0
    while time.time() < deadline:
        time.sleep(0.25)
        if s.eval(f"!!document.querySelector('{COMPOSER_SELECTOR}')"):
            return


def attach(s: CDPSocket, paths: list[str], timeout: float = 15.0) -> None:
    """Uploads local files through Claude's file input using CDP DOM.setFileInputFiles."""
    abs_paths = [str(Path(p).expanduser().resolve()) for p in paths]
    for p in abs_paths:
        if not os.path.isfile(p):
            raise FileNotFoundError(f"Attachment file not found: {p}")

    s.eval(f"""(() => {{
        if (!document.querySelector('{FILE_INPUT_SELECTOR}')) {{
            const trigger = document.querySelector('{ATTACHMENT_TRIGGER_SELECTOR}');
            if (trigger) trigger.click();
        }}
    }})()""")
    time.sleep(0.3)
    s.set_input_files(FILE_INPUT_SELECTOR, abs_paths)


def send(s: CDPSocket, prompt: str, attachments: list[str] | None = None, timeout: float = 120.0, extract_artifacts: bool = False) -> dict:
    """Sends a prompt (with optional attachments) and returns response text and optional artifacts."""
    if attachments:
        attach(s, attachments)
        time.sleep(1.0)

    before_turns = s.eval("document.querySelectorAll('.font-claude-response, .font-claude-message, [data-testid=\"ai-message\"]').length") or 0

    inserted = s.eval(f"""(() => {{
        const composer = document.querySelector('{COMPOSER_SELECTOR}');
        if (!composer) return {{ ok: false, error: "Composer not found" }};
        composer.focus();
        document.execCommand('selectAll', false, null);
        document.execCommand('delete', false, null);
        const ok = document.execCommand('insertText', false, {json.dumps(prompt)});
        composer.dispatchEvent(new Event('input', {{ bubbles: true }}));
        return {{ ok: true }};
    }})()""")
    if not inserted.get("ok"):
        raise CDPError(f"Failed to insert prompt into Claude composer: {inserted.get('error')}")

    deadline = time.time() + 8.0
    while time.time() < deadline:
        can_send = s.eval(f"""(() => {{
            const btn = document.querySelector('{SEND_BUTTON_SELECTOR}');
            return btn && !btn.disabled;
        }})()""")
        if can_send:
            break
        time.sleep(0.15)

    clicked = s.eval(f"""(() => {{
        const btn = document.querySelector('{SEND_BUTTON_SELECTOR}');
        if (btn && !btn.disabled) {{
            btn.click();
            return true;
        }}
        return false;
    }})()""")
    if not clicked:
        raise CDPError("Could not click Claude send button (button not present or remains disabled)")

    gen_start = time.time() + 20.0
    while time.time() < gen_start:
        time.sleep(0.25)
        cur = s.eval(f"""(() => {{
            const isStreaming = !!document.querySelector('[data-is-streaming="true"], {STOP_BUTTON_SELECTOR}');
            const turns = document.querySelectorAll('.font-claude-response, .font-claude-message, [data-testid="ai-message"]').length;
            return {{ isStreaming, turns }};
        }})()""")
        if cur.get("isStreaming") or cur.get("turns", 0) > before_turns:
            break

    gen_deadline = time.time() + timeout
    last_seen = ""
    stable_count = 0

    while time.time() < gen_deadline:
        time.sleep(0.4)
        status = s.eval(f"""(() => {{
            const stop = document.querySelector('{STOP_BUTTON_SELECTOR}');
            const isStreaming = !!(document.querySelector('[data-is-streaming="true"]') || stop);
            const msgs = document.querySelectorAll('.font-claude-response, .font-claude-message, [data-testid="ai-message"]');
            const last = msgs.length > 0 ? msgs[msgs.length - 1] : null;
            if (!last) return {{ isStreaming, count: msgs.length, text: "" }};
            const prose = last.querySelector('.standard-markdown, .progressive-markdown, .markdown, .prose') || last;
            const quota = document.body.innerText.includes("You are out of free messages");
            return {{
                isStreaming,
                count: msgs.length,
                text: prose.innerText.trim(),
                quota
            }};
        }})()""")

        if status.get("quota"):
            raise CDPError("CLAUDE_QUOTA_EXHAUSTED: You are out of free messages")

        is_streaming = status.get("isStreaming", False)
        count = status.get("count", 0)
        text = status.get("text", "")

        if count > before_turns and text and not is_streaming:
            if text == last_seen:
                stable_count += 1
                if stable_count >= 2:
                    break
            else:
                last_seen = text
                stable_count = 0
        else:
            if text:
                last_seen = text
                stable_count = 0

    artifacts = None
    if extract_artifacts:
        artifacts = s.eval("""(() => {
            const panel = document.querySelector('div[data-testid="artifact-panel"], aside');
            if (!panel) return null;
            const codeTab = panel.querySelector('button[role="tab"][aria-label*="Code" i]');
            if (codeTab && codeTab.getAttribute('aria-selected') !== 'true') codeTab.click();
            const code = panel.querySelector('pre code, pre');
            return {
                title: (panel.querySelector('h2, h3, [class*="title"]')?.textContent || '').trim(),
                code: code ? code.textContent : null
            };
        })()""")

    return {
        "text": last_seen,
        "artifacts": artifacts
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Claude.ai CLI adapter over Chrome CDP")
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--project", help="Select Claude project container by name or UUID")
    ap.add_argument("--attach", action="append", default=[], help="Attach local files")
    ap.add_argument("--check", action="store_true", help="Check CDP reachability and login state")
    ap.add_argument("--new", action="store_true", help="Start a fresh conversation in Claude (/new)")
    ap.add_argument("--artifacts", action="store_true", help="Extract artifact code if generated")
    ap.add_argument("--list-projects", action="store_true", help="List all discovered Claude projects")
    ns = ap.parse_args()

    # Read piped stdin if present
    if not sys.stdin.isatty() and not (ns.check or ns.list_projects):
        try:
            piped = sys.stdin.read().strip()
            if piped:
                ns.prompt = f"{ns.prompt}\n\n{piped}" if ns.prompt else piped
        except Exception:
            pass

    try:
        if ns.check:
            check()
            print("ok")
            return 0

        p = ensure_claude_page()
        with CDPSocket(p["webSocketDebuggerUrl"]) as s:
            if ns.list_projects:
                projs = list_projects(s)
                print(f"Discovered Claude Projects ({len(projs)}):")
                for pr in projs:
                    print(f"  - {pr['name']:<25} {pr['href']}")
                return 0

            if ns.project:
                select_project(s, ns.project)

            if ns.new:
                start_new_conversation(s)

            if ns.prompt:
                res = send(s, ns.prompt, ns.attach if ns.attach else None, extract_artifacts=ns.artifacts)
                print(res["text"])
                if res.get("artifacts") and res["artifacts"].get("code"):
                    print(f"\n--- Artifact: {res['artifacts'].get('title', 'Code')} ---")
                    print(res["artifacts"]["code"])
                return 0
            else:
                cur_url = s.eval("location.href")
                print(cur_url)
                return 0

    except Exception as exc:
        print(f"claude-cdp: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
