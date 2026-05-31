# Planning Agent — Interactive Dropdown Wizard

This reference covers Phase 2 (Planning) and Phase 4 (Verification) of the Dev Build Wizard.

---

## Phase 2: Planning Widget — Full HTML Spec

When generating the planning widget, produce a self-contained HTML artifact. The widget uses
dark theme, smooth transitions, and a persistent plain-English side panel.

### Core Architecture

```
┌─────────────────────────────────────────────────────────────┐
│  PHASE TRACKER: [Analyze ✓] → [Plan ●] → [Build] → [Guide] │
├──────────────────────────────┬──────────────────────────────┤
│  DROPDOWN PANEL (left 60%)   │  PLAIN ENGLISH PANEL (40%)   │
│                              │                              │
│  [Project Type ▼]            │  📖 What is this?            │
│  > Web App                   │  ─────────────────────────── │
│                              │  [Explanation of selected    │
│  [Primary Language ▼]        │   option in plain English]   │
│  > Python                    │                              │
│                              │  💡 When to use it:          │
│  [Backend Framework ▼]       │  [1 sentence]                │
│  > FastAPI                   │                              │
│  ? Why does this matter?     │  ⚠️  When NOT to use it:     │
│    [accordion content]       │  [1 sentence]                │
│                              │                              │
│  [Database ▼]                │  🔍 Search for more info     │
│  > PostgreSQL                │  [Generates search prompt]   │
│                              │                              │
│  ...more dropdowns...        │  🔤 Jargon Glossary          │
│                              │  [Click any underlined term] │
│  [⚡ Let Claude Decide]       │                              │
│  [ ] Refine Mode             │                              │
│                              │                              │
│  [🚀 Generate Build Plan]    │                              │
└──────────────────────────────┴──────────────────────────────┘
```

### HTML Widget Template

The widget must include:

**CSS Variables (dark theme):**
```css
--bg-primary: #0d1117;
--bg-secondary: #161b22;
--bg-tertiary: #21262d;
--border: #30363d;
--accent: #58a6ff;
--accent-green: #3fb950;
--accent-orange: #d29922;
--accent-purple: #bc8cff;
--text-primary: #e6edf3;
--text-secondary: #8b949e;
--text-muted: #484f58;
--font-mono: 'JetBrains Mono', 'Fira Code', monospace;
--font-ui: 'IBM Plex Sans', sans-serif;
```

**Google Fonts import:**
```html
<link href="https://fonts.googleapis.com/css2?family=IBM+Plex+Sans:wght@400;500;600&family=JetBrains+Mono:wght@400;600&display=swap" rel="stylesheet">
```

**Phase Tracker:** Horizontal row of steps with connecting line. Completed steps show ✓ in green
circle. Current step pulses with accent color. Future steps are dimmed.

**Dropdown Component:** Each dropdown must:
- Show the currently selected value prominently
- Open a styled dropdown panel (not native browser select) for consistency
- Highlight the hovered option
- On selection, update the side panel immediately with new plain-English content
- Show a small "ℹ️" icon that when clicked toggles the "Why does this matter?" accordion
- In Refine Mode: show a follow-up question below after selection

**Side Panel:** Updates on every dropdown interaction. Content is pulled from the jargon library
(see `jargon-library.md`). Terms in the explanation that are themselves technical get an underline
style and open a tooltip on click.

**"Let Claude Decide" Button:** Fills all unset dropdowns with recommended values. For each one,
briefly explains why in a small badge below the dropdown: "Auto-selected: Best for Python projects
needing fast startup".

**"Generate Build Plan" Button:** Prominent, full-width at bottom. Disabled until at least Project
Type and Primary Language are selected. On click, shows a loading animation and transitions to Phase 3.

**Refine Mode Toggle:** When ON, after each selection shows one follow-up question. Examples:
- After PostgreSQL: "Will you need full-text search? [Yes] [No] [Not Sure]"
- After FastAPI: "Will your API need to handle file uploads? [Yes] [No] [Not Sure]"
- After Docker: "Are you deploying to a managed service or your own server? [Managed] [Own Server]"
These answers are appended to the build plan context.

**"I Don't Know What This Means" Link:** Below each dropdown, a small italic link. Clicking it
expands a card that:
1. Gives a real-world analogy (no tech terms)
2. Lists 3 popular projects that use this choice
3. Links to a generated search prompt the user can copy-paste into Google or Claude

---

## Phase 4: Build Agent — Verification

### Bug Check Procedure

For each generated file, perform this analysis pass:

**Python files:**
- Missing `try/except` around file I/O, network calls, database queries
- Bare `except:` clauses (should catch specific exceptions)
- `print()` statements left in production code paths (should use logging)
- Hardcoded credentials, tokens, or connection strings
- Missing `if __name__ == "__main__":` guard
- F-strings with undefined variables
- Import statements for packages not in requirements

**JavaScript/TypeScript files:**
- Missing `await` on async function calls
- Unhandled Promise rejections (no `.catch()` or `try/catch`)
- `console.log()` left in production paths
- `any` type used in TypeScript (flag as warning)
- Missing null checks before property access
- Secrets in client-side code

**C# files:**
- Missing null checks (nullable reference types)
- `using` statements missing for IDisposable
- Async methods without `Async` suffix
- Synchronous calls inside async methods (`.Result`, `.Wait()`)
- Missing cancellation token parameters

**All files:**
- TODO/FIXME comments (flag as Info)
- Placeholder values like "YOUR_KEY_HERE", "CHANGE_ME", "example.com"
- Mismatched env variable names between code and `.env.example`

### Severity Levels

| Level | Meaning | Action |
|-------|---------|--------|
| 🔴 Critical | Will crash or expose security vulnerability | Must fix before running |
| 🟡 Warning | May cause bugs under load or edge cases | Should fix |
| 🔵 Info | Style or improvement suggestion | Nice to have |

### Stress Test Script Generation

**For Python/FastAPI projects — use `locust`:**
```python
# locustfile.py template
from locust import HttpUser, task, between

class ProjectUser(HttpUser):
    wait_time = between(1, 3)

    @task(3)
    def get_main_endpoint(self):
        self.client.get("/")

    @task(1)
    def post_data(self):
        self.client.post("/api/items", json={"name": "test"})
```
Run command: `locust -f locustfile.py --host=http://localhost:8000 --users=50 --spawn-rate=5`

**For Node.js projects — use `k6`:**
```javascript
// k6-load-test.js template
import http from 'k6/http';
import { sleep } from 'k6';

export const options = {
  vus: 50,
  duration: '30s',
};

export default function() {
  http.get('http://localhost:3000/');
  sleep(1);
}
```
Run command: `k6 run k6-load-test.js`

**For any project — basic curl test:**
```bash
# Quick smoke test — run this first
for i in {1..10}; do
  curl -s -o /dev/null -w "%{http_code}\n" http://localhost:PORT/health
done
```

### Verification Output Block

```
╔══════════════════════════════════════════╗
║         BUG CHECK REPORT                 ║
╠══════════════════════════════════════════╣
║ Files Scanned:    N                      ║
║ 🔴 Critical:      N                      ║
║ 🟡 Warnings:      N                      ║
║ 🔵 Info:          N                      ║
╠══════════════════════════════════════════╣
║ ISSUES                                   ║
║                                          ║
║ 🔴 [file.py:23] Hardcoded API key        ║
║    Found: api_key = "sk-abc123"          ║
║    Fix:   Move to .env, use os.getenv()  ║
║                                          ║
║ 🟡 [routes.py:45] Missing error handler  ║
║    Found: db.query(sql)                  ║
║    Fix:   Wrap in try/except             ║
╠══════════════════════════════════════════╣
║ STRESS TEST                              ║
║ Script: [tool] — [filename]              ║
║ Run:    [command]                        ║
║ Target: [endpoints being tested]         ║
╚══════════════════════════════════════════╝
```
