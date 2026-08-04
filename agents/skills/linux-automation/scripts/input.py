import sys
import fcntl
import subprocess
from pathlib import Path
from rich.console import Console

console = Console()

LOCK_FILE_DIR = Path("/tmp/linux-automation-locks")
LOCK_FILE_DIR.mkdir(parents=True, exist_ok=True)

class MutexLock:
    def __init__(self, name: str):
        self.lock_file = LOCK_FILE_DIR / f"{name}.lock"
        self.fd = None

    def acquire(self):
        self.fd = open(self.lock_file, "w")
        try:
            fcntl.flock(self.fd, fcntl.LOCK_EX)
        except IOError:
            console.print(f"[red]Failed to acquire lock for {self.lock_file}[/red]")
            sys.exit(1)

    def release(self):
        if self.fd:
            fcntl.flock(self.fd, fcntl.LOCK_UN)
            self.fd.close()

def run_ydotool(cmd_args: list[str]):
    try:
        subprocess.run(["ydotool", *cmd_args], check=True)
    except subprocess.CalledProcessError as e:
        console.print(f"[red]ydotool error:[/red] {e}")


def hotkey(keys: str):
    """
    Press a key combination like ``"ctrl+c"`` or ``"ctrl+shift+t"``.
    Prefers ``wtype`` (lower latency on Wayland, composes modifiers
    cleanly); falls back to ``ydotool key`` when wtype is unavailable.
    Both accept ``+``-separated key names and linux input-event codes.
    """
    try:
        subprocess.run(["wtype", "-M", "ctrl", "-k", keys], check=True)
        return
    except (subprocess.CalledProcessError, FileNotFoundError):
        pass
    # ydotool key wants space-separated tokens; accept either "+" or " ".
    token = keys.replace("+", " ")
    run_ydotool(["key", token])

def handle_cli(args):
    lock = MutexLock("input")
    lock.acquire()
    try:
        if args.command == "mouse":
            if args.action == "move":
                run_ydotool(["mousemove", "-a", "--", str(args.x), str(args.y)])
            elif args.action == "click":
                if args.x != 0 or args.y != 0:
                    run_ydotool(["mousemove", "-a", "--", str(args.x), str(args.y)])
                run_ydotool(["click", "0x110"])
            elif args.action == "rightclick":
                if args.x != 0 or args.y != 0:
                    run_ydotool(["mousemove", "-a", "--", str(args.x), str(args.y)])
                run_ydotool(["click", "0x111"])
            elif args.action == "doubleclick":
                if args.x != 0 or args.y != 0:
                    run_ydotool(["mousemove", "-a", "--", str(args.x), str(args.y)])
                run_ydotool(["click", "0x110"])
                run_ydotool(["click", "0x110"])
            elif args.action == "drag":
                # Move to start, mouse down, move to end, mouse up
                run_ydotool(["mousemove", "-a", "--", str(args.x), str(args.y)])
                run_ydotool(["click", "0x40110"])  # button down
                run_ydotool(["mousemove", "-a", "--", str(args.to_x), str(args.to_y)])
                run_ydotool(["click", "0x80110"])  # button up

        elif args.command == "keyboard":
            if args.action == "type":
                run_ydotool(["type", args.text])
            elif args.action == "hotkey":
                hotkey(args.text)
    finally:
        lock.release()
