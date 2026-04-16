#!/bin/bash
# HAW Kiel Notebook Image Test Suite
# Tests base, cpu, and gpu images before pushing to registry

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "${SCRIPT_DIR}"

REGISTRY="${REGISTRY:-docker.io}"
REGISTRY_USER="${REGISTRY_USER:-local}"
TAG="${TAG:-test}"

BASE_IMAGE="notebook-base:${TAG}"
CPU_IMAGE="notebook-cpu:${TAG}"
GPU_IMAGE="notebook-gpu:${TAG}"

PASS=0
FAIL=0

# ── helpers ───────────────────────────────────────────────────────────────────
_header() { echo ""; echo "══════════════════════════════════════════════════════"; echo "  $*"; echo "══════════════════════════════════════════════════════"; }
_step()   { echo "  ▶ $*"; }
_ok()     { echo "  ✓ $*"; ((PASS++)); }
_fail()   { echo "  ✗ $*"; ((FAIL++)); }

run_test() {
    local description="$1"
    shift
    _step "${description}"
    if output=$(docker run --rm "$@" 2>&1); then
        _ok "${description}"
        if [[ "${VERBOSE:-0}" == "1" ]]; then
            echo "${output}" | sed 's/^/    /'
        fi
    else
        _fail "${description}"
        echo "${output}" | sed 's/^/    /'
    fi
}

# ── build ─────────────────────────────────────────────────────────────────────
_header "Building images"

_step "Building base image"
if docker build -f Dockerfile.base -t "${BASE_IMAGE}" . 2>&1; then
    _ok "Base image built"
else
    _fail "Base image build failed"
    echo "  Cannot continue without base image."
    exit 1
fi

_step "Building CPU image"
if docker build -f Dockerfile.cpu \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    -t "${CPU_IMAGE}" . 2>&1; then
    _ok "CPU image built"
else
    _fail "CPU image build failed"
fi

_step "Building GPU image"
if docker build -f Dockerfile.gpu \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    -t "${GPU_IMAGE}" . 2>&1; then
    _ok "GPU image built"
else
    _fail "GPU image build failed"
fi

# ── base image tests ──────────────────────────────────────────────────────────
_header "Testing base image: ${BASE_IMAGE}"

_step "Checking image size"
SIZE=$(docker image inspect "${BASE_IMAGE}" --format='{{.Size}}' | awk '{printf "%.1f GB\n", $1/1073741824}')
_ok "Image size: ${SIZE}"

run_test "jovyan user exists with correct UID" \
    "${BASE_IMAGE}" bash -c 'id jovyan | grep -q "uid=1000"'

run_test "venv exists at ~/.venv" \
    "${BASE_IMAGE}" test -d /home/jovyan/.venv

run_test "uv available in venv" \
    "${BASE_IMAGE}" uv --version

run_test "python resolves to venv python" \
    "${BASE_IMAGE}" bash -c 'python --version && python -c "import sys; assert \".venv\" in sys.prefix, f\"Wrong prefix: {sys.prefix}\""'

run_test "jupyterhub-singleuser available" \
    "${BASE_IMAGE}" jupyterhub-singleuser --version

run_test "jupyterhub-singleuser symlinked to /usr/local/bin" \
    "${BASE_IMAGE}" test -L /usr/local/bin/jupyterhub-singleuser

run_test "jupyter symlinked to /usr/local/bin" \
    "${BASE_IMAGE}" test -L /usr/local/bin/jupyter

run_test "jupyter lab available" \
    "${BASE_IMAGE}" jupyter lab --version

run_test "jupyter kernelspec list shows Python (uv)" \
    "${BASE_IMAGE}" bash -c 'jupyter kernelspec list | grep -q "uv-env"'

run_test "jupyter kernelspec list shows R" \
    "${BASE_IMAGE}" bash -c 'jupyter kernelspec list | grep -qi "ir"'

run_test "start.sh is executable" \
    "${BASE_IMAGE}" test -x /usr/local/bin/start.sh

run_test "fix-permissions is executable" \
    "${BASE_IMAGE}" test -x /usr/local/bin/fix-permissions

run_test "run-hooks.sh is executable" \
    "${BASE_IMAGE}" test -x /usr/local/bin/run-hooks.sh

run_test "before-notebook.d directory exists" \
    "${BASE_IMAGE}" test -d /usr/local/bin/before-notebook.d

# ── Python package tests ───────────────────────────────────────────────────────
_header "Testing Python packages: ${BASE_IMAGE}"

run_test "numpy" \
    "${BASE_IMAGE}" python -c "import numpy; print(numpy.__version__)"

run_test "pandas" \
    "${BASE_IMAGE}" python -c "import pandas; print(pandas.__version__)"

run_test "scipy" \
    "${BASE_IMAGE}" python -c "import scipy; print(scipy.__version__)"

run_test "matplotlib" \
    "${BASE_IMAGE}" python -c "import matplotlib; print(matplotlib.__version__)"

run_test "scikit-learn" \
    "${BASE_IMAGE}" python -c "import sklearn; print(sklearn.__version__)"

run_test "seaborn" \
    "${BASE_IMAGE}" python -c "import seaborn; print(seaborn.__version__)"

run_test "plotly" \
    "${BASE_IMAGE}" python -c "import plotly; print(plotly.__version__)"

run_test "transformers" \
    "${BASE_IMAGE}" python -c "import transformers; print(transformers.__version__)"

run_test "sentence-transformers" \
    "${BASE_IMAGE}" python -c "import sentence_transformers; print(sentence_transformers.__version__)"

run_test "dask" \
    "${BASE_IMAGE}" python -c "import dask; print(dask.__version__)"

run_test "bokeh" \
    "${BASE_IMAGE}" python -c "import bokeh; print(bokeh.__version__)"

run_test "altair" \
    "${BASE_IMAGE}" python -c "import altair; print(altair.__version__)"

run_test "statsmodels" \
    "${BASE_IMAGE}" python -c "import statsmodels; print(statsmodels.__version__)"

run_test "sympy" \
    "${BASE_IMAGE}" python -c "import sympy; print(sympy.__version__)"

run_test "sqlalchemy" \
    "${BASE_IMAGE}" python -c "import sqlalchemy; print(sqlalchemy.__version__)"

run_test "numba" \
    "${BASE_IMAGE}" python -c "import numba; print(numba.__version__)"

run_test "h5py" \
    "${BASE_IMAGE}" python -c "import h5py; print(h5py.__version__)"

run_test "jupyter-resource-usage" \
    "${BASE_IMAGE}" python -c "import jupyter_resource_usage"

run_test "uv importable from venv" \
    "${BASE_IMAGE}" python -c "import uv"

# ── R tests ───────────────────────────────────────────────────────────────────
_header "Testing R packages: ${BASE_IMAGE}"

run_test "R available" \
    "${BASE_IMAGE}" Rscript -e "cat(R.version\$version.string, '\n')"

run_test "tidyverse" \
    "${BASE_IMAGE}" Rscript -e "library(tidyverse); cat('tidyverse OK\n')"

run_test "tidymodels" \
    "${BASE_IMAGE}" Rscript -e "library(tidymodels); cat('tidymodels OK\n')"

run_test "ggplot2" \
    "${BASE_IMAGE}" Rscript -e "library(ggplot2); cat('ggplot2 OK\n')"

run_test "caret" \
    "${BASE_IMAGE}" Rscript -e "library(caret); cat('caret OK\n')"

run_test "randomForest" \
    "${BASE_IMAGE}" Rscript -e "library(randomForest); cat('randomForest OK\n')"

run_test "shiny" \
    "${BASE_IMAGE}" Rscript -e "library(shiny); cat('shiny OK\n')"

run_test "rmarkdown" \
    "${BASE_IMAGE}" Rscript -e "library(rmarkdown); cat('rmarkdown OK\n')"

run_test "IRkernel" \
    "${BASE_IMAGE}" Rscript -e "library(IRkernel); cat('IRkernel OK\n')"

# ── system tool tests ─────────────────────────────────────────────────────────
_header "Testing system tools: ${BASE_IMAGE}"

run_test "git" \
    "${BASE_IMAGE}" git --version

run_test "pandoc" \
    "${BASE_IMAGE}" pandoc --version

run_test "latex (xelatex)" \
    "${BASE_IMAGE}" xelatex --version

run_test "tini" \
    "${BASE_IMAGE}" tini --version

# ── uid remapping test ────────────────────────────────────────────────────────
_header "Testing NB_UID remapping: ${BASE_IMAGE}"

run_test "start.sh remaps UID when run as root with NB_UID set" \
    -e NB_UID=1234 --user root \
    "${BASE_IMAGE}" bash -c 'id jovyan | grep -q "uid=1234" && echo "UID remap OK"'

# ── CPU image tests ───────────────────────────────────────────────────────────
_header "Testing CPU image: ${CPU_IMAGE}"

run_test "torch importable" \
    "${CPU_IMAGE}" python -c "import torch; print(torch.__version__)"

run_test "torch is CPU-only build" \
    "${CPU_IMAGE}" python -c "import torch; assert not torch.cuda.is_available(), 'CUDA unexpectedly available'; print('CPU-only confirmed')"

run_test "torch basic tensor operation" \
    "${CPU_IMAGE}" python -c "import torch; x = torch.ones(3,3); print('tensor op OK:', x.sum().item())"

# ── GPU image tests ───────────────────────────────────────────────────────────
_header "Testing GPU image (build only — no GPU required): ${GPU_IMAGE}"

run_test "torch importable" \
    "${GPU_IMAGE}" python -c "import torch; print(torch.__version__)"

run_test "jupyterlab-nvdashboard installed" \
    "${GPU_IMAGE}" python -c "import jupyterlab_nvdashboard; print('nvdashboard OK')"

run_test "torch CUDA build (GPU availability depends on runtime)" \
    "${GPU_IMAGE}" python -c "import torch; print('CUDA available:', torch.cuda.is_available())"

# ── marimo kernel tests (in base image) ──────────────────────────────────────
_header "Testing Marimo kernel: ${BASE_IMAGE}"

run_test "marimo importable" \
    "${BASE_IMAGE}" python -c "import marimo; print(marimo.__version__)"

run_test "marimo CLI available" \
    "${BASE_IMAGE}" marimo --version

run_test "marimo kernelspec JSON exists" \
    "${BASE_IMAGE}" test -f "/home/jovyan/.local/share/jupyter/kernels/marimo/kernel.json"

run_test "marimo kernel registered" \
    "${BASE_IMAGE}" bash -c "jupyter kernelspec list | grep -qi marimo"

# ── summary ───────────────────────────────────────────────────────────────────
_header "Test Summary"
echo "  Passed: ${PASS}"
echo "  Failed: ${FAIL}"
echo ""

if [[ "${FAIL}" -gt 0 ]]; then
    echo "  ✗ Some tests failed. Fix issues before pushing."
    exit 1
else
    echo "  ✓ All tests passed. Safe to push."
    echo ""
    echo ""
    echo "  To push to registry:"
    echo "    export REGISTRY=docker.io"
    echo "    export REGISTRY_USER=<username>"
    echo ""
    echo "    docker login \${REGISTRY}"
    echo ""
    echo "    docker tag ${BASE_IMAGE} \${REGISTRY}/\${REGISTRY_USER}/notebook-base:latest"
    echo "    docker push \${REGISTRY}/\${REGISTRY_USER}/notebook-base:latest"
    echo ""
    echo "    docker build -f Dockerfile.cpu \"
    echo "      --build-arg BASE_IMAGE=\${REGISTRY}/\${REGISTRY_USER}/notebook-base:latest \"
    echo "      -t \${REGISTRY}/\${REGISTRY_USER}/notebook-cpu:latest ."
    echo "    docker push \${REGISTRY}/\${REGISTRY_USER}/notebook-cpu:latest"
    echo ""
    echo "    docker build -f Dockerfile.gpu \"
    echo "      --build-arg BASE_IMAGE=\${REGISTRY}/\${REGISTRY_USER}/notebook-base:latest \"
    echo "      -t \${REGISTRY}/\${REGISTRY_USER}/notebook-gpu:latest ."
    echo "    docker push \${REGISTRY}/\${REGISTRY_USER}/notebook-gpu:latest"

    exit 0
fi
