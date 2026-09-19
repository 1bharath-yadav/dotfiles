#!/usr/bin/env python3
"""Direct CDP over a page-level websocket -- stdlib only, no agent-browser, no daemon.

THE TECHNIQUE ("direct page-socket CDP")
    GET /json/list  ->  pick ONE page target  ->  open that page's own
    ws://127.0.0.1:<port>/devtools/page/<id>  ->  drive it with Runtime.evaluate (DOM)
    and DOM.setFileInputFiles (uploads). One short-lived connection per invocation.

WHY IT NEVER STEALS FOCUS
    Raising a window / switching tabs only happens through a few browser-level calls.
    This module never sends them. Do NOT add any of:
      Target.activateTarget, Page.bringToFront   (raise window / switch tab)
      Input.dispatch*                            (needs OS focus; use DOM .click() instead)
      Target.createTarget on a HEADED browser    (raises the window; open_page() refuses)
    (agent-browser's `tab <id> <cmd>` == "switch tab": it sends Page.bringToFront and
    discards <cmd>. That is what stole focus. See ../README.md.)
"""
from __future__ import annotations

import base64
import json
import os
import socket
import struct
import time
import urllib.request
from pathlib import Path
from urllib.parse import urlparse

HOST = "127.0.0.1"
PORT = os.environ.get("CDP_PORT") or os.environ.get("CHATGPT_CDP_PORT") or "9222"


class CDPError(RuntimeError):
    pass


# --- HTTP side of CDP (no side effects) ------------------------------------
def http_json(path: str, timeout: float = 2.0):
    try:
        with urllib.request.urlopen(f"http://{HOST}:{PORT}{path}", timeout=timeout) as r:
            return json.load(r)
    except OSError as exc:
        raise CDPError(f"CDP not reachable on {HOST}:{PORT} ({exc})") from exc


def version() -> dict:
    return http_json("/json/version")


def is_headless() -> bool:
    if os.environ.get("CDP_HEADLESS") == "1" or os.environ.get("XOY_HEADLESS") == "1":
        return True
    try:
        v = version()
        b = v.get("Browser", "").lower()
        ua = v.get("User-Agent", "").lower()
        return "headless" in b or "headless" in ua
    except Exception:
        return False


def pages(*hosts: str) -> list[dict]:
    """Page targets whose URL host is (a subdomain of) one of `hosts`."""
    out = []
    for t in http_json("/json/list"):
        if t.get("type") != "page" or not t.get("webSocketDebuggerUrl"):
            continue
        h = urlparse(t.get("url", "")).hostname or ""
        if not hosts or any(h == x or h.endswith("." + x) for x in hosts):
            out.append(t)
    return out


# --- minimal RFC 6455 websocket client ---------------------------------------
class CDPSocket:
    """One CDP session (page target or browser target). Use as a context manager."""

    def __init__(self, ws_url: str, timeout: float = 8.0):
        u = urlparse(ws_url)
        self.buf = b""
        self.next_id = 0
        self.sock = socket.create_connection((u.hostname, u.port), timeout=timeout)
        key = base64.b64encode(os.urandom(16)).decode()
        self.sock.sendall(
            (
                f"GET {u.path} HTTP/1.1\r\nHost: {u.hostname}:{u.port}\r\n"
                "Upgrade: websocket\r\nConnection: Upgrade\r\n"
                f"Sec-WebSocket-Key: {key}\r\nSec-WebSocket-Version: 13\r\n\r\n"
            ).encode()
        )
        head = self._read_until(b"\r\n\r\n")
        if b" 101 " not in head.split(b"\r\n", 1)[0]:
            raise CDPError(f"websocket upgrade refused: {head[:80]!r}")

    def __enter__(self) -> "CDPSocket":
        return self

    def __exit__(self, *exc) -> None:
        try:
            self._send_frame(0x8, b"")
        except OSError:
            pass
        self.sock.close()

    def _fill(self) -> None:
        chunk = self.sock.recv(65536)
        if not chunk:
            raise CDPError("connection closed by browser")
        self.buf += chunk

    def _read_until(self, marker: bytes) -> bytes:
        while marker not in self.buf:
            self._fill()
        head, _, self.buf = self.buf.partition(marker)
        return head

    def _read(self, n: int) -> bytes:
        while len(self.buf) < n:
            self._fill()
        out, self.buf = self.buf[:n], self.buf[n:]
        return out

    def _send_frame(self, opcode: int, payload: bytes) -> None:
        n = len(payload)
        if n < 126:
            header = bytes([0x80 | opcode, 0x80 | n])
        elif n < 65536:
            header = bytes([0x80 | opcode, 0x80 | 126]) + struct.pack(">H", n)
        else:
            header = bytes([0x80 | opcode, 0x80 | 127]) + struct.pack(">Q", n)
        mask = os.urandom(4)
        self.sock.sendall(header + mask + bytes(b ^ mask[i % 4] for i, b in enumerate(payload)))

    def _recv_message(self) -> str:
        data = b""
        while True:
            b0, b1 = self._read(2)
            fin, opcode, n = b0 & 0x80, b0 & 0x0F, b1 & 0x7F
            if n == 126:
                n = struct.unpack(">H", self._read(2))[0]
            elif n == 127:
                n = struct.unpack(">Q", self._read(8))[0]
            mask = self._read(4) if b1 & 0x80 else None  # servers don't mask; tolerate it
            payload = self._read(n)
            if mask:
                payload = bytes(b ^ mask[i % 4] for i, b in enumerate(payload))
            if opcode == 0x8:
                raise CDPError("browser closed the websocket")
            if opcode == 0x9:  # ping
                self._send_frame(0xA, payload)
                continue
            if opcode == 0xA:  # pong
                continue
            data += payload
            if fin:
                return data.decode()

    # --- CDP ---------------------------------------------------------------
    def call(self, method: str, params: dict | None = None) -> dict:
        self.next_id += 1
        mid = self.next_id
        self._send_frame(0x1, json.dumps({"id": mid, "method": method, "params": params or {}}).encode())
        while True:  # skip events; wait for our reply
            msg = json.loads(self._recv_message())
            if msg.get("id") == mid:
                if "error" in msg:
                    raise CDPError(f"{method}: {msg['error'].get('message')}")
                return msg.get("result", {})

    def eval(self, expression: str, *, await_promise: bool = False):
        """Runtime.evaluate. userGesture=True gives transient user activation, so the page
        treats element.click() like a real click (mic/audio start) -- without any focus."""
        r = self.call(
            "Runtime.evaluate",
            {"expression": expression, "returnByValue": True, "userGesture": True, "awaitPromise": await_promise},
        )
        if "exceptionDetails" in r:
            d = r["exceptionDetails"]
            raise CDPError(f"page script failed: {d.get('exception', {}).get('description') or d.get('text')}")
        return r.get("result", {}).get("value")

    def wait_for(self, expression: str, timeout: float = 30.0, interval: float = 0.25, what: str = "condition"):
        """Poll a JS expression until truthy; returns its value."""
        deadline = time.time() + timeout
        while True:
            v = self.eval(expression)
            if v:
                return v
            if time.time() >= deadline:
                raise CDPError(f"timed out after {timeout:.0f}s waiting for {what}")
            time.sleep(interval)

    def navigate(self, url: str) -> None:
        """Page.navigate: changes this tab's URL. Does not raise or focus anything."""
        self.call("Page.navigate", {"url": url})

    def set_input_files(self, selector: str, paths: list[str]) -> None:
        """Attach local files to an <input type=file> (works while the tab is in the background)."""
        files = []
        for p in paths:
            fp = Path(p).expanduser().resolve()
            if not fp.is_file():
                raise FileNotFoundError(str(fp))
            files.append(str(fp))
        root = self.call("DOM.getDocument", {"depth": 0})["root"]["nodeId"]
        node = self.call("DOM.querySelector", {"nodeId": root, "selector": selector}).get("nodeId")
        if not node:
            raise CDPError(f"no element matches {selector!r}")
        self.call("DOM.setFileInputFiles", {"nodeId": node, "files": files})


# --- browser-level helpers ---------------------------------------------------
def open_page(url: str, timeout: float = 20.0) -> dict:
    """Open a new tab. HEADLESS ONLY: in a headed browser this raises the window."""
    if not is_headless():
        raise CDPError(
            "refusing to open a tab in a HEADED browser (it would raise the window). "
            "Open the site once yourself, or run the browser headless."
        )
    with CDPSocket(version()["webSocketDebuggerUrl"]) as browser:
        tid = browser.call("Target.createTarget", {"url": url})["targetId"]
    deadline = time.time() + timeout
    while time.time() < deadline:
        for t in http_json("/json/list"):
            if t.get("id") == tid and t.get("webSocketDebuggerUrl"):
                return t
        time.sleep(0.1)
    raise CDPError("new tab did not appear in /json/list")
