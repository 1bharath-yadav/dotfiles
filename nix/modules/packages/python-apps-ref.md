# ~/apps migration reference — 2026-03-28

# These were in apps/global/pyproject.toml (mega-venv, now retired)

# Reinstall strategy per tool:

# ── via uv tool install (global CLI tools, live in ~/.local/bin) ──────────────

# uv tool install marimo # interactive notebooks

# uv tool install euporie # terminal jupyter frontend

# uv tool install jupyter # classic jupyter lab/notebook

# uv tool install piper-tts --with pathvalidate

# ── via , (comma / nix run) — ephemeral, no install needed ──────────────────

# , manim # math animation

# , duckdb # SQL CLI

# ── in a project's pyproject.toml (never global) ────────────────────────────

# pandas, seaborn, duckdb → data analysis projects

# tensorflow-cpu, keras → ML projects

# openvino → inference projects

# ipykernel → any project that needs jupyter kernel

# ── open-webui ───────────────────────────────────────────────────────────────

# Managed as a systemd user service or via Nix (services.open-webui)

# Secret moved to: ~/.config/open-webui/.webui_secret_key
