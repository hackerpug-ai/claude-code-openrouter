#!/bin/bash
# Set OpenRouter model configuration for Claude Code
# Usage: set-model.sh [--global|--project] MODEL_ID

set -euo pipefail

# Default to project-level config
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
    --*)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
    *)
      MODEL_ID="$1"
      shift
      ;;
  esac
done

if [[ -z "${MODEL_ID}" ]]; then
  echo "Error: No model ID specified" >&2
  echo "Usage: set-model.sh [--global|--project] MODEL_ID" >&2
  exit 1
fi

# Determine config path
if [[ "${CONFIG_SCOPE}" == "global" ]]; then
  CONFIG_DIR="${HOME}/.claude"
  CONFIG_FILE="${CONFIG_DIR}/settings.json"
else
  CONFIG_DIR="$(pwd)/.claude"
  CONFIG_FILE="${CONFIG_DIR}/settings.json"
fi

# Create .claude directory if needed
mkdir -p "${CONFIG_DIR}"

# Initialize or read existing config
if [[ -f "${CONFIG_FILE}" ]]; then
  EXISTING_CONFIG=$(cat "${CONFIG_FILE}")
else
  EXISTING_CONFIG="{}"
fi

# Update config with OpenRouter settings
# We need to merge with existing config using node or python
UPDATE_SCRIPT="
const config = ${EXISTING_CONFIG};
config.openrouter = config.openrouter || {};
config.openrouter.model = '${MODEL_ID}';
config.openrouter.enabled = true;

// Set environment variables for Claude Code
process.env.ANTHROPIC_BASE_URL = 'https://openrouter.ai/api';
process.env.ANTHROPIC_AUTH_TOKEN = process.env.OPENROUTER_API_KEY || '';
process.env.ANTHROPIC_API_KEY = '';

// Output the updated config
console.log(JSON.stringify(config, null, 2));

// Output shell commands for hot-swapping
console.error('');
console.error('export ANTHROPIC_BASE_URL=\"https://openrouter.ai/api\"');
console.error('export ANTHROPIC_AUTH_TOKEN=\"$OPENROUTER_API_KEY\"');
console.error('export ANTHROPIC_API_KEY=\"\"');
console.error('export ANTHROPIC_DEFAULT_MODEL=\"${MODEL_ID}\"');
"

if command -v node &>/dev/null; then
  UPDATED_CONFIG=$(echo "${UPDATE_SCRIPT}" | node - 2>&1)
  # Separate config output from stderr (shell exports)
  NEW_CONFIG=$(echo "${UPDATED_CONFIG}" | grep -v "^export")
  SHELL_EXPORTS=$(echo "${UPDATED_CONFIG}" | grep "^export" || true)

  echo "${NEW_CONFIG}" > "${CONFIG_FILE}"
  echo "✅ Model set to: ${MODEL_ID}" >&2
  echo "📁 Config file: ${CONFIG_FILE}" >&2
  if [[ -n "${SHELL_EXPORTS}" ]]; then
    echo "" >&2
    echo "🔄 To hot-swap for current session, run:" >&2
    echo "${SHELL_EXPORTS}" >&2
  fi
else
  # Fallback: simple JSON manipulation with Python or manual
  python3 -c "
import json
import sys

config = ${EXISTING_CONFIG}
if 'openrouter' not in config:
    config['openrouter'] = {}
config['openrouter']['model'] = '${MODEL_ID}'
config['openrouter']['enabled'] = True

print(json.dumps(config, indent=2))
" > "${CONFIG_FILE}"

  echo "✅ Model set to: ${MODEL_ID}" >&2
  echo "📁 Config file: ${CONFIG_FILE}" >&2
  echo "" >&2
  echo "🔄 To hot-swap for current session, run:" >&2
  echo "export ANTHROPIC_BASE_URL=\"https://openrouter.ai/api\"" >&2
  echo "export ANTHROPIC_AUTH_TOKEN=\"\$OPENROUTER_API_KEY\"" >&2
  echo "export ANTHROPIC_API_KEY=\"\"" >&2
  echo "export ANTHROPIC_DEFAULT_MODEL=\"${MODEL_ID}\"" >&2
fi