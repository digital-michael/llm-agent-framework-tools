#!/usr/bin/env bash
# init-profile.sh — Scaffold a personal or team profile repo from llm-agent-framework templates.
# Contract: llm-agent-framework/docs/tooling.md#init-profile
set -euo pipefail

PROFILE_TYPE=""
TARGET_PATH=""
INFRA_PATH=""
GIT_INIT=true

usage() {
  echo "Usage: $0 --type <personal|team> --target <path> --infra <path> [--no-git-init]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)       PROFILE_TYPE="$2"; shift 2 ;;
    --target)     TARGET_PATH="$2";  shift 2 ;;
    --infra)      INFRA_PATH="$2";   shift 2 ;;
    --no-git-init) GIT_INIT=false;   shift   ;;
    *) usage ;;
  esac
done

[[ -z "$PROFILE_TYPE" || -z "$TARGET_PATH" || -z "$INFRA_PATH" ]] && usage
[[ "$PROFILE_TYPE" != "personal" && "$PROFILE_TYPE" != "team" ]] && {
  echo "Error: --type must be 'personal' or 'team'" >&2; exit 1
}

TEMPLATE_SOURCE="${INFRA_PATH}/templates/${PROFILE_TYPE}"
[[ ! -d "$TEMPLATE_SOURCE" ]] && {
  echo "Error: template source not found: $TEMPLATE_SOURCE" >&2; exit 1
}
[[ -d "$TARGET_PATH" ]] && {
  echo "Error: target path already exists: $TARGET_PATH" >&2; exit 1
}

mkdir -p "$TARGET_PATH"
cp -r "${TEMPLATE_SOURCE}/." "$TARGET_PATH/"

echo "Scaffolded ${PROFILE_TYPE} profile at: $TARGET_PATH"
echo "Files created:"
find "$TARGET_PATH" -type f | sort | sed "s|^|  |"

if [[ "$GIT_INIT" == true ]]; then
  git -C "$TARGET_PATH" init -q
  echo "Initialized git repo at: $TARGET_PATH"
fi

echo ""
echo "Next steps:"
echo "  1. Fill in the template files in: $TARGET_PATH"
echo "  2. Run scaffold-project.sh to connect a project to this profile"
