---
name: postcli
description: >
  Build, extend, and work with postcli — a Python CLI tool that replicates
  Postman's full environment variable system and runs Postman collection
  exports (v2.1) from the command line. Trigger this skill when the user
  wants to: add new CLI commands to postcli, extend the collection parser
  for new Postman formats, add variable scopes or dynamic variables, write
  tests for postcli modules, integrate postcli into CI pipelines, build a
  similar Postman-compatible CLI, or work with Click+requests+rich CLI
  patterns for HTTP tooling.
---

# PostCLI — Postman Collection & Environment Variable CLI

Stack: **Python 3.9+ · Click · requests · rich · pytest**

Replicates Postman's environment variable system and runs Postman v2.1
collection exports from the terminal with full `{{variable}}` resolution,
scope hierarchy, dynamic variables, and auth support.

---

## Project Structure

```
postcli/
├── __init__.py              # Package init, PostCliError, __version__
├── __main__.py              # python -m postcli entry point
├── cli.py                   # Click CLI — all commands and groups
├── collection.py            # Postman v2.1 collection parser + data models
├── environment.py           # Environment CRUD + persistence (~/.postcli/)
├── executor.py              # HTTP request execution engine (requests)
├── variables.py             # VariableResolver — {{var}} interpolation
├── utils.py                 # Shared helpers
├── formats/
│   ├── __init__.py
│   └── postman_v21.py       # v2.1 format-specific parsing logic
└── tests/
    ├── test_cli.py
    ├── test_collection.py
    ├── test_environment.py
    ├── test_executor.py
    ├── test_variables.py
    └── fixtures/
        ├── sample_collection.json
        └── sample_environment.json
```

---

## Dev Commands

```bash
pip install -e .
postcli --version
pytest postcli/tests/ -v          # 155 tests
```

---

## Key CLI Commands

```bash
# Environments
postcli env create --name Production
postcli env set Production baseUrl "https://api.example.com"
postcli env set Production apiKey "abc123" --type secret
postcli env list
postcli env show Production
postcli env import My_Env.postman_environment.json
postcli env export Production --output prod.json
postcli env delete Production

# Collections
postcli collection parse my_collection.json
postcli collection list my_collection.json

# Run a request
postcli run my_collection.json "Get Users" --env Production
postcli run my_collection.json "Get User" --env Dev --var userId=42 --verbose
```

---

## Data Models

```python
@dataclass
class PostmanCollection:
    info: CollectionInfo          # name, description, schema, _postman_id
    items: List[CollectionItem]   # requests and folders
    variables: List[Variable]     # collection-level variables
    auth: Optional[Auth]

@dataclass
class CollectionItem:
    name: str
    item_type: str                # "request" | "folder"
    request: Optional[Request]
    items: List[CollectionItem]   # sub-items for folders

@dataclass
class Request:
    method: str
    url: str
    headers: List[Header]
    body: Optional[Body]
    auth: Optional[Auth]
    description: Optional[str]

@dataclass
class Environment:
    id: str
    name: str
    values: List[Variable]
    created_at: datetime
    updated_at: datetime
```

---

## Variable Resolution

`VariableResolver` resolves `{{variable}}` placeholders with a 3-tier
scope hierarchy — **collection > environment > global** — and supports
Postman dynamic variables:

```python
resolver = VariableResolver(
    collection_vars={"baseUrl": "https://api.example.com"},
    environment_vars={"apiKey": "secret"},
    global_vars={},
)

resolver.resolve("{{baseUrl}}/users?key={{apiKey}}")
# → "https://api.example.com/users?key=secret"
```

### Dynamic variables

| Variable | Example output |
|----------|----------------|
| `{{$guid}}` | `550e8400-e29b-41d4-a716-446655440000` |
| `{{$timestamp}}` | `1748726400` |
| `{{$randomInt}}` | `0–1000` |
| `{{$randomUUID}}` | UUID v4 |
| `{{$isoTimestamp}}` | ISO 8601 string |

### Default values

```
{{missingVar:defaultValue}}   →  uses "defaultValue" if var not found
```

---

## Adding a New CLI Command

```python
# cli.py — add under the relevant group
@env_group.command("clone")
@click.argument("source_name")
@click.argument("target_name")
def env_clone(source_name, target_name):
    """Clone an environment under a new name."""
    env = load_environment(source_name)
    if not env:
        console.print(f"[red]Environment '{source_name}' not found[/red]")
        raise click.Abort()
    new_env = create_environment(target_name, {v.key: v.value for v in env.values})
    from postcli.environment import save_environment
    save_environment(new_env)
    console.print(f"[green]Cloned '{source_name}' → '{target_name}'[/green]")
```

---

## Adding a New Collection Format

1. Create `postcli/formats/postman_v20.py` with a `parse_v20(data: dict) -> PostmanCollection` function.
2. In `collection.py`, detect the schema version and dispatch:

```python
def load_collection(path: str) -> PostmanCollection:
    data = load_json(path)
    schema = data.get("info", {}).get("schema", "")
    if "v2.1" in schema:
        return parse_collection_v21(data)
    elif "v2.0" in schema:
        from postcli.formats.postman_v20 import parse_v20
        return parse_v20(data)
    raise PostCliError(f"Unsupported collection schema: {schema}")
```

---

## Executor Pattern

```python
resolver = VariableResolver(environment_vars={"baseUrl": "https://api.example.com"})
executor = RequestExecutor(resolver, timeout=30)

collection = load_collection("my_collection.json")
response = executor.execute_from_collection(collection, "Get Users")

print(response.status_code)       # 200
print(response.response_time_ms)  # 142
print(response.body)              # JSON string
executor.close()
```

---

## Environment Storage

Environments are stored as JSON at `~/.postcli/environments/<id>.json`.

```python
from postcli.environment import create_environment, save_environment, load_environment

env = create_environment("staging", {"baseUrl": "https://staging.example.com"})
save_environment(env)

loaded = load_environment("staging")   # load by name or ID
```

---

## Testing Pattern

```python
# tests/test_variables.py pattern
def test_scope_priority():
    resolver = VariableResolver(
        collection_vars={"key": "collection"},
        environment_vars={"key": "environment"},
    )
    assert resolver.resolve("{{key}}") == "collection"   # collection wins

# tests/test_executor.py — mock HTTP
def test_execute_get(mocker):
    mock_resp = mocker.Mock()
    mock_resp.status_code = 200
    mock_resp.text = '{"users": []}'
    mock_resp.headers = {}
    mock_resp.elapsed.total_seconds.return_value = 0.1
    mocker.patch("requests.Session.request", return_value=mock_resp)
    ...
```

---

## Conventions

- All errors raise `PostCliError` (defined in `postcli/__init__.py`)
- CLI catches `PostCliError` and prints `[red]Error: ...[/red]` via `rich`
- Environment IDs are UUIDs; users reference envs by name in all commands
- Secret-type variables are displayed as `***` in `env show`
- `executor.close()` must be called to release the `requests.Session`
