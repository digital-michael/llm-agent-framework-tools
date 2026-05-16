#!/usr/bin/env bash
# scaffold-project.sh — Write .llm-framework.yml for a new or existing project repository.
# Contract: llm-agent-framework/docs/tooling.md#scaffold-project
set -euo pipefail

PROJECT_PATH=""
INFRA_PATH=""
TEAM_PATH=""
PERSONAL_PATH=""
OVERWRITE=false

usage() {
  echo "Usage: $0 --project <path> --infra <path> [--team <path>] [--personal <path>] [--overwrite]"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --project)   PROJECT_PATH="$2";  shift 2 ;;
    --infra)     INFRA_PATH="$2";    shift 2 ;;
    --team)      TEAM_PATH="$2";     shift 2 ;;
    --personal)  PERSONAL_PATH="$2"; shift 2 ;;
    --overwrite) OVERWRITE=true;     shift   ;;
    *) usage ;;
  esac
done

[[ -z "$PROJECT_PATH" || -z "$INFRA_PATH" ]] && usage

CONFIG_FILE="${PROJECT_PATH}/.llm-framework.yml"

[[ ! -d "$PROJECT_PATH" ]] && { echo "Error: project path not found: $PROJECT_PATH" >&2; exit 1; }
[[ ! -d "$INFRA_PATH" ]]   && { echo "Error: infrastructure path not found: $INFRA_PATH" >&2; exit 1; }
[[ -n "$TEAM_PATH" && ! -d "$TEAM_PATH" ]]     && { echo "Error: team path not found: $TEAM_PATH" >&2; exit 1; }
[[ -n "$PERSONAL_PATH" && ! -d "$PERSONAL_PATH" ]] && { echo "Error: personal path not found: $PERSONAL_PATH" >&2; exit 1; }

if [[ -f "$CONFIG_FILE" && "$OVERWRITE" == false ]]; then
  echo "Error: $CONFIG_FILE already exists. Use --overwrite to replace it." >&2
  exit 1
fi

# Determine operating mode
if [[ -n "$PERSONAL_PATH" ]]; then
  MODE="Full"
elif [[ -n "$TEAM_PATH" ]]; then
  MODE="Team"
else
  MODE="Standalone"
fi

# Write config
{
  echo "# .llm-framework.yml — LLM Agent Collaboration Framework configuration"
  echo "# Operating mode: $MODE"
  echo ""
  echo "framework:"
  echo "  infrastructure: \"$INFRA_PATH\""
  [[ -n "$TEAM_PATH" ]]     && echo "  team: \"$TEAM_PATH\""
  [[ -n "$PERSONAL_PATH" ]] && echo "  personal: \"$PERSONAL_PATH\""
} > "$CONFIG_FILE"

echo "Written: $CONFIG_FILE"
echo "Operating mode: $MODE"
echo ""
echo "Next steps:"
echo "  - Commit .llm-framework.yml to your project repo (or add to .gitignore if paths are machine-specific)"
echo "  - At session start, the agent will read this file and resolve the framework layer stack"
