#!/usr/bin/env python3
import json
import sys
import os

from letta_client import Letta
from letta_assistant.services import letta_service
from letta_assistant import config as app_cfg

def main():
    if len(sys.argv) < 2:
        print(json.dumps({"error": "No command"}))
        sys.exit(1)

    cmd = sys.argv[1]

    try:
        cfg = app_cfg.load()
        if not cfg.get("base_url"):
            # Assume local setup, fallback to empty defaults if missing
            pass
            
        client = letta_service.init_client()
        
        if cmd == "models":
            models = list(client.models.list())
            res = []
            for m in models:
                mid = m.handle or m.model
                res.append(mid)
            print(json.dumps({"success": True, "data": res}))
            
        elif cmd == "agents":
            agents = list(client.agents.list())
            res = [{"id": a.id, "name": a.name or "Unnamed"} for a in agents]
            print(json.dumps({"success": True, "data": res}))
            
        else:
            print(json.dumps({"error": "Unknown command"}))
            
    except Exception as e:
        print(json.dumps({"error": str(e), "success": False}))

if __name__ == "__main__":
    main()
