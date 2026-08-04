"""Screenshot capture via grim."""
import time
import subprocess
from pathlib import Path
from rich.console import Console
import hyprland

console = Console()


def run_cmd(cmd: str):
    subprocess.run(cmd, shell=True)


def _default_output_path() -> Path:
    pics = subprocess.run(
        ["xdg-user-dir", "PICTURES"], capture_output=True, text=True
    ).stdout.strip()
    if not pics:
        pics = str(Path.home() / "Pictures")
    out_dir = Path(pics) / "Screenshots"
    out_dir.mkdir(parents=True, exist_ok=True)
    return out_dir / f"Screenshot_{time.strftime('%Y-%m-%d_%H.%M.%S')}.png"


def _geometry_of_active_window() -> str | None:
    """Return a grim ``-g`` geometry string for the active window, or None."""
    win = hyprland.get_json("activewindow")
    if win and "at" in win and "size" in win:
        at, size = win["at"], win["size"]
        return f'{at[0]},{at[1]} {size[0]}x{size[1]}'
    return None


def capture(mode: str = "fullscreen", output: str | None = None, delay: float = 0.0) -> str:
    """
    Take a screenshot and return its path. ``mode`` is one of
    ``fullscreen``, ``monitor``, ``active``, ``region``.
    """
    if delay > 0:
        console.print(f"[yellow]Waiting {delay}s before capture...[/yellow]")
        time.sleep(delay)

    if output:
        filename = Path(output)
        filename.parent.mkdir(parents=True, exist_ok=True)
    else:
        filename = _default_output_path()

    if mode == "fullscreen":
        run_cmd(f'grim "{filename}"')
    elif mode == "monitor":
        active_ws = hyprland.get_json("activeworkspace")
        monitor = active_ws.get("monitor", "") if active_ws else ""
        if monitor:
            run_cmd(f'grim -o "{monitor}" "{filename}"')
        else:
            run_cmd(f'grim "{filename}"')
    elif mode == "region":
        run_cmd(f'grim -g "$(slurp)" "{filename}"')
    elif mode == "active":
        geom = _geometry_of_active_window()
        if geom:
            run_cmd(f'grim -g "{geom}" "{filename}"')
        else:
            run_cmd(f'grim "{filename}"')
    else:
        console.print(f"[red]Unknown screenshot mode:[/red] {mode}")
        return ""

    console.print(f"[green]Saved screenshot to:[/green] {filename}")
    return str(filename)


def handle_cli(args):
    capture(mode=args.mode, output=args.output, delay=args.delay)
