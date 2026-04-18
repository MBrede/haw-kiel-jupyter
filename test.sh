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
FAILED_TESTS=()

# ── helpers ───────────────────────────────────────────────────────────────────
_header() { echo ""; echo "══════════════════════════════════════════════════════"; echo "  $*"; echo "══════════════════════════════════════════════════════"; }
_step()   { echo "  ▶ $*"; }
_ok()     { echo "  ✓ $*"; ((PASS++)); }
_fail()   { echo "  ✗ $*"; ((FAIL++)); FAILED_TESTS+=("$*"); }

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

run_test "python resolves to venv python" \
    "${BASE_IMAGE}" bash -c 'python -c "import sys; assert sys.prefix == \"/opt/venv\", f\"Wrong prefix: {sys.prefix}\""'

run_test "uv available" \
    "${BASE_IMAGE}" uv --version

# ── kernel location tests (kernels must survive PVC home mount) ───────────────
_header "Testing kernel locations: ${BASE_IMAGE}"

run_test "uv-env kernel not in home dir (would be hidden by PVC)" \
    "${BASE_IMAGE}" bash -c '! test -f /home/jovyan/.local/share/jupyter/kernels/uv-env/kernel.json'

run_test "marimo CLI available in venv" \
    "${BASE_IMAGE}" bash -c 'test -x /opt/venv/bin/marimo'

run_test "marimo-jupyter-extension installed as labextension" \
    "${BASE_IMAGE}" bash -c 'test -d /opt/venv/share/jupyter/labextensions/@marimo-team'

# ── bspm / R package manager tests ───────────────────────────────────────────
_header "Testing bspm sudo configuration: ${BASE_IMAGE}"

run_test "bspm.sudo = TRUE set in Rprofile.site" \
    "${BASE_IMAGE}" bash -c 'grep -q "bspm.sudo = TRUE" /etc/R/Rprofile.site'

run_test "bspm sudoers rule has correct permissions (0440)" \
    --user root --entrypoint bash "${BASE_IMAGE}" -c '[[ $(stat -c "%a" /etc/sudoers.d/bspm) == "440" ]]'

run_test "bspm sudoers rule scoped to bspm.py only" \
    --user root --entrypoint bash "${BASE_IMAGE}" -c 'grep "bspm.py" /etc/sudoers.d/bspm'

run_test "bspm.py owned by root (not writable by jovyan)" \
    --entrypoint bash "${BASE_IMAGE}" -c '[[ $(stat -c "%U" /usr/local/lib/R/site-library/bspm/service/bspm.py) == "root" ]]'

# ── package smoke tests (one each — if venv/R is broken nothing imports) ──────
_header "Testing packages: ${BASE_IMAGE}"

run_test "Python venv packages (cloudpickle)" \
    "${BASE_IMAGE}" python -c "import cloudpickle; print(cloudpickle.__version__)"

run_test "R packages (crayon)" \
    "${BASE_IMAGE}" Rscript -e "library(crayon); cat('crayon OK\n')"

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

# ── UID remapping test ────────────────────────────────────────────────────────
_header "Testing NB_UID remapping: ${BASE_IMAGE}"

run_test "start.sh remaps UID when run as root with NB_UID set" \
    -e NB_UID=1234 --user root \
    "${BASE_IMAGE}" bash -c 'id jovyan | grep -q "uid=1234" && echo "UID remap OK"'

# ── single-user server test helper ───────────────────────────────────────────
# Uses jupyter lab with a generated token — no JupyterHub required
test_singleuser() {
    local image="$1"
    local port="$2"

    _step "Starting Jupyter server (${image})"
    CID=$(docker run -d \
        -p "${port}:8888" \
        "${image}" \
        jupyter lab --no-browser --ip=0.0.0.0 --ServerApp.token='' --ServerApp.password='' 2>/dev/null)

    if [[ -z "${CID}" ]]; then
        _fail "Could not start server container (${image})"
        return
    fi

    # wait up to 30s for server to respond
    READY=0
    for i in $(seq 1 30); do
        if curl -sf -o /dev/null "http://localhost:${port}/api" 2>/dev/null; then
            READY=1
            break
        fi
        sleep 1
    done

    if [[ "${READY}" -eq 1 ]]; then
        _ok "Server started and healthy (${image})"
    else
        _fail "Server did not become healthy within 30s (${image})"
        docker logs "${CID}" 2>&1 | tail -20 | sed 's/^/    /'
    fi

    docker rm -f "${CID}" > /dev/null 2>&1
}

_header "Testing single-user server: ${BASE_IMAGE}"
test_singleuser "${BASE_IMAGE}" 18888

run_test "uv-env kernel registered" \
    "${BASE_IMAGE}" bash -c 'jupyter kernelspec list | grep -q uv-env'
run_test "IR kernel registered" \
    "${BASE_IMAGE}" bash -c 'jupyter kernelspec list | grep -qi ir'
run_test "Marimo server extension enabled" \
    "${BASE_IMAGE}" bash -c 'jupyter server extension list 2>&1 | grep -qi marimo'

# ── CPU image tests ───────────────────────────────────────────────────────────
_header "Testing CPU image: ${CPU_IMAGE}"

run_test "torch CPU-only build" \
    "${CPU_IMAGE}" python -c "import torch; assert not torch.cuda.is_available(), 'CUDA unexpectedly available'; print(torch.__version__)"

test_singleuser "${CPU_IMAGE}" 18889

# ── GPU image tests ───────────────────────────────────────────────────────────
_header "Testing GPU image: ${GPU_IMAGE}"

run_test "nvdashboard installed" \
    "${GPU_IMAGE}" python -c "import jupyterlab_nvdashboard; print('nvdashboard OK')"

run_test "VRAM limit script reads VRAM_LIMIT_GB" \
    "${GPU_IMAGE}" bash -c 'grep -q "VRAM_LIMIT_GB" /home/jovyan/.ipython/profile_default/startup/00-gpu-limit.py'

test_singleuser "${GPU_IMAGE}" 18890

# ── summary ───────────────────────────────────────────────────────────────────
_header "Test Summary"
echo "  Passed: ${PASS}"
echo "  Failed: ${FAIL}"

if [[ "${FAIL}" -gt 0 ]]; then
    echo ""
    echo "  Failed tests:"
    for t in "${FAILED_TESTS[@]}"; do
        echo "    ✗ ${t}"
    done
    echo ""
    echo "  Fix the above before pushing."
    exit 1
fi

echo "  ✓ All tests passed."
echo ""

if [[ "${REGISTRY_USER}" == "local" ]]; then
    echo "  REGISTRY_USER not set — skipping push."
    echo "  Set REGISTRY and REGISTRY_USER to push automatically."
    exit 0
fi

# ── push ──────────────────────────────────────────────────────────────────────
_header "Pushing to ${REGISTRY}/${REGISTRY_USER}"

push_image() {
    local src="$1"
    local dst="$2"
    _step "Tagging ${src} → ${dst}"
    docker tag "${src}" "${dst}"
    _step "Pushing ${dst}"
    if docker push "${dst}" 2>&1; then
        _ok "Pushed ${dst}"
    else
        _fail "Push failed: ${dst}"
    fi
}

push_image "${BASE_IMAGE}" "${REGISTRY}/${REGISTRY_USER}/notebook-base:latest"
push_image "${CPU_IMAGE}"  "${REGISTRY}/${REGISTRY_USER}/notebook-cpu:latest"
push_image "${GPU_IMAGE}"  "${REGISTRY}/${REGISTRY_USER}/notebook-gpu:latest"

echo ""
if [[ "${FAIL}" -gt 0 ]]; then
    echo "  ✗ Some pushes failed."
    exit 1
else
    echo "  ✓ All images pushed successfully."
    exit 0
fi
