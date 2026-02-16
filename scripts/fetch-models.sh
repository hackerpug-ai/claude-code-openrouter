#!/bin/bash
# Fetch models from OpenRouter API and cache them locally
# Usage: fetch-models.sh [--force] [--api-key KEY]

set -euo pipefail

# Configuration
CACHE_DIR="${HOME}/.openrouter-plugin"
CACHE_FILE="${CACHE_DIR}/models.json"
CACHE_TTL=3600  # 1 hour in seconds

# Parse arguments
FORCE_REFRESH=false
API_KEY="${OPENROUTER_API_KEY:-}"

while [[ $# -gt 0 ]]; do
  case $1 in
    --force|-f)
      FORCE_REFRESH=true
      shift
      ;;
    --api-key)
      API_KEY="$2"
      shift 2
      ;;
    *)
      echo "Unknown option: $1"
      exit 1
      ;;
  esac
done

# Create cache directory
mkdir -p "${CACHE_DIR}"

# Check if cache exists and is valid
if [[ "${FORCE_REFRESH}" != "true" ]] && [[ -f "${CACHE_FILE}" ]]; then
  CACHE_AGE=$(($(date +%s) - $(stat -f %m "${CACHE_FILE}" 2>/dev/null || stat -c %Y "${CACHE_FILE}" 2>/dev/null)))
  if [[ ${CACHE_AGE} -lt ${CACHE_TTL} ]]; then
    # Cache is valid, output cached models
    cat "${CACHE_FILE}"
    exit 0
  fi
fi

# Fetch from API
API_URL="https://openrouter.ai/api/v1/models"

if [[ -n "${API_KEY}" ]]; then
  HTTP_CODE=$(curl -s -o "${CACHE_FILE}.tmp" -w "%{http_code}" \
    -H "Authorization: Bearer ${API_KEY}" \
    "${API_URL}")
else
  # No auth needed for public model list
  HTTP_CODE=$(curl -s -o "${CACHE_FILE}.tmp" -w "%{http_code}" "${API_URL}")
fi

if [[ "${HTTP_CODE}" == "200" ]]; then
  mv "${CACHE_FILE}.tmp" "${CACHE_FILE}"
  cat "${CACHE_FILE}"
else
  echo "Error: Failed to fetch models (HTTP ${HTTP_CODE})" >&2
  rm -f "${CACHE_FILE}.tmp"
  exit 1
fi