# OpenRouter Plugin for Claude Code

Dynamically fetch and switch between 600+ OpenRouter AI models in Claude Code without needing to remember model IDs.

## Features

- **Dynamic model discovery** - Fetch latest models from OpenRouter API
- **Smart caching** - Local cache with 1-hour TTL for fast access
- **Hot-swapping** - Change models mid-session via environment variables
- **Flexible configuration** - Project-level or global settings
- **Search & filter** - Find models by name, provider, pricing, capabilities
- **Cost tracking** - See pricing and context length at a glance

## Quick Start

### 1. Install the Plugin

```bash
# Clone or symlink to Claude Code plugins
ln -s ~/Projects/openrouter-plugin ~/.claude/plugins/openrouter-plugin

# Or add to project-specific plugins
mkdir -p .claude/plugins
ln -s ~/Projects/openrouter-plugin .claude/plugins/openrouter-plugin
```

### 2. Set Up OpenRouter API Key

```bash
# Add to ~/.zshrc or ~/.bashrc
export OPENROUTER_API_KEY="sk-your-api-key-here"
```

Get your API key from https://openrouter.ai/keys

### 3. Use the Plugin

Start Claude Code and use the commands:

```bash
# List all available models
/or-models

# Search for a specific model
/or-models claude

# Set a model for your project
/or-set anthropic/claude-sonnet-4

# Check current configuration
/or-status
```

## Commands

### `/or-models` - List and Search Models

List all available OpenRouter models with filtering options:

```bash
/or-models                           # List all models
/or-models claude                    # Search for "claude"
/or-models --free                    # Show only free models
/or-models --provider google         # Filter by provider
/or-models --refresh                 # Force refresh from API
```

Output includes:
- Model name and ID
- Context length
- Pricing (per million tokens)
- Key capabilities (vision, tools, streaming)

### `/or-set` - Set Active Model

Set the model for Claude Code:

```bash
/or-set anthropic/claude-sonnet-4        # Set for current project
/or-set --global google/gemini-2.5-pro  # Set globally
/or-set                                  # Interactive selection
```

The command outputs shell exports for hot-swapping:

```bash
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""
export ANTHROPIC_DEFAULT_MODEL="anthropic/claude-sonnet-4"
```

### `/or-status` - Show Configuration

Display current OpenRouter setup:

```bash
/or-status              # Summary
/or-status --verbose    # Detailed configuration
```

Shows:
- Active model and scope
- API key status
- Cache information
- Configuration file locations

## Configuration

### Project-Level Settings

Create `.claude/settings.json` in your project:

```json
{
  "openrouter": {
    "enabled": true,
    "model": "anthropic/claude-sonnet-4"
  }
}
```

### Global Settings

Add to `~/.claude/settings.json`:

```json
{
  "openrouter": {
    "enabled": true,
    "model": "z-ai/glm-4-7b-chatsft"
  }
}
```

### Priority Order

1. Project config (`.claude/settings.json`)
2. Global config (`~/.claude/settings.json`)
3. Default Claude behavior

## Model Selection Guide

### Best for Coding

- `z-ai/glm-4-7b-chatsft` - Excellent for code, cost-effective
- `anthropic/claude-sonnet-4` - Strong reasoning, good tools
- `qwen/qwen3-coder-next` - Specialized for code agents

### Best for Long Context

- `google/gemini-2.5-pro-preview` - 1M+ tokens
- `anthropic/claude-opus-4-6` - 1M tokens
- `qwen/qwen3-235b` - 262K tokens

### Best Value

- `meta-llama/llama-3.1-70b-instruct:free` - Free tier
- `qwen/qwen3-coder-next` - $0.07/M input
- `stepfun/step-3.5-flash` - Fast, low cost

## How It Works

### Architecture

```
┌─────────────────┐
│  Claude Code    │
└────────┬────────┘
         │
         ▼
┌─────────────────────────────────┐
│   OpenRouter Plugin Commands    │
│  /or-models | /or-set | /or-status│
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│     Scripts & Skills            │
│  ├─ fetch-models.sh             │
│  ├─ set-model.sh                │
│  └─ openrouter-models skill     │
└────────┬────────────────────────┘
         │
         ▼
┌─────────────────────────────────┐
│      OpenRouter API             │
│   /api/v1/models (free)         │
└─────────────────────────────────┘
```

### Caching Strategy

- **Cache location**: `~/.openrouter-plugin/models.json`
- **Cache TTL**: 1 hour
- **Force refresh**: Use `/or-models --refresh`
- **Offline mode**: Works with cached models

### Hot-Swapping Process

1. Plugin runs `set-model.sh` script
2. Script updates settings.json
3. Script outputs shell exports
4. User evals or copies exports to current shell
5. New requests use updated model

## Troubleshooting

### "API key not found" error

```bash
# Check if OPENROUTER_API_KEY is set
echo $OPENROUTER_API_KEY

# Add to ~/.zshrc
export OPENROUTER_API_KEY="sk-your-key"
source ~/.zshrc
```

### Models not loading

```bash
# Force refresh cache
/or-models --refresh

# Check cache file
ls -la ~/.openrouter-plugin/models.json

# Manually test API
curl https://openrouter.ai/api/v1/models | jq '.data | length'
```

### Model not working after `/or-set`

```bash
# Check configuration
/or-status --verbose

# Verify environment variables
echo $ANTHROPIC_BASE_URL
echo $ANTHROPIC_AUTH_TOKEN

# Hot-swap manually
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""
```

## Development

### Project Structure

```
openrouter-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/
│   ├── models.md            # /or-models command
│   ├── set.md               # /or-set command
│   └── status.md            # /or-status command
├── skills/
│   └── openrouter-models/
│       └── SKILL.md         # OpenRouter knowledge
├── scripts/
│   ├── fetch-models.sh      # Fetch models from API
│   └── set-model.sh         # Update configuration
└── README.md
```

### Scripts

- **fetch-models.sh**: Caches OpenRouter model list locally
- **set-model.sh**: Updates Claude Code config with model selection

## Contributing

Contributions welcome! Areas for improvement:
- Interactive model selector UI
- Cost tracking and budget alerts
- RSS feed integration for new models
- Model comparison feature
- Performance benchmarks

## License

MIT

## Resources

- [OpenRouter Documentation](https://openrouter.ai/docs)
- [OpenRouter Models API](https://openrouter.ai/docs/api/api-reference/models/get-models)
- [Claude Code Docs](https://code.claude.com/docs)
- [Model Pricing](https://openrouter.ai/models)