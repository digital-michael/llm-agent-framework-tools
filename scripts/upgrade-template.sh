#!/usr/bin/env bash
# upgrade-template.sh — Detect and apply infrastructure template updates to a filled-out profile file.
# Contract: llm-agent-framework/docs/tooling.md#upgrade-template
set -euo pipefail

PROFILE_FILE=""
TEMPLATE_FILE=""

usage() {
  echo "Usage: $0 --profile <path-to-filled-out-file> --template <path-to-infra-template>"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --profile)  PROFILE_FILE="$2";  shift 2 ;;
    --template) TEMPLATE_FILE="$2"; shift 2 ;;
    *) usage ;;
  esac
done

[[ -z "$PROFILE_FILE" || -z "$TEMPLATE_FILE" ]] && usage
[[ ! -f "$PROFILE_FILE" ]]  && { echo "Error: profile file not found: $PROFILE_FILE" >&2;  exit 1; }
[[ ! -f "$TEMPLATE_FILE" ]] && { echo "Error: template file not found: $TEMPLATE_FILE" >&2; exit 1; }

extract_version() {
  grep -E '^template-version:' "$1" | awk '{print $2}' | tr -d '"' | head -1
}

PROFILE_VERSION=$(extract_version "$PROFILE_FILE")
TEMPLATE_VERSION=$(extract_version "$TEMPLATE_FILE")

echo "Profile version:     ${PROFILE_VERSION:-<not set>}"
echo "Infrastructure version: ${TEMPLATE_VERSION:-<not set>}"

if [[ "$PROFILE_VERSION" == "$TEMPLATE_VERSION" ]]; then
  echo "No upgrade needed — versions match."
  exit 0
fi

echo ""
echo "Versions differ. Showing structural diff (--- profile, +++ template):"
echo ""
diff --unified=2 "$PROFILE_FILE" "$TEMPLATE_FILE" || true

echo ""
echo "Review the diff above."
echo "To apply changes: manually edit $PROFILE_FILE and update template-version to $TEMPLATE_VERSION"
echo ""
echo "WARNING: This script shows the diff only. Interactive merge is not yet automated."
echo "         See docs/tooling.md#upgrade-template for the full contract."
