"""
Hyprland IPC Event Listener for linux-automation.
Connects to Hyprland's UNIX socket (.socket2.sock) to listen for window & workspace events.
"""
import os
import socket
import threading
import time
from typing import Callable, Optional
from rich.console import Console

import hyprland

console = Console()

def get_event_socket_path() -> Optional[str]:
    his = os.environ.get("HYPRLAND_INSTANCE_SIGNATURE")
    xdg_runtime = os.environ.get("XDG_RUNTIME_DIR", f"/run/user/{os.getuid()}")
    if not his:
        console.print("[yellow]HYPRLAND_INSTANCE_SIGNATURE not set[/yellow]")
        return None
    sock_path = f"{xdg_runtime}/hypr/{his}/.socket2.sock"
    if os.path.exists(sock_path):
        return sock_path
    return None


class HyprlandEventListener:
    def __init__(self):
        self.sock_path = get_event_socket_path()
        self._stop_event = threading.Event()
        self._thread: Optional[threading.Thread] = None
        self.callbacks = []

    def add_callback(self, callback: Callable[[str, str], None]):
        """Add a callback function with signature `fn(event_name, event_data)`."""
        self.callbacks.append(callback)

    def start(self):
        if not self.sock_path:
            console.print("[red]Cannot start event listener: socket2.sock not found.[/red]")
            return False
        self._stop_event.clear()
        self._thread = threading.Thread(target=self._listen_loop, daemon=True)
        self._thread.start()
        console.print("[green]Started Hyprland event listener thread.[/green]")
        return True

    def stop(self):
        self._stop_event.set()
        if self._thread and self._thread.is_alive():
            self._thread.join(timeout=2.0)
        console.print("[dim]Stopped Hyprland event listener.[/dim]")

    def _listen_loop(self):
        try:
            s = socket.socket(socket.AF_UNIX, socket.SOCK_STREAM)
            s.connect(self.sock_path)
            s.settimeout(1.0)
            buffer = ""
            while not self._stop_event.is_set():
                try:
                    data = s.recv(4096)
                    if not data:
                        break
                    buffer += data.decode("utf-8", errors="replace")
                    while "\n" in buffer:
                        line, buffer = buffer.split("\n", 1)
                        line = line.strip()
                        if not line:
                            continue
                        if ">>" in line:
                            event_name, event_data = line.split(">>", 1)
                            for cb in self.callbacks:
                                try:
                                    cb(event_name, event_data)
                                except Exception as e:
                                    console.print(f"[red]Error in event callback:[/red] {e}")
                except socket.timeout:
                    continue
        except Exception as e:
            console.print(f"[red]Event listener error:[/red] {e}")


def auto_route_window_rule(class_substring: str, target_workspace: str, duration: float = 10.0):
    """
    Subscribes to Hyprland events for `duration` seconds, matching any new window
    whose class contains `class_substring`, and moves it to `target_workspace`.
    """
    listener = HyprlandEventListener()
    routed = []

    def _on_event(event_name: str, event_data: str):
        if event_name == "openwindow":
            # format: address,workspace,class,title
            parts = event_data.split(",")
            if len(parts) >= 3:
                addr, ws, win_class = parts[0], parts[1], parts[2]
                if class_substring.lower() in win_class.lower():
                    console.print(f"[cyan]Auto-routing window 0x{addr} ({win_class}) -> workspace {target_workspace}[/cyan]")
                    hyprland.dispatch_lua(f'hl.dsp.window.move({{ window = "address:0x{addr}", workspace = "{target_workspace}" }})')
                    routed.append(addr)

    listener.add_callback(_on_event)
    ok = listener.start()
    if ok:
        time.sleep(duration)
        listener.stop()
    return routed
