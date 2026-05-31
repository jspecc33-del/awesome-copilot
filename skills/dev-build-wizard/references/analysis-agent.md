# Analysis Agent — Deep Project Analyzer

This reference covers Phase 1 of the Dev Build Wizard. Read this before running the analysis phase.

---

## Goal

Extract a complete, structured picture of the user's project from their description — even if their
description is vague, casual, or incomplete. Don't ask questions yet. Make intelligent inferences
and flag gaps clearly in the output.

---

## Extraction Targets

From the user's message, extract or infer:

| Field | How to Extract | If Missing |
|-------|---------------|------------|
| Project name | User-provided or infer from context | Use "My Project" as placeholder |
| Project type | Look for keywords: "website", "app", "API", "script", "tool", "bot" | Ask in Phase 2 dropdown |
| Tech mentions | Any language/framework/tool names mentioned | Leave blank for Phase 2 |
| Data needs | Any mention of "save", "store", "users", "login", "history", "search" | Flag as "likely needs backend" |
| Scale | Words like "personal", "team", "business", "thousands of users" | Assume "personal" if unspecified |
| Timeline | Any urgency signals ("quickly", "by Friday", "just exploring") | Assume "no deadline" |
| Existing code | "I have a...", "I started...", "I already..." | Assume fresh start |

---

## Backend Detection Logic

Use this decision tree to determine if a backend is required:

```
Does the project need to save data between sessions?
├── YES → Backend needed (database + API layer)
└── NO → Continue...

Does the project need user accounts / login?
├── YES → Backend needed (auth service at minimum)
└── NO → Continue...

Will multiple people use it at the same time?
├── YES → Backend needed (shared state management)
└── NO → Continue...

Does it call external APIs that require secret keys?
├── YES → Backend strongly recommended (never expose secret keys in frontend)
└── NO → Continue...

Does it process files, images, or large data?
├── YES → Backend likely needed (storage + compute)
└── NO → Frontend-only is probably fine
```

### Backend Gap Warning Template

If a backend gap is detected:

```
⚠️  BACKEND GAP DETECTED
─────────────────────────
Your project description includes [FEATURE] which requires a backend,
but no backend was mentioned in your plan.

Without a backend, this will fail:
• [Specific feature that won't work]
• [Another feature]

Recommended fix: Add [BACKEND_OPTION] to handle [CAPABILITY].

This will be presented as a choice in the planning phase.
```

---

## Risk Assessment

Score 1–3 for each risk dimension:

| Risk | Score 1 | Score 2 | Score 3 |
|------|---------|---------|---------|
| **Auth complexity** | No auth | Single user auth | Multi-role/OAuth |
| **Data complexity** | No data | Simple CRUD | Relations/migrations |
| **Scale risk** | Personal use | Small team | Public-facing |
| **Integration risk** | No external APIs | 1–2 APIs | 3+ APIs or real-time |
| **Infrastructure risk** | Local only | Simple cloud | Microservices/containers |

If any dimension scores 3, flag it as a **Key Risk** in the analysis block.

---

## Complexity Estimation

| Complexity | Criteria | Rough Time Estimate |
|------------|----------|---------------------|
| Low | ≤ 3 files, no backend, no auth | 1–4 hours |
| Medium | 5–20 files, simple backend, basic auth | 1–3 days |
| High | 20+ files, multiple services, complex auth | 1–3 weeks |
| Expert | Distributed systems, custom protocols, real-time | Months |

---

## Analysis Block Output Format

Always output this exact structure at the end of Phase 1:

```
╔══════════════════════════════════════════╗
║           PROJECT ANALYSIS               ║
╠══════════════════════════════════════════╣
║ Name:           [name or "My Project"]   ║
║ Type:           [type]                   ║
║ Backend Needed: [Yes / No / Likely]      ║
║ Backend Gap:    [None / ⚠️ Detected]     ║
║ Complexity:     [Low/Medium/High/Expert] ║
║ Estimated Time: [estimate]               ║
╠══════════════════════════════════════════╣
║ KEY RISKS                                ║
║ • [risk 1]                               ║
║ • [risk 2 if any]                        ║
╠══════════════════════════════════════════╣
║ GAPS (need your input in planning phase) ║
║ • [gap 1]                                ║
║ • [gap 2 if any]                         ║
╚══════════════════════════════════════════╝
```

After the analysis block, write one plain-English paragraph summarising what you understood and what
you're about to help them build. Keep it conversational and encouraging. Then transition to Phase 2.
