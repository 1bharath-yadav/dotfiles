#!/usr/bin/env python3
"""Google Gemini CDP adapter using direct page-socket CDP -- zero focus stealing, zero agent-browser."""
from __future__ import annotations

import argparse
import base64
import json
import os
import sys
import time
import urllib.request
from pathlib import Path

# Add cdp-agents root to sys.path for direct cdp_page import
AGENT_ROOT = Path(__file__).resolve().parent.parent
if str(AGENT_ROOT) not in sys.path:
    sys.path.insert(0, str(AGENT_ROOT))

from cdp_page import CDPSocket, CDPError, pages, open_page, is_headless


COMPOSER_SELECTOR = 'rich-textarea .ql-editor[contenteditable="true"], rich-textarea div[contenteditable="true"]'
SEND_BUTTON_SELECTOR = 'button[aria-label*="Send message" i], button[aria-label*="Send prompt" i], button.send-button'
STOP_BUTTON_SELECTOR = 'button[aria-label*="Stop" i], button.stop-button, [data-test-id="stop-button"]'
ATTACHMENT_TRIGGER_SELECTOR = 'button[aria-label*="Upload" i], button[aria-label*="Add files" i]'
FILE_INPUT_SELECTOR = 'input[type="file"]'


def ensure_gemini_page() -> dict:
    """Finds an existing Gemini tab or opens one if running headless."""
    tabs = pages("gemini.google.com")
    if tabs:
        return tabs[0]
    if is_headless():
        return open_page("https://gemini.google.com/app")
    raise CDPError("No Gemini tab found (host: gemini.google.com). Open https://gemini.google.com in Chrome or run headless.")


def check() -> bool:
    """Verifies that Gemini is reachable, logged in, and composer is ready."""
    p = ensure_gemini_page()
    with CDPSocket(p["webSocketDebuggerUrl"]) as s:
        status = s.eval(f"""(() => {{
            const composer = document.querySelector('{COMPOSER_SELECTOR}');
            const login = document.querySelector('a[href*="/signin"], a[href*="/auth"], button:has-text("Sign in")');
            return {{
                composer: !!composer,
                loginNeeded: !!login,
                title: document.title,
                url: location.href
            }};
        }})()""")
        if status.get("loginNeeded"):
            raise CDPError("Gemini requires login")
        if not status.get("composer"):
            raise CDPError(f"Gemini composer not found on {status.get('url')} (title: {status.get('title')})")
    return True


def select_gem_or_notebook(s: CDPSocket, name: str, timeout: float = 10.0) -> str:
    """Selects a Gem or Notebook by visible name."""
    want = name.strip().lower()
    res = s.eval(f"""(() => {{
        const expandBtn = document.querySelector('button[aria-label*="Expand sidebar" i], button[aria-label*="Main menu" i]');
        if (expandBtn) expandBtn.click();

        const links = [...document.querySelectorAll('a[href*="/gem/"], a[href*="/notebook/"], a[href*="/gems/"]')];
        for (const a of links) {{
            const text = (a.textContent || '').trim().toLowerCase();
            const aria = (a.getAttribute('aria-label') || '').toLowerCase();
            if (text === {json.dumps(want)} || text.includes({json.dumps(want)}) || aria.includes({json.dumps(want)})) {{
                a.click();
                return {{ ok: true, href: a.href, text }};
            }}
        }}
        const available = links.map(a => a.textContent?.trim()).filter(Boolean);
        return {{ ok: false, available }};
    }})()""")

    if res.get("ok"):
        time.sleep(1.0)
        return s.eval("location.href")

    avail = ", ".join(res.get("available", [])) or "none"
    raise CDPError(f"Gemini Gem/Notebook '{name}' not found. Available: {avail}")


def start_new_conversation(s: CDPSocket) -> None:
    """Navigates to a fresh Gemini conversation."""
    clicked = s.eval("""(() => {
        const newChat = document.querySelector('a[href="/app"], a[aria-label*="New chat" i], button[aria-label*="New chat" i]');
        if (newChat) {
            newChat.click();
            return true;
        }
        return false;
    })()""")
    if not clicked:
        s.navigate("https://gemini.google.com/app")

    deadline = time.time() + 10.0
    while time.time() < deadline:
        time.sleep(0.25)
        if s.eval(f"!!document.querySelector('{COMPOSER_SELECTOR}')"):
            return


def attach(s: CDPSocket, paths: list[str], timeout: float = 15.0) -> None:
    """Uploads local files through Gemini's file input using CDP DOM.setFileInputFiles."""
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


def send(s: CDPSocket, prompt: str, attachments: list[str] | None = None, timeout: float = 120.0) -> str:
    """Sends a prompt (with optional attachments) and returns completed model response."""
    if attachments:
        attach(s, attachments)
        time.sleep(1.0)

    before_turns = s.eval("document.querySelectorAll('model-response, gmp-model-response').length") or 0

    # Insert prompt into rich-textarea
    inserted = s.eval(f"""(() => {{
        const editor = document.querySelector('{COMPOSER_SELECTOR}');
        if (!editor) return {{ ok: false, error: "Composer not found" }};
        editor.focus();
        document.execCommand('selectAll', false, null);
        document.execCommand('delete', false, null);
        const ok = document.execCommand('insertText', false, {json.dumps(prompt)});
        if (!ok || !editor.textContent?.includes({json.dumps(prompt[:10])})) {{
            editor.innerHTML = '';
            const p = document.createElement('p');
            p.textContent = {json.dumps(prompt)};
            editor.appendChild(p);
        }}
        editor.dispatchEvent(new Event('input', {{ bubbles: true, composed: true }}));
        editor.dispatchEvent(new Event('change', {{ bubbles: true, composed: true }}));
        return {{ ok: true }};
    }})()""")
    if not inserted.get("ok"):
        raise CDPError(f"Failed to insert prompt into Gemini composer: {inserted.get('error')}")

    # Wait for send button
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
        raise CDPError("Could not click Gemini send button (button not present or remains disabled)")

    # Phase 1: Wait for generation to start
    gen_start = time.time() + 25.0
    while time.time() < gen_start:
        time.sleep(0.25)
        cur = s.eval(f"""(() => {{
            const stop = document.querySelector('{STOP_BUTTON_SELECTOR}');
            const turns = document.querySelectorAll('model-response, gmp-model-response').length;
            return {{ isStreaming: !!stop, turns }};
        }})()""")
        if cur.get("isStreaming") or cur.get("turns", 0) > before_turns:
            break

    # Phase 2: Wait for generation to complete
    gen_deadline = time.time() + timeout
    last_seen = ""
    stable_count = 0

    while time.time() < gen_deadline:
        time.sleep(0.4)
        status = s.eval(f"""(() => {{
            const stop = document.querySelector('{STOP_BUTTON_SELECTOR}');
            const isStreaming = !!(stop && stop.getAttribute('aria-hidden') !== 'true');
            const msgs = document.querySelectorAll('model-response, gmp-model-response');
            const last = msgs.length > 0 ? msgs[msgs.length - 1] : null;
            if (!last) return {{ isStreaming, count: msgs.length, text: "" }};
            const prose = last.querySelector('message-content, .model-response-text, .markdown') || last;
            return {{
                isStreaming,
                count: msgs.length,
                text: prose.innerText.trim()
            }};
        }})()""")

        is_streaming = status.get("isStreaming", False)
        count = status.get("count", 0)
        text = status.get("text", "")

        if count > before_turns and text and not is_streaming:
            if text == last_seen:
                stable_count += 1
                if stable_count >= 2:
                    return text
            else:
                last_seen = text
                stable_count = 0
        else:
            if text:
                last_seen = text
                stable_count = 0

    if last_seen:
        return last_seen
    raise CDPError(f"Timed out after {timeout}s waiting for Gemini response")


def play_listen_tts(s: CDPSocket, timeout: float = 12.0) -> bool:
    """Clicks Gemini's native 'Listen' (TTS) button on the latest response."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        res = s.eval("""(() => {
            const responses = document.querySelectorAll('model-response, gmp-model-response');
            if (responses.length === 0) return { ok: false, error: "No response" };
            const last = responses[responses.length - 1];

            // Direct button
            const direct = last.querySelector('button[aria-label*="Listen" i], [data-test-id="listen-button"]');
            if (direct) {
                direct.click();
                return { ok: true, method: "direct" };
            }

            // More actions overflow
            const more = last.querySelector('button[aria-label*="More" i], button[data-test-id="more-options"]');
            if (more) {
                more.click();
                return { ok: true, method: "more_clicked" };
            }
            return { ok: false };
        })()""")

        if res.get("ok"):
            if res.get("method") == "direct":
                return True
            if res.get("method") == "more_clicked":
                time.sleep(0.3)
                clicked = s.eval("""(() => {
                    const item = [...document.querySelectorAll('[role="menuitem"]')].find(m =>
                        (m.innerText || '').toLowerCase().includes('listen') ||
                        (m.getAttribute('aria-label') || '').toLowerCase().includes('listen')
                    );
                    if (item) {
                        item.click();
                        return true;
                    }
                    return false;
                })()""")
                if clicked:
                    return True
        time.sleep(0.5)
    raise CDPError("Timed out waiting to find and click Gemini Listen button")


def generate_image(s: CDPSocket, prompt: str, output_path: str = "image.png", timeout: float = 120.0) -> dict:
    """Generates an image via Imagen 3 on Gemini and downloads it to output_path."""
    clean_prompt = prompt.strip()
    trigger_words = ["generate", "draw", "create an image", "image of", "picture of", "illustration of"]
    if not any(w in clean_prompt.lower() for w in trigger_words):
        full_prompt = f"Generate an image of: {clean_prompt}"
    else:
        full_prompt = clean_prompt

    get_imgs_code = """(() => {
        const imgs = [...document.querySelectorAll('model-response img, generated-image img')].filter(img => {
            const src = img.currentSrc || img.src || '';
            const alt = (img.alt || '').toLowerCase();
            if (!src || src.startsWith('data:image/svg') || src.includes('avatar') || src.includes('profile')) return false;
            return src.includes('googleusercontent.com') || src.includes('generativecontent') || alt.includes('generated') || (img.naturalWidth > 200 && img.naturalHeight > 200);
        });
        return imgs.map(img => ({
            src: img.currentSrc || img.src,
            alt: img.alt || '',
            width: img.naturalWidth || img.width,
            height: img.naturalHeight || img.height
        }));
    })()"""

    before_imgs = s.eval(get_imgs_code) or []
    before_srcs = {i["src"] for i in before_imgs if isinstance(i, dict) and i.get("src")}

    # Submit image generation prompt
    send(s, full_prompt)

    # Wait for image to render
    gen_deadline = time.time() + timeout
    target_img = None

    while time.time() < gen_deadline:
        time.sleep(0.5)
        current_imgs = s.eval(get_imgs_code) or []
        new_imgs = [i for i in current_imgs if i.get("src") and i["src"] not in before_srcs]
        if new_imgs:
            target_img = new_imgs[-1]
            break
        elif not before_srcs and current_imgs:
            target_img = current_imgs[-1]
            break

    if not target_img or not target_img.get("src"):
        raise CDPError(f"No generated image found in Gemini response after {timeout}s")

    img_src = target_img["src"]
    out_file = Path(output_path).expanduser().resolve()
    out_file.parent.mkdir(parents=True, exist_ok=True)

    # In-browser authenticated fetch
    fetch_result = s.eval(f"""(async () => {{
        const url = {json.dumps(img_src)};
        try {{
            const resp = await fetch(url, {{ credentials: 'include' }});
            if (!resp.ok) return {{ error: `Fetch HTTP ${{resp.status}}` }};
            const blob = await resp.blob();
            return await new Promise((resolve) => {{
                const reader = new FileReader();
                reader.onloadend = () => resolve({{
                    dataUrl: reader.result,
                    mimeType: blob.type,
                    size: blob.size
                }});
                reader.onerror = () => resolve({{ error: "FileReader failed" }});
                reader.readAsDataURL(blob);
            }});
        }} catch (err) {{
            return {{ error: err.message }};
        }}
    }})()""", await_promise=True)

    saved = False
    file_size = 0
    mime_type = ""

    if isinstance(fetch_result, dict) and fetch_result.get("dataUrl"):
        data_url = fetch_result["dataUrl"]
        mime_type = fetch_result.get("mimeType", "")
        header, b64 = data_url.split(",", 1)
        raw_bytes = base64.b64decode(b64)
        out_file.write_bytes(raw_bytes)
        file_size = len(raw_bytes)
        saved = True
    elif img_src.startswith("http://") or img_src.startswith("https://"):
        req = urllib.request.Request(img_src, headers={"User-Agent": "Mozilla/5.0"})
        with urllib.request.urlopen(req, timeout=30) as resp:
            raw_bytes = resp.read()
            out_file.write_bytes(raw_bytes)
            file_size = len(raw_bytes)
            mime_type = resp.headers.get_content_type()
            saved = True

    if not saved:
        raise CDPError(f"Failed to download Gemini generated image from {img_src}: {fetch_result}")

    return {
        "path": str(out_file),
        "size": file_size,
        "mime_type": mime_type,
        "alt": target_img.get("alt", "")
    }


def main() -> int:
    ap = argparse.ArgumentParser(description="Google Gemini CLI adapter over Chrome CDP")
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--gem", help="Select Gem or Notebook container by name")
    ap.add_argument("--attach", action="append", default=[], help="Attach local files")
    ap.add_argument("--check", action="store_true", help="Check CDP reachability and login state")
    ap.add_argument("--new", action="store_true", help="Start a fresh conversation in Gemini (/app)")
    ap.add_argument("--tts", nargs="?", const="", help="Listen to Gemini response via native TTS")
    ap.add_argument("--imgen", nargs="?", const="", help="Generate image via Imagen 3 and download to file")
    ap.add_argument("-o", "--output", help="Output file path for generated image (default: image.png)")
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

        p = ensure_gemini_page()
        with CDPSocket(p["webSocketDebuggerUrl"]) as s:
            if ns.gem:
                select_gem_or_notebook(s, ns.gem)

            if ns.new:
                start_new_conversation(s)

            if ns.imgen is not None:
                img_prompt = ns.imgen if ns.imgen != "" else ns.prompt
                if not img_prompt:
                    ap.error("--imgen requires an image prompt")
                out_path = ns.output or "image.png"
                res = generate_image(s, img_prompt, out_path)
                print(f"Downloaded image ({res['size']} bytes, {res['mime_type']}) -> {res['path']}")
                return 0

            if ns.tts is not None:
                tts_text = ns.tts if ns.tts != "" else ns.prompt
                if not tts_text:
                    ap.error("--tts requires text to read")
                response = send(s, tts_text)
                play_listen_tts(s)
                print(response)
                return 0

            if ns.prompt:
                response = send(s, ns.prompt, ns.attach if ns.attach else None)
                print(response)
                return 0
            else:
                cur_url = s.eval("location.href")
                print(cur_url)
                return 0

    except Exception as exc:
        print(f"gemini-cdp: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
