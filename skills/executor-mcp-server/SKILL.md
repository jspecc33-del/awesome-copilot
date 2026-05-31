---
name: executor-mcp-server
description: >
  Use the executor-mcp-server MCP tools to run bash commands, execute Python/JS/TS
  code snippets, make HTTP API calls, chain tool calls across multiple MCP servers,
  and inspect the sandbox environment. Trigger this skill when the user asks to run
  code, execute a script, make an API request, or chain tool operations — especially
  when sandboxed or isolated execution is needed. Also use for phrases like "run
  this in a sandbox", "execute this Python", "call this API", "chain these tools",
  or "what runtimes are available in the sandbox".
---

# Executor MCP Server

Five tools for sandboxed execution. The sandbox directory is isolated; all file
operations stay within it. Timeouts and output limits prevent runaway processes.

---

## `exec_bash` — Run shell commands

```json
{
  "tool": "exec_bash",
  "arguments": {
    "command": "ls -la && echo 'hello'",
    "working_dir": "subdir",
    "env": { "MY_VAR": "value" },
    "timeout_ms": 10000
  }
}
```

- `command` (required) — any bash command or pipeline
- `working_dir` — subdirectory inside the sandbox (no path traversal)
- `env` — extra environment variables merged with the sandbox env
- `timeout_ms` — override the server default timeout

Output format: `STDOUT:` / `STDERR:` / `EXIT_CODE:` blocks. `isError: true` when
exit code is non-zero or execution timed out.

**Common patterns:**
```bash
# Install a package inside the sandbox
pip install requests --target ./deps

# Run a script already in the sandbox
python3 myscript.py --flag value

# Pipe commands
cat data.csv | awk -F, '{print $2}' | sort | uniq -c
```

---

## `exec_code` — Execute code snippets

```json
{
  "tool": "exec_code",
  "arguments": {
    "language": "python",
    "code": "import math\nprint(math.sqrt(2))",
    "stdin": "optional input",
    "timeout_ms": 15000,
    "args": ["--verbose"]
  }
}
```

- `language` — `python`, `javascript`, or `typescript`
- `code` — the full source to execute (written to a temp file, then run)
- `stdin` — optional text fed to the process stdin
- `args` — CLI arguments passed after the script path
- `timeout_ms` — override timeout

On Linux the code runs inside `unshare -n` (network namespace isolation).
Output includes a `[Network isolated via unshare]` or warning line.

**Examples:**

Python data processing:
```python
import json, sys
data = json.load(sys.stdin)
result = sorted(data, key=lambda x: x['score'], reverse=True)
print(json.dumps(result[:5], indent=2))
```

JavaScript async:
```javascript
const res = await fetch('https://api.example.com/data');
const json = await res.json();
console.log(JSON.stringify(json, null, 2));
```

TypeScript (requires `tsx` or `ts-node` in the sandbox):
```typescript
interface Item { id: number; name: string }
const items: Item[] = [{ id: 1, name: 'foo' }, { id: 2, name: 'bar' }];
console.log(items.filter(i => i.id > 1));
```

---

## `exec_http` — HTTP API calls

```json
{
  "tool": "exec_http",
  "arguments": {
    "url": "https://api.example.com/items",
    "method": "POST",
    "headers": { "Authorization": "Bearer TOKEN" },
    "body": { "name": "test", "value": 42 },
    "timeout_ms": 10000,
    "response_format": "json"
  }
}
```

- `url` (required) — must pass the server's domain allow/block policy
- `method` — `GET` (default), `POST`, `PUT`, `PATCH`, `DELETE`, `HEAD`
- `headers` — merged with auto-set `Content-Type: application/json` when body is an object
- `body` — object (serialized to JSON) or string
- `response_format` — `auto` (default), `json`, or `text`

Output format: `STATUS:` / `HEADERS:` / `BODY:` blocks. `isError: true` when
status ≥ 400 or request fails.

**Patterns:**
```json
// Simple GET
{ "url": "https://httpbin.org/get" }

// Authenticated POST
{ "url": "https://api.github.com/repos/owner/repo/issues",
  "method": "POST",
  "headers": { "Authorization": "token ghp_xxx" },
  "body": { "title": "Bug report", "body": "Details..." } }
```

---

## `exec_chain` — Chain tool calls across MCP servers

Runs a sequence of MCP tool calls against any MCP servers (launched as subprocesses):

```json
{
  "tool": "exec_chain",
  "arguments": {
    "description": "Fetch data, process it, post results",
    "steps": [
      {
        "step_id": "fetch",
        "server_command": "node /path/to/executor/dist/index.js",
        "tool_name": "exec_http",
        "arguments": { "url": "https://api.example.com/data" },
        "on_error": "abort"
      },
      {
        "step_id": "process",
        "server_command": "node /path/to/executor/dist/index.js",
        "tool_name": "exec_code",
        "arguments": {
          "language": "python",
          "code": "import json,sys\ndata=json.load(sys.stdin)\nprint(json.dumps([x for x in data if x['active']]))"
        },
        "on_error": "continue"
      }
    ]
  }
}
```

- `description` — human-readable label for the chain
- `steps` — ordered list (max 10); each step spawns a fresh MCP subprocess
- `on_error` — `"abort"` stops the chain; `"continue"` skips failures and proceeds

Each step's result appears in the output under a `--- step_id ---` header.

---

## `exec_sandbox_info` — Inspect the environment

```json
{ "tool": "exec_sandbox_info", "arguments": {} }
```

Returns a JSON object with:
- `sandbox_dir`, `default_timeout_ms`, `max_output_bytes`
- `transport`, `http_port`
- `allowed_domains`, `blocked_domains`
- `platform`, `node_version`
- `runtimes` — availability of `bash`, `python3`, `node`, `tsx`, `ts-node`, `unshare`
- `env_vars` — current config env variables

Use this first to understand what's available before running code.

---

## Error Handling

All tools return `isError: true` when:
- Exit code is non-zero (`exec_bash`, `exec_code`)
- HTTP status ≥ 400 (`exec_http`)
- Domain blocked by policy (`exec_http`)
- Any step fails with `on_error: "abort"` (`exec_chain`)
- Timeout exceeded (any tool)

Timed-out results begin with `[TIMED OUT]`. Truncated output ends with
`[output truncated]`.
