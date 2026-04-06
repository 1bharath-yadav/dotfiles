"""Memory commands: /blocks, /passages, /memory, /memfs"""

from __future__ import annotations
import json
import os
import subprocess
import time
from pathlib import Path

from letta_client import Letta
from letta_client import APIStatusError as ApiError


# ── /memfs — Letta cloud folder/file API ─────────────────────────────────────

_fs_cache: dict = {"time": 0, "tree": None}


def cmd_fs(client: Letta, agent_id: str, args: str = "") -> str:
    global _fs_cache

    parts = args.strip().split(maxsplit=1)
    subcmd = parts[0] if parts else ""
    rest = parts[1] if len(parts) > 1 else ""

    if subcmd == "mkdir":
        if not rest:
            return "Usage: /memfs mkdir <name>"
        try:
            folder = client.folders.create(name=rest)
            _fs_cache["time"] = 0
            return f"[OK] Created folder '{rest}' (id={folder.id})"
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    if subcmd == "rmdir":
        if not rest:
            return "Usage: /memfs rmdir <id>"
        try:
            client.folders.delete(folder_id=rest)
            _fs_cache["time"] = 0
            return f"[OK] Deleted folder {rest}"
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    if subcmd == "upload":
        sp = rest.split(maxsplit=1)
        if len(sp) < 2:
            return "Usage: /memfs upload <folder_id> <filepath>"
        f_id, path = sp
        try:
            with open(path, "rb") as fh:
                uploaded = client.folders.files.upload(folder_id=f_id, file=fh)
            _fs_cache["time"] = 0
            return f"[OK] Uploaded to {f_id} (id={uploaded.id})"
        except Exception as e:
            return f"[ERROR] Upload failed: {e}"

    if subcmd == "rmfile":
        sp = rest.split(maxsplit=1)
        if len(sp) < 2:
            return "Usage: /memfs rmfile <folder_id> <file_id>"
        f_id, file_id = sp
        try:
            client.folders.files.delete(folder_id=f_id, file_id=file_id)
            _fs_cache["time"] = 0
            return f"[OK] Deleted file {file_id}"
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    # Default / json: return tree JSON
    if time.time() - _fs_cache["time"] > 10 or not _fs_cache["tree"]:
        try:
            folders = list(client.folders.list())
            tree: dict = {"type": "fs_tree", "folders": []}
            for folder in folders:
                fd = {
                    "id": folder.id,
                    "name": getattr(folder, "name", "Unnamed"),
                    "files": [],
                }
                try:
                    for f in list(client.folders.files.list(folder_id=folder.id)):
                        fd["files"].append({
                            "id": f.id,
                            "name": getattr(f, "name", getattr(f, "file_name", "Unknown")),
                        })
                except Exception:
                    pass
                tree["folders"].append(fd)
            _fs_cache["tree"] = tree
            _fs_cache["time"] = time.time()
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    if subcmd in ("json", "fs_tree", ""):
        return json.dumps(_fs_cache["tree"])

    # Human-readable fallback
    tree = _fs_cache["tree"]
    lines = [f"[MEMFS] {len(tree['folders'])} folder(s)"]
    for f in tree["folders"]:
        lines.append(f"  {f['name']} ({f['id']})")
        for fi in f["files"]:
            lines.append(f"    {fi['name']} ({fi['id']})")
    return "\n".join(lines)


# ── /memory — local git-backed memory filesystem ─────────────────────────────

def _mem_root(agent_id: str) -> Path:
    return Path.home() / ".letta" / "agents" / agent_id / "memory"


def _ensure_init(root: Path) -> None:
    root.mkdir(parents=True, exist_ok=True)
    if not (root / ".git").exists():
        subprocess.run(["git", "init"], cwd=root, check=True, capture_output=True)
        try:
            subprocess.run(["git", "branch", "-M", "main"], cwd=root,
                           check=True, capture_output=True)
        except subprocess.CalledProcessError:
            pass


def _build_tree(root: Path) -> dict:
    """Walk root and build nested folder/file tree, excluding .git."""
    all_files = sorted(
        p for p in root.rglob("*")
        if p.is_file() and ".git" not in p.parts and ".letta" not in p.parts
    )

    # Build a dict of folder_rel_path -> list of file entries
    folders: dict[str, dict] = {}
    for p in all_files:
        rel = p.relative_to(root)
        # folder = parent relative to root (may be nested like "reference/dotfiles")
        folder_rel = str(rel.parent) if str(rel.parent) != "." else ""
        if folder_rel not in folders:
            folders[folder_rel] = {
                "id": folder_rel or "root",
                "name": folder_rel or "(root)",
                "files": [],
            }
        folders[folder_rel]["files"].append({
            "id": str(rel),          # relative path — unique id
            "name": p.name,
        })

    # Sort folders: root first, then alphabetical
    ordered = sorted(folders.values(), key=lambda f: ("" if f["id"] == "root" else f["id"]))
    return {"type": "memory_tree", "root": str(root), "folders": ordered}


def cmd_memory(client: Letta, agent_id: str, args: str = "") -> str:
    """Local git-backed memory tree at ~/.letta/agents/{id}/memory/.

    /memory              — human-readable tree
    /memory json         — JSON tree for UI
    /memory read <rel>   — read file contents
    /memory write <rel>  — write file (content from stdin placeholder)
    /memory mkdir <rel>  — create directory
    /memory rmdir <rel>  — remove directory tree
    /memory delete <rel> — delete a file
    /memory commit [msg] — git commit all changes
    /memory log          — git log (last 10)
    /memory init         — force re-initialise git repo
    """
    if not agent_id:
        return "[ERROR] No active agent."

    root = _mem_root(agent_id)
    parts = args.strip().split(maxsplit=1)
    subcmd = parts[0] if parts else ""
    rest = parts[1] if len(parts) > 1 else ""

    # ── init ────────────────────────────────────────────────────────────────
    if subcmd == "init":
        _ensure_init(root)
        return f"[OK] Memory repo ready at {root}"

    # ── json / (default) ────────────────────────────────────────────────────
    if subcmd in ("json", ""):
        _ensure_init(root)
        tree = _build_tree(root)
        return json.dumps(tree)

    # ── human list ──────────────────────────────────────────────────────────
    if subcmd == "list":
        _ensure_init(root)
        tree = _build_tree(root)
        if not tree["folders"]:
            return "[MEMORY] Empty — no files yet."
        lines = [f"[MEMORY] {root}"]
        for folder in tree["folders"]:
            lines.append(f"  {folder['name']}/")
            for f in folder["files"]:
                lines.append(f"    {f['name']}")
        return "\n".join(lines)

    # ── read ────────────────────────────────────────────────────────────────
    if subcmd == "read":
        if not rest:
            return "Usage: /memory read <relative-path>"
        p = root / rest
        if not p.exists():
            return f"[ERROR] Not found: {rest}"
        return p.read_text(encoding="utf-8")

    # ── write ────────────────────────────────────────────────────────────────
    if subcmd == "write":
        sp = rest.split(maxsplit=1)
        if len(sp) < 2:
            return "Usage: /memory write <relative-path> <content>"
        rel, content = sp
        p = root / rel
        p.parent.mkdir(parents=True, exist_ok=True)
        p.write_text(content, encoding="utf-8")
        return f"[OK] Written: {rel}"

    # ── mkdir ────────────────────────────────────────────────────────────────
    if subcmd == "mkdir":
        if not rest:
            return "Usage: /memory mkdir <relative-dir>"
        d = root / rest
        d.mkdir(parents=True, exist_ok=True)
        (d / ".gitkeep").touch()
        return f"[OK] Created dir: {rest}"

    # ── rmdir ────────────────────────────────────────────────────────────────
    if subcmd == "rmdir":
        if not rest:
            return "Usage: /memory rmdir <relative-dir>"
        import shutil
        d = root / rest
        if d.exists() and d.is_dir():
            shutil.rmtree(d)
            return f"[OK] Removed: {rest}"
        return f"[ERROR] Directory not found: {rest}"

    # ── delete ────────────────────────────────────────────────────────────────
    if subcmd in ("delete", "rmfile"):
        if not rest:
            return "Usage: /memory delete <relative-path>"
        p = root / rest
        if p.exists() and p.is_file():
            p.unlink()
            return f"[OK] Deleted: {rest}"
        return f"[ERROR] File not found: {rest}"

    # ── commit ────────────────────────────────────────────────────────────────
    if subcmd == "commit":
        msg = rest or "Update memory"
        try:
            subprocess.run(["git", "add", "."], cwd=root, check=True, capture_output=True)
            res = subprocess.run(
                ["git", "commit", "-m", msg], cwd=root,
                capture_output=True, text=True
            )
            if res.returncode == 0:
                return f"[OK] Committed: {msg}"
            return f"[INFO] {res.stdout.strip() or res.stderr.strip()}"
        except subprocess.CalledProcessError as e:
            return f"[ERROR] git failed: {e}"

    # ── log ────────────────────────────────────────────────────────────────
    if subcmd == "log":
        try:
            res = subprocess.run(
                ["git", "log", "--max-count=10", "--pretty=format:%h %s (%ar)"],
                cwd=root, capture_output=True, text=True, check=True
            )
            return res.stdout or "[INFO] No commits yet."
        except subprocess.CalledProcessError:
            return "[INFO] Not a git repo or no commits yet."

    return "Usage: /memory [json|list|read|write|mkdir|rmdir|delete|commit|log|init]"


# ── /passages — archival memory passages ─────────────────────────────────────

def cmd_passages(client: Letta, agent_id: str, args: str = "") -> str:
    """Manage archival memory passages.

    /passages              — list 10 most recent passages
    /passages <query>      — semantic search (top 5)
    /passages add <text>   — insert a new passage
    """
    if not agent_id:
        return "[ERROR] No active agent. Use /resume <id> first."

    parts = args.strip().split(maxsplit=1)
    subcmd = parts[0] if parts else ""
    rest = parts[1] if len(parts) > 1 else ""

    if subcmd == "add":
        if not rest:
            return "Usage: /passages add <text>"
        try:
            results = client.agents.passages.create(agent_id=agent_id, text=rest)
            passage = results[0]
            return f"[OK] Passage inserted (id={passage.id})."
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    if subcmd:
        query = args.strip()
        try:
            results = list(client.agents.passages.list(
                agent_id=agent_id, query_text=query, limit=5))
            if not results:
                return f"No passages found for '{query}'."
            lines = [f"[SEARCH] '{query}' — {len(results)} result(s)"]
            for passage in results:
                score_str = f"  score={passage.score:.3f}" if getattr(passage, "score", None) is not None else ""
                preview = passage.text[:120].replace("\n", " ")
                lines.append(f"  •{score_str}  {preview}")
            return "\n".join(lines)
        except ApiError as e:
            return f"[ERROR] {e.status_code}: {e.body}"

    # List recent
    try:
        results = list(client.agents.passages.list(agent_id=agent_id, limit=10))
        if not results:
            return "No archival passages found."
        lines = [f"[PASSAGES] {len(results)} recent passage(s)"]
        for passage in results:
            preview = passage.text[:100].replace("\n", " ")
            lines.append(f"  • {preview}")
        return "\n".join(lines)
    except ApiError as e:
        return f"[ERROR] {e.status_code}: {e.body}"
