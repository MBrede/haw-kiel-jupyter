#!/bin/bash
# Runs before the notebook server starts (before-notebook.d).
#
# Detects course groups from JUPYTERHUB_GROUPS (format: course_<ID>, e.g. course_CC_SS26).
# For instructors (professors/admins): creates a per-course directory under ~/courses/<ID>/
# and initialises the nbgrader database on first login.
# For students: no action needed — nbgrader fetch/submit works via the shared exchange.
#
# Keycloak group conventions:
#   professors, admins  → instructor role
#   course_<ID>         → course membership (add both professors AND students)

GROUPS="${JUPYTERHUB_GROUPS:-}"

is_instructor() {
    [[ "$GROUPS" == *professors* ]] || [[ "$GROUPS" == *admins* ]]
}

if ! is_instructor; then
    exit 0
fi

# Extract all course_* groups into an array
IFS=',' read -ra GROUP_LIST <<< "$GROUPS"
COURSE_IDS=()
for g in "${GROUP_LIST[@]}"; do
    g="${g// /}"  # trim spaces
    if [[ "$g" == course_* ]]; then
        COURSE_IDS+=("${g#course_}")
    fi
done

if [[ ${#COURSE_IDS[@]} -eq 0 ]]; then
    # Instructor but no course group assigned yet — nothing to do
    exit 0
fi

for COURSE_ID in "${COURSE_IDS[@]}"; do
    COURSE_DIR="${HOME}/courses/${COURSE_ID}"

    # Skip if already initialised
    if [[ -f "${COURSE_DIR}/nbgrader_config.py" ]]; then
        continue
    fi

    echo "[nbgrader-setup] Initialising course directory for: ${COURSE_ID}"
    mkdir -p "${COURSE_DIR}"

    cat > "${COURSE_DIR}/nbgrader_config.py" << EOF
c = get_config()  # noqa: F821

c.CourseDirectory.course_id = "${COURSE_ID}"
c.CourseDirectory.root = "${COURSE_DIR}"
EOF

    cd "${COURSE_DIR}" && nbgrader db upgrade 2>&1 | sed "s/^/[nbgrader-setup] ${COURSE_ID}: /"
    echo "[nbgrader-setup] Done: ${COURSE_DIR}"
done
