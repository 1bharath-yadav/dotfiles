#!/usr/bin/env python3
"""ChatGPT web adapter over an existing authenticated Chrome CDP session."""
from __future__ import annotations

import argparse
import json
import os
import subprocess
import sys
import time
from pathlib import Path

# Use the shared cdp_page module
sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
from cdp_page import CDPSocket, CDPError, pages, http_json, version, is_headless

VOICE_START_SELECTORS = (
    'button[aria-label="Start Voice"]',
    'button[data-testid="voice-mode-button"]',
)
VOICE_STOP_SELECTORS = (
    'button[aria-label="End Voice" i]',
    'button[aria-label="Close voice mode"]',
    'button[aria-label="Exit voice"]',
    'button[data-testid="close-voice-mode"]',
)

COMPOSER_SELECTOR = '#prompt-textarea'
FILE_INPUT_SELECTOR = '#upload-files, input[type="file"]'

ROUTING_FILE = Path.home() / ".config/xoy/routing.json"
DOTFILES_ROUTING_FILE = Path.home() / ".dotfiles/dot_config/xoy/routing.json"


# ── Routing & Cache Configuration ──────────────────────────────────────────
def load_routing_config() -> dict:
    """Loads routing configuration and cached project URLs."""
    if ROUTING_FILE.exists():
        try:
            return json.loads(ROUTING_FILE.read_text(encoding="utf-8"))
        except Exception:
            pass
    return {
        "defaults": {
            "livemode": {"project": "assistant", "fallback_project": "tmp", "max_turns": 50},
            "tts": {"project": "tts-stt", "fallback_project": "tmp", "max_turns": 25},
            "stt": {"project": "tts-stt", "use_scratch_composer": True},
            "imgen": {"project": "images", "fallback_project": "tmp", "max_turns": 20},
            "adhoc": {"default_project": "tmp"}
        },
        "cached_urls": {
            "tmp": "https://chatgpt.com/g/g-p-6a6db113e49c819181613beaa56855f8-tmp/project"
        }
    }


def save_routing_config(cfg: dict) -> None:
    """Saves routing configuration both locally and in dotfiles repo."""
    try:
        ROUTING_FILE.parent.mkdir(parents=True, exist_ok=True)
        content = json.dumps(cfg, indent=2) + "\n"
        ROUTING_FILE.write_text(content, encoding="utf-8")
        if DOTFILES_ROUTING_FILE.parent.exists():
            DOTFILES_ROUTING_FILE.write_text(content, encoding="utf-8")
    except Exception:
        pass


def resolve_project_name(requested: str | None, role: str = "adhoc") -> str:
    """Determines target project name based on explicit request or role defaults."""
    if requested:
        return requested.strip()
    cfg = load_routing_config()
    defaults = cfg.get("defaults", {})
    if role in defaults:
        return defaults[role].get("project", "tmp")
    return defaults.get("adhoc", {}).get("default_project", "tmp")


# ── Dual-Tab Role Engine ───────────────────────────────────────────────────
def ensure_chatgpt_pages(timeout: float = 15.0) -> list[dict]:
    """Finds all existing ChatGPT page targets, navigating idle tabs or opening if needed."""
    ps = pages("chatgpt.com")
    if ps:
        return ps

    # In headless or headed, navigate idle tab or create target
    all_pages = [t for t in http_json("/json/list") if t.get("type") == "page" and t.get("webSocketDebuggerUrl")]
    idle = [t for t in all_pages if "newtab" in t.get("url", "") or t.get("url") in ("about:blank", "")]
    if idle:
        with CDPSocket(idle[0]["webSocketDebuggerUrl"]) as s:
            s.navigate("https://chatgpt.com/")
    else:
        with CDPSocket(version()["webSocketDebuggerUrl"]) as b:
            b.call("Target.createTarget", {"url": "https://chatgpt.com/"})

    deadline = time.time() + timeout
    while time.time() < deadline:
        time.sleep(0.5)
        ps = pages("chatgpt.com")
        if ps:
            return ps
    raise CDPError("No ChatGPT tab found in Chrome CDP session and could not open one")


def get_role_page(role: str = "tools") -> dict:
    """Resolves page target using the Dual-Tab concurrency model.
    - 'voice': Targets Tab 1 (dedicated to persistent Live Voice session).
    - 'tools': Targets Tab 2 (dedicated to TTS, STT, and ad-hoc commands).
      If only 1 tab exists, opens Tab 2 so voice is never interrupted.
    """
    chat_tabs = ensure_chatgpt_pages()

    if len(chat_tabs) == 1 and role != "voice":
        try:
            with CDPSocket(version()["webSocketDebuggerUrl"]) as b:
                b.call("Target.createTarget", {"url": "https://chatgpt.com/"})
            time.sleep(1.0)
            chat_tabs = pages("chatgpt.com")
        except Exception:
            pass

    if len(chat_tabs) > 1:
        if role == "voice":
            return chat_tabs[0]
        else:
            return chat_tabs[1]

    return chat_tabs[0]


def check() -> bool:
    """Verifies that ChatGPT is reachable, logged in, and composer is ready."""
    p = get_role_page("tools")
    with CDPSocket(p["webSocketDebuggerUrl"]) as s:
        status = s.eval(f"""(() => {{
            const composer = document.querySelector('{COMPOSER_SELECTOR}');
            const login = document.querySelector('button[data-testid="login-button"], a[href*="/auth/login"]');
            return {{
                composer: !!composer,
                loginNeeded: !!login,
                title: document.title
            }};
        }})()""")
        if status.get("loginNeeded"):
            raise CDPError("ChatGPT requires login")
        if not status.get("composer"):
            raise CDPError(f"ChatGPT composer not found (page title: {status.get('title')})")
    return True


# ── Project Discovery & Navigation ─────────────────────────────────────────
def list_projects(s: CDPSocket) -> list[dict]:
    """Lists all projects discovered in the ChatGPT sidebar."""
    s.eval("""(() => {
        const openBtn = document.querySelector('button[aria-label="Open sidebar"]');
        if (openBtn) openBtn.click();
    })()""")
    time.sleep(0.3)

    return s.eval("""(() => {
        const btns = [...document.querySelectorAll('button[aria-label="Open project home"]')];
        return btns.map(b => {
            const row = b.closest('li') || b.parentElement;
            const raw = row ? row.innerText.trim() : '';
            const firstLine = raw.split(/\\r?\\n/)[0];
            return {
                name: firstLine,
                hasHomeBtn: true
            };
        }).filter(x => x.name);
    })()""")


def select_project(s: CDPSocket, name: str, timeout: float = 12.0) -> str:
    """Navigates to the specified project by name with cache acceleration and fallback."""
    cfg = load_routing_config()
    cached_urls = cfg.get("cached_urls", {})
    target_name = name.strip()
    target_lower = target_name.lower()

    # Fast path: use cached project URL if available
    cached_url = cached_urls.get(target_lower)
    cur_url = s.eval("location.href")

    if cached_url:
        if cur_url == cached_url or (f"-{target_lower}/" in cur_url.lower()):
            return cur_url
        s.navigate(cached_url)
        deadline = time.time() + timeout
        while time.time() < deadline:
            time.sleep(0.25)
            if s.eval(f"!!document.querySelector('{COMPOSER_SELECTOR}')"):
                return cached_url
        return s.eval("location.href")

    # Check if already in this project by name
    if f"-{target_lower}/" in cur_url.lower() or f"/{target_lower}/" in cur_url.lower():
        return cur_url

    # Ensure sidebar is open
    s.eval("""(() => {
        const openBtn = document.querySelector('button[aria-label="Open sidebar"]');
        if (openBtn) openBtn.click();
    })()""")
    time.sleep(0.3)

    found = s.eval(f"""(() => {{
        const want = {json.dumps(target_lower)};
        const btns = [...document.querySelectorAll('button[aria-label="Open project home"]')];
        for (const b of btns) {{
            const row = b.closest('li') || b.parentElement;
            const raw = row ? row.innerText.trim() : '';
            const txt = raw.split(/\\r?\\n/)[0].toLowerCase();
            if (txt === want || txt.includes(want)) {{
                b.click();
                return {{ ok: true, matched: txt }};
            }}
        }}
        const available = btns.map(b => {{
            const row = b.closest('li') || b.parentElement;
            return (row ? row.innerText.trim() : '').split(/\\r?\\n/)[0];
        }}).filter(Boolean);
        return {{ ok: false, available }};
    }})()""")

    if found.get("ok"):
        deadline = time.time() + timeout
        while time.time() < deadline:
            time.sleep(0.3)
            new_url = s.eval("location.href")
            composer_ready = s.eval(f"!!document.querySelector('{COMPOSER_SELECTOR}')")
            if composer_ready and new_url != cur_url:
                cached_urls[target_lower] = new_url.split("/c/")[0]
                cfg["cached_urls"] = cached_urls
                save_routing_config(cfg)
                return new_url
        return s.eval("location.href")

    # Project not found in sidebar: check fallback
    available = found.get("available", [])
    defaults = cfg.get("defaults", {})
    fallback = None
    for role_cfg in defaults.values():
        if isinstance(role_cfg, dict) and role_cfg.get("project") == target_name:
            fallback = role_cfg.get("fallback_project")
            break

    if fallback and fallback != target_name and any(fallback.lower() in x.lower() for x in available):
        print(f"[note] Project '{target_name}' not found. Falling back to '{fallback}'. "
              f"(Create '{target_name}' in ChatGPT to isolate).", file=sys.stderr)
        return select_project(s, fallback, timeout=timeout)

    avail_str = ', '.join(available) if available else 'none'
    raise CDPError(f"ChatGPT project '{name}' not found. Available: {avail_str}")


def start_new_conversation(s: CDPSocket, project_name: str | None = None, timeout: float = 10.0) -> None:
    """Starts a brand new conversation with 0 turns in the target project or root."""
    cfg = load_routing_config()
    cached_urls = cfg.get("cached_urls", {})

    if project_name:
        target_lower = project_name.strip().lower()
        if target_lower in cached_urls:
            s.navigate(cached_urls[target_lower])
        else:
            select_project(s, project_name)
            # Click project home button to exit thread
            s.eval("""(() => {
                const projectBtn = document.querySelector('button[aria-label="Open project home"]');
                if (projectBtn) projectBtn.click();
            })()""")
    else:
        clicked = s.eval("""(() => {
            const newChat = document.querySelector('a[aria-label="New chat"], a[href="/"]');
            if (newChat) {
                newChat.click();
                return true;
            }
            return false;
        })()""")
        if not clicked:
            s.navigate("https://chatgpt.com/")

    # Wait for composer to be ready and clear of any stop button
    deadline = time.time() + timeout
    while time.time() < deadline:
        time.sleep(0.25)
        status = s.eval(f"""(() => {{
            const composer = document.querySelector('{COMPOSER_SELECTOR}');
            const stop = document.querySelector('button[data-testid="stop-button"], button[aria-label*="Stop" i]');
            return {{
                ready: !!composer,
                isStop: !!stop
            }};
        }})()""")
        if status.get("ready") and not status.get("isStop"):
            return


# ── Attachments & Prompt Submission ────────────────────────────────────────
def attach(s: CDPSocket, paths: list[str], timeout: float = 15.0) -> None:
    """Attaches files to the composer via CDP DOM.setFileInputFiles."""
    abs_paths = [str(Path(p).expanduser().resolve()) for p in paths]
    for p in abs_paths:
        if not os.path.isfile(p):
            raise FileNotFoundError(f"Attachment file not found: {p}")

    s.set_input_files(FILE_INPUT_SELECTOR, abs_paths)

    deadline = time.time() + timeout
    while time.time() < deadline:
        time.sleep(0.3)
        chips = s.eval("""(() => {
            return document.querySelectorAll('[data-testid^="attachment-"], button[aria-label*="Remove file"]').length;
        })()""")
        if chips >= len(abs_paths):
            return
    has_files = s.eval(f"""(() => {{
        const el = document.querySelector('{FILE_INPUT_SELECTOR}');
        return !!(el && el.files && el.files.length >= {len(abs_paths)});
    }})()""")
    if not has_files:
        raise CDPError(f"Attachment upload timed out for: {paths}")


def _submit_prompt(s: CDPSocket, prompt: str) -> None:
    """Inserts prompt text into the composer and clicks the send button."""
    # If composer has a stuck stop button from an interrupted generation, dismiss it
    stuck = s.eval("""(() => {
        const stop = document.querySelector('button[data-testid="stop-button"], button[aria-label*="Stop" i]');
        if (stop) {
            stop.click();
            return true;
        }
        return false;
    })()""")
    if stuck:
        time.sleep(0.5)

    entered = s.eval(f"""(() => {{
        const el = document.querySelector('{COMPOSER_SELECTOR}');
        if (!el) return {{ error: "Composer element not found" }};
        el.focus();
        document.execCommand('selectAll', false, null);
        document.execCommand('delete', false, null);
        document.execCommand('insertText', false, {json.dumps(prompt)});
        el.dispatchEvent(new Event('input', {{ bubbles: true }}));
        const sendBtn = document.querySelector('button[data-testid="send-button"]') ||
                        document.querySelector('button[aria-label="Send prompt"]');
        return {{
            ok: true,
            hasSend: !!sendBtn,
            disabled: sendBtn ? sendBtn.disabled : true
        }};
    }})()""")
    if not entered.get("ok"):
        raise CDPError(f"Failed to enter prompt into composer: {entered.get('error')}")

    # Wait for send button to appear and become enabled
    deadline = time.time() + 8.0
    while time.time() < deadline:
        btn_state = s.eval("""(() => {
            const sendBtn = document.querySelector('button[data-testid="send-button"]') ||
                            document.querySelector('button[aria-label="Send prompt"]');
            return {
                exists: !!sendBtn,
                disabled: sendBtn ? sendBtn.disabled : true
            };
        })()""")
        if btn_state.get("exists") and not btn_state.get("disabled"):
            break
        time.sleep(0.15)

    # Click send button
    clicked = s.eval("""(() => {
        const sendBtn = document.querySelector('button[data-testid="send-button"]') ||
                        document.querySelector('button[aria-label="Send prompt"]');
        if (!sendBtn || sendBtn.disabled) return false;
        sendBtn.click();
        return true;
    })()""")
    if not clicked:
        raise CDPError("Could not click send button (button not present or remains disabled)")


def send(s: CDPSocket, prompt: str, attachments: list[str] | None = None, timeout: float = 90.0) -> str:
    """Sends a prompt (with optional attachments) and returns the completed assistant response."""
    if attachments:
        attach(s, attachments)
        time.sleep(0.8)

    # Initial state
    init_state = s.eval("""(() => {
        const msgs = document.querySelectorAll('[data-message-author-role="assistant"]');
        return {
            count: msgs.length,
            lastText: msgs.length > 0 ? msgs[msgs.length - 1].innerText.trim() : ""
        };
    })()""")
    before_count = init_state.get("count", 0)

    # Submit prompt
    _submit_prompt(s, prompt)

    # Phase 1: Wait for response streaming/generation to begin
    gen_start_deadline = time.time() + 20.0
    while time.time() < gen_start_deadline:
        time.sleep(0.25)
        cur = s.eval("""(() => {
            const stop = document.querySelector('button[data-testid="stop-button"], button[aria-label*="Stop" i]');
            const msgs = document.querySelectorAll('[data-message-author-role="assistant"]');
            return {
                generating: !!stop,
                count: msgs.length
            };
        })()""")
        if cur.get("generating") or cur.get("count", 0) > before_count:
            break

    # Phase 2: Wait for generation to finish
    gen_deadline = time.time() + timeout
    last_seen = ""
    stable_count = 0

    while time.time() < gen_deadline:
        time.sleep(0.4)
        state = s.eval("""(() => {
            const stop = document.querySelector('button[data-testid="stop-button"], button[aria-label*="Stop" i]');
            const msgs = document.querySelectorAll('[data-message-author-role="assistant"]');
            const last = msgs.length > 0 ? msgs[msgs.length - 1] : null;
            if (!last) return { generating: !!stop, count: msgs.length, text: "" };
            const prose = last.querySelector('.markdown, .ProseMirror, [class*="prose"]') || last;
            return {
                generating: !!stop,
                count: msgs.length,
                text: prose ? prose.innerText.trim() : ""
            };
        })()""")
        generating = state.get("generating", False)
        count = state.get("count", 0)
        text = state.get("text", "")

        if count > before_count and text and not generating:
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
    raise CDPError(f"Timed out after {timeout}s waiting for ChatGPT response")


# ── TTS (Text to Speech) ───────────────────────────────────────────────────
def build_tts_prompt(text: str) -> str:
    """Builds the educator-narrator prompt template for text-to-speech reading."""
    cleaned = text.strip()
    if cleaned.lower().startswith("please read"):
        return cleaned

    import re
    sentences = [s.strip() for s in re.split(r'[.!?]+', cleaned) if s.strip()]
    count = len(sentences)
    words = {
        1: "one sentence",
        2: "two sentences",
        3: "three sentences",
        4: "four sentences",
        5: "five sentences",
        6: "six sentences",
        7: "seven sentences",
        8: "eight sentences",
        9: "nine sentences",
        10: "ten sentences",
    }
    specifier = words.get(count, "text")
    if specifier == "text":
        prefix = "Please read the following text exactly as written, in a clear, warm narrating voice like a educater explainer narrator. "
    else:
        prefix = f"Please read the following {specifier} exactly as written, in a clear, warm narrating voice like a educater explainer narrator. "
    return prefix + cleaned


def play_read_aloud(s: CDPSocket, timeout: float = 12.0) -> bool:
    """Finds and clicks the Read aloud / Play audio button on the latest assistant response."""
    deadline = time.time() + timeout
    while time.time() < deadline:
        res = s.eval("""(() => {
            const msgs = document.querySelectorAll('[data-message-author-role="assistant"]');
            if (msgs.length === 0) return { ok: false, error: "No assistant message" };
            const lastMsg = msgs[msgs.length - 1];

            let container = lastMsg.parentElement;
            for (let i = 0; i < 6; i++) {
                if (!container) break;
                if (container.querySelector('button[aria-label="More actions"]') ||
                    container.querySelector('button[aria-label*="Read aloud" i]') ||
                    container.querySelector('button[aria-label*="Play" i]')) {
                    break;
                }
                container = container.parentElement;
            }
            if (!container) container = document;

            // Direct button check
            const directBtn = [...container.querySelectorAll('button')].find(b => {
                const aria = (b.getAttribute('aria-label') || '').toLowerCase();
                return aria.includes('read aloud') || aria.startsWith('play audio') || aria === 'read';
            });
            if (directBtn) {
                directBtn.click();
                return { ok: true, method: "direct" };
            }

            // More actions menu check
            const moreBtn = container.querySelector('button[aria-label="More actions"]');
            if (moreBtn) {
                moreBtn.click();
                return { ok: true, method: "more_clicked" };
            }
            return { ok: false };
        })()""")
        if res.get("ok"):
            if res.get("method") == "direct":
                return True
            if res.get("method") == "more_clicked":
                time.sleep(0.3)
                clicked_item = s.eval("""(() => {
                    const item = [...document.querySelectorAll('[role="menuitem"]')].find(m =>
                        m.innerText.toLowerCase().includes('read aloud')
                    );
                    if (item) {
                        item.click();
                        return true;
                    }
                    return false;
                })()""")
                if clicked_item:
                    return True
        time.sleep(0.5)
    raise CDPError("Timed out waiting to find and click Read aloud button")


# ── Image Generation (--imgen) ─────────────────────────────────────────────
def generate_image(s: CDPSocket, prompt: str, output_path: str = "image.png", timeout: float = 120.0) -> dict:
    """Sends an image generation prompt, waits for the image to be created, and downloads it to output_path."""
    import base64
    import urllib.request

    clean_prompt = prompt.strip()
    trigger_words = ["generate", "draw", "create an image", "image of", "picture of", "illustration of"]
    if not any(w in clean_prompt.lower() for w in trigger_words):
        full_prompt = f"Generate an image of: {clean_prompt}"
    else:
        full_prompt = clean_prompt

    # Query existing generated images before sending prompt
    get_imgs_code = """(() => {
        const imgs = [...document.querySelectorAll('img')].filter(img => {
            const src = img.src || '';
            const alt = (img.alt || '').toLowerCase();
            if (!src || src.includes('avatar') || src.includes('auth0') || src.includes('chrome-extension') || src.startsWith('data:image/svg')) return false;
            return alt.startsWith('generated image') || src.includes('backend-api/estuary') || src.includes('oaiusercontent') || (img.naturalWidth > 200 && img.naturalHeight > 200);
        });
        return imgs.map(img => ({
            src: img.src,
            alt: img.alt || '',
            width: img.naturalWidth || img.width,
            height: img.naturalHeight || img.height
        }));
    })()"""

    before_imgs = s.eval(get_imgs_code) or []
    before_srcs = {i["src"] for i in before_imgs if isinstance(i, dict) and i.get("src")}
    before_asst_count = s.eval("document.querySelectorAll('[data-message-author-role=\"assistant\"]').length") or 0

    _submit_prompt(s, full_prompt)

    # Phase 1: Wait for generation to start
    gen_start_deadline = time.time() + 25.0
    while time.time() < gen_start_deadline:
        time.sleep(0.3)
        cur = s.eval("""(() => {
            const stop = document.querySelector('button[data-testid="stop-button"], button[aria-label*="Stop" i]');
            return { generating: !!stop };
        })()""")
        if cur.get("generating"):
            break

    # Phase 2: Wait for generation to complete and locate the image
    gen_deadline = time.time() + timeout
    target_img = None
    response_text = ""

    while time.time() < gen_deadline:
        time.sleep(0.5)
        status = s.eval(f"""(() => {{
            const stop = document.querySelector('button[data-testid="stop-button"], button[aria-label*="Stop" i]');
            const msgs = document.querySelectorAll('[data-message-author-role="assistant"]');
            const lastMsg = msgs.length > 0 ? msgs[msgs.length - 1] : null;
            const imgs = {get_imgs_code};
            return {{
                generating: !!stop,
                imgs: imgs,
                asstCount: msgs.length,
                lastText: lastMsg ? lastMsg.innerText.trim() : ""
            }};
        }})()""")

        generating = status.get("generating", False)
        current_imgs = status.get("imgs", []) or []
        asst_count = status.get("asstCount", 0)
        response_text = status.get("lastText", "")

        new_imgs = [i for i in current_imgs if i.get("src") and i["src"] not in before_srcs]

        if not generating:
            if new_imgs:
                with_alt = [i for i in new_imgs if i.get("alt")]
                target_img = with_alt[-1] if with_alt else new_imgs[-1]
                break
            elif not before_srcs and current_imgs:
                with_alt = [i for i in current_imgs if i.get("alt")]
                target_img = with_alt[-1] if with_alt else current_imgs[-1]
                break
            elif asst_count > before_asst_count and response_text:
                # Text response returned (refusal/error) without image
                break

    # Grace period check if needed
    if not target_img:
        grace = time.time() + 6.0
        while time.time() < grace:
            time.sleep(0.5)
            current_imgs = s.eval(get_imgs_code) or []
            new_imgs = [i for i in current_imgs if i.get("src") and i["src"] not in before_srcs]
            if new_imgs:
                with_alt = [i for i in new_imgs if i.get("alt")]
                target_img = with_alt[-1] if with_alt else new_imgs[-1]
                break
            elif not before_srcs and current_imgs:
                with_alt = [i for i in current_imgs if i.get("alt")]
                target_img = with_alt[-1] if with_alt else current_imgs[-1]
                break

    if not target_img or not target_img.get("src"):
        err_detail = f": {response_text}" if response_text else ""
        raise CDPError(f"No generated image found in ChatGPT response after {timeout}s{err_detail}")

    img_src = target_img["src"]
    out_file = Path(output_path).expanduser().resolve()
    out_file.parent.mkdir(parents=True, exist_ok=True)

    # In-browser authenticated fetch
    fetch_result = s.eval(f"""(async () => {{
        const url = {json.dumps(img_src)};
        try {{
            const resp = await fetch(url);
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
        raise CDPError(f"Failed to download generated image from {img_src}: {fetch_result}")

    return {
        "path": str(out_file),
        "size": file_size,
        "mime_type": mime_type,
        "alt": target_img.get("alt", ""),
        "text": response_text
    }


# ── Live Voice Mode ────────────────────────────────────────────────────────
def _voice_js(action: str) -> str:
    """Runs inside the page. action: on | off | toggle | status. Atomic check + click."""
    return f"""(() => {{
  const START = {json.dumps(list(VOICE_START_SELECTORS))};
  const STOP = {json.dumps(list(VOICE_STOP_SELECTORS))};
  const pick = (sels) => {{
    for (const s of sels) {{
      const b = document.querySelector(s);
      if (b && !b.disabled && b.getAttribute('aria-hidden') !== 'true') return b;
    }}
    return null;
  }};
  const stop = pick(STOP), start = pick(START);
  const active = !!stop;
  const action = {json.dumps(action)};
  const want = action === 'toggle' ? (active ? 'off' : 'on') : (action === 'new' ? 'on' : action);
  let result = action === 'status' ? 'status' : 'noop';
  if (want === 'on' && !active) {{
    if (start) {{ start.click(); result = 'started'; }} else {{ result = 'unavailable'; }}
  }} else if (want === 'off' && active) {{
    stop.click(); result = 'stopped';
  }}
  return JSON.stringify({{active, startable: !!start, result}});
}})()"""


def live_mode(action: str = "toggle", project_name: str | None = None) -> bool:
    """Controls ChatGPT Voice Mode on the dedicated voice tab."""
    page = get_role_page("voice")
    target_project = resolve_project_name(project_name, "livemode")

    with CDPSocket(page["webSocketDebuggerUrl"]) as ps:
        if action == "new":
            start_new_conversation(ps, target_project)
            time.sleep(0.5)
        elif project_name:
            select_project(ps, target_project)

        info = json.loads(ps.eval(_voice_js(action)))

    if info["result"] == "unavailable":
        raise CDPError("voice start control not found (is chatgpt.com loaded and signed in?)")
    if info["result"] == "started":
        return True
    if info["result"] == "stopped":
        return False
    return bool(info["active"])


# ── STT (Speech to Text / Dictation) ───────────────────────────────────────
def type_with_wtype(text: str) -> None:
    """Types text at the current active cursor via wtype in a single atomic burst."""
    if not text.strip():
        return
    time.sleep(0.05)
    cmd = ["wtype", "-m", "logo", "-m", "alt", "--", text.strip() + " "]
    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode != 0:
        fallback_cmd = ["wtype", "--", text.strip() + " "]
        subprocess.run(fallback_cmd, capture_output=True, text=True)


# ── Quickshell HUD state ───────────────────────────────────────────────────
QS_STATE_DIR = Path.home() / ".cache" / "qs-dictation"
QS_STATUS = QS_STATE_DIR / "status"
QS_TEXT = QS_STATE_DIR / "text"


def _qs_write(status: str, text: str | None = None) -> None:
    """Updates Quickshell DictationHud state: status in {recording, transcribing, idle}."""
    try:
        QS_STATE_DIR.mkdir(parents=True, exist_ok=True)
        QS_STATUS.write_text(status, encoding="utf-8")
        if text is not None:
            with QS_TEXT.open("a", encoding="utf-8") as f:
                f.write(text + " ")
    except Exception:
        pass
    try:
        if status == "recording":
            subprocess.run(["quickshell", "-c", "ii", "ipc", "call", "dictation", "show"],
                           check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.2)
        elif status == "idle":
            subprocess.run(["quickshell", "-c", "ii", "ipc", "call", "dictation", "hide"],
                           check=False, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=0.2)
    except Exception:
        pass


def stt(action: str = "toggle", timeout: float = 15.0) -> str:
    """ChatGPT Dictation / STT. Runs on tools tab with zero focus stealing."""
    page = get_role_page("tools")
    with CDPSocket(page["webSocketDebuggerUrl"]) as s:
        state = s.eval("""(() => {
            const start = document.querySelector('button[aria-label="Start dictation"]');
            const submit = document.querySelector('button[aria-label="Submit dictation"]');
            const transcribing = document.querySelector('button[aria-label="Transcribing dictation"]');
            const cancel = document.querySelector('button[aria-label="Cancel dictation"]');
            const composer = document.querySelector('#prompt-textarea');
            return {
                canStart: !!start,
                isRecording: !!submit,
                isTranscribing: !!transcribing,
                hasComposer: !!composer,
                composerText: composer ? composer.innerText.trim() : ""
            };
        })()""")

        if action == "status":
            if state.get("isRecording"):
                return "recording"
            if state.get("isTranscribing"):
                return "transcribing"
            return "idle" if (state.get("canStart") or state.get("hasComposer")) else "unavailable"

        if action == "cancel":
            s.eval("""(() => {
                const cancel = document.querySelector('button[aria-label="Cancel dictation"]');
                if (cancel) cancel.click();
            })()""")
            _qs_write("idle")
            return "cancelled"

        want_start = False
        if action == "start":
            want_start = True
        elif action == "stop":
            want_start = False
        elif action == "toggle":
            want_start = not state.get("isRecording") and not state.get("isTranscribing")

        if want_start:
            if state.get("isRecording"):
                return "already_recording"
            s.eval("""(() => {
                const composer = document.querySelector('#prompt-textarea');
                if (composer) {
                    composer.focus();
                    document.execCommand('selectAll', false, null);
                    document.execCommand('delete', false, null);
                }
                const start = document.querySelector('button[aria-label="Start dictation"]');
                if (start) start.click();
            })()""")
            try:
                QS_STATE_DIR.mkdir(parents=True, exist_ok=True)
                QS_TEXT.write_text("", encoding="utf-8")
            except Exception:
                pass
            _qs_write("recording")
            return "started"
        else:
            if not state.get("isRecording") and not state.get("isTranscribing"):
                _qs_write("idle")
                return "not_recording"

            _qs_write("transcribing")
            if state.get("isRecording"):
                s.eval("""(() => {
                    const submit = document.querySelector('button[aria-label="Submit dictation"]');
                    if (submit) submit.click();
                })()""")

            deadline = time.time() + timeout
            transcribed_text = ""
            while time.time() < deadline:
                time.sleep(0.25)
                res = s.eval("""(() => {
                    const transcribing = document.querySelector('button[aria-label="Transcribing dictation"]');
                    const cancel = document.querySelector('button[aria-label="Cancel dictation"]');
                    const start = document.querySelector('button[aria-label="Start dictation"]');
                    const composer = document.querySelector('#prompt-textarea');
                    const text = composer ? composer.innerText.trim() : "";
                    return {
                        isBusy: !!transcribing || !!cancel,
                        canStart: !!start,
                        text: text
                    };
                })()""")
                if not res.get("isBusy") and (res.get("canStart") or res.get("text")):
                    transcribed_text = res.get("text", "")
                    break

            _qs_write("idle")

            if transcribed_text:
                s.eval("""(() => {
                    const composer = document.querySelector('#prompt-textarea');
                    if (composer) {
                        composer.focus();
                        document.execCommand('selectAll', false, null);
                        document.execCommand('delete', false, null);
                    }
                })()""")
                type_with_wtype(transcribed_text)
                return transcribed_text
            else:
                return ""


def _notify_error(msg: str) -> None:
    try:
        subprocess.run(
            ["notify-send", "-a", "chatgpt-voice", "-u", "low", "ChatGPT", msg],
            check=False, timeout=2, capture_output=True,
        )
    except Exception:
        pass


def main() -> int:
    ap = argparse.ArgumentParser(description="ChatGPT CLI adapter over Chrome CDP")
    ap.add_argument("prompt", nargs="?")
    ap.add_argument("--project", help="Select ChatGPT project container by name")
    ap.add_argument("--attach", action="append", default=[], help="Attach local files")
    ap.add_argument("--check", action="store_true", help="Check CDP and ChatGPT readiness")
    ap.add_argument("--livemode", choices=["on", "off", "toggle", "status", "new"], help="Live Voice mode control")
    ap.add_argument("--stt", choices=["start", "stop", "toggle", "status", "cancel"], help="Dictation / STT control")
    ap.add_argument("--tts", nargs="?", const="", help="Convert text to speech via ChatGPT Read Aloud")
    ap.add_argument("--imgen", nargs="?", const="", help="Generate image via ChatGPT and download to output file")
    ap.add_argument("-o", "--output", help="Output file path for generated image (default: image.png)")
    ap.add_argument("--new", action="store_true", help="Start a fresh conversation in target container")
    ap.add_argument("--list-projects", action="store_true", help="List all available ChatGPT projects")
    ns = ap.parse_args()

    if ns.livemode and (ns.prompt or ns.attach or ns.stt or ns.tts is not None or ns.imgen is not None):
        ap.error("--livemode is background-only; don't combine it with other flags")
    if ns.stt and (ns.prompt or ns.attach or ns.livemode or ns.tts is not None or ns.imgen is not None):
        ap.error("--stt is background-only; don't combine it with other flags")

    # Read piped stdin if present
    if not sys.stdin.isatty() and not (ns.livemode or ns.stt or ns.check or ns.list_projects):
        try:
            piped = sys.stdin.read().strip()
            if piped:
                ns.prompt = f"{ns.prompt}\n\n{piped}" if ns.prompt else piped
        except Exception:
            pass

    try:
        if ns.list_projects:
            page = get_role_page("tools")
            with CDPSocket(page["webSocketDebuggerUrl"]) as s:
                projs = list_projects(s)
                cfg = load_routing_config()
                cached = cfg.get("cached_urls", {})
                print(f"Available Projects ({len(projs)}):")
                for p in projs:
                    name = p["name"]
                    cached_url = cached.get(name.lower(), "(not cached)")
                    print(f"  - {name:<20} {cached_url}")
                defaults = cfg.get("defaults", {})
                print("\nDefault Role Routing:")
                for role, rcfg in defaults.items():
                    if isinstance(rcfg, dict):
                        print(f"  {role:<10} -> project: {rcfg.get('project')} (fallback: {rcfg.get('fallback_project', 'none')})")
            return 0

        if ns.livemode:
            active = live_mode(ns.livemode, ns.project)
            if ns.livemode == "status":
                print("on" if active else "off")
            return 0

        if ns.stt:
            res = stt(ns.stt)
            if res:
                print(res)
            return 0

        if ns.check:
            check()
            print("ok")
            return 0

        page = get_role_page("tools")
        with CDPSocket(page["webSocketDebuggerUrl"]) as s:
            if ns.tts is not None:
                tts_text = ns.tts if ns.tts != "" else ns.prompt
                if not tts_text:
                    ap.error("--tts requires text to read")
                target_project = resolve_project_name(ns.project, "tts")
                select_project(s, target_project)

                # Check auto-rotation limit
                turn_count = s.eval("document.querySelectorAll('[data-message-author-role=\"assistant\"]').length") or 0
                max_turns = load_routing_config().get("defaults", {}).get("tts", {}).get("max_turns", 25)
                if ns.new or turn_count >= max_turns:
                    start_new_conversation(s, target_project)

                prompt = build_tts_prompt(tts_text)
                response = send(s, prompt)
                play_read_aloud(s)
                print(response)
                return 0

            if ns.imgen is not None:
                img_prompt = ns.imgen if ns.imgen != "" else ns.prompt
                if not img_prompt:
                    ap.error("--imgen requires an image prompt")
                out_path = ns.output or "image.png"
                target_project = resolve_project_name(ns.project, "imgen")
                select_project(s, target_project)

                turn_count = s.eval("""(() => {
                    const users = document.querySelectorAll('[data-message-author-role="user"]').length;
                    const imgs = document.querySelectorAll('img[alt^="Generated image"], [class*="imagegen-image"]').length;
                    return Math.max(users, imgs);
                })()""") or 0
                max_turns = load_routing_config().get("defaults", {}).get("imgen", {}).get("max_turns", 20)
                is_stuck = s.eval("!!document.querySelector('button[data-testid=\"stop-button\"], button[aria-label*=\"Stop\" i]')")
                if ns.new or turn_count >= max_turns or is_stuck:
                    start_new_conversation(s, target_project)

                res = generate_image(s, img_prompt, out_path)
                print(f"Downloaded image ({res['size']} bytes, {res['mime_type']}) -> {res['path']}")
                if res.get("text"):
                    print(res["text"])
                return 0

            # Ad-hoc prompt / project command
            target_project = resolve_project_name(ns.project, "adhoc")
            select_project(s, target_project)

            if ns.new:
                start_new_conversation(s, target_project)

            if ns.prompt:
                response = send(s, ns.prompt, ns.attach if ns.attach else None)
                print(response)
                return 0
            else:
                cur_url = s.eval("location.href")
                print(cur_url)
                return 0

    except Exception as exc:
        msg = f"chatgpt-cdp: {exc}"
        print(msg, file=sys.stderr)
        if ns.stt:
            _qs_write("idle")
        elif ns.livemode:
            _notify_error(msg)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
