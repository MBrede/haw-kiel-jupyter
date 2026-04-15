#!/bin/bash
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Adapted for HAW Kiel: activates uv venv instead of conda environment

NB_USER="${NB_USER:-jovyan}"
VENV="${VENV:-/home/${NB_USER}/.venv}"

if [[ -f "${VENV}/bin/activate" ]]; then
    # shellcheck disable=SC1090
    source "${VENV}/bin/activate"
fi
