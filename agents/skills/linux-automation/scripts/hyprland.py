import json
import subprocess
from rich.console import Console

console = Console()

def run_hyprctl(command: str) -> str:
    """Run a hyprctl command and return stdout string."""
    try:
        result = subprocess.run(["hyprctl", *command.split()], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        # Fall back to passing single argument if spaces need quoting
        try:
            result = subprocess.run(["hyprctl", command], capture_output=True, text=True, check=True)
            return result.stdout.strip()
        except subprocess.CalledProcessError:
            console.print(f"[red]hyprctl error:[/red] {e.stderr}")
            return ""

def get_json(command: str):
    """Run a hyprctl JSON command and return parsed output."""
    output = run_hyprctl(f"-j {command}")
    try:
        return json.loads(output) if output else None
    except json.JSONDecodeError:
        return None

def dispatch_lua(expression: str):
    """
    Execute a Hyprland *dispatcher* expression via the Hyprlua config layer,
    e.g. ``hl.dsp.focus({ workspace = "3" })``. Use this for the user-facing
    binds defined in this setup (dots-hyprland / Hyprlua ``hl.dsp.*``).
    """
    try:
        result = subprocess.run(["hyprctl", "dispatch", expression], capture_output=True, text=True, check=True)
        return result.stdout.strip()
    except subprocess.CalledProcessError as e:
        console.print(f"[red]dispatch error:[/red] {e.stderr}")
        return ""


def dispatch(expression: str):
    """
    Raw ``hyprctl dispatch <expr>`` for plain Hyprland keywords that are not
    part of the Hyprlua ``hl.dsp.*`` surface, e.g. ``"resizeactive 10 0"``
    or ``"movefocus l"``. Prefer :func:`dispatch_lua` for binds you see in
    your config.
    """
    return dispatch_lua(expression)


def resize_window(width_delta: int = 0, height_delta: int = 0):
    """
    Resize the active window by a delta in pixels (Hyprland's
    ``resizeactive`` takes signed deltas). Positive grows, negative shrinks.
    """
    return dispatch_lua(f"resizeactive {width_delta} {height_delta}")

def focus_workspace(target: str):
    """Focus workspace using system hl.dsp focus."""
    dispatch_lua(f'hl.dsp.focus({{ workspace = "{target}" }})')

def focus_window(target: str):
    """Focus window by address, title, or class."""
    if not target.startswith("address:") and not target.startswith("class:") and not target.startswith("title:"):
        # Check if target is address (0x...)
        if target.startswith("0x"):
            target = f"address:{target}"
        else:
            target = f"class:{target}"
    dispatch_lua(f'hl.dsp.focus({{ window = "{target}" }})')

def toggle_special(scratchpad: str):
    """Toggle special workspace scratchpad."""
    dispatch_lua(f'hl.dsp.workspace.toggle_special("{scratchpad}")')

def get_workspace_window_counts():
    """Return a mapping of numeric workspace ID -> list of client windows."""
    clients = get_json("clients") or []
    counts = {}
    for c in clients:
        ws = c.get("workspace", {})
        ws_id = ws.get("id")
        # Only count regular numeric workspaces (id > 0)
        if isinstance(ws_id, int) and ws_id > 0:
            counts.setdefault(ws_id, []).append(c)
    return counts

def find_planned_or_available_workspace(preferred: str | int | None = None) -> str:
    """
    Find a planned or available workspace that has fewer than 2 mapped windows.
    If preferred is specified and has < 2 windows, return str(preferred).
    Otherwise, find the first numeric workspace (1, 2, 3, ...) with < 2 windows.
    """
    counts = get_workspace_window_counts()
    if preferred is not None:
        try:
            pref_id = int(preferred)
            if len(counts.get(pref_id, [])) < 2:
                return str(pref_id)
        except (ValueError, TypeError):
            pass

    for ws in range(1, 11):
        if len(counts.get(ws, [])) < 2:
            return str(ws)
    return "1"

def organize_workspaces():
    """
    Organize mapped windows across workspaces so that no workspace has more than 2 windows.
    Moves excess windows to available workspaces (max 2 per workspace).
    """
    counts = get_workspace_window_counts()
    reorganized = []
    
    for ws_id, windows in list(counts.items()):
        if len(windows) > 2:
            excess = windows[2:]
            for win in excess:
                addr = win.get("address")
                cls = win.get("class") or win.get("title") or "window"
                target_ws = find_planned_or_available_workspace()
                dispatch_lua(f'hl.dsp.window.move({{ window = "address:{addr}", workspace = "{target_ws}" }})')
                reorganized.append(f"{cls} -> WS {target_ws}")
                counts.setdefault(int(target_ws), []).append(win)

    return reorganized

def handle_cli(args):
    if args.command == "window":
        if args.action == "active":
            data = get_json("activewindow")
            console.print_json(data=data)
        elif args.action == "list":
            data = get_json("clients")
            console.print_json(data=data)
        elif args.action == "focus":
            target = args.target if args.target else ""
            focus_window(target)
        elif args.action == "move":
            # move expects "x y" or a workspace ref; pass target verbatim.
            if args.target:
                dispatch_lua(f'hl.dsp.window.move({{ workspace = "{args.target}" }})')
        elif args.action == "resize":
            # target like "10 0" or "-20 -20" -> pixel deltas (w h).
            parts = (args.target or "").split()
            if len(parts) == 2:
                resize_window(int(parts[0]), int(parts[1]))
            else:
                console.print("[red]resize target must be 'Wdelt Hdelt', e.g. '10 0'[/red]")
        elif args.action == "close":
            dispatch_lua('hl.dsp.window.close()')
        elif args.action == "kill":
            dispatch_lua('hl.dsp.exec_cmd("hyprctl kill")')
        elif args.action == "float":
            dispatch_lua('hl.dsp.window.float({ action = "toggle" })')
        elif args.action == "fullscreen":
            dispatch_lua('hl.dsp.window.fullscreen({ mode = "fullscreen", action = "toggle" })')
        elif args.action == "maximize":
            dispatch_lua('hl.dsp.window.fullscreen({ mode = "maximized", action = "toggle" })')
        elif args.action == "minimize":
            dispatch_lua('hl.dsp.window.move({ workspace = "special:minimized", follow = false })')

    elif args.command == "workspace":
        if args.action == "list":
            data = get_json("workspaces")
            console.print_json(data=data)
        elif args.action == "focus":
            focus_workspace(args.target)
        elif args.action == "movetoworkspace":
            dispatch_lua(f'hl.dsp.window.move({{ workspace = "{args.target}" }})')
        elif args.action == "toggle_special":
            target = args.target if args.target else "special"
            toggle_special(target)
        elif args.action == "organize":
            moved = organize_workspaces()
            if moved:
                console.print(f"[green]Reorganized workspaces (max 2 per workspace):[/green] {', '.join(moved)}")
            else:
                console.print("[green]Workspaces are organized (max 2 windows per workspace).[/green]")

    elif args.command == "monitor":
        if args.action == "list":
            data = get_json("monitors")
            console.print_json(data=data)
        elif args.action == "active":
            active_ws = get_json("activeworkspace")
            mon_id = active_ws.get("monitorID", 0) if active_ws else 0
            monitors = get_json("monitors")
            active_mon = next((m for m in monitors if m.get("id") == mon_id), monitors[0] if monitors else {})
            console.print_json(data=active_mon)
        elif args.action == "focus":
            dispatch_lua(f'hl.dsp.focus({{ monitor = "{args.target}" }})')

