# Setup Guide — Plain-English Instructions + Visual How-To

This reference covers Phase 5 of the Dev Build Wizard.

---

## SETUP.md Template

Write a setup guide that reads like a conversation, not a technical manual.

### Structure

```markdown
# How to Run [PROJECT NAME]

**What this is:** [1 sentence plain English description — no jargon]

**You'll need:** [bullet list of requirements — state them as things, not tech]
- A computer running Windows, Mac, or Linux
- An internet connection (for the first setup only)
- About [X] minutes

---

## Step 1 — Download the Starter Files

[plain English: "Download and unzip the starter files, or clone the repo if you know how."]

**If you're using Git** (a tool for downloading and tracking code):
```bash
git clone [REPO_URL]
cd [PROJECT_NAME]
```
*Plain English: This downloads the project to a new folder on your computer and opens that folder.*

**If you're NOT using Git:**
Download the ZIP → right-click → Extract All → open the extracted folder.

---

## Step 2 — Run the Setup Script

This step installs all the pieces the project needs to run.

**On Mac or Linux:**
```bash
chmod +x setup.sh
./setup.sh
```
*Plain English: `chmod +x` gives permission to run the script. `./setup.sh` runs it.*

**On Windows (PowerShell):**
```powershell
.\setup.ps1
```
*Plain English: This runs the Windows version of the setup script.*

**What this does:** Checks your computer has the right tools installed, downloads the project's
dependencies (like ingredients in a recipe — the project needs these to work), and sets up
your configuration file.

**If you see an error here:** Look for the line starting with ✗ — it will tell you exactly
what's missing and where to get it.

---

## Step 3 — Set Up Your Configuration

The setup script created a `.env` file. This is where you put your private settings
(like passwords and API keys — things only you should know).

Open `.env` in any text editor (Notepad, VS Code, TextEdit — anything works):

```
APP_NAME=My App
DATABASE_URL=postgresql://localhost/mydb    ← your database address
SECRET_KEY=change-this-to-something-random  ← make this long and random
```

**For each line marked `← change this`:**
- Replace the placeholder value with your real value
- Don't add spaces around the `=` sign
- Don't use quotes unless a value contains spaces

*Plain English: The `.env` file is like a settings page that the app reads when it starts up.
It keeps your private info out of the code so you don't accidentally share it.*

---

## Step 4 — Start the App

```bash
[START_COMMAND]
```

*Plain English: This boots up the application. Leave this terminal window open — closing it
stops the app.*

**You're done when you see:**
```
[EXPECTED_SUCCESS_OUTPUT]
```

Open your browser and go to: `[URL]`

---

## Troubleshooting

These are the three most common problems and how to fix them:

### "Permission denied" (Mac/Linux)
**What it means:** Your system is blocking the script from running.
**Fix:** Run `chmod +x setup.sh` then try again.

### "Port already in use"
**What it means:** Something else on your computer is already using the same door (port)
the app wants to use.
**Fix:** Either stop the other program, or change the `PORT=` line in your `.env` file
to a different number (try 8001, 8002, etc.).

### "Module not found" / "Cannot find module"
**What it means:** The setup script didn't finish installing all the pieces.
**Fix:** Delete the `node_modules` folder (or `.venv` for Python) and run the setup script again.

---

## You're Done! Here's What You've Got

[Summary of what the project does and what the user can do with it next]

**Explore your project:**
- [Feature 1] → try it at [URL/path]
- [Feature 2] → [how to access it]

**Make it your own:**
- Open `[FILE]` to [common customization]
- Change `[SETTING]` in `.env` to [what it controls]
```

---

## Visual How-To Diagram Widget Spec

Generate this as an HTML widget via `show_widget`. This is an interactive step-by-step
visual guide — not a static diagram.

### Layout

```
┌─────────────────────────────────────────────────────────┐
│  HOW TO USE [PROJECT NAME]                              │
│                                                         │
│  ┌──────┐    ┌──────┐    ┌──────┐    ┌──────┐         │
│  │  1   │ →  │  2   │ →  │  3   │ →  │  4   │         │
│  │Setup │    │Config│    │ Run  │    │ Use  │         │
│  └──────┘    └──────┘    └──────┘    └──────┘         │
│                                                         │
│  ┌─────────────────────────────────────────────────┐   │
│  │  STEP DETAIL PANEL (updates on step click)      │   │
│  │                                                 │   │
│  │  🟢 Run this command:                           │   │
│  │  $ ./setup.sh                                   │   │
│  │                                                 │   │
│  │  💬 What this does (plain English):             │   │
│  │  [explanation]                                  │   │
│  │                                                 │   │
│  │  ✓ You know it worked when: [success signal]    │   │
│  │                                                 │   │
│  │  🆘 I'm stuck → [generates help prompt]         │   │
│  └─────────────────────────────────────────────────┘   │
└─────────────────────────────────────────────────────────┘
```

### Step Cards

Each step card is a clickable rounded rectangle:
- **Color coding**: Green border = run a command, Blue = check something,
  Orange = edit a file, Purple = test something
- **Icon**: Emoji that matches the action (⚡ run, 📝 edit, 🔍 check, 🧪 test)
- **Short label**: 1–3 words max
- **Active state**: Card lifts slightly, border brightens, detail panel updates

### Detail Panel Content (for each step)

1. **Action type badge**: "RUN THIS" / "CHECK THIS" / "EDIT THIS" / "TEST THIS"
2. **Command block** (if applicable): Styled code block with copy button
3. **Plain English explanation**: 2–3 sentences, zero jargon
4. **Success signal**: "You know it worked when you see: [text]"
5. **"I'm Stuck" button**: Generates this prompt for the user to copy:
   ```
   I'm setting up [PROJECT NAME] on [OS]. I'm on Step [N] ([STEP NAME]).
   I ran: [COMMAND]
   I expected to see: [SUCCESS SIGNAL]
   Instead I got: [USER FILLS THIS IN]
   Please help me diagnose and fix this.
   ```
   This prompt is formatted in a copyable text area below the button.

### Animations

- Steps connected by animated dashed line that fills in as user progresses
- Clicking a step card does a gentle scale-up + border glow animation
- Detail panel content fades in smoothly on step change
- "I'm Stuck" button has a subtle shake animation to draw attention

### Completion State

When the user clicks the final step (Use), show a celebration card:
```
🎉 You're all set!
[PROJECT NAME] is running at [URL]

Share it: [if applicable]
Extend it: [suggested next step]
```

---

## Jargon Annotation Rules (for SETUP.md)

When a technical term must appear in the setup guide, follow this pattern:

**Terminal** *(plain: the black text window where you type commands)*
**Repository** *(plain: a folder that tracks all changes to your code)*
**Environment variables** *(plain: private settings your app reads at startup)*
**Port** *(plain: a numbered "door" on your computer that apps use to talk to each other)*
**Dependency** *(plain: a piece of code someone else wrote that your project uses)*
**Virtual environment** *(plain: an isolated space just for this project's tools, so they don't clash with other projects)*
**Package manager** *(plain: a tool that downloads and installs code packages for you, like an app store for code)*
**API** *(plain: a way for two programs to talk to each other, like a waiter taking your order to the kitchen)*

Add new terms following the same pattern: **Term** *(plain: [analogy in everyday language])*
