# System-wide nbgrader configuration — baked into the container image.
# Course-specific overrides go in ~/course/nbgrader_config.py.

c = get_config()  # noqa: F821

# ── Exchange (shared RWX PVC mounted at /srv/nbgrader/exchange) ───────────────
c.Exchange.root = '/srv/nbgrader/exchange'
# Each course gets its own subdirectory inside the exchange root
c.Exchange.path_includes_course = True

# ── JupyterHub auth: group-based instructor access ────────────────────────────
# Users in these JupyterHub groups (synced from Keycloak) can access formgrader
c.JupyterHubAuthPlugin.instructor_groups = ['professors', 'admins']
# Everyone else who can log in is treated as a student
c.JupyterHubAuthPlugin.student_groups = ['students', 'cpu-users', 'gpu-users']
