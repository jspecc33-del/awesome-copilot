---
name: python-build-check
description: >
  GitHub Actions CI workflow for Python projects: runs pytest with JSON
  reporting, uploads the report as an artifact, and posts a score/summary
  comment on every pull request. Supports Postgres and Redis service
  containers for integration tests. Fails the build on any test errors.
---

# Python Build Check Workflow

Runs your Python test suite on every push and PR, surfaces a
`build_score/100` in a PR comment, uploads a full JSON report as an
artifact, and gates merges on test status.

## What it does

1. **Spins up service containers** — Postgres 15 and Redis 7 (configurable)
2. **Installs dependencies** — `pip install -e .[dev]` + `pytest-json-report`
3. **Runs pytest** — quick mode (`-x`, short tracebacks) → `build-report.json`
4. **Summarises results** — computes a `score/100` and pass/fail status
5. **Uploads artifact** — `build-report` retained for 30 days
6. **Comments on PRs** — posts/updates a results table with remediation hints
7. **Fails the build** — exits non-zero when any test fails or errors

## Usage

Copy `.github/workflows/build-check.yml` into your repo and set three secrets:

| Secret | Purpose |
|--------|---------|
| `WRITE_API_KEY` | App write key (used by security tests) |
| `SPLUNK_HEC_TOKEN` | Splunk HEC token (used by SIEM tests) |

The Postgres and Redis service containers are started automatically; no
external infrastructure is needed for CI runs.

## Configuration

Adjust the pytest invocation in the workflow to change scope or add flags:

```yaml
# Full mode — remove -x to keep running after first failure
pytest tests/ --tb=long --json-report --json-report-file=build-report.json

# Single suite
pytest tests/test_risk.py -v --json-report --json-report-file=build-report.json

# With coverage
pytest tests/ --cov=osschain --cov-report=json --json-report --json-report-file=build-report.json
```

## PR Comment Format

```
### Build Check Results
**Score:** 95/100
**Status:** PASSED ✅

| Metric | Count |
|--------|-------|
| Passed | 38    |
| Failed | 0     |
| Errors | 0     |
| Total  | 38    |

✅ No issues found.
```

On failure the comment lists the first 10 failing test node IDs with their
last longrepr line so reviewers can triage without opening the artifact.
Comments are updated in-place on subsequent pushes to the same PR.

## Fail on Critical Issues

To mirror the guide's severity-gate pattern, extend the summarise step:

```python
# fail if security tests specifically are broken
security_failures = [
    t for t in report['tests']
    if 'security' in t['nodeid'] and t['outcome'] != 'passed'
]
if security_failures:
    sys.exit(1)
```
