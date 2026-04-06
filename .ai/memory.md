Python snippets

If you are recreating MemFS in your own app, the simplest backend approach is to implement it as a git-backed markdown repo on disk, because that matches Letta Code’s documented model closely. Letta says MemFS is stored in a local path like ~/.letta/agents/<agent-id>/memory and saved through git commits.
1. Create a MemFS repo for an agent

python
from pathlib import Path
import subprocess

def memfs_path(agent_id: str) -> Path:
    return Path.home() / ".myapp" / "agents" / agent_id / "memory"

def init_memfs(agent_id: str) -> Path:
    root = memfs_path(agent_id)
    (root / "system").mkdir(parents=True, exist_ok=True)
    (root / "reflections").mkdir(parents=True, exist_ok=True)
    (root / "preferences").mkdir(parents=True, exist_ok=True)
    (root / "tasks").mkdir(parents=True, exist_ok=True)

    if not (root / ".git").exists():
        subprocess.run(["git", "init"], cwd=root, check=True)
        subprocess.run(["git", "branch", "-M", "main"], cwd=root, check=True)

    return root

2. Create a memory file

python
from pathlib import Path

def write_memory_file(agent_id: str, rel_path: str, description: str, body: str, read_only: bool = False):
    root = memfs_path(agent_id)
    path = root / rel_path
    path.parent.mkdir(parents=True, exist_ok=True)

    content = f"""---
description: {description}
read_only: {"true" if read_only else "false"}
---

{body}
"""
    path.write_text(content, encoding="utf-8")
    return str(path)

Usage:

python
init_memfs("agent_123")

write_memory_file(
    "agent_123",
    "system/persona.md",
    "Stores the assistant persona and behavior.",
    "You are a precise engineering assistant. Prefer clean APIs and minimal ambiguity."
)

write_memory_file(
    "agent_123",
    "preferences/ui.md",
    "Stores UI and product preferences learned over time.",
    "User prefers editable tables, keyboard shortcuts, and split-pane layouts."
)

3. Read a memory file

python
from pathlib import Path

def read_memory_file(agent_id: str, rel_path: str) -> str:
    path = memfs_path(agent_id) / rel_path
    return path.read_text(encoding="utf-8")

Usage:

python
text = read_memory_file("agent_123", "system/persona.md")
print(text)

4. List the memory tree

python
from pathlib import Path

def list_memory_files(agent_id: str):
    root = memfs_path(agent_id)
    return sorted(
        str(p.relative_to(root))
        for p in root.rglob("*.md")
        if ".git" not in p.parts
    )

Usage:

python
files = list_memory_files("agent_123")
for f in files:
    print(f)

5. Update a memory file

python
def update_memory_file(agent_id: str, rel_path: str, new_body: str):
    path = memfs_path(agent_id) / rel_path
    raw = path.read_text(encoding="utf-8")

    if raw.startswith("---"):
        _, frontmatter, body = raw.split("---", 2)
        updated = f"---{frontmatter}---\n{new_body.lstrip()}"
    else:
        updated = new_body

    path.write_text(updated, encoding="utf-8")
    return str(path)

Usage:

python
update_memory_file(
    "agent_123",
    "tasks/current-focus.md",
    "Current priorities:\n- Build CRUD UI for MemFS\n- Add git history browser\n- Add pinned-memory indicators\n"
)

6. Delete a memory file

python
def delete_memory_file(agent_id: str, rel_path: str):
    path = memfs_path(agent_id) / rel_path
    if path.exists():
        path.unlink()
        return True
    return False

7. Commit changes to git

python
import subprocess

def git_commit_memfs(agent_id: str, message: str):
    root = memfs_path(agent_id)
    subprocess.run(["git", "add", "."], cwd=root, check=True)
    subprocess.run(["git", "commit", "-m", message], cwd=root, check=True)

Usage:

python
git_commit_memfs("agent_123", "Update persona and UI preferences")

This matches Letta’s documented MemFS workflow where memory edits are saved via git commits so they can affect the agent’s effective memory state.
8. Show git history in the UI

python
import subprocess

def git_log_memfs(agent_id: str, limit: int = 20):
    root = memfs_path(agent_id)
    result = subprocess.run(
        ["git", "log", f"--max-count={limit}", "--pretty=format:%H|%ad|%s", "--date=iso"],
        cwd=root,
        check=True,
        capture_output=True,
        text=True,
    )
    rows = []
    for line in result.stdout.splitlines():
        commit_hash, date, message = line.split("|", 2)
        rows.append({
            "hash": commit_hash,
            "date": date,
            "message": message,
        })
    return rows

9. Roll back a file to an older revision

python
import subprocess

def restore_file_from_commit(agent_id: str, commit_hash: str, rel_path: str):
    root = memfs_path(agent_id)
    subprocess.run(
        ["git", "checkout", commit_hash, "--", rel_path],
        cwd=root,
        check=True,
    )

Versioning and rollback are one of the key advantages Letta attributes to MemFS over legacy blocks.