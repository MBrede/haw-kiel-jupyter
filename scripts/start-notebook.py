#!/usr/bin/env python
# Copyright (c) Jupyter Development Team.
# Distributed under the terms of the Modified BSD License.
# Adapted for HAW Kiel: prepends uv venv to PATH so jupyter resolves from venv
import os
import shlex
import sys

# Ensure uv venv is on PATH
NB_USER = os.environ.get("NB_USER", "jovyan")
VENV = os.environ.get("VENV", f"/home/{NB_USER}/.venv")
venv_bin = os.path.join(VENV, "bin")
current_path = os.environ.get("PATH", "")
if venv_bin not in current_path:
    os.environ["PATH"] = f"{venv_bin}:{current_path}"
os.environ["VIRTUAL_ENV"] = VENV

# If we are in a JupyterHub, pass on to start-singleuser.py instead
if "JUPYTERHUB_API_TOKEN" in os.environ:
    print(
        "WARNING: using start-singleuser.py instead of start-notebook.py to start a server associated with JupyterHub.",
        flush=True,
    )
    command = ["/usr/local/bin/start-singleuser.py"] + sys.argv[1:]
    os.execvp(command[0], command)

command = []

if os.environ.get("RESTARTABLE") == "yes":
    command.append("run-one-constantly")

command.append("jupyter")

jupyter_command = os.environ.get("DOCKER_STACKS_JUPYTER_CMD", "lab")
command.append(jupyter_command)

if "NOTEBOOK_ARGS" in os.environ:
    command += shlex.split(os.environ["NOTEBOOK_ARGS"])

command += sys.argv[1:]

print("Executing: " + " ".join(command), flush=True)
os.execvp(command[0], command)
