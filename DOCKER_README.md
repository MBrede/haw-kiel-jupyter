# HAW Kiel JupyterHub Notebook Images

Custom notebook images for the JupyterHub teaching infrastructure at HAW Kiel (Hochschule für Angewandte Wissenschaften Kiel). Built for use with JupyterHub on a Kubernetes (RKE2) cluster and designed for courses in Data Science, Cloud Computing, and Generative AI.

## Images

| Image | Base | Description |
|---|---|---|
| `notebook-base` | ubuntu:24.04 | Shared base with all common packages |
| `notebook-cpu` | `notebook-base` | CPU-only PyTorch for standard workloads |
| `notebook-gpu` | `notebook-base` | CUDA-enabled PyTorch + GPU monitoring |

## Kernels

All images expose three Jupyter kernels:

- **Python (uv)** — Python 3.12 in a [uv](https://github.com/astral-sh/uv)-managed virtual environment
- **R** — R via [r2u](https://eddelbuettel.github.io/r2u/) binary packages for Ubuntu 24.04
- **Marimo** — [Marimo](https://marimo.io/) reactive notebook kernel

## Python Packages

All images include the following Python packages (installed via `uv` into a virtual environment at `~/.venv`):

`jupyterlab`, `jupyterhub`, `notebook`, `ipykernel`, `ipympl`, `ipywidgets`, `altair`, `beautifulsoup4`, `bokeh`, `bottleneck`, `cloudpickle`, `dask`, `dill`, `h5py`, `jupyterlab-git`, `matplotlib`, `numba`, `numexpr`, `numpy`, `openpyxl`, `pandas`, `patsy`, `plotly`, `scikit-image`, `scikit-learn`, `scipy`, `seaborn`, `sentence-transformers`, `sqlalchemy`, `statsmodels`, `sympy`, `transformers`, `xlrd`, `jupyter-resource-usage`, `marimo`, `uv`

The `notebook-cpu` image adds CPU-only PyTorch. The `notebook-gpu` image adds CUDA-enabled PyTorch and `jupyterlab-nvdashboard` for GPU monitoring.

## R Packages

R packages are installed via [r2u](https://eddelbuettel.github.io/r2u/) as pre-compiled Ubuntu binaries (significantly faster than `install.packages()`):

`r-base`, `caret`, `crayon`, `devtools`, `e1071`, `forecast`, `hexbin`, `htmltools`, `htmlwidgets`, `IRkernel`, `nycflights13`, `randomForest`, `RCurl`, `rmarkdown`, `RODBC`, `RSQLite`, `shiny`, `tidymodels`, `tidyverse`

## Attribution

The startup scripts (`start.sh`, `run-hooks.sh`, `fix-permissions`), server configuration (`jupyter_server_config.py`), and container conventions (jovyan user, `NB_UID`/`NB_GID` remapping, `before-notebook.d` hooks) are adapted from the [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks) project.

> Copyright (c) Jupyter Development Team.
> Distributed under the terms of the Modified BSD License.

The following files are copied verbatim from `jupyter/docker-stacks`:
- `fix-permissions` (from `docker-stacks-foundation`)
- `run-hooks.sh` (from `docker-stacks-foundation`)
- `start.sh` (from `docker-stacks-foundation`)
- `start-singleuser.py` (from `base-notebook`)
- `docker_healthcheck.py` (from `base-notebook`)

The following files are adapted:
- `start-notebook.py` — prepends the uv venv to `PATH` before delegating to `start.sh`
- `jupyter_server_config.py` — `CONDA_DIR` reference replaced with `VENV` for SSL certificate path resolution

## Key Differences from Jupyter Docker Stacks

- **No conda/mamba** — Python package management is handled entirely by [uv](https://github.com/astral-sh/uv)
- **uv venv as kernel** — the active Python kernel is a uv-managed venv at `~/.venv`, not the conda base environment
- **R via r2u** — binary R packages from Ubuntu apt instead of conda
- **Built from `ubuntu:24.04`** — no conda base layer

## Source

[github.com/MBrede/haw-kiel-jupyter](https://github.com/MBrede/haw-kiel-jupyter)
