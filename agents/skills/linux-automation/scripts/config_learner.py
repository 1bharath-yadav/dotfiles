import os
import re
import json
import hashlib
from pathlib import Path
from rich.console import Console

console = Console()
KNOWLEDGE_DIR = Path(__file__).parent.parent / "knowledge"

def get_file_hash(filepath: Path) -> str:
    """Return SHA256 hash of a file."""
    if not filepath.exists(): return ""
    hasher = hashlib.sha256()
    with open(filepath, 'rb') as f:
        hasher.update(f.read())
    return hasher.hexdigest()

def extract_lua_binds(content: str):
    """
    Extract ``hl.bind("KEYS", action, { opts })`` calls from Lua config.

    Uses balanced-paren scanning rather than a naive regex, because the
    ``action`` argument is itself a Lua call containing nested parens and
    string literals (e.g. ``hl.dsp.exec_cmd("grim - | wl-copy")``). The
    old regex truncated at the first ``)`` and produced entries with
    unbalanced parens. This walks char-by-char respecting quotes and
    nesting depth so the extracted ``action`` is always complete.
    """
    binds = []
    needle = 'hl.bind('
    i = 0
    n = len(content)
    while True:
        start = content.find(needle, i)
        if start == -1:
            break
        # Position right after "hl.bind("
        j = start + len(needle)
        args, end = _scan_balanced_args(content, j)
        i = end
        if not args:
            continue
        keys = args[0].strip().strip('"').strip("'")
        action = args[1].strip() if len(args) > 1 else ""
        opts = args[2] if len(args) > 2 else ""
        desc = ""
        if opts:
            m = re.search(r'description\s*=\s*"([^"]+)"', opts)
            if m:
                desc = m.group(1)
        binds.append({"keys": keys, "action": action, "description": desc})
    return binds


def _scan_balanced_args(src: str, pos: int) -> tuple[list[str], int]:
    """
    Starting at ``pos`` (just inside the opening ``(`` of a call), split the
    call arguments on top-level commas, respecting quoted strings and nested
    ``()`` / ``{}`` / ``[]``. Returns (args, index_after_closing_paren).
    """
    args: list[str] = []
    depth = 0
    buf: list[str] = []
    quote = None
    i = pos
    n = len(src)
    while i < n:
        c = src[i]
        if quote:
            buf.append(c)
            if c == quote and src[i - 1] != '\\':
                quote = None
            i += 1
            continue
        if c in ('"', "'"):
            quote = c
            buf.append(c)
        elif c in '([{':
            depth += 1
            buf.append(c)
        elif c in ')]}':
            if depth == 0:
                # Closing paren of the hl.bind(...) call itself.
                if buf:
                    args.append(''.join(buf))
                return args, i + 1
            depth -= 1
            buf.append(c)
        elif c == ',' and depth == 0:
            args.append(''.join(buf))
            buf = []
        else:
            buf.append(c)
        i += 1
    return args, i

def learn_configs():
    """Parse Hyprland configs and rebuild knowledge cache."""
    KNOWLEDGE_DIR.mkdir(parents=True, exist_ok=True)
    cache_file = KNOWLEDGE_DIR / "cache.json"
    cache = {}
    if cache_file.exists():
        with open(cache_file, "r") as f:
            cache = json.load(f)

    hypr_dir = Path(os.path.expanduser("~/.config/hypr"))
    lua_files = list(hypr_dir.rglob("*.lua"))
    
    current_hashes = {str(f): get_file_hash(f) for f in lua_files}
    
    if cache.get("hashes") == current_hashes:
        console.print("[green]Configs unchanged. Cache is up to date.[/green]")
        return
        
    console.print("[yellow]Configs changed. Rebuilding knowledge base...[/yellow]")
    
    all_binds = []
    for f in lua_files:
        content = f.read_text(errors='ignore')
        all_binds.extend(extract_lua_binds(content))

    with open(KNOWLEDGE_DIR / "keybindings.json", "w") as f:
        json.dump(all_binds, f, indent=2)

    cache["hashes"] = current_hashes
    with open(cache_file, "w") as f:
        json.dump(cache, f, indent=2)
    console.print("[green]Knowledge base rebuilt successfully.[/green]")

def handle_cli(args):
    learn_configs()
