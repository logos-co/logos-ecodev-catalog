#!/usr/bin/env bash
# Add a Logos module to this catalog: registers it as a git submodule
# under submodules/ and generates the matching per-module release
# workflow from .github/workflows/release-module.yml.template.
#
# Usage:
#   ./scripts/add-module.sh <git-url> [submodule-name] [branch]
#
# Examples:
#   ./scripts/add-module.sh https://github.com/me/my-cool-module
#   ./scripts/add-module.sh https://github.com/me/my-cool-module my-cool-module main
#
# After running:
#   - review `git status`
#   - commit (.gitmodules, submodules/<name>, the new workflow file)
#   - push, then trigger "Release <name>" from the Actions tab
#     (or run the umbrella "Release all modules")

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

URL="${1:-}"
if [ -z "${URL}" ]; then
  echo "usage: $0 <git-url> [submodule-name] [branch]" >&2
  exit 2
fi

# Derive a default submodule directory name from the URL basename.
NAME="${2:-}"
if [ -z "${NAME}" ]; then
  NAME="$(basename "${URL%.git}")"
fi
BRANCH="${3:-}"

PATH_REL="submodules/${NAME}"
TEMPLATE=".github/workflows/release-module.yml.template"

if [ ! -f "${TEMPLATE}" ]; then
  echo "error: ${TEMPLATE} not found — run from a fork of logos-modules-release-base" >&2
  exit 1
fi

if [ -e "${PATH_REL}" ]; then
  echo "error: ${PATH_REL} already exists" >&2
  exit 1
fi

echo "==> adding submodule ${NAME}"
if [ -n "${BRANCH}" ]; then
  git submodule add -b "${BRANCH}" "${URL}" "${PATH_REL}"
else
  git submodule add "${URL}" "${PATH_REL}"
fi

# One workflow per module: metadata.json at the repo root, or one per
# subdirectory holding one (multi-module repo).
MODULES=""
if [ -f "${PATH_REL}/metadata.json" ]; then
  MODULES="${NAME}"
else
  for m in "${PATH_REL}"/*/metadata.json; do
    [ -f "${m}" ] || continue
    MODULES="${MODULES} ${NAME}/$(basename "$(dirname "${m}")")"
  done
fi
if [ -z "${MODULES// /}" ]; then
  echo "error: no metadata.json in ${PATH_REL} (root or one level down)" >&2
  exit 1
fi

for MOD in ${MODULES}; do
  WORKFLOW=".github/workflows/release-$(echo "${MOD}" | tr / -).yml"
  echo "==> generating ${WORKFLOW}"
  sed "s|__MODULE__|${MOD}|g" "${TEMPLATE}" > "${WORKFLOW}"
done

cat <<EOF

Done. Next:

  git add .gitmodules "${PATH_REL}" .github/workflows/
  git commit -m "Add ${NAME}"
  git push

Then publish it:
  - Actions tab → "Release ${MODULES# }" → Run workflow
  - or run "Release all modules" to (re)publish everything

A new release is cut whenever you bump the submodule pointer
(and thereby its metadata.json#version) and re-run the workflow.
EOF
