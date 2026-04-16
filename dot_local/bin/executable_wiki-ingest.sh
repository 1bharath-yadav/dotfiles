#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# wiki-ingest.sh wrapper
# Redirects to modular python backend allowing strict venv isolation
# =============================================================================

# Route via virtual environment
exec /home/archer/projects/office/.venv/bin/python /home/archer/projects/office/wiki_tools/ingest.py "$@"
