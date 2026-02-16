#!/bin/bash
# OR-SET(1) OpenRouter Plugin for Claude Code
#
# ---
# name: or-set
# description: Set the active OpenRouter model for Claude Code (with hot-swap support)
# argument-hint: [--global|--project] <model-id>
# ---

set -euo pipefail

# Plugin root
CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Default values
CONFIG_SCOPE="project"
MODEL_ID=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --global|-g)
      CONFIG_SCOPE="global"
      shift
      ;;
    --project|-p)
      CONFIG_SCOPE="project"
      shift
      ;;
    --help|-h)
      grep '^#' "$0" | tail -n +2 | cut -c 3- | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *)
      MODEL_ID="$1"
      shift
      ;;
  esac
done

# Interactive mode: no model ID provided
if [[ -z "${MODEL_ID}" ]]; then
  echo "🔍 OpenRouter Model Selector"
  echo "============================="
  echo ""

  # Fetch models
  if ! MODELS_JSON=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-models.sh" 2>/dev/null); then
    echo "❌ Error: Failed to fetch models" >&2
    exit 1
  fi

  # Show top models
  echo "Popular Models:"
  echo ""

  if command -v jq &>/dev/null; then
    echo "${MODELS_JSON}" | jq -r '.data[:20] | to_entries[] | "\(.key + 1). \(.value.name // .value.id) (\(.value.id))"' 2>/dev/null || echo "${MODELS_JSON}"
  else
    echo "${MODELS_JSON}" | head -n 20
  fi

  echo ""
  echo "Enter model ID (or name):"
  read -r USER_INPUT

  if [[ -z "${USER_INPUT}" ]]; then
    echo "❌ No model selected" >&2
    exit 1
  fi

  # Try to find exact match
  MODEL_ID=$(echo "${MODELS_JSON}" | jq -r ".data[] | select(.id == \"${USER_INPUT}\" or .name == \"${USER_INPUT}\") | .id" 2>/dev/null | head -n 1)

  # If no exact match, use input as-is
  if [[ -z "${MODEL_ID}" ]]; then
    MODEL_ID="${USER_INPUT}"
  fi
fi

# Validate model ID format (basic check)
if [[ ! "${MODEL_ID}" =~ ^[a-z0-9_-]+/[a-z0-9._-]+$ ]] && [[ ! "${MODEL_ID}" =~ ^[a-z0-9_-]+/[a-z0-9._-]+:[a-z0-9_-]+$ ]]; then
  echo "⚠️  Warning: Model ID format looks unusual" >&2
  echo "   Expected format: provider/model-name" >&2
  echo "   Example: anthropic/claude-sonnet-4" >&2
  echo "" >&2
fi

# Run set-model script
bash "${CLAUDE_PLUGIN_ROOT}/scripts/set-model.sh" \
  ${CONFIG_SCOPE:+--${CONFIG_SCOPE}} \
  "${MODEL_ID}"
