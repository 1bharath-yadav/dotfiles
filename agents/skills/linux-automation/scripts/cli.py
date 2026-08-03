#!/usr/bin/env -S uv run --python 3.12
# /// script
# requires-python = ">=3.12"
# dependencies = [
#   "requests",
#   "rich",
#   "pillow",
# ]
# ///

import sys
import argparse
from rich.console import Console

console = Console()


def parse_args():
    parser = argparse.ArgumentParser(prog="linux-automation", description="Linux Workstation Automation & Hyprland Controller")
    subparsers = parser.add_subparsers(dest="command", help="Available subcommands")

    # screenshot
    parser_shot = subparsers.add_parser("screenshot", help="Take a screenshot")
    parser_shot.add_argument("mode", choices=["fullscreen", "monitor", "active", "region"], nargs="?", default="fullscreen", help="Capture target")
    parser_shot.add_argument("--delay", type=float, default=0.0, help="Delay capture in seconds")
    parser_shot.add_argument("--output", type=str, help="Custom output image path")

    # ocr
    parser_ocr = subparsers.add_parser("ocr", help="Extract text via OCR pipeline")
    parser_ocr.add_argument("source", choices=["region", "clipboard", "file", "active"], nargs="?", default="region", help="OCR source")
    parser_ocr.add_argument("--file", type=str, help="Image file path if source is file")
    parser_ocr.add_argument("--boxes", action="store_true", help="Output bounding boxes & confidence")

    # clipboard
    parser_clip = subparsers.add_parser("clipboard", help="Clipboard operations")
    parser_clip.add_argument("action", choices=["copy", "paste", "history", "clear"], nargs="?", default="paste", help="Clipboard action")
    parser_clip.add_argument("--text", type=str, help="Text to copy to clipboard")

    # notify
    parser_notify = subparsers.add_parser("notify", help="Send a desktop notification")
    parser_notify.add_argument("summary", type=str, help="Notification title / summary")
    parser_notify.add_argument("body", type=str, nargs="?", default="", help="Notification body text")

    # window
    parser_window = subparsers.add_parser("window", help="Hyprland window management")
    parser_window.add_argument("action", choices=["focus", "move", "resize", "close", "kill", "float", "tile", "fullscreen", "minimize", "maximize", "active", "list"], help="Window action")
    parser_window.add_argument("--target", type=str, help="Target window title, class, or address")

    # workspace
    parser_ws = subparsers.add_parser("workspace", help="Workspace management")
    parser_ws.add_argument("action", choices=["focus", "movetoworkspace", "toggle_special", "list", "organize"], help="Workspace action")
    parser_ws.add_argument("target", type=str, nargs="?", help="Target workspace or scratchpad name")

    # monitor
    parser_mon = subparsers.add_parser("monitor", help="Monitor management")
    parser_mon.add_argument("action", choices=["list", "active", "focus"], help="Monitor action")
    parser_mon.add_argument("target", type=str, nargs="?", help="Monitor ID or name")

    # launch
    parser_launch = subparsers.add_parser("launch", help="Launch a command or desktop application in a planned workspace (max 2 per workspace)")
    parser_launch.add_argument("app", type=str, help="Application executable or command")
    parser_launch.add_argument("--workspace", "-w", type=str, help="Target planned workspace (defaults to first with < 2 windows)")

    # mouse
    parser_mouse = subparsers.add_parser("mouse", help="Mouse GUI automation")
    parser_mouse.add_argument("action", choices=["move", "click", "doubleclick", "rightclick", "drag"], help="Mouse action")
    parser_mouse.add_argument("x", type=int, nargs="?", default=0, help="X coordinate")
    parser_mouse.add_argument("y", type=int, nargs="?", default=0, help="Y coordinate")
    parser_mouse.add_argument("--to-x", type=int, default=0, help="Drag destination X coordinate")
    parser_mouse.add_argument("--to-y", type=int, default=0, help="Drag destination Y coordinate")

    # keyboard
    parser_kb = subparsers.add_parser("keyboard", help="Keyboard GUI automation")
    parser_kb.add_argument("action", choices=["type", "hotkey"], help="Keyboard action")
    parser_kb.add_argument("text", type=str, help="Text to type or hotkey combination (e.g. CTRL+ALT+T)")

    # accessibility (AT-SPI) -- preferred way to interact with desktop apps
    parser_a11y = subparsers.add_parser("a11y", help="Accessibility-tree automation via AT-SPI (prefer this over screenshots/OCR for desktop apps)")
    parser_a11y.add_argument("action", choices=["check", "apps", "tree", "find", "click", "type", "read"], help="Accessibility action")
    parser_a11y.add_argument("--app", type=str, help="Application name substring to scope the query to")
    parser_a11y.add_argument("--role", type=str, help="AT-SPI role name to match, e.g. 'push button', 'text'")
    parser_a11y.add_argument("--name", type=str, help="Substring of the accessible name to match (find/tree); text to set (type)")
    parser_a11y.add_argument("--depth", type=int, default=6, help="Max tree depth for 'tree'")
    parser_a11y.add_argument("--path", type=str, help="Comma-separated child-index path identifying an element, e.g. 0,2,1 (from find/tree output)")

    # browser
    parser_browser = subparsers.add_parser("browser", help="Browser automation via CDP agent-browser")
    parser_browser.add_argument("action", choices=["status", "open", "click", "type", "scroll", "extract", "screenshot", "pdf"], help="Browser action")
    parser_browser.add_argument("--url", type=str, help="Target URL")
    parser_browser.add_argument("--selector", type=str, help="CSS / DOM element selector")
    parser_browser.add_argument("--text", type=str, help="Input text for typing")

    # learn
    subparsers.add_parser("learn", help="Inspect Hyprland configs and update knowledge base")

    # doctor
    parser_doc = subparsers.add_parser(
        "doctor", help="Health-check every backend (at-spi, ydotool, hyprctl, grim, ...). Never runs sudo."
    )
    parser_doc.add_argument("--json", action="store_true", help="Emit JSON instead of a table")

    return parser.parse_args()

def main():
    args = parse_args()
    if not args.command:
        console.print("[yellow]No subcommand provided. Run `linux-automation --help` for usage.[/yellow]")
        sys.exit(0)

    if args.command == "screenshot":
        import screen
        screen.handle_cli(args)
    elif args.command == "ocr":
        import ocr
        ocr.handle_cli(args)
    elif args.command == "clipboard":
        import clipboard
        clipboard.handle_cli(args)
    elif args.command in ["window", "workspace", "monitor"]:
        import hyprland
        hyprland.handle_cli(args)
    elif args.command in ["mouse", "keyboard"]:
        import input
        input.handle_cli(args)
    elif args.command == "launch":
        import api
        target_ws = api.launch(args.app, workspace=args.workspace)
        console.print(f"[green]Launched on WS {target_ws} (max 2 apps/ws enforced): {args.app}[/green]")
    elif args.command == "a11y":
        import accessibility
        accessibility.handle_cli(args)
    elif args.command == "browser":
        import browser
        browser.handle_cli(args)
    elif args.command == "learn":
        import config_learner
        config_learner.handle_cli(args)
    elif args.command == "doctor":
        import doctor
        doctor.handle_cli(args)
    elif args.command == "notify":
        import os
        summary_esc = args.summary.replace('"', '\\"')
        body_esc = args.body.replace('"', '\\"')
        os.system(f'notify-send "{summary_esc}" "{body_esc}"')
    else:
        console.print("[red]Invalid command.[/red]")
        sys.exit(1)

if __name__ == "__main__":
    main()
