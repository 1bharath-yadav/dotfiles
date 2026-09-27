# archmcp

`archmcp` is the dotfiles-managed bridge for attaching local MCP servers to ChatGPT through one OpenAI Secure MCP Tunnel.

## Architecture

```text
~/.config/archmcp/mcp.json
        │
        ▼
     archmcp CLI
        │
        ▼
 generated tunnel-client profile
        │
        ▼
one OpenAI Secure MCP Tunnel
        │
   ┌────┼─────────┐
   ▼    ▼         ▼
  MCP  MCP       MCP ...
```

The JSON file is the source of truth. The generated YAML profile is runtime state and should not be edited manually.

## Configuration

The user config is `~/.config/archmcp/mcp.json` and follows the familiar Claude Desktop / VS Code `mcpServers` shape.

HTTP MCP:

```json
{
  "mcpServers": {
    "filesystem": {
      "type": "http",
      "url": "http://127.0.0.1:3001/mcp"
    }
  }
}
```

Stdio MCP:

```json
{
  "mcpServers": {
    "browser": {
      "command": "npx",
      "args": ["-y", "example-mcp-server"],
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

HTTP entries may also define `headers`. Stdio entries use `command`, `args`, and optional `env`.
## CLI

```bash
archmcp list
archmcp get NAME
archmcp add NAME --url http://127.0.0.1:3000/mcp
archmcp add NAME --command npx --arg -y --arg example-mcp-server
archmcp add NAME --command npx --arg -y --arg example-mcp-server --env KEY=value
archmcp remove NAME
archmcp restart
archmcp status
archmcp enable
archmcp disable
```

`archmcp add` edits `mcp.json`, regenerates the tunnel profile, and restarts the single tunnel service. Removing a server does the same. Direct edits to `mcp.json` are supported; run `archmcp restart` afterward to compile the changes.

## OpenAI tunnel

`~/.env` supplies the existing tunnel credentials:

```text
CONTROL_PLANE_TUNNEL_ID
CONTROL_PLANE_API_KEY
```

`archmcp` and `archmcp.service` source `~/.env` rather than storing these secrets in the dotfiles repository. Never copy either value into `mcp.json` or the generated profile.

The runtime profile is generated at:

```text
~/.local/state/archmcp/tunnel-client/archmcp.yaml
```

The service uses `tunnel-client run --profile-file ...`; `--profile` is a profile name and must not be given a filesystem path.

## systemd

The persistent user service is:

```text
~/.config/systemd/user/archmcp.service
```

After a dotfiles update:

```bash
systemctl --user daemon-reload
archmcp enable
archmcp status
```

The service restarts automatically on failure. The MCP registry can be changed without manually managing tunnel processes.

## Adding MCPs

Prefer a stable, descriptive channel/server name because that name becomes the tunnel-client MCP channel identifier.

For HTTP MCP servers:

```bash
archmcp add github --url http://127.0.0.1:5001/mcp
```

For stdio servers:

```bash
archmcp add browser --command npx --arg -y --arg '@playwright/mcp'
```

For environment variables:

```bash
archmcp add service --command python --arg server.py --env API_MODE=local
```

For HTTP headers:

```bash
archmcp add api --url https://example.internal/mcp --header 'Authorization: Bearer ...'
```

Do not commit bearer tokens, API keys, passwords, or other credentials in `mcp.json`. Prefer environment-backed authentication where the MCP server supports it.

## Direct JSON editing

Example multi-server registry:

```json
{
  "mcpServers": {
    "filesystem": {
      "type": "http",
      "url": "http://127.0.0.1:3001/mcp"
    },
    "browser": {
      "command": "npx",
      "args": ["-y", "@playwright/mcp"],
      "env": {
        "NODE_ENV": "production"
      }
    }
  }
}
```

After editing:

```bash
archmcp restart
```

`archmcp list` reads the JSON registry; it does not inspect or modify individual MCP processes directly.
