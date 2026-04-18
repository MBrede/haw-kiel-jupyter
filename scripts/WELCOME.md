# Welcome to the HAW Kiel JupyterHub

## Available Kernels

| Kernel | Use |
|--------|-----|
| **Python (uv)** | Standard Python kernel — all scientific packages pre-installed |
| **R** | R kernel with tidyverse, caret, tidymodels and more |
| **Marimo** | Reactive notebooks (`.py` files) — see section below |

## Switching Profiles

Use **Hub → Switch Server Profile** (or `Ctrl+Shift+H`) to change your compute profile:

| Profile | CPU | RAM | GPU |
|---------|-----|-----|-----|
| Standard | 16 cores | 16 GB | — |
| Large CPU | 32 cores | 32 GB | — |
| GPU | 16 cores | 32 GB | NVIDIA A40 (46 GB VRAM) |
| GPU (shared) | 8 cores | 16 GB | ~12 GB VRAM |

> **Note:** Switching profiles stops your running server. Your files are always preserved.

## Installing Python Packages

Packages installed into the venv at `/opt/venv` persist across sessions:

```bash
uv pip install <package>
```

For a quick one-off install in the current session:

```bash
pip install <package>
```

## Installing R Packages

R is configured with `bspm` (Bridge to System Package Manager).
`install.packages()` automatically uses apt binary packages via r2u — much faster than building from source:

```r
install.packages("ggplot2")   # installs the pre-built r-cran-ggplot2 binary
```

Packages not available via r2u fall back to CRAN automatically.

## Marimo

Marimo is a reactive notebook format for Python (`.py` files instead of `.ipynb`).

**New Marimo notebook:** Launcher → *New Marimo Notebook*

**Open an existing `.py` file:** Right-click → *Edit with marimo*

**Convert a Jupyter notebook:** Right-click on `.ipynb` → *Convert to marimo*

Start the Marimo server from the sidebar (Marimo icon on the left panel).
Marimo sessions run independently of the Jupyter kernel — start the server once per session.

## File Storage

All files under `~/` (your home directory) are stored on a persistent 50 GB volume and survive server restarts and profile switches.

> `lost+found` visible in the file browser can be ignored — it is a filesystem artifact.

## GPU Monitoring

In GPU profiles, **nvdashboard** is available:

```
Menu: View → Activate Command Palette → type "GPU" → open GPU Dashboards
```

Shows real-time VRAM usage, GPU utilisation, and memory bandwidth.

## Managing API Keys (Secrets Manager)

The **Secrets Manager** extension lets you store API keys (GitHub, HuggingFace, OpenAI, etc.) securely in your session without hardcoding them in notebooks.

Access it via the key icon in the left sidebar. Secrets are stored **in memory only** — they are not written to disk and must be re-entered after each server restart.

## Assignments (nbgrader)

If your course uses nbgrader for assignments:

```bash
# List available assignments
nbgrader list --course <course-id>

# Fetch an assignment
nbgrader fetch_assignment --course <course-id> <assignment>

# Submit your work
nbgrader submit --course <course-id> <assignment>
```

Ask your instructor for the course ID.

---

*Questions or issues? Contact your instructor or the IT support team.*
