import os
import subprocess
from rich.console import Console

console = Console()

def run_cmd(cmd_args: list[str], input_data=None) -> str:
    result = subprocess.run(cmd_args, input=input_data, capture_output=True, text=True)
    return result.stdout.strip() if result.returncode == 0 else ""

def handle_cli(args):
    if args.action == "copy":
        if args.text:
            # wl-copy forks a background process to hold the Wayland
            # selection and the parent only exits when the selection is
            # replaced. subprocess.run() would deadlock waiting for that.
            # Fix: use Popen (fire-and-forget); wl-copy serves the selection
            # as a background daemon.
            proc = subprocess.Popen(
                ["wl-copy"],
                stdin=subprocess.PIPE,
                stdout=subprocess.DEVNULL,
                stderr=subprocess.DEVNULL,
            )
            try:
                proc.communicate(input=args.text.encode(), timeout=5)
            except subprocess.TimeoutExpired:
                # Expected: wl-copy is now serving in the background.
                proc.kill()
            console.print("[green]Copied to clipboard.[/green]")
        else:
            console.print("[red]No text provided to copy. Use --text 'content'.[/red]")
    elif args.action == "paste":
        text = run_cmd(["wl-paste"])
        console.print(text)
    elif args.action == "history":
        history = run_cmd(["cliphist", "list"])
        if history:
            console.print(history)
        else:
            console.print("[yellow]Clipboard history empty or cliphist unavailable.[/yellow]")
    elif args.action == "clear":
        run_cmd(["wl-copy", "-c"])
        run_cmd(["cliphist", "wipe"])
        console.print("[green]Clipboard cleared.[/green]")
