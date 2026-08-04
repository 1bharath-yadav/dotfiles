import os
import subprocess
from rich.console import Console

console = Console()

AGENT_BROWSER_BIN = "/home/archer/.openagents/nodejs/bin/agent-browser"

def run_agent_browser(args: list[str]) -> str:
    if not os.path.exists(AGENT_BROWSER_BIN):
        console.print("[red]agent-browser binary not found![/red]")
        return ""
    try:
        # Pass --auto-connect flag if available or run command
        res = subprocess.run([AGENT_BROWSER_BIN, "--auto-connect", *args], capture_output=True, text=True, timeout=15)
        if res.returncode != 0:
            # Fall back without --auto-connect if flag failed
            res = subprocess.run([AGENT_BROWSER_BIN, *args], capture_output=True, text=True, timeout=15)
        return res.stdout.strip()
    except subprocess.CalledProcessError as e:
        console.print(f"[red]agent-browser error:[/red] {e.stderr}")
        return ""
    except Exception as e:
        console.print(f"[red]agent-browser exception:[/red] {e}")
        return ""

def handle_cli(args):
    if args.action == "status":
        out = run_agent_browser(["snapshot"])
        console.print(out)
    elif args.action == "open":
        if args.url:
            out = run_agent_browser(["open", args.url])
            console.print(out)
        else:
            console.print("[red]URL required (--url).[/red]")
    elif args.action == "click":
        if args.selector:
            out = run_agent_browser(["click", args.selector])
            console.print(out)
    elif args.action == "type":
        if args.selector and args.text:
            out = run_agent_browser(["fill", args.selector, args.text])
            console.print(out)
    elif args.action == "scroll":
        out = run_agent_browser(["wait", "1000"])
        console.print(out)
    elif args.action == "extract":
        out = run_agent_browser(["snapshot"])
        console.print(out)
    elif args.action == "screenshot":
        out = run_agent_browser(["screenshot"])
        console.print(out)
    elif args.action == "pdf":
        out = run_agent_browser(["screenshot", "--full"])
        console.print(out)

