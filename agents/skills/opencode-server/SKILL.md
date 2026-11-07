---
name: opencode-server
description: Manage, monitor, diagnose, and interact with the local OpenCode persistent server and background service (opencode-serve.service on port 4096). Make sure to use this skill whenever the user mentions starting, stopping, restarting, or debugging the OpenCode server, checking server status or journalctl logs, testing OpenCode API endpoints (/api/info, /api/model, /api/session, /api/experimental/generate/text), making authenticated REST calls to the local OpenCode instance, or troubleshooting systemd unit configuration.
---

# OpenCode Server Management (`opencode-server`)

Manage, inspect, and interact with the local persistent OpenCode API server running as a user-level systemd service (`opencode-serve.service`) on **port 4096**.

---

## 1. Architecture & Invariants

- **Persistent Service**: Systemd user service `opencode-serve.service` running `opencode serve --hostname 127.0.0.1 --port 4096`.
- **Authentication**: HTTP Basic Auth.
  - Username: `opencode` (default)
  - Password: Stored in `~/.config/opencode/server.env` under `OPENCODE_SERVER_PASSWORD`.
- **API Spec**: OpenCode V2 endpoints are prefixed with `/api/`. Full OpenAPI 3.1 specification is served at `http://127.0.0.1:4096/openapi.json`.
- **Dotfiles / Chezmoi Management**:
  - Service unit template: `~/.dotfiles/dot_config/systemd/user/opencode-serve.service`
  - Global config: `~/.dotfiles/dot_config/opencode/private_opencode.json` (deployed to `~/.config/opencode/opencode.json`)

---

## 2. Bundled CLI Helper (`opencode-server.sh`)

The skill includes a pre-authenticated helper script located at `scripts/opencode-server.sh`.

```bash
# Check service health and /api/info
~/.agents/skills/opencode-server/scripts/opencode-server.sh status

# Restart service and verify health
~/.agents/skills/opencode-server/scripts/opencode-server.sh restart

# View recent systemd journal logs (default 50 lines)
~/.agents/skills/opencode-server/scripts/opencode-server.sh logs 100

# Make an authenticated API request
~/.agents/skills/opencode-server/scripts/opencode-server.sh api GET /api/info
~/.agents/skills/opencode-server/scripts/opencode-server.sh api GET /api/model

# Run stateless text generation through a model
~/.agents/skills/opencode-server/scripts/opencode-server.sh generate "Hello from OpenCode" "antigravity-gemini-3.8-flash-low" "google"
```

---

## 3. Manual Service Commands

### Service Lifecycle
```bash
# Check status
systemctl --user status opencode-serve.service --no-pager

# Restart server
systemctl --user restart opencode-serve.service

# Stop / Start
systemctl --user stop opencode-serve.service
systemctl --user start opencode-serve.service
```

### Inspecting Logs
```bash
# Systemd journal logs
journalctl --user -u opencode-serve.service -n 50 --no-pager

# Follow logs in real time
journalctl --user -u opencode-serve.service -f

# Application debug logs
tail -n 100 ~/.local/share/opencode/log/opencode.log
```

---

## 4. Interacting with the OpenCode V2 API

Always authenticate requests with HTTP Basic Auth:

```bash
PASSWORD=$(grep OPENCODE_SERVER_PASSWORD ~/.config/opencode/server.env | cut -d= -f2)
BASE_URL="http://127.0.0.1:4096"
```

### Server Health & Info
```bash
curl -s -u "opencode:$PASSWORD" "$BASE_URL/api/info"
```

### List Models & Providers
```bash
curl -s -u "opencode:$PASSWORD" "$BASE_URL/api/model" | jq .
```

### Stateless Text Generation (`POST /api/experimental/generate/text`)
Note: In OpenCode V2, the `model` parameter is a structured object `{ providerID, id }`, not a bare string.

```bash
curl -s -u "opencode:$PASSWORD" -X POST "$BASE_URL/api/experimental/generate/text" \
  -H "Content-Type: application/json" \
  -d '{
    "prompt": "Hello world!",
    "model": {
      "providerID": "google",
      "id": "antigravity-gemini-3.8-flash-low"
    }
  }' | jq -r '.data.text'
```

### Create Session & Send Message
```bash
# Create a new session
SESSION=$(curl -s -u "opencode:$PASSWORD" -X POST "$BASE_URL/api/session" \
  -H "Content-Type: application/json" \
  -d '{"title": "Automated Session"}')
SESSION_ID=$(echo "$SESSION" | jq -r '.data.id')

# Send a prompt to the session
curl -s -u "opencode:$PASSWORD" -X POST "$BASE_URL/api/session/$SESSION_ID/prompt" \
  -H "Content-Type: application/json" \
  -d '{"text": "Hello, assist me with this task."}'
```

---

## 5. Troubleshooting & Known Gotchas

### False-Positive "Failed with result 'exit-code'" (Status 130)
- **Cause**: When stopped or restarted, OpenCode handles SIGINT and exits with code `130` (`128 + 2`). Systemd interprets code 130 as an error unless explicitly permitted.
- **Fix**: The service unit includes `SuccessExitStatus=0 130 143 SIGINT SIGTERM`. If modifying the service file, always keep this line in `[Service]`.

### Port 4096 in Use
- Check occupying process:
  ```bash
  ss -tulpn | grep 4096
  ```
- If another orphan `opencode serve` process is holding the port, terminate it before starting `opencode-serve.service`.

### Plugin Initialization Timing on Startup
- Immediately upon startup, plugins and MCP servers (such as `agentmemory`, `gitnexus`, `context7`) initialize asynchronously.
- During the first 2-5 seconds, calls to `/api/experimental/generate/text` may return:
  `{"_tag":"ServiceUnavailableError","message":"Location plugins did not finish activating"}`
- Allow a 3-second grace period after starting/restarting before sending inference queries.
