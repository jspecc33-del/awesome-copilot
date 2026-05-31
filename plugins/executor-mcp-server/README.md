# executor-mcp-server

Universal sandboxed execution MCP server for Claude Code. Provides five tools for running bash commands, executing code snippets, making HTTP calls, chaining tool calls across servers, and inspecting the sandbox environment.

## Tools

| Tool | Description |
|------|-------------|
| `exec_bash` | Run any bash command in a sandbox directory |
| `exec_code` | Execute Python, JavaScript, or TypeScript snippets (network-isolated via `unshare` on Linux) |
| `exec_http` | Make HTTP API calls with domain allow/block-list policies |
| `exec_chain` | Chain multiple MCP tool calls across servers in sequence |
| `exec_sandbox_info` | Inspect runtimes, limits, and policies in the active sandbox |

## Quick Start

```bash
# Install and build
npm install
npm run build

# Run as stdio MCP server (default)
node dist/index.js

# Run as HTTP server
TRANSPORT=http PORT=3456 node dist/index.js
```

## Configuration

All settings are controlled via environment variables:

| Variable | Default | Description |
|----------|---------|-------------|
| `SANDBOX_DIR` | `./sandbox` | Working directory for all executions |
| `EXEC_TIMEOUT_MS` | `30000` | Default execution timeout (ms) |
| `MAX_OUTPUT_BYTES` | `524288` | Max stdout/stderr bytes per call (512 KB) |
| `ALLOWED_DOMAINS` | *(all)* | Comma-separated allowlist for `exec_http` |
| `BLOCKED_DOMAINS` | *(none)* | Comma-separated blocklist for `exec_http` |
| `TRANSPORT` | `stdio` | `stdio` or `http` |
| `PORT` | `3456` | HTTP port (only when `TRANSPORT=http`) |

## Add to Claude Code

Add to `.claude/settings.json`:

```json
{
  "mcpServers": {
    "executor": {
      "command": "node",
      "args": ["/path/to/executor-mcp-server/dist/index.js"],
      "env": {
        "SANDBOX_DIR": "/tmp/claude-sandbox",
        "EXEC_TIMEOUT_MS": "30000"
      }
    }
  }
}
```
