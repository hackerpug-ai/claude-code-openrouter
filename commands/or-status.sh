#!/bin/bash
# OR-STATUS(1) OpenRouter Plugin for Claude Code
#
# ---
# name: or-status
# description: Show current OpenRouter configuration and active model
# argument-hint: [--verbose]
# ---

set -euo pipefail

# Plugin root
CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Parse arguments
VERBOSE=false
while [[ $# -gt 0 ]]; do
  case $1 in
    --verbose|-v)
      VERBOSE=true
      shift
      ;;
    --help|-h)
      grep '^#' "$0" | tail -n +2 | cut -c 3- | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *)
      echo "Unknown option: $1" >&2
      exit 1
      ;;
  esac
done

echo "🔧 OpenRouter Configuration"
echo "==========================="
echo ""

# Track status
STATUS="❌ Inactive"
ACTIVE_MODEL=""
ACTIVE_SCOPE=""

# Check project config
PROJECT_CONFIG=".claude/settings.json"
if [[ -f "${PROJECT_CONFIG}" ]]; then
  if grep -q "openrouter" "${PROJECT_CONFIG}" 2>/dev/null; then
    if command -v jq &>/dev/null; then
      PROJECT_MODEL=$(jq -r '.openrouter.model // empty' "${PROJECT_CONFIG}" 2>/dev/null)
      PROJECT_ENABLED=$(jq -r '.openrouter.enabled // false' "${PROJECT_CONFIG}" 2>/dev/null)
      if [[ "${PROJECT_ENABLED}" == "true" ]] && [[ -n "${PROJECT_MODEL}" ]]; then
        STATUS="✅ Active"
        ACTIVE_MODEL="${PROJECT_MODEL}"
        ACTIVE_SCOPE="project"
      fi
    fi
  fi
fi

# Check global config if no active project model
if [[ "${STATUS}" != "✅ Active" ]]; then
  GLOBAL_CONFIG="${HOME}/.claude/settings.json"
  if [[ -f "${GLOBAL_CONFIG}" ]]; then
    if grep -q "openrouter" "${GLOBAL_CONFIG}" 2>/dev/null; then
      if command -v jq &>/dev/null; then
        GLOBAL_MODEL=$(jq -r '.openrouter.model // empty' "${GLOBAL_CONFIG}" 2>/dev/null)
        GLOBAL_ENABLED=$(jq -r '.openrouter.enabled // false' "${GLOBAL_CONFIG}" 2>/dev/null)
        if [[ "${GLOBAL_ENABLED}" == "true" ]] && [[ -n "${GLOBAL_MODEL}" ]]; then
          STATUS="✅ Active"
          ACTIVE_MODEL="${GLOBAL_MODEL}"
          ACTIVE_SCOPE="global"
        fi
      fi
    fi
  fi
fi

# Display status
echo "Status: ${STATUS}"
if [[ -n "${ACTIVE_MODEL}" ]]; then
  echo "Model: ${ACTIVE_MODEL}"
  echo "Scope: ${ACTIVE_SCOPE}"
fi
echo ""

# API Key status
if [[ -n "${OPENROUTER_API_KEY:-}" ]]; then
  echo "API Key: ✅ Configured (OPENROUTER_API_KEY)"
else
  echo "API Key: ⚠️  Not set (set OPENROUTER_API_KEY environment variable)"
fi
echo "Base URL: https://openrouter.ai/api"
echo ""

# Cache info
CACHE_FILE="${HOME}/.openrouter-plugin/models.json"
if [[ -f "${CACHE_FILE}" ]]; then
  echo "💾 Cache Info:"
  echo "   ├─ Location: ${CACHE_FILE}"

  if command -v jq &>/dev/null; then
    MODEL_COUNT=$(jq '.data | length' "${CACHE_FILE}" 2>/dev/null || echo "N/A")
    echo "   ├─ Models: ${MODEL_COUNT}"
  fi

  CACHE_AGE=$(($(date +%s) - $(stat -f %m "${CACHE_FILE}" 2>/dev/null || stat -c %Y "${CACHE_FILE}" 2>/dev/null)))
  CACHE_AGE_MINS=$((CACHE_AGE / 60))
  if [[ ${CACHE_AGE_MINS} -lt 60 ]]; then
    echo "   ├─ Age: ${CACHE_AGE_MINS} minutes old"
  else
    echo "   ├─ Age: $((CACHE_AGE_MINS / 60)) hours old"
  fi

  CACHE_EXPIRY=$((3600 - CACHE_AGE))
  if [[ ${CACHE_EXPIRY} -gt 0 ]]; then
    echo "   └─ Expires in: $((CACHE_EXPIRY / 60)) minutes"
  else
    echo "   └─ Status: Expired (refresh needed)"
  fi
  echo ""
else
  echo "💾 Cache: Not initialized (run /or-models to fetch)"
  echo ""
fi

# Configuration files
echo "📁 Configuration Files:"
if [[ -f "${PROJECT_CONFIG}" ]]; then
  echo "   ├─ Project: ${PROJECT_CONFIG}"
else
  echo "   ├─ Project: (none)"
fi

if [[ -f "${HOME}/.claude/settings.json" ]]; then
  echo "   └─ Global: ${HOME}/.claude/settings.json"
else
  echo "   └─ Global: (none)"
fi
echo ""

# Environment variables
echo "🌍 Environment Variables:"
echo "   ANTHROPIC_BASE_URL: ${ANTHROPIC_BASE_URL:-default}"
if [[ -n "${ANTHROPIC_AUTH_TOKEN:-}" ]]; then
  echo "   ANTHROPIC_AUTH_TOKEN: ✅ Set"
else
  echo "   ANTHROPIC_AUTH_TOKEN: ⚠️  Not set"
fi
echo ""

# Verbose mode
if [[ "${VERBOSE}" == "true" ]]; then
  echo "📋 Verbose Details:"
  echo "   ---"

  # Show full config
  if [[ -f "${PROJECT_CONFIG}" ]]; then
    echo "   Project Config:"
    jq '.' "${PROJECT_CONFIG}" 2>/dev/null | sed 's/^/   /' || echo "   (error reading)"
    echo "   ---"
  fi

  if [[ -f "${HOME}/.claude/settings.json" ]]; then
    echo "   Global Config:"
    jq '.' "${HOME}/.claude/settings.json" 2>/dev/null | sed 's/^/   /' || echo "   (error reading)"
    echo "   ---"
  fi

  # Network test
  echo "   Testing OpenRouter API connectivity..."
  if curl -s -o /dev/null -w "%{http_code}" --max-time 5 "https://openrouter.ai/api/v1/models" 2>/dev/null | grep -q "200"; then
    echo "   ✅ API is reachable"
  else
    echo "   ⚠️  API connection failed"
  fi
fi
