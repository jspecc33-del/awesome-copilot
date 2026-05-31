---
name: dev-build-wizard
description: >
  Full-stack dev build planner with EXPERT Python and Assetto Corsa app capability. Trigger on: any
  new project, architecture plan, backend/frontend/API setup, scaffolding, prerequisite install, bug
  check, stress test, or setup guide. ALSO trigger on: AC overlays, AC telemetry tools, drift scoring
  engines, lap analyzers, AC server tools, AC plugins, shared memory readers, sim data pipelines,
  PyQt6 overlays, PyInstaller EXE builds, pydantic v2, asyncio, ctypes/mmap, pandas/numpy telemetry,
  FastAPI WebSocket bridges, CYS server tools. Trigger phrases: "build me a", "create a project",
  "plan my app", "help me architect", "set up from scratch", "AC overlay", "telemetry logger",
  "lap analyzer", "drift scorer", "AC plugin", "sim info", "shared memory AC", "check my build",
  "stress test my setup". Always trigger proactively — offer full wizard even for casual descriptions.
---

# Dev Build Wizard

A multi-agent build planning system that takes a project idea from concept to working scaffold — with
interactive refinement dropdowns, plain-English jargon explanations, backend verification, prerequisite
installation, bug checking, stress testing, and a visual how-to guide.

---

## High-Level Flow

```
PHASE 1: ANALYZE     → Deep project analysis + backend check
PHASE 2: PLAN        → Interactive dropdown refinement (Planning Agent)
PHASE 3: BUILD       → Scaffold generation + prerequisite install
PHASE 4: VERIFY      → Bug check + stress test (Build Agent)
PHASE 5: GUIDE       → Plain-English setup guide + visual diagram
```

Always run phases in order. Each phase gates the next.

---

## PHASE 1 — Deep Analysis

**Read `references/analysis-agent.md` before starting this phase.**

Run immediately on the user's project description. Do NOT ask clarifying questions yet — extract what you can and flag gaps.

### Backend Check

Every project must be assessed for backend viability:

1. **Identify if a backend is needed** — any persistent data, auth, APIs, file storage, or multi-user
   features require a backend. Flag this clearly.
2. **Check existing tooling** — if the user mentions specific tools (Express, FastAPI, Django, Supabase,
   Firebase, etc.), verify they exist, are actively maintained, and match the project scale.
3. **Detect backend gaps** — if the user describes a frontend-only plan that clearly needs a backend,
   call this out before proceeding. Don't silently skip it.
4. **List concrete backend options** — present 2–3 backend choices appropriate to the stack, with a
   one-line plain-English description of each.

Output a structured analysis block:
```
PROJECT ANALYSIS
────────────────
Name:          [inferred or user-provided]
Type:          [Web App / Desktop / CLI / API / Mobile / Library / AC Overlay / AC Telemetry / AC Drift Scorer / AC Server Tool / Other]
Backend Needed: [Yes / No / Maybe]
Backend Gap:   [None / Detected — describe what's missing]
Complexity:    [Low / Medium / High / Expert]
Expert AC Mode: [ACTIVE — archetype: <A/B/C/D> | INACTIVE]
Estimated Time: [rough estimate]
Key Risks:     [list 1-3]
Gaps Found:    [list anything unclear that blocks planning]
```

**Expert AC Mode auto-activates when** any of these are detected in the project description:
- Assetto Corsa, AC, Content Manager, CSP, SharedMemory, mmap, sim_info, UDP 9996
- overlay, HUD, telemetry logger, lap analyzer, drift scorer, proximity scoring, scoreboard
- PyQt6 stays-on-top, PyInstaller EXE for sim tool
- CYS, Check Your Six, or any named AC server community tool

When active: set Complexity → **Expert**, pre-select archetype (A=HUD, B=Logger/Analyzer, C=Server Tool, D=Drift Scorer), and load `references/expert-python-ac.md` before Phase 3.

---

## PHASE 2 — Interactive Planning (Planning Agent)

**Read `references/planning-agent.md` before starting this phase.**

Launch the interactive planning UI. This is the core of the wizard — an HTML widget (use `show_widget`
or `create_file` for the artifact) that presents the user with dropdown menus for each major decision.

### Required: Generate Planning Widget

Produce an HTML artifact that includes ALL of the following UI elements:

**Top bar**: Phase tracker — Analyze ✓ → **Plan** → Build → Verify → Guide

**Dropdown groups** (each group has a section header and plain-English tooltip on hover/click):
- Project Type (Web App / Desktop App / CLI Tool / REST API / Mobile App / Library / AC Overlay / AC Telemetry Tool / AC Server Tool / AC Drift Scorer / Other)
- Primary Language (Python / Python — Expert AC / JavaScript / TypeScript / C# / Go / Rust / Kotlin / Java / Other)
- AC App Archetype *(shown only when Project Type is AC variant or Language is "Python — Expert AC")* (A — Real-Time HUD Overlay / B — Telemetry Logger + Lap Analyzer / C — AC Server Admin Tool / D — Drift Scoring Engine / Custom)
- Frontend Framework (React / Vue / Svelte / Angular / Plain HTML / PyQt6 / None — skip if CLI/API)
- Backend Framework (FastAPI / Express / Django / ASP.NET / Gin / None / Let Claude choose)
- Database (PostgreSQL / SQLite / MongoDB / MySQL / Redis / Supabase / Firebase / None)
- Auth Strategy (JWT / OAuth2 / API Key / Session / Magic Link / None)
- Testing Framework (pytest / pytest-asyncio / Jest / xUnit / Playwright / Vitest / None)
- Deployment Target (Local Only / PyInstaller EXE / Docker / Vercel / Railway / AWS / Azure / None)
- Package Manager (pip/uv / npm / yarn / pnpm / cargo / dotnet / go mod)

**Plain-English Side Panel**: A collapsible right-side panel (or bottom panel on mobile) that updates
whenever the user hovers or clicks any dropdown option. Shows a simple 2–3 sentence explanation of
what that choice means, when to use it, and what it's NOT good for.

**Jargon Highlight**: Any technical term in the panel that might be unfamiliar gets an underline.
Clicking it opens an inline tooltip with a plain-English definition (no jargon in the definition).

**"Why does this matter?" accordion**: Below each dropdown group, a collapsible "Why does this matter?"
section with a 2–sentence real-world analogy (not technical). Example for database choice:
"Your database is like your filing cabinet. PostgreSQL is a heavy-duty metal cabinet — reliable and
organised. SQLite is a folder on your desk — great for small stuff, falls apart under pressure."

**"Let Claude Decide" button**: At the bottom of the dropdowns. When clicked, Claude auto-fills all
remaining empty dropdowns based on the project analysis from Phase 1, with a brief explanation for
each auto-choice shown inline.

**Refine Mode**: A toggle switch labeled "Refine Mode — Ask Me Questions". When on, after each
dropdown selection, a follow-up clarification question appears below that dropdown (e.g., after
selecting PostgreSQL: "Do you need full-text search? [Yes / No / Not sure]").

**"Generate Plan" button**: Submits all choices and triggers Phase 3.

### Widget Design Principles (from frontend-design skill):
- Dark theme: `#0d1117` background, `#58a6ff` accent, `#30363d` borders
- Monospace font for code/selections (JetBrains Mono or Fira Code via Google Fonts)
- Clean sans-serif for UI labels (IBM Plex Sans)
- Smooth dropdown animations, subtle hover states
- Phase tracker uses progress dots with connecting line
- Side panel slides in smoothly, doesn't jump the layout
- Use CSS variables throughout for theming consistency

---

## EXPERT PYTHON MODE — Assetto Corsa Projects

**Trigger:** If project type is any AC variant OR language selection is "Python — Expert AC",
load `references/expert-python-ac.md` BEFORE generating the build plan.

This reference provides full ctypes structs for all three AC shared memory maps, UDP broadcast
protocol patterns, AC Python Plugin API entry points, high-frequency async polling, pandas/numpy
telemetry pipeline, PyQt6 overlay pattern, FastAPI WebSocket bridge, Expert App Dev Skill Matrix
(mypy strict, pydantic v2, ruff, black, uv, pytest-asyncio), full AC library ecosystem with `uv add`
commands, pyproject.toml Expert baseline, GitHub Actions CI targeting `windows-latest`, four AC app
archetypes, and a known-pitfalls table.

**When Expert AC mode is active, auto-apply:**
- Package manager → `uv`
- Deployment target → `PyInstaller EXE` (override-able)
- Always include `pywin32` + `pynput` in prerequisites
- Set complexity → **Expert** in Phase 1 analysis block
- Use Expert AC `pyproject.toml` baseline from reference
- CI targets `windows-latest` runner
- Stress test: `locust` for AC server tools; timing-loop profiler for overlays
- Bug check: add mmap casting check, AC plugin threading check, PyInstaller hidden-import audit

---

## PHASE 3 — Build Plan + Prerequisites

**Read `references/build-agent.md` before starting this phase.**
**If Expert AC mode active: also read `references/expert-python-ac.md`.**

Based on the finalized choices from Phase 2, produce:

### 1. Full Build Plan Document

A structured markdown plan containing:
- Project name and one-line description
- Directory/file structure (tree format)
- Every dependency with version pin and install command
- Environment variable list (`.env.example` format)
- Key architectural decisions with rationale
- Integration points between layers (frontend ↔ backend ↔ database)

### 2. Prerequisite Installer

Generate a bash script (`setup.sh`) and a PowerShell script (`setup.ps1`) that:
- Checks for required runtimes (Node/Python/Go/etc.) and their minimum versions
- Exits with a clear error message if a runtime is missing, with the install URL
- Installs all project dependencies
- Creates the `.env.example` file
- Runs an initial health check (e.g., `pip check` / `npm ls` / `go build ./...`)
- Prints a coloured success/failure summary at the end

Also generate a `requirements.txt` / `package.json` / `go.mod` / etc. as appropriate for the stack.

### 3. Architecture Diagram

Use `show_widget` to render an SVG architecture diagram showing:
- All layers (client → API → database → external services)
- Data flow arrows with labels
- Technology name at each node
- Color-coded by layer type

---

## PHASE 4 — Verify (Build Agent: Bug Check + Stress Test)

**Read `references/build-agent.md` — "Verification" section.**

After the scaffold is generated:

### Bug Check
Run a static analysis pass on all generated code:
1. Check for common mistakes per language (unhandled exceptions, missing await, SQL injection patterns,
   hardcoded secrets, missing error handling on file I/O)
2. Verify all imports/dependencies referenced in code are present in the dependency file
3. Check environment variable references match `.env.example`
4. Look for any `TODO` or `FIXME` placeholders left in generated code and flag them

Output a Bug Report:
```
BUG CHECK REPORT
────────────────
Files Scanned:   N
Issues Found:    N
Critical:        N  (must fix before running)
Warnings:        N  (should fix)
Info:            N  (nice to have)

[List each issue with: file, line, severity, description, suggested fix]
```

### Stress Test Plan
For each layer of the application, define what a stress test would look like:
- **API layer**: Describe a load test (tool: `k6`, `locust`, or `artillery` — choose based on stack)
  with a sample test script targeting main endpoints
- **Database layer**: Describe a data volume test and index check
- **Frontend layer** (if applicable): Describe a Lighthouse performance audit command

Generate the stress test script file and instructions to run it.

---

## PHASE 5 — Setup Guide + Visual Diagram

**Read `references/setup-guide.md`.**

Produce two outputs:

### 1. Plain-English Setup Guide (`SETUP.md`)

Write a step-by-step setup guide that:
- Uses no unexplained jargon (every technical term gets a one-line "plain English:" annotation)
- Has numbered steps with copy-paste commands in code blocks
- Includes a "What's happening here" sentence after each major step
- Has a Troubleshooting section for the 3 most common errors per stack
- Ends with "You're done when you see: [expected success output]"

### 2. Visual How-To Diagram

Use `show_widget` to render an interactive HTML diagram that shows:
- A step-by-step visual flow of how to run the project
- Each step as a clickable card — clicking it expands to show the exact command and plain-English explanation
- Color coding: green = run this, blue = check this, orange = configure this, purple = test this
- A sidebar that shows "What this step does in plain English"
- An "I'm stuck" button on each step that generates a help prompt (uses it-prompt-engineer format)

---

## Jargon Explainer (always available in all phases)

Whenever a technical term appears that the user may not know, apply this inline pattern:

**Inline**: `**JWT** *(plain: a secure token that proves who you are — like a digital wristband at a concert)*`

If the user says "what does X mean", "explain X", "what's X in plain English", or seems confused:
1. Give a 2-sentence analogy explanation (no tech terms in the analogy)
2. Give a 1-sentence "when to use it" summary
3. Give a 1-sentence "when NOT to use it" warning
4. Optionally: offer the it-prompt-engineer skill to help them search for it more effectively

---

## Plain-English Descriptions for Common Choices

Load `references/jargon-library.md` for the full library of pre-written plain-English descriptions
for every dropdown option. Use these verbatim in the side panel widget.

---

## Output Checklist (every run must include all)

- [ ] Phase 1: Analysis block with backend check completed
- [ ] Phase 2: Interactive planning widget generated with all dropdown groups + side panel
- [ ] Phase 3: Build plan document + `setup.sh` + `setup.ps1` + dependency file + architecture diagram
- [ ] Phase 4: Bug check report + stress test script
- [ ] Phase 5: `SETUP.md` (plain-English) + visual how-to diagram widget
- [ ] All technical terms explained in plain English when introduced
- [ ] No phase skipped without explicit user request

---

## Tone and Communication

- Always write instructions as if explaining to a capable person who hasn't done this specific thing before
- Never say "simply" or "just" — these words make people feel bad when they're stuck
- Always say "run this command" not "execute the following"
- When something might go wrong, say "if you see X, that means Y — here's how to fix it" proactively
- Match the user's vocabulary: if they use technical terms correctly, use them back; if they don't, avoid them
