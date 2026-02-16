---
name: openrouter-models
description: OpenRouter API integration, model selection, and Claude Code configuration guidance
version: 1.0.0
---

# OpenRouter Models for Claude Code

This skill provides guidance on using OpenRouter's extensive model catalog with Claude Code, including dynamic model fetching, selection strategies, and configuration patterns.

## When to Use This Skill

Use this skill when:
- Selecting an OpenRouter model for a specific task
- Configuring Claude Code to use OpenRouter
- Understanding model capabilities and pricing
- Troubleshooting OpenRouter integration
- Optimizing model selection for cost/performance

## OpenRouter API Overview

OpenRouter provides unified access to 600+ AI models through a single API endpoint. Key features:

- **Free model listing API**: No authentication required
- **Comprehensive metadata**: Pricing, context length, capabilities
- **Provider failover**: Automatic routing between providers
- **Compatible with Anthropic API**: Drop-in replacement for Claude

### Model List Endpoint

```
GET https://openrouter.ai/api/v1/models
```

Returns JSON with model data including:
- `id`: Model identifier (e.g., `anthropic/claude-sonnet-4`)
- `name`: Human-readable display name
- `context_length`: Maximum tokens supported
- `pricing`: Cost per million tokens (prompt/completion)
- `architecture`: Modality support (text, image, audio)
- `supported_parameters`: API features (tools, streaming, etc.)

## Model Selection Strategy

### For Coding Tasks

Best models for programming and code-related work:
1. **GLM-4.7** (`z-ai/glm-4-7b-chatsft`) - Excellent for coding, cost-effective
2. **Claude Sonnet 4** (`anthropic/claude-sonnet-4`) - Strong reasoning, tools
3. **Qwen Coder 3** (`qwen/qwen3-coder-next`) - Specialized for code agents
4. **DeepSeek R1** (`deepseek/deepseek-r1`) - Great for debugging, low cost

### For Long Context

Models with extended context windows:
1. **Gemini 2.5 Pro** (`google/gemini-2.5-pro-preview`) - 1M+ tokens
2. **Claude Opus 4.6** (`anthropic/claude-opus-4-6`) - 1M tokens
3. **Qwen3** series - Up to 262K tokens

### For Cost Optimization

Free or low-cost options:
1. **Llama 3.1 70B** (`meta-llama/llama-3.1-70b-instruct:free`) - Free tier
2. **Qwen models** - Very low pricing, good performance
3. **Step 3.5 Flash** (`stepfun/step-3.5-flash`) - Fast, low cost

## Claude Code Integration

### Environment Variables

To use OpenRouter with Claude Code, set these variables:

```bash
# Required
export ANTHROPIC_BASE_URL="https://openrouter.ai/api"
export ANTHROPIC_AUTH_TOKEN="$OPENROUTER_API_KEY"
export ANTHROPIC_API_KEY=""  # Must be explicitly empty

# Optional: Set default models
export ANTHROPIC_DEFAULT_OPUS_MODEL="anthropic/claude-opus-4-6"
export ANTHROPIC_DEFAULT_SONNET_MODEL="anthropic/claude-sonnet-4"
export ANTHROPIC_DEFAULT_HAIKU_MODEL="z-ai/glm-4-5b-chatsft"
```

### Configuration File

Add to `.claude/settings.json` (project) or `~/.claude/settings.json` (global):

```json
{
  "openrouter": {
    "enabled": true,
    "model": "anthropic/claude-sonnet-4",
    "baseUrl": "https://openrouter.ai/api"
  }
}
```

## Hot-Swapping Models

To change models during a session:

1. **Use plugin commands**: `/or-set <model-id>`
2. **Export environment variables**:
   ```bash
   export ANTHROPIC_DEFAULT_MODEL="google/gemini-2.5-pro-preview"
   ```
3. **Use Claude's built-in**: `/model <model-id>`

## API Key Management

### Getting an API Key

1. Sign up at https://openrouter.ai
2. Navigate to Keys page
3. Create a new API key
4. Set `OPENROUTER_API_KEY` environment variable

### Best Practices

- Store API keys in environment variables, not config files
- Use `.env-global` or `.zshrc` for persistent key storage
- Never commit API keys to version control
- Use spending limits in OpenRouter dashboard

## Model Features Reference

### Vision Capabilities

Models supporting image input:
- `google/gemini-2.5-pro-preview` - Excellent vision
- `anthropic/claude-3.5-sonnet` - Strong visual understanding
- `openai/gpt-4o` - Good multimodal support

### Tool/Function Calling

Best models for agent workflows:
- `anthropic/claude-opus-4-6` - Superior tool use
- `anthropic/claude-sonnet-4` - Balanced tools + speed
- `qwen/qwen3-coder-next` - Optimized for code tools

### Thinking/Reasoning

Models with extended reasoning:
- `deepseek/deepseek-r1` - Deep reasoning chains
- `qwen/qwen3-max-thinking` - Multi-step reasoning
- `anthropic/claude-opus-4-6` - Complex problem solving

## Pricing Reference

Approximate costs per million tokens (as of 2026-02):

| Model | Input | Output | Notes |
|-------|-------|--------|-------|
| Claude Opus 4.6 | $5.00 | $25.00 | Premium, best quality |
| Claude Sonnet 4 | $3.00 | $15.00 | Balanced |
| Gemini 2.5 Pro | $0.60 | $3.60 | Good value, long context |
| GLM-4.7 | $0.30 | $2.55 | Excellent for coding |
| Qwen Coder | $0.07 | $0.30 | Very cost-effective |
| Llama 3.1 70B | Free | Free | Limited availability |

## Troubleshooting

### Common Issues

**"Auth failed" error**:
- Verify `OPENROUTER_API_KEY` is set
- Check `ANTHROPIC_API_KEY` is empty string
- Ensure `ANTHROPIC_BASE_URL` points to OpenRouter

**Model not found**:
- Refresh model cache: `/or-models --refresh`
- Check model ID format: `provider/model-name`
- Verify model is available on OpenRouter

**Slow responses**:
- Check provider routing in OpenRouter dashboard
- Try a different model/provider
- Verify network connectivity

## Advanced Configuration

### Provider Preferences

Specify which providers to use:

```json
{
  "openrouter": {
    "provider": {
      "order": ["anthropic", "amazonaws", "google"],
      "allow_fallbacks": true
    }
  }
}
```

### Request Routing

Route different task types to different models:

```json
{
  "openrouter": {
    "models": {
      "default": "anthropic/claude-sonnet-4",
      "coding": "z-ai/glm-4-7b-chatsft",
      "reasoning": "deepseek/deepseek-r1",
      "vision": "google/gemini-2.5-pro-preview"
    }
  }
}
```

## References

- OpenRouter Docs: https://openrouter.ai/docs
- Models API: https://openrouter.ai/docs/api/api-reference/models/get-models
- Claude Code Integration: https://openrouter.ai/docs/guides/guides/claude-code-integration
- TypeScript SDK: https://openrouter.ai/docs/sdks/typescript