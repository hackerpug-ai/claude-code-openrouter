#!/bin/bash
# OR-MODELS(1) OpenRouter Plugin for Claude Code
#
# ---
# name: or-models
# description: List, search, and filter OpenRouter models dynamically fetched from the API
# argument-hint: [--refresh] [--free] [search-query]
# ---

set -euo pipefail

# Plugin root
CLAUDE_PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Default values
FORCE_REFRESH=false
FILTER_FREE=false
SEARCH_QUERY=""
FILTER_PROVIDER=""
MIN_CONTEXT=0
MAX_PRICE=""

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --refresh|-r)
      FORCE_REFRESH=true
      shift
      ;;
    --free|-f)
      FILTER_FREE=true
      shift
      ;;
    --provider|-p)
      FILTER_PROVIDER="$2"
      shift 2
      ;;
    --min-context)
      MIN_CONTEXT="$2"
      shift 2
      ;;
    --max-price)
      MAX_PRICE="$2"
      shift 2
      ;;
    --help|-h)
      grep '^#' "$0" | tail -n +2 | cut -c 3- | sed 's/^# //' | sed 's/^#//'
      exit 0
      ;;
    *)
      SEARCH_QUERY="$1"
      shift
      ;;
  esac
done

# Fetch models (with --force flag if needed)
FETCH_ARGS=""
if [[ "${FORCE_REFRESH}" == "true" ]]; then
  FETCH_ARGS="--force"
fi

MODELS_JSON=$(bash "${CLAUDE_PLUGIN_ROOT}/scripts/fetch-models.sh" ${FETCH_ARGS} 2>/dev/null)

if [[ -z "${MODELS_JSON}" ]]; then
  echo "❌ Error: Failed to fetch models from OpenRouter API" >&2
  echo "   Check your internet connection or try again later." >&2
  exit 1
fi

# Parse and filter models using jq (if available) or basic tools
if command -v jq &>/dev/null; then
  # Build jq filter
  JQ_FILTER='.data | .[] | select(.architecture != null or .id != null)'

  if [[ "${FILTER_FREE}" == "true" ]]; then
    JQ_FILTER="${JQ_FILTER} | select(.pricing.prompt == \"0\" or .pricing.prompt == \"0.0\")"
  fi

  if [[ -n "${FILTER_PROVIDER}" ]]; then
    JQ_FILTER="${JQ_FILTER} | select(.id | startswith(\"${FILTER_PROVIDER}/\"))"
  fi

  if [[ -n "${MIN_CONTEXT}" ]] && [[ "${MIN_CONTEXT}" -gt 0 ]]; then
    JQ_FILTER="${JQ_FILTER} | select(.context_length >= ${MIN_CONTEXT})"
  fi

  if [[ -n "${MAX_PRICE}" ]]; then
    JQ_FILTER="${JQ_FILTER} | select((.pricing.prompt | tonumber) <= ${MAX_PRICE})"
  fi

  if [[ -n "${SEARCH_QUERY}" ]]; then
    JQ_FILTER="${JQ_FILTER} | select(.id | ascii_downcase | contains(\"${SEARCH_QUERY,,}\")) or select(.name | ascii_downcase | contains(\"${SEARCH_QUERY,,}\"))"
  fi

  # Display models
  echo "📡 OpenRouter Models"
  echo "===================="
  echo ""

  # Count models first
  MODEL_COUNT=$(echo "${MODELS_JSON}" | jq "${JQ_FILTER}" 2>/dev/null | jq -s 'length')
  echo "Found ${MODEL_COUNT} model(s)"
  echo ""

  # Format and display
  echo "${MODELS_JSON}" | jq -r "${JQ_FILTER}" 2>/dev/null | while read -r model; do
    MODEL_ID=$(echo "${model}" | jq -r '.id // empty')
    MODEL_NAME=$(echo "${model}" | jq -r '.name // .id')
    CONTEXT=$(echo "${model}" | jq -r '.context_length // "N/A"')
    PRICE_IN=$(echo "${model}" | jq -r '.pricing.prompt // "N/A"')
    PRICE_OUT=$(echo "${model}" | jq -r '.pricing.completion // "N/A"')

    # Format context length
    if [[ "${CONTEXT}" != "N/A" ]]; then
      if [[ "${CONTEXT}" -ge 1000000 ]]; then
        CONTEXT_FMT="$((CONTEXT / 1000000))M tokens"
      elif [[ "${CONTEXT}" -ge 1000 ]]; then
        CONTEXT_FMT="$((CONTEXT / 1000))K tokens"
      else
        CONTEXT_FMT="${CONTEXT} tokens"
      fi
    else
      CONTEXT_FMT="N/A"
    fi

    # Format pricing
    if [[ "${PRICE_IN}" == "0" ]] || [[ "${PRICE_IN}" == "0.0" ]]; then
      PRICE_FMT="🆓 Free"
    else
      PRICE_FMT="$${PRICE_IN}/M in, $${PRICE_OUT}/M out"
    fi

    # Extract provider from model ID
    PROVIDER=$(echo "${MODEL_ID}" | cut -d'/' -f1)

    echo "📦 ${MODEL_NAME}"
    echo "   ├─ ID: ${MODEL_ID}"
    echo "   ├─ Provider: ${PROVIDER}"
    echo "   ├─ Context: ${CONTEXT_FMT}"
    echo "   └─ Price: ${PRICE_FMT}"
    echo ""
  done
else
  # Fallback: show raw models if jq not available
  echo "⚠️  Warning: jq not found. Showing raw output."
  echo "   Install jq for better formatting: brew install jq"
  echo ""
  echo "${MODELS_JSON}"
fi

# Show cache info
CACHE_FILE="${HOME}/.openrouter-plugin/models.json"
if [[ -f "${CACHE_FILE}" ]]; then
  CACHE_AGE=$(($(date +%s) - $(stat -f %m "${CACHE_FILE}" 2>/dev/null || stat -c %Y "${CACHE_FILE}" 2>/dev/null)))
  CACHE_AGE_MINS=$((CACHE_AGE / 60))

  echo "💾 Cache: ${CACHE_FILE}"
  if [[ ${CACHE_AGE_MINS} -lt 60 ]]; then
    echo "   Age: ${CACHE_AGE_MINS} minutes old"
  else
    echo "   Age: $((CACHE_AGE_MINS / 60)) hours old"
  fi
  echo "   Refresh with: /or-models --refresh"
fi
