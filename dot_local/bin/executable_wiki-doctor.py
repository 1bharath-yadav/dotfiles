#!/usr/bin/env python3
import sys
import subprocess

# Reroute directly to the modular linter using the strict venv
cmd = ["/home/archer/projects/office/.venv/bin/python", "/home/archer/projects/office/wiki_tools/lint.py"]
sys.exit(subprocess.run(cmd).returncode)
