# Expert Python — Assetto Corsa Application Development

Reference module for the Dev Build Wizard.

**Load this file when:** project type is Assetto Corsa app, sim telemetry tool, AC plugin, AC data
logger, AC overlay, AC server tool, drift scoring engine, lap analyzer, setup tool, or any Python
project tagged complexity **Expert** targeting Assetto Corsa / Content Manager / CSP.

---

## TABLE OF CONTENTS

1. AC Data Interfaces
   - 1a. Shared Memory (mmap) — primary, ~333 Hz
   - 1b. UDP Broadcast — multi-client, cross-machine
   - 1c. AC Python Plugin API — in-game overlays
2. Expert Python Patterns for AC Apps
   - 2a. High-frequency polling without blocking
   - 2b. Telemetry data pipeline (pandas + numpy)
   - 2c. Real-time and post-session plotting
   - 2d. Desktop GUI overlay (PyQt6)
   - 2e. WebSocket bridge (FastAPI + asyncio)
3. Expert App Dev Skill Matrix
4. AC-Specific Library Ecosystem
5. Expert Python Tooling Standards
6. AC App Archetypes + Starter Stacks
7. Known Pitfalls and Hard Rules

---

## 1. AC Data Interfaces

### 1a. Shared Memory (Primary)

AC exposes three named Windows memory-mapped files:

| Map Name                   | Struct               | Update Rate  | Key Contents                                      |
|----------------------------|----------------------|--------------|---------------------------------------------------|
| `Local\acpmf_physics`      | `SPageFilePhysics`   | ~333 Hz      | Speed, velocity, g-force, slip, tyres, RPM, gear  |
| `Local\acpmf_graphics`     | `SPageFileGraphics`  | ~33 Hz       | World pos, session status, flags, penalties       |
| `Local\acpmf_static`       | `SPageFileStatic`    | Session start | Car/track metadata, max RPM, fuel capacity       |

```python
import mmap
import ctypes
from ctypes import c_float, c_int32

class SPageFilePhysics(ctypes.Structure):
    _fields_ = [
        ("packetId",              c_int32),
        ("gas",                   c_float),
        ("brake",                 c_float),
        ("fuel",                  c_float),
        ("gear",                  c_int32),
        ("rpms",                  c_int32),
        ("steerAngle",            c_float),
        ("speedKmh",              c_float),
        ("velocity",              c_float * 3),
        ("accG",                  c_float * 3),
        ("wheelSlip",             c_float * 4),
        ("wheelLoad",             c_float * 4),
        ("wheelsPressure",        c_float * 4),
        ("wheelAngularSpeed",     c_float * 4),
        ("tyreWear",              c_float * 4),
        ("tyreDirtyLevel",        c_float * 4),
        ("tyreCoreTemperature",   c_float * 4),
        ("camberRAD",             c_float * 4),
        ("suspensionTravel",      c_float * 4),
        ("drs",                   c_float),
        ("tc",                    c_float),
        ("heading",               c_float),
        ("pitch",                 c_float),
        ("roll",                  c_float),
        ("cgHeight",              c_float),
        ("carDamage",             c_float * 5),
        ("numberOfTyresOut",      c_int32),
        ("pitLimiterOn",          c_int32),
        ("abs",                   c_float),
        ("rideHeight",            c_float * 2),
        ("turboBoost",            c_float),
        ("airTemp",               c_float),
        ("roadTemp",              c_float),
        ("localAngularVel",       c_float * 3),
        ("finalFF",               c_float),
        ("brakeTemp",             c_float * 4),
        ("clutch",                c_float),
        ("tyreTempI",             c_float * 4),
        ("tyreTempM",             c_float * 4),
        ("tyreTempO",             c_float * 4),
        ("isAIControlled",        c_int32),
        ("brakeBias",             c_float),
        ("localVelocity",         c_float * 3),
    ]

def open_shared_map(tag: str, struct_type: type) -> mmap.mmap:
    try:
        return mmap.mmap(-1, ctypes.sizeof(struct_type),
                         tagname=tag, access=mmap.ACCESS_READ)
    except OSError as e:
        raise RuntimeError(f"AC shared memory not available ({tag}): {e}") from e

def read_struct(shm: mmap.mmap, struct_type: type):
    """Always copy buffer — never cast a live mmap slice. AC writes mid-read."""
    shm.seek(0)
    return struct_type.from_buffer_copy(shm.read(ctypes.sizeof(struct_type)))
```

**Key rules:**
- Use `packetId` change detection — skip frames where id matches last read.
- Gate all `SPageFileStatic` reads on `SPageFileGraphics.status == AC_LIVE`.
- `packetId` is `c_int32` — compare with `!=`, not `>` (wraps at ~2B).
- Wrap `open_shared_map()` in `try/except RuntimeError` — always.

---

### 1b. UDP Broadcast

AC server broadcasts on **UDP port 9996** (configurable `server_cfg.ini`).
Protocol: Kunos binary UDP. Key opcodes: `0x82` CAR_UPDATE, `0xC9` LAP_COMPLETED.

```python
import asyncio, struct

class ACUDPProtocol(asyncio.DatagramProtocol):
    def datagram_received(self, data: bytes, addr: tuple):
        match data[0]:
            case 0x82:
                car_id, _, speed = struct.unpack_from("<HHf", data, 1)
                world_pos = struct.unpack_from("<3f", data, 9)
            case 0xC9:
                car_id, lap_ms, cuts = struct.unpack_from("<HiH", data, 1)

async def start_udp(host: str = "0.0.0.0", port: int = 9996):
    loop = asyncio.get_running_loop()
    transport, _ = await loop.create_datagram_endpoint(
        ACUDPProtocol, local_addr=(host, port))
    return transport
```

---

### 1c. AC Python Plugin API (in-game overlays)

App path: `%USERPROFILE%\Documents\Assetto Corsa\apps\python\<AppName>\<AppName>.py`

```python
import ac, acsys

app_id = speed_label = None

def acMain(ac_version: str) -> str:
    global app_id, speed_label
    app_id = ac.newApp("MyOverlay")
    ac.setSize(app_id, 400, 120)
    speed_label = ac.addLabel(app_id, "Speed")
    ac.setPosition(speed_label, 10, 10)
    ac.addRenderCallback(app_id, acRender)
    return "MyOverlay"   # MUST return string

def acUpdate(deltaT: float):
    speed = ac.getCarState(0, acsys.CS.SpeedKMH)
    ac.setLabelText(speed_label, f"{speed:.1f} km/h")

def acRender(deltaT: float):
    ac.glColor4f(0.1, 0.1, 0.1, 0.85)
    ac.glQuad(0, 0, 400, 120)

def acShutdown():
    pass
```

**Available in AC plugin sandbox:** `ac`, `acsys`, `sim_info`, `os`, `sys`, `math`, `json`, `re`, `collections`.
**NEVER use in AC plugin:** `threading`, `multiprocessing`, `subprocess`, `socket` — unstable in AC Python sandbox.

---

## 2. Expert Python Patterns

### 2a. High-Frequency Polling Without Blocking

```python
import asyncio, time
from dataclasses import dataclass, field

@dataclass
class TelemetryFrame:
    timestamp: float
    speed_kmh: float
    rpm: int
    gear: int
    throttle: float
    brake: float
    wheel_slip: list[float] = field(default_factory=list)

class TelemetryStream:
    def __init__(self, poll_hz: int = 100):
        self._interval = 1.0 / poll_hz
        self._shm = open_shared_map("Local\\acpmf_physics", SPageFilePhysics)
        self._last_id = -1
        self._callbacks: list[callable] = []

    def on_frame(self, fn: callable):
        self._callbacks.append(fn)
        return fn

    async def run(self):
        while True:
            phys = read_struct(self._shm, SPageFilePhysics)
            if phys.packetId != self._last_id:
                self._last_id = phys.packetId
                frame = TelemetryFrame(
                    timestamp=time.monotonic(),
                    speed_kmh=phys.speedKmh, rpm=phys.rpms,
                    gear=phys.gear, throttle=phys.gas, brake=phys.brake,
                    wheel_slip=list(phys.wheelSlip),
                )
                for cb in self._callbacks:
                    if asyncio.iscoroutinefunction(cb):
                        await cb(frame)
                    else:
                        cb(frame)
            await asyncio.sleep(self._interval)
```

---

### 2b. Telemetry Data Pipeline (pandas + numpy)

```python
import numpy as np
import pandas as pd
from pathlib import Path

def frames_to_df(frames: list[TelemetryFrame]) -> pd.DataFrame:
    return pd.DataFrame([vars(f) for f in frames])

def compute_lap_metrics(df: pd.DataFrame) -> dict:
    return {
        "max_speed_kmh":  df["speed_kmh"].max(),
        "avg_speed_kmh":  df["speed_kmh"].mean(),
        "max_rpm":        df["rpm"].max(),
        "throttle_pct":   (df["throttle"] > 0.95).mean() * 100,
        "brake_pct":      (df["brake"] > 0.05).mean() * 100,
        "avg_wheel_slip": np.array(df["wheel_slip"].tolist()).mean(axis=0).tolist(),
    }

def save_lap(frames: list[TelemetryFrame], path: Path):
    frames_to_df(frames).to_parquet(path, compression="snappy")

def compare_laps(df_a: pd.DataFrame, df_b: pd.DataFrame) -> pd.DataFrame:
    """Time-align two laps and diff key channels."""
    for df in (df_a, df_b):
        t = df["timestamp"] - df["timestamp"].iloc[0]
        df["t_norm"] = t / t.iloc[-1]
    merged = pd.merge_asof(
        df_a.sort_values("t_norm"), df_b.sort_values("t_norm"),
        on="t_norm", suffixes=("_a", "_b"), direction="nearest"
    )
    merged["delta_speed"] = merged["speed_kmh_a"] - merged["speed_kmh_b"]
    return merged
```

---

### 2c. Real-Time and Post-Session Plotting

```python
# Live overlay — matplotlib animation
import matplotlib.pyplot as plt, matplotlib.animation as animation
speed_data: list[float] = []
fig, ax = plt.subplots()
def animate(i):
    ax.clear(); ax.plot(speed_data[-200:], color="#58a6ff")
    ax.set_ylim(0, 300); ax.set_title("Speed km/h")
ani = animation.FuncAnimation(fig, animate, interval=100)
plt.show()

# Post-session analysis — Plotly HTML report
import plotly.graph_objects as go
from plotly.subplots import make_subplots

def plot_lap_comparison(df_a: pd.DataFrame, df_b: pd.DataFrame) -> go.Figure:
    fig = make_subplots(rows=3, cols=1, shared_xaxes=True,
                        subplot_titles=("Speed", "Throttle/Brake", "Wheel Slip"))
    for df, name, color in [(df_a, "Lap A", "#58a6ff"), (df_b, "Lap B", "#f78166")]:
        fig.add_trace(go.Scatter(x=df["timestamp"], y=df["speed_kmh"],
                                 name=name, line=dict(color=color)), row=1, col=1)
    fig.update_layout(template="plotly_dark", height=700)
    return fig  # fig.write_html("lap_compare.html")
```

---

### 2d. Desktop GUI Overlay (PyQt6)

```python
from PyQt6.QtWidgets import QApplication, QMainWindow, QLabel, QVBoxLayout, QWidget
from PyQt6.QtCore import QTimer, Qt
from PyQt6.QtGui import QFont
import sys

class ACOverlay(QMainWindow):
    def __init__(self):
        super().__init__()
        self.setWindowFlags(Qt.WindowType.FramelessWindowHint |
                            Qt.WindowType.WindowStaysOnTopHint)
        self.setAttribute(Qt.WidgetAttribute.WA_TranslucentBackground)
        self._label = QLabel("0 km/h")
        self._label.setFont(QFont("JetBrains Mono", 32, QFont.Weight.Bold))
        self._label.setStyleSheet("color: #58a6ff;")
        w = QWidget(); lay = QVBoxLayout(); lay.addWidget(self._label)
        w.setLayout(lay); self.setCentralWidget(w)
        self._shm = open_shared_map("Local\\acpmf_physics", SPageFilePhysics)
        self._last_id = -1
        QTimer(self, timeout=self._poll, interval=16).start()

    def _poll(self):
        phys = read_struct(self._shm, SPageFilePhysics)
        if phys.packetId != self._last_id:
            self._last_id = phys.packetId
            self._label.setText(f"{phys.speedKmh:.0f} km/h")

if __name__ == "__main__":
    app = QApplication(sys.argv)
    ACOverlay().show()
    sys.exit(app.exec())
```

---

### 2e. WebSocket Bridge (FastAPI + asyncio)

Stream telemetry to a browser scoreboard or remote dashboard:

```python
from fastapi import FastAPI, WebSocket
import asyncio, json

app = FastAPI()
stream = TelemetryStream(poll_hz=60)
subscribers: list[WebSocket] = []

@app.websocket("/telemetry")
async def ws_endpoint(ws: WebSocket):
    await ws.accept()
    subscribers.append(ws)
    try:
        while True: await ws.receive_text()
    finally:
        subscribers.remove(ws)

@stream.on_frame
async def broadcast(frame: TelemetryFrame):
    payload = json.dumps(vars(frame))
    dead = []
    for ws in subscribers:
        try: await ws.send_text(payload)
        except Exception: dead.append(ws)
    for ws in dead: subscribers.remove(ws)

# Run: uvicorn main:app --port 8765
```

---

## 3. Expert App Dev Skill Matrix

Apply on ALL Expert-complexity Python AC projects:

| Concern              | Tool / Pattern                                    | Notes                                         |
|----------------------|---------------------------------------------------|-----------------------------------------------|
| Type safety          | `mypy --strict` + `pydantic v2`                   | All IO boundaries as Pydantic BaseModel       |
| Web framework        | `FastAPI` + `uvicorn`                             | Async-native, auto OpenAPI docs               |
| ORM                  | `SQLAlchemy 2.x async` + `alembic`               | Always `AsyncSession`, never sync in async    |
| Testing              | `pytest` + `pytest-asyncio` + `pytest-cov`        | Coverage ≥ 80%, asyncio_mode = "auto"         |
| Packaging            | `uv` (fastest resolver)                           | Lock file always committed                    |
| Linting              | `ruff` (replaces flake8 + isort + pyupgrade)      | Single tool, zero config needed               |
| Formatting           | `black` line-length 100                           | Non-negotiable for AC tool projects           |
| Background tasks     | `asyncio.TaskGroup` (Python 3.11+)                | Prefer over Celery for single-process         |
| Caching              | `functools.lru_cache` / `redis-py` async          | Redis for multi-process or persistent         |
| Logging              | `structlog` + `RotatingFileHandler`               | JSON output for tooling, human-readable dev   |
| Profiling            | `cProfile` + `snakeviz` / `py-spy` (live)        | Profile before optimizing hot paths           |
| Windows integration  | `pywin32`                                         | Window handles, process info, z-order         |
| Input capture        | `pynput`                                          | Global hotkeys for overlay toggle / logging   |
| Video/replay         | `ffmpeg-python`                                   | Sync telemetry with replay video              |
| Auth (if API)        | `python-jose` JWT + `passlib[bcrypt]`             | Never roll own crypto                         |

---

## 4. AC-Specific Library Ecosystem

| Library           | Purpose                                           | Install                            |
|-------------------|---------------------------------------------------|------------------------------------|
| `sim_info`        | AC shared memory wrapper (AC SDK style)           | Bundled with AC / manual port      |
| `pandas`          | Lap data analysis, channel comparison             | `uv add pandas`                    |
| `numpy`           | Vectorized tyre/slip/angle calculations           | `uv add numpy`                     |
| `plotly`          | Interactive HTML lap analysis reports             | `uv add plotly`                    |
| `matplotlib`      | Live overlays, offline session plots              | `uv add matplotlib`                |
| `PyQt6`           | Desktop GUI overlays (stays-on-top window)        | `uv add PyQt6`                     |
| `fastapi`         | REST + WebSocket bridge to browser overlays       | `uv add fastapi uvicorn`           |
| `pydantic`        | Telemetry frame models, config validation         | `uv add pydantic`                  |
| `sqlalchemy`      | Lap database / session history                    | `uv add sqlalchemy aiosqlite`      |
| `pywin32`         | Win32 API — window z-order, process hooks         | `uv add pywin32`                   |
| `pynput`          | Global hotkey listener for overlays               | `uv add pynput`                    |
| `ffmpeg-python`   | Telemetry + video mux for replay analysis         | `uv add ffmpeg-python`             |
| `rich`            | Terminal dashboards, CLI output                   | `uv add rich`                      |
| `typer`           | CLI interfaces for AC utility tools               | `uv add typer`                     |
| `httpx`           | Async HTTP for AC server REST APIs                | `uv add httpx`                     |
| `structlog`       | Structured logging (JSON + human)                 | `uv add structlog`                 |

---

## 5. Expert Python Tooling Standards

### Always generate these files

```
pyproject.toml          ← project metadata, ruff/black/mypy/pytest config
uv.lock                 ← locked deps, always committed
.python-version         ← exact pin (e.g., 3.12.3)
.env.example            ← all env vars documented
Makefile                ← make test, make lint, make run
```

### pyproject.toml baseline (Expert AC project)

```toml
[project]
name = "ac-tool"
version = "0.1.0"
requires-python = ">=3.12"
dependencies = [
    "fastapi>=0.115", "uvicorn[standard]>=0.30",
    "pydantic>=2.7", "sqlalchemy>=2.0", "aiosqlite>=0.20",
    "numpy>=2.0", "pandas>=2.2", "plotly>=5.22",
    "pywin32>=306", "structlog>=24.1", "httpx>=0.27",
]

[tool.ruff]
line-length = 100
select = ["E","F","I","UP","B","SIM"]

[tool.black]
line-length = 100

[tool.mypy]
strict = true
python_version = "3.12"

[tool.pytest.ini_options]
asyncio_mode = "auto"
```

### CI (GitHub Actions — Windows-first for AC tools)

```yaml
name: CI
on: [push, pull_request]
jobs:
  check:
    runs-on: windows-latest
    steps:
      - uses: actions/checkout@v4
      - uses: astral-sh/setup-uv@v3
      - run: uv sync --frozen
      - run: uv run ruff check .
      - run: uv run black --check .
      - run: uv run mypy .
      - run: uv run pytest --cov --cov-fail-under=80
```

---

## 6. AC App Archetypes + Starter Stacks

### A — Real-Time HUD Overlay
```
Stack:    Python 3.12 / PyQt6 / ctypes mmap / structlog
Pattern:  QTimer @16ms → mmap read → Qt label update
Key libs: PyQt6, pywin32, pynput
Deploy:   PyInstaller one-file EXE (add --hidden-import win32api)
```

### B — Telemetry Logger + Lap Analyzer
```
Stack:    Python 3.12 / FastAPI / SQLAlchemy async / aiosqlite / pandas / plotly
Pattern:  TelemetryStream → SQLite insert → REST API + Plotly HTML reports
Deploy:   Local service + Windows Task Scheduler autostart
```

### C — AC Server Admin Tool
```
Stack:    Python 3.12 / FastAPI / httpx / Typer / rich
Pattern:  Typer CLI + FastAPI REST proxy to AC server UDP/REST
Deploy:   Docker (Linux server) or bare Python service (Windows)
```

### D — Drift Scoring Engine (CYS-style)
```
Stack:    Python 3.12 / numpy / pandas / FastAPI / pydantic v2
Input:    mmap SPageFilePhysics @100Hz — angle, speed, slip, proximity delta
Scoring:  configurable formula (angle × speed × zone_multiplier)
Output:   WebSocket → browser scoreboard on LAN
Deploy:   Local service, scoreboard served on LAN browser
```

---

## 7. Known Pitfalls and Hard Rules

| Pitfall                               | Rule                                                               |
|---------------------------------------|--------------------------------------------------------------------|
| Casting live mmap slice               | ALWAYS copy: `.read()` then `from_buffer_copy()` — never direct cast |
| `threading` in AC plugin              | Use `acUpdate` loop only — threading crashes AC plugin sandbox    |
| `asyncio.run()` inside async context  | Use `create_task()` or `TaskGroup` — never nested `run()`         |
| numpy 1.x vs 2.x                      | Pin `numpy>=2.0` — dtype API changed, breaks 1.x code silently   |
| PyInstaller + pywin32                 | `--hidden-import win32api,win32con,pywintypes` — not auto-detected |
| mmap when AC not running              | Always wrap `open_shared_map()` in `try/except`                   |
| Stale `SPageFileStatic`               | Gate reads on `SPageFileGraphics.status == AC_LIVE`               |
| `packetId` integer overflow           | Compare with `!=` not `>` — wraps at ~2.1B (c_int32)             |
| Plotly in PyInstaller bundle          | Use `fig.write_html("out.html")` — embedded renderer broken       |
| pydantic v1 vs v2 syntax             | Use `model_config = ConfigDict(...)` not `class Config` (v2 only) |
| `asyncio_mode` not set in pytest      | Add `asyncio_mode = "auto"` in `pyproject.toml` or tests hang     |
