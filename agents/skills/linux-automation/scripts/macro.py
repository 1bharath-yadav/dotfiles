"""
Macro Recorder & Replayer for linux-automation.
Allows recording sequences of high-level actions and replaying them deterministically.
"""
import json
import time
from pathlib import Path
from rich.console import Console

import api

console = Console()

class MacroEngine:
    def __init__(self, filepath: str | Path | None = None):
        self.filepath = Path(filepath) if filepath else Path("/tmp/macro_last.json")
        self.steps = []

    def record(self, action_type: str, **kwargs):
        step = {
            "type": action_type,
            "params": kwargs,
            "timestamp": time.time()
        }
        self.steps.append(step)
        console.print(f"[dim]Macro recorded step:[/dim] {action_type} {kwargs}")

    def save(self, filepath: str | Path | None = None):
        target = Path(filepath) if filepath else self.filepath
        target.parent.mkdir(parents=True, exist_ok=True)
        with open(target, "w") as f:
            json.dump(self.steps, f, indent=2)
        console.print(f"[green]Macro saved to {target}[/green]")

    def load(self, filepath: str | Path | None = None):
        target = Path(filepath) if filepath else self.filepath
        with open(target, "r") as f:
            self.steps = json.load(f)
        console.print(f"[green]Loaded {len(self.steps)} macro steps from {target}[/green]")

    def replay(self, delay_multiplier: float = 1.0):
        console.print(f"[cyan]Replaying macro ({len(self.steps)} steps)...[/cyan]")
        results = []
        for i, step in enumerate(self.steps, 1):
            action_type = step["type"]
            params = step.get("params", {})
            console.print(f" [dim]Step {i}/{len(self.steps)}:[/dim] {action_type}")

            if action_type == "launch":
                api.launch(params["cmd"])
            elif action_type == "type":
                api.type_text(params["text"])
            elif action_type == "hotkey":
                api.hotkey(params["keys"])
            elif action_type == "focus":
                api.focus(params["target"])
            elif action_type == "click":
                api.click(params.get("x", 0), params.get("y", 0), params.get("button", "left"))
            elif action_type == "copy":
                api.copy(params["text"])
            elif action_type == "wait":
                time.sleep(params.get("seconds", 1.0) * delay_multiplier)
            elif action_type == "window_close":
                import hyprland
                hyprland.dispatch_lua('hl.dsp.window.close()')
            else:
                console.print(f"[yellow]Unknown macro step type: {action_type}[/yellow]")
            
            time.sleep(0.2 * delay_multiplier)
            results.append({"step": i, "type": action_type, "status": "ok"})
        return results
