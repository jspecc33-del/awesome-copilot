# Build Agent — Scaffold Generation & Prerequisite Installer

This reference covers Phase 3 of the Dev Build Wizard: generating the project scaffold,
installing prerequisites, and producing the architecture diagram.

---

## Scaffold Generation Rules

### File Structure

Always produce a complete directory tree BEFORE writing any code. Format:

```
my-project/
├── .env.example
├── .gitignore
├── README.md
├── SETUP.md
├── [dependency file]         # requirements.txt / package.json / go.mod / etc.
├── [setup script].sh         # Linux/Mac
├── [setup script].ps1        # Windows
├── [stress test file]
├── src/ OR app/ OR [project name]/
│   ├── main.[ext]
│   ├── config.[ext]
│   ├── models/
│   ├── routes/ OR handlers/ OR controllers/
│   ├── services/
│   └── utils/
├── tests/
│   ├── test_main.[ext]
│   └── conftest.[ext]        # or equivalent
└── docs/
    └── architecture.md
```

Adapt directory names to match framework conventions (e.g., FastAPI uses `routers/`, Express uses
`routes/`, Django uses app-per-feature).

### What to Actually Generate

Generate the actual file content for:
- `main.[ext]` — entry point with basic startup code and health check route
- `config.[ext]` — environment variable loading pattern
- `.env.example` — all required env vars with placeholder values and comments
- `.gitignore` — pre-filled for the chosen stack
- `[dependency file]` — with pinned versions
- `setup.sh` and `setup.ps1` — full prerequisite installer
- `tests/test_main.[ext]` — one passing test and one example test skeleton

Do NOT generate placeholder skeleton files that just say "add your code here". Every file should
be immediately runnable and serve as a working starting point.

---

## setup.sh Template

```bash
#!/usr/bin/env bash
set -e

# ─── Colors ────────────────────────────────────────────────
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

ok()   { echo -e "${GREEN}✓${NC} $1"; }
warn() { echo -e "${YELLOW}⚠${NC} $1"; }
fail() { echo -e "${RED}✗${NC} $1"; exit 1; }
info() { echo -e "${BLUE}→${NC} $1"; }

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  [PROJECT NAME] — Setup Wizard"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# ─── Runtime checks ────────────────────────────────────────
info "Checking prerequisites..."

# [RUNTIME] check — replace with appropriate runtime
if ! command -v [runtime] &>/dev/null; then
    fail "[Runtime] not found. Install from: [URL]
    Quick install: [one-liner install command if available]"
fi

[RUNTIME]_version=$([runtime] --version 2>&1 | head -1)
ok "[Runtime] found: $[RUNTIME]_version"

# Minimum version check
# [RUNTIME]_major=$(echo $[RUNTIME]_version | grep -o '[0-9]*' | head -1)
# if [ "$[RUNTIME]_major" -lt [MIN_VERSION] ]; then
#     fail "[Runtime] [MIN_VERSION]+ required. Found: $[RUNTIME]_version"
# fi

# ─── Virtual environment (Python) ──────────────────────────
# [UNCOMMENT FOR PYTHON]
# info "Creating virtual environment..."
# [runtime] -m venv .venv
# source .venv/bin/activate
# ok "Virtual environment created: .venv"

# ─── Install dependencies ───────────────────────────────────
info "Installing dependencies..."
[INSTALL_COMMAND]
ok "Dependencies installed"

# ─── Health check ───────────────────────────────────────────
info "Running dependency health check..."
[HEALTH_CHECK_COMMAND]
ok "Dependency check passed"

# ─── Environment setup ──────────────────────────────────────
if [ ! -f ".env" ]; then
    cp .env.example .env
    warn ".env file created from .env.example — open it and fill in your values before running!"
else
    ok ".env file already exists"
fi

# ─── Done ───────────────────────────────────────────────────
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "${GREEN}  Setup complete!${NC}"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  Next steps:"
echo "  1. Edit .env with your actual values"
echo "  2. [START_COMMAND]"
echo "  3. Open [URL] in your browser"
echo ""
```

---

## setup.ps1 Template (Windows PowerShell)

```powershell
# [PROJECT NAME] — Setup Wizard (Windows)
$ErrorActionPreference = "Stop"

function ok   { param($msg) Write-Host "✓ $msg" -ForegroundColor Green }
function warn { param($msg) Write-Host "⚠ $msg" -ForegroundColor Yellow }
function fail { param($msg) Write-Host "✗ $msg" -ForegroundColor Red; exit 1 }
function info { param($msg) Write-Host "→ $msg" -ForegroundColor Cyan }

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  [PROJECT NAME] — Setup Wizard"
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""

# Runtime check
info "Checking prerequisites..."
if (-not (Get-Command [runtime] -ErrorAction SilentlyContinue)) {
    fail "[Runtime] not found. Download from: [URL]"
}
ok "[Runtime] found: $([runtime] --version 2>&1)"

# Install
info "Installing dependencies..."
[INSTALL_COMMAND_WINDOWS]
ok "Dependencies installed"

# .env setup
if (-not (Test-Path ".env")) {
    Copy-Item ".env.example" ".env"
    warn ".env created — fill in your values before running!"
} else {
    ok ".env already exists"
}

Write-Host ""
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host "  Setup complete!" -ForegroundColor Green
Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
Write-Host ""
Write-Host "  Next: Edit .env then run [START_COMMAND]"
Write-Host ""
```

---

## Architecture Diagram Widget Spec

Generate an SVG diagram via `show_widget` with these elements:

### Layers (top to bottom)
1. **Client Layer** (blue): Browser / Mobile App / CLI
2. **API Gateway** (purple, if applicable): Reverse proxy / Load balancer
3. **Application Layer** (green): Main backend framework
4. **Service Layer** (teal, if applicable): Auth service, File service, etc.
5. **Data Layer** (orange): Database(s), Cache
6. **External Layer** (grey): Third-party APIs, CDN, Email service

### Node Style
- Rounded rectangle, filled with layer color at 20% opacity
- Border in layer color at 100%
- Icon (emoji or simple SVG shape) + framework name
- Port numbers shown in small text below name

### Arrow Style
- Directional arrows between layers showing data flow
- Label on arrow: the protocol (HTTP, WebSocket, SQL, gRPC, etc.)
- Dashed arrows for async/event flows

### Diagram Dimensions
- Width: 700px, Height: auto (scales with complexity)
- Centered in widget
- Legend in bottom-right corner

---

## Stack-Specific Templates

### Python + FastAPI + PostgreSQL

```python
# main.py
from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from contextlib import asynccontextmanager
import uvicorn
import os

from .config import settings
from .routers import items  # replace with your routers

@asynccontextmanager
async def lifespan(app: FastAPI):
    # Startup
    print(f"Starting {settings.app_name}...")
    yield
    # Shutdown
    print("Shutting down...")

app = FastAPI(
    title=settings.app_name,
    version="0.1.0",
    lifespan=lifespan
)

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

app.include_router(items.router, prefix="/api/v1")

@app.get("/health")
async def health_check():
    return {"status": "ok", "service": settings.app_name}

if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)
```

```python
# config.py
from pydantic_settings import BaseSettings
from typing import List

class Settings(BaseSettings):
    app_name: str = "My App"
    database_url: str
    secret_key: str
    allowed_origins: List[str] = ["http://localhost:3000"]
    debug: bool = False

    class Config:
        env_file = ".env"

settings = Settings()
```

### Node.js + Express

```javascript
// src/index.js
import express from 'express';
import cors from 'cors';
import helmet from 'helmet';
import { config } from './config.js';
import { itemsRouter } from './routes/items.js';

const app = express();

app.use(helmet());
app.use(cors({ origin: config.allowedOrigins }));
app.use(express.json());

app.use('/api/v1/items', itemsRouter);

app.get('/health', (req, res) => {
  res.json({ status: 'ok', service: config.appName });
});

app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({ error: 'Internal server error' });
});

app.listen(config.port, () => {
  console.log(`${config.appName} running on port ${config.port}`);
});
```

---

## Dependency File Templates

### Python (requirements.txt)
```
# Core
fastapi==0.115.0
uvicorn[standard]==0.30.6
pydantic-settings==2.5.2

# Database
sqlalchemy==2.0.35
alembic==1.13.3
asyncpg==0.29.0         # for async PostgreSQL

# Auth (if needed)
python-jose[cryptography]==3.3.0
passlib[bcrypt]==1.7.4

# Dev
pytest==8.3.3
pytest-asyncio==0.24.0
httpx==0.27.2           # test client for FastAPI
```

### Node.js (package.json skeleton)
```json
{
  "name": "my-project",
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "start": "node src/index.js",
    "dev": "nodemon src/index.js",
    "test": "jest",
    "test:coverage": "jest --coverage"
  },
  "dependencies": {
    "express": "^4.21.0",
    "cors": "^2.8.5",
    "helmet": "^8.0.0",
    "dotenv": "^16.4.5"
  },
  "devDependencies": {
    "nodemon": "^3.1.7",
    "jest": "^29.7.0",
    "supertest": "^7.0.0"
  }
}
```
