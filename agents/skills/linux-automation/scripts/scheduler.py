#!/usr/bin/env python3
"""
scheduler.py - Flock-based resource lock manager and task priority queue.
Manages hardware mutex locks (LOCK_MOUSE, LOCK_KEYBOARD, LOCK_CLIPBOARD)
under /run/user/$UID/linux-automation/.
"""
import os
import sys
import fcntl
import json
import time
from typing import Dict, Any, Optional

def get_lock_dir() -> str:
    uid = str(os.getuid())
    lock_dir = f"/run/user/{uid}/linux-automation"
    os.makedirs(lock_dir, exist_ok=True)
    return lock_dir

class HardwareLock:
    def __init__(self, resource_name: str, timeout: float = 10.0):
        self.resource_name = resource_name
        self.timeout = timeout
        self.lock_dir = get_lock_dir()
        self.lock_file = os.path.join(self.lock_dir, f"{resource_name}.lock")
        self._fd: Optional[int] = None

    def acquire(self) -> bool:
        start_time = time.time()
        self._fd = os.open(self.lock_file, os.O_CREAT | os.O_RDWR)
        while True:
            try:
                fcntl.flock(self._fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
                os.write(self._fd, f"PID:{os.getpid()} TIME:{time.time()}\n".encode())
                return True
            except (BlockingIOError, IOError):
                if time.time() - start_time >= self.timeout:
                    return False
                time.sleep(0.1)

    def release(self):
        if self._fd is not None:
            try:
                fcntl.flock(self._fd, fcntl.LOCK_UN)
                os.close(self._fd)
            except Exception:
                pass
            self._fd = None

def main():
    if len(sys.argv) < 3:
        print("Usage: scheduler.py <acquire|release|status> <mouse|keyboard|clipboard> [timeout_sec]")
        sys.exit(1)
    
    action = sys.argv[1]
    resource = sys.argv[2]
    timeout = float(sys.argv[3]) if len(sys.argv) > 3 else 5.0
    
    lock = HardwareLock(resource, timeout)
    if action == "acquire":
        ok = lock.acquire()
        print(json.dumps({"status": "acquired" if ok else "timeout", "resource": resource}))
        if not ok:
            sys.exit(1)
    elif action == "release":
        lock.release()
        print(json.dumps({"status": "released", "resource": resource}))

if __name__ == "__main__":
    main()
