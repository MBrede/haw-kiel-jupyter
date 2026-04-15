# HAW Kiel Jupyter Notebook Images

Custom JupyterHub single-user notebook images for the teaching infrastructure at
[HAW Kiel](https://www.haw-hamburg.de/hochschule/technik-und-informatik/departments/informatik/),
used in courses on Data Science, Cloud Computing, and Generative AI.

Deployed on a Kubernetes (RKE2) cluster on DFNCloud OpenStack with JupyterHub and Keycloak SSO.

## Images

| Image | Tag | Description |
|---|---|---|
| [`mbrede/notebook-base`](https://hub.docker.com/r/mbrede/notebook-base) | `latest` | Shared base: uv venv, R via r2u, all common packages |
| [`mbrede/notebook-cpu`](https://hub.docker.com/r/mbrede/notebook-cpu) | `latest` | Base + CPU-only PyTorch |
| [`mbrede/notebook-gpu`](https://hub.docker.com/r/mbrede/notebook-gpu) | `latest` | Base + CUDA PyTorch + nvdashboard |

## Stack

- **Python** — [uv](https://github.com/astral-sh/uv) venv at `~/.venv`, registered as "Python (uv)" kernel
- **R** — installed via [r2u](https://eddelbuettel.github.io/r2u/) binary apt packages for Ubuntu 24.04, registered as "R" kernel
- **Marimo** — [Marimo](https://marimo.io/) reactive notebooks, registered as "Marimo" kernel
- **Base OS** — Ubuntu 24.04 (noble)
- **JupyterHub compatibility** — startup scripts adapted from [Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks), supports `NB_UID`/`NB_GID` remapping and `before-notebook.d` hooks

## Repository Structure

```
├── Dockerfile.base          # Ubuntu 24.04 + uv + R + all shared packages
├── Dockerfile.cpu           # extends base, adds CPU-only PyTorch
├── Dockerfile.gpu           # extends base, adds CUDA PyTorch + nvdashboard
├── test.sh                  # build and test all images locally
├── DOCKER_README.md         # Docker Hub description
├── LICENSE
└── scripts/
    ├── fix-permissions          # verbatim from jupyter/docker-stacks-foundation
    ├── run-hooks.sh             # verbatim from jupyter/docker-stacks-foundation
    ├── start.sh                 # verbatim from jupyter/docker-stacks-foundation
    ├── start-singleuser.py      # verbatim from jupyter/base-notebook
    ├── docker_healthcheck.py    # verbatim from jupyter/base-notebook
    ├── start-notebook.py        # adapted: prepends uv venv to PATH
    ├── jupyter_server_config.py # adapted: CONDA_DIR → VENV
    └── 10activate-venv.sh       # replaces 10activate-conda-env.sh
```

## Building

```bash
export REGISTRY=docker.io
export REGISTRY_USER=mbrede

# build and test locally first
./test.sh

# push base
docker tag notebook-base:test ${REGISTRY}/${REGISTRY_USER}/notebook-base:latest
docker push ${REGISTRY}/${REGISTRY_USER}/notebook-base:latest

# build and push cpu and gpu
docker build -f Dockerfile.cpu \
  --build-arg BASE_IMAGE=${REGISTRY}/${REGISTRY_USER}/notebook-base:latest \
  -t ${REGISTRY}/${REGISTRY_USER}/notebook-cpu:latest .
docker push ${REGISTRY}/${REGISTRY_USER}/notebook-cpu:latest

docker build -f Dockerfile.gpu \
  --build-arg BASE_IMAGE=${REGISTRY}/${REGISTRY_USER}/notebook-base:latest \
  -t ${REGISTRY}/${REGISTRY_USER}/notebook-gpu:latest .
docker push ${REGISTRY}/${REGISTRY_USER}/notebook-gpu:latest
```

## Testing

```bash
chmod +x test.sh
./test.sh

# verbose output for passing tests too
VERBOSE=1 ./test.sh
```

The test script builds all three images locally, runs import checks for every
Python and R package, verifies kernel registration, checks startup script
availability, and prints push commands on success.

## Attribution

Startup scripts and container conventions are adapted from
[Jupyter Docker Stacks](https://github.com/jupyter/docker-stacks)
(Copyright © Jupyter Development Team, Modified BSD License).
See [LICENSE](LICENSE) for details.

## License

BSD 3-Clause — see [LICENSE](LICENSE).
