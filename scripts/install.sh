#!/bin/bash
# OpenRouter Plugin Installation Script
# Usage: install.sh [--global|--project]

set -euo pipefail

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Default installation scope
INSTALL_SCOPE="project"
PLUGIN_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# Parse arguments
while [[ $# -gt 0 ]]; do
  case $1 in
    --global|-g)
      INSTALL_SCOPE="global"
      shift
      ;;
    --project|-p)
      INSTALL_SCOPE="project"
      shift
      ;;
    *)
      echo -e "${RED}Unknown option: $1${NC}" >&2
      exit 1
      ;;
  esac
done

echo -e "${BLUE}OpenRouter Plugin for Claude Code${NC}"
echo "======================================"
echo ""

# Check if OPENROUTER_API_KEY is set
if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
  echo -e "${YELLOW}Warning: OPENROUTER_API_KEY not set${NC}"
  echo ""
  echo "Get your API key from: https://openrouter.ai/keys"
  echo ""
  read -p "Enter your OpenRouter API key (or press Enter to skip): " API_KEY_INPUT
  if [[ -n "$API_KEY_INPUT" ]]; then
    echo ""
    echo -e "${GREEN}Add this to your ~/.zshrc or ~/.bashrc:${NC}"
    echo "export OPENROUTER_API_KEY=\"$API_KEY_INPUT\""
    echo ""
  fi
fi

# Create symlink to plugins directory
if [[ "${INSTALL_SCOPE}" == "global" ]]; then
  PLUGINS_DIR="${HOME}/.claude/plugins"
  echo -e "${BLUE}Installing globally...${NC}"
else
  PLUGINS_DIR="$(pwd)/.claude/plugins"
  echo -e "${BLUE}Installing for current project...${NC}"
fi

mkdir -p "${PLUGINS_DIR}"

# Remove existing symlink if present
if [[ -L "${PLUGINS_DIR}/openrouter-plugin" ]]; then
  rm "${PLUGINS_DIR}/openrouter-plugin"
fi

# Create symlink
ln -s "${PLUGIN_ROOT}" "${PLUGINS_DIR}/openrouter-plugin"

echo -e "${GREEN}✓ Plugin installed to: ${PLUGINS_DIR}/openrouter-plugin${NC}"
echo ""

# Test the installation
echo -e "${BLUE}Testing installation...${NC}"
if bash "${PLUGIN_ROOT}/scripts/fetch-models.sh" > /dev/null 2>&1; then
  echo -e "${GREEN}✓ Model fetch script works${NC}"
else
  echo -e "${YELLOW}⚠ Model fetch test failed (may need API key for full functionality)${NC}"
fi

echo ""
echo -e "${GREEN}Installation complete!${NC}"
echo ""
echo "Available commands:"
echo "  /or-models    - List and search models"
echo "  /or-set       - Set active model"
echo "  /or-status    - Show configuration"
echo ""
echo "For more information, see: ${PLUGIN_ROOT}/README.md"
echo ""

# Remind about shell restart if needed
if [[ -n "$API_KEY_INPUT" ]]; then
  echo -e "${YELLOW}Don't forget to restart your shell or run: source ~/.zshrc${NC}"
  echo ""
fi