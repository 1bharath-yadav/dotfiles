#!/usr/bin/env python3
"""Z.ai (chat.z.ai) GLM Web CLI adapter using direct page-socket CDP -- zero focus stealing, zero agent-browser."""
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


COMPOSER_SELECTOR = "#chat-input"
SEND_BUTTON_SELECTOR = "button#send-message-button"
STOP_BUTTON_SELECTOR = ".messageInputContainer div.relative.size-7 button, .messageInputContainer button:has(span.rounded-xs)"
FILE_INPUT_SELECTOR = ".messageInputContainer input[type='file'], input[type='file']"


def ensure_zai_page() -> dict:
    """Finds an existing Z.ai tab or opens one if running headless."""
    tabs = pages("z.ai", "chat.z.ai")
    if tabs:
        return tabs[0]
    if is_headless():
        return open_page("https://chat.z.ai/")
    raise CDPError("No Z.ai tab found (host: chat.z.ai / z.ai). Open https://chat.z.ai in Chrome or run headless.")


def check() -> bool:
    """Verifies that Z.ai is reachable, logged in, and composer is ready."""
    p = ensure_zai_page()
    with CDPSocket(p["webSocketDebuggerUrl"]) as s:
        status = s.eval(f"""(() => {{
            const composer = document.querySelector("{COMPOSER_SELECTOR}");
            const login = document.querySelector('button:has-text("Sign in"), button:has-text("Log in"), a[href*="/login"]');
            return {{
                composer: !!composer,
                loginNeeded: !!login,
                title: document.title,
                url: location.href
            }};
        }})()""")
        if status.get("loginNeeded"):
            raise CDPError("Z.ai requires login")
        if not status.get("composer"):
            raise CDPError(f"Z.ai composer not found on {status.get('url')} (title: {status.get('title')})")
    return True


def start_new_conversation(s: CDPSocket) -> None:
    """Starts a fresh conversation in Z.ai."""
    clicked = s.eval("""(() => {
        const btn = document.getElementById("new-chat-button") ||
                    document.querySelector('button.navNewChat, button[aria-label="New Chat"]');
        if (btn) {
            btn.click();
            return true;
        }
        window.dispatchEvent(new CustomEvent("switchNewChat"));
        return true;
    })()""")
    if not clicked:
        s.navigate("https://chat.z.ai/")

    deadline = time.time() + 10.0
    while time.time() < deadline:
        time.sleep(0.25)
        if s.eval(f"!!document.querySelector('{COMPOSER_SELECTOR}')"):
            return


def set_deep_think(s: CDPSocket, enable: bool) -> bool:
    """Toggles Deep Think mode in Z.ai."""
    return s.eval(f"""(() => {{
        const btn = document.querySelector('.messageInputContainer button[data-autothink]');
        if (!btn) return false;
        const isEnabled = btn.getAttribute('data-autothink') === 'true';
        if (isEnabled !== {json.dumps(enable)}) {{
            btn.click();
        }}
        return true;
    }})()""")


def set_search(s: CDPSocket, enable: bool) -> bool:
    """Toggles Web Search mode in Z.ai."""
    return s.eval(f"""(() => {{
        const btn = document.querySelector('.messageInputContainer button[data-selected]:not([data-autothink])');
        if (!btn) return false;
        const isEnabled = btn.getAttribute('data-selected') === 'true';
        if (isEnabled !== {json.dumps(enable)}) {{
            btn.click();
        }}
        return true;
    }})()""")


def attach(s: CDPSocket, paths: list[str], timeout: float = 15.0) -> None:
    """Uploads local files through Z.ai's file input using CDP DOM.setFileInputFiles."""
    abs_paths = [str(Path(p).expanduser().resolve()) for p in paths]
    for p in abs_paths:
        if not os.path.isfile(p):
            raise FileNotFoundError(f"Attachment file not found: {p}")

    s.set_input_files(FILE_INPUT_SELECTOR, abs_paths)


def send(s: CDPSocket, prompt: str, attachments: list[str] | None = None, timeout: float = 120.0, think: bool | None = None, search: bool | None = None) -> dict:
    """Sends a prompt to Z.ai, waits for generation to finish, and returns response and reasoning."""
    if think is not None:
        set_deep_think(s, think)
        time.sleep(0.2)
    if search is not None:
        set_search(s, search)
        time.sleep(0.2)

    if attachments:
        attach(s, attachments)
        time.sleep(1.0)

    before_turns = s.eval("document.querySelectorAll('#messages-container .chat-assistant').length") or 0

    # Insert text into composer
    inserted = s.eval(f"""(() => {{
        const input = document.getElementById("chat-input");
        if (!input) return {{ ok: false, error: "Composer not found" }};
        input.value = {json.dumps(prompt)};
        input.dispatchEvent(new Event("input", {{ bubbles: true }}));
        input.style.height = "auto";
        input.style.height = Math.min(input.scrollHeight, 160) + "px";
        return {{ ok: true }};
    }})()""")
    if not inserted.get("ok"):
        raise CDPError(f"Failed to insert prompt into Z.ai composer: {inserted.get('error')}")

    # Wait for send button
    deadline = time.time() + 8.0
    while time.time() < deadline:
        can_send = s.eval(f"""(() => {{
            const btn = document.querySelector('{SEND_BUTTON_SELECTOR}');
            return btn && !btn.disabled && !btn.classList.contains('disabled');
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
        raise CDPError("Could not click Z.ai send button (button not present or disabled)")

    # Phase 1: Wait for generation to start
    gen_start = time.time() + 20.0
    while time.time() < gen_start:
        time.sleep(0.25)
        cur = s.eval(f"""(() => {{
            const stop = document.querySelector('{STOP_BUTTON_SELECTOR}');
            const turns = document.querySelectorAll('#messages-container .chat-assistant').length;
            return {{ isGenerating: !!stop, turns }};
        }})()""")
        if cur.get("isGenerating") or cur.get("turns", 0) > before_turns:
            break

    # Phase 2: Wait for generation to complete
    gen_deadline = time.time() + timeout
    last_seen = ""
    last_thinking = ""
    stable_count = 0

    while time.time() < gen_deadline:
        time.sleep(0.4)
        status = s.eval(f"""(() => {{
            const stop = document.querySelector('{STOP_BUTTON_SELECTOR}');
            const isGenerating = !!stop;
            const msgs = document.querySelectorAll('#messages-container .chat-assistant');
            const lastMsg = msgs.length > 0 ? msgs[msgs.length - 1] : null;
            if (!lastMsg) return {{ isGenerating, text: "", thinking: "", count: msgs.length }};

            const thinkEl = lastMsg.querySelector('.thinking-block, details');
            const thinking = thinkEl ? thinkEl.innerText.trim() : "";

            const clone = lastMsg.cloneNode(true);
            clone.querySelectorAll('.thinking-block, details').forEach(el => el.remove());
            const text = clone.innerText.trim();

            const hasCopy = !!lastMsg.querySelector('.copy-response-button');

            return {{
                isGenerating,
                text,
                thinking,
                hasCopy,
                count: msgs.length
            }};
        }})()""")

        is_generating = status.get("isGenerating", False)
        text = status.get("text", "")
        thinking = status.get("thinking", "")
        has_copy = status.get("hasCopy", False)

        if text:
            last_seen = text
        if thinking:
            last_thinking = thinking

        if not is_generating and text and (has_copy or not is_generating):
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
    ap = argparse.ArgumentParser(description="Z.ai (chat.z.ai) GLM Web CLI adapter over Chrome CDP")
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--think", action="store_true", help="Enable Deep Think mode")
    ap.add_argument("--no-think", action="store_true", help="Disable Deep Think mode")
    ap.add_argument("--search", action="store_true", help="Enable Web Search mode")
    ap.add_argument("--no-search", action="store_true", help="Disable Web Search mode")
    ap.add_argument("--show-thinking", action="store_true", help="Print the reasoning/thinking process")
    ap.add_argument("--attach", action="append", default=[], help="Attach local files")
    ap.add_argument("--check", action="store_true", help="Check CDP reachability and login state")
    ap.add_argument("--new", action="store_true", help="Start a fresh conversation in Z.ai")
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

        p = ensure_zai_page()
        with CDPSocket(p["webSocketDebuggerUrl"]) as s:
            if ns.new:
                start_new_conversation(s)

            think_mode = True if ns.think else (False if ns.no_think else None)
            search_mode = True if ns.search else (False if ns.no_search else None)

            if ns.prompt:
                res = send(s, ns.prompt, ns.attach if ns.attach else None, think=think_mode, search=search_mode)
                if ns.show_thinking and res.get("thinking"):
                    print("--- Z.ai Thought Process ---")
                    print(res["thinking"])
                    print("--- Answer ---")
                print(res["text"])
                return 0
            else:
                cur_url = s.eval("location.href")
                print(cur_url)
                return 0

    except Exception as exc:
        print(f"zai-cdp: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
