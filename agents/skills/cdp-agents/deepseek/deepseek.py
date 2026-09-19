#!/usr/bin/env python3
"""DeepSeek Web (chat.deepseek.com) CDP adapter using direct page-socket CDP -- zero focus stealing, zero agent-browser."""
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


COMPOSER_SELECTOR = "textarea#chat-input, textarea[placeholder*='DeepSeek'], textarea"
FILE_INPUT_SELECTOR = 'input[type="file"]'


def ensure_deepseek_page() -> dict:
    """Finds an existing DeepSeek tab or opens one if running headless."""
    tabs = pages("deepseek.com")
    if tabs:
        return tabs[0]
    if is_headless():
        return open_page("https://chat.deepseek.com/")
    raise CDPError("No DeepSeek tab found (host: chat.deepseek.com). Open https://chat.deepseek.com in Chrome or run headless.")


def check() -> bool:
    """Verifies that DeepSeek is reachable, logged in, and composer is ready."""
    p = ensure_deepseek_page()
    with CDPSocket(p["webSocketDebuggerUrl"]) as s:
        status = s.eval(f"""(() => {{
            const composer = document.querySelector("{COMPOSER_SELECTOR}");
            const login = document.querySelector('a[href*="/login"], button:has-text("Log in"), button:has-text("Sign in")');
            return {{
                composer: !!composer,
                loginNeeded: !!login,
                title: document.title,
                url: location.href
            }};
        }})()""")
        if status.get("loginNeeded"):
            raise CDPError("DeepSeek requires login")
        if not status.get("composer"):
            raise CDPError(f"DeepSeek composer not found on {status.get('url')} (title: {status.get('title')})")
    return True


def start_new_conversation(s: CDPSocket) -> None:
    """Starts a new chat in DeepSeek."""
    clicked = s.eval("""(() => {
        const btn = document.querySelector("div._5a8ac7a.a084f19e") ||
                    [...document.querySelectorAll("div[tabindex='0'], button")].find(el =>
                        /^\\s*(New chat|新对话)\\s*$/i.test(el.textContent)
                    );
        if (btn && btn.offsetParent !== null) {
            btn.click();
            return true;
        }
        return false;
    })()""")
    if not clicked:
        s.navigate("https://chat.deepseek.com/")

    deadline = time.time() + 10.0
    while time.time() < deadline:
        time.sleep(0.25)
        if s.eval(f"!!document.querySelector('{COMPOSER_SELECTOR}')"):
            return


def set_deepthink(s: CDPSocket, enable: bool) -> bool:
    """Toggles DeepThink (R1 Reasoner) mode."""
    return s.eval(f"""(() => {{
        const btn = [...document.querySelectorAll(".ds-toggle-button, [role='button']")].find(el =>
            /DeepThink|深度思考/i.test(el.textContent)
        );
        if (!btn) return false;
        const isActive = btn.classList.contains("ds-toggle-button--selected") || btn.getAttribute("aria-pressed") === "true";
        if (isActive !== {json.dumps(enable)}) {{
            btn.click();
        }}
        return true;
    }})()""")


def set_search(s: CDPSocket, enable: bool) -> bool:
    """Toggles Web Search mode."""
    return s.eval(f"""(() => {{
        const btn = [...document.querySelectorAll(".ds-toggle-button, [role='button']")].find(el =>
            /Search|联网搜索/i.test(el.textContent)
        );
        if (!btn) return false;
        const isActive = btn.classList.contains("ds-toggle-button--selected") || btn.getAttribute("aria-pressed") === "true";
        if (isActive !== {json.dumps(enable)}) {{
            btn.click();
        }}
        return true;
    }})()""")


def attach(s: CDPSocket, paths: list[str], timeout: float = 15.0) -> None:
    """Uploads local files through DeepSeek's file input using CDP DOM.setFileInputFiles."""
    abs_paths = [str(Path(p).expanduser().resolve()) for p in paths]
    for p in abs_paths:
        if not os.path.isfile(p):
            raise FileNotFoundError(f"Attachment file not found: {p}")

    s.set_input_files(FILE_INPUT_SELECTOR, abs_paths)


def send(s: CDPSocket, prompt: str, attachments: list[str] | None = None, timeout: float = 120.0, think: bool | None = None, search: bool | None = None) -> dict:
    """Sends a prompt to DeepSeek, waits for generation to finish, and returns response and reasoning."""
    if think is not None:
        set_deepthink(s, think)
        time.sleep(0.2)
    if search is not None:
        set_search(s, search)
        time.sleep(0.2)

    if attachments:
        attach(s, attachments)
        time.sleep(1.0)

    before_turns = s.eval("document.querySelectorAll('.ds-markdown').length") or 0

    # Insert text into composer
    inserted = s.eval(f"""(() => {{
        const el = document.querySelector("{COMPOSER_SELECTOR}");
        if (!el) return {{ ok: false, error: "Composer not found" }};
        el.focus();
        el.value = {json.dumps(prompt)};
        el.dispatchEvent(new Event('input', {{ bubbles: true }}));
        el.dispatchEvent(new Event('change', {{ bubbles: true }}));
        return {{ ok: true }};
    }})()""")
    if not inserted.get("ok"):
        raise CDPError(f"Failed to insert prompt into DeepSeek composer: {inserted.get('error')}")

    # Wait for send button
    deadline = time.time() + 8.0
    while time.time() < deadline:
        can_send = s.eval("""(() => {
            const btn = document.querySelector("[role='button'].ds-button._52c986b, .ds-button._52c986b.ds-button--circle, div.ds-icon-button._52c986b") ||
                        document.querySelector("button[aria-label='Send'], div[role='button'][aria-label='Send']");
            if (!btn) return false;
            return !btn.disabled && btn.getAttribute('aria-disabled') !== 'true' && !btn.classList.contains('ds-button--disabled');
        })()""")
        if can_send:
            break
        time.sleep(0.15)

    clicked = s.eval("""(() => {
        const btn = document.querySelector("[role='button'].ds-button._52c986b, .ds-button._52c986b.ds-button--circle, div.ds-icon-button._52c986b") ||
                    document.querySelector("button[aria-label='Send'], div[role='button'][aria-label='Send']");
        if (btn) {
            btn.click();
            return true;
        }
        return false;
    })()""")
    if not clicked:
        raise CDPError("Could not click DeepSeek send button")

    # Phase 1: Wait for generation to start
    gen_start = time.time() + 20.0
    while time.time() < gen_start:
        time.sleep(0.25)
        cur = s.eval("""(() => {
            const btn = document.querySelector("[role='button'].ds-button._52c986b, div.ds-icon-button");
            const html = btn ? btn.innerHTML.toLowerCase() : "";
            const aria = btn ? (btn.getAttribute('aria-label') || '').toLowerCase() : "";
            const isGenerating = aria.includes('stop') || html.includes('rect') || html.includes('square');
            const turns = document.querySelectorAll('.ds-markdown').length;
            return { isGenerating, turns };
        })()""")
        if cur.get("isGenerating") or cur.get("turns", 0) > before_turns:
            break

    # Phase 2: Wait for generation to complete
    gen_deadline = time.time() + timeout
    last_seen = ""
    last_thinking = ""
    stable_count = 0

    while time.time() < gen_deadline:
        time.sleep(0.4)
        status = s.eval("""(() => {
            const btn = document.querySelector("[role='button'].ds-button._52c986b, div.ds-icon-button");
            const html = btn ? btn.innerHTML.toLowerCase() : "";
            const aria = btn ? (btn.getAttribute('aria-label') || '').toLowerCase() : "";
            const isGenerating = aria.includes('stop') || html.includes('rect') || html.includes('square');

            const msgs = [...document.querySelectorAll("div.ds-message, [data-virtual-list-item-key]")].filter(m => m.querySelector(".ds-markdown"));
            const lastMsg = msgs.length > 0 ? msgs[msgs.length - 1] : null;
            if (!lastMsg) return { isGenerating, text: "", thinking: "", count: msgs.length };

            const thinkEl = lastMsg.querySelector(".ds-think-content");
            const thinking = thinkEl ? thinkEl.innerText.trim() : "";

            const allMd = [...lastMsg.querySelectorAll(".ds-markdown")];
            const finalMd = allMd.find(md => !md.closest(".ds-think-content"));
            const text = finalMd ? finalMd.innerText.trim() : "";

            const hasAction = !!lastMsg.querySelector(".ds-icon-button");

            return {
                isGenerating,
                text,
                thinking,
                hasAction,
                count: msgs.length
            };
        })()""")

        is_generating = status.get("isGenerating", False)
        text = status.get("text", "")
        thinking = status.get("thinking", "")
        has_action = status.get("hasAction", False)

        if text:
            last_seen = text
        if thinking:
            last_thinking = thinking

        if not is_generating and text and (has_action or not status.get("isGenerating")):
            if text == last_seen:
                stable_count += 1
                if stable_count >= 2:
                    break
            else:
                last_seen = text
                stable_count = 0

    return {
        "text": last_seen,
        "thinking": last_thinking
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="DeepSeek Web CLI adapter over Chrome CDP")
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--think", "--r1", action="store_true", help="Enable DeepThink (R1 Reasoner) mode")
    ap.add_argument("--no-think", action="store_true", help="Disable DeepThink (use chat model)")
    ap.add_argument("--search", action="store_true", help="Enable Web Search mode")
    ap.add_argument("--no-search", action="store_true", help="Disable Web Search mode")
    ap.add_argument("--show-thinking", action="store_true", help="Print the reasoning/thinking process")
    ap.add_argument("--attach", action="append", default=[], help="Attach local files")
    ap.add_argument("--check", action="store_true", help="Check CDP reachability and login state")
    ap.add_argument("--new", action="store_true", help="Start a fresh conversation in DeepSeek")
    ns = ap.parse_args()

    if not sys.stdin.isatty() and not (ns.check or ns.new):
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

        p = ensure_deepseek_page()
        with CDPSocket(p["webSocketDebuggerUrl"]) as s:
            if ns.new:
                start_new_conversation(s)

            think_mode = True if ns.think else (False if ns.no_think else None)
            search_mode = True if ns.search else (False if ns.no_search else None)

            if ns.prompt:
                res = send(s, ns.prompt, ns.attach if ns.attach else None, think=think_mode, search=search_mode)
                if ns.show_thinking and res.get("thinking"):
                    print("--- DeepThink (R1) Reasoning ---")
                    print(res["thinking"])
                    print("--- Answer ---")
                print(res["text"])
                return 0
            else:
                cur_url = s.eval("location.href")
                print(cur_url)
                return 0

    except Exception as exc:
        print(f"deepseek-cdp: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
