# OpenRouter Plugin - Claude Code Context

**Project**: openrouter-plugin
**Description**: Dynamically fetch and switch between 600+ OpenRouter AI models in Claude Code
**Version**: 0.1.0

---

## Project Documentation

### Plugin Development Guide

This project includes comprehensive plugin development documentation in the `docs/` directory:

| Document | Purpose | Location |
|----------|---------|----------|
| **Security Guide** | Security best practices, permission manifests, ${CLAUDE_PLUGIN_ROOT} patterns | `docs/plugin-security.md` |
| **Validation Guide** | Schema validation, testing requirements, CLI specification | `docs/plugin-validation.md` |
| **Lifecycle Guide** | Versioning, deprecation, dependencies, distribution | `docs/plugin-lifecycle.md` |
| **Proposals** | Ready-to-merge additions to official docs | `docs/plugin-proposals.md` |
| **README** | Documentation overview | `docs/README.md` |

**When working on this plugin**, reference these documents for:
- Security patterns before implementing hooks or MCP servers
- Validation requirements before releasing changes
- Versioning guidelines when making breaking changes

---

## Project Structure

```
openrouter-plugin/
├── .claude-plugin/
│   └── plugin.json          # Plugin manifest
├── commands/                # Slash commands
│   ├── models.md            # /or-models
│   ├── set.md               # /or-set
│   └── status.md            # /or-status
├── skills/                  # Agent Skills
│   └── openrouter-models/
│       └── SKILL.md         # OpenRouter knowledge
├── scripts/                 # Utility scripts
│   ├── fetch-models.sh      # Fetch models from API
│   └── set-model.sh         # Update configuration
├── docs/                    # Plugin development docs
│   ├── plugin-security.md
│   ├── plugin-validation.md
│   ├── plugin-lifecycle.md
│   ├── plugin-proposals.md
│   └── README.md
└── README.md                # User documentation
```

---

## Key Concepts

### ${CLAUDE_PLUGIN_ROOT}

This environment variable contains the absolute path to the plugin directory. Always use it for plugin-relative paths:

```bash
# In hook scripts or MCP server configs
"${CLAUDE_PLUGIN_ROOT}/scripts/fetch-models.sh"
"${CLAUDE_PLUGIN_ROOT}/cache/models.json"
```

### API Key Management

This plugin requires `OPENROUTER_API_KEY` to be set in the user's environment:

```bash
export OPENROUTER_API_KEY="sk-your-key-here"
```

**Never hardcode API keys** in the plugin. Reference `docs/plugin-security.md` for secret management patterns.

---

## Development Workflow

### Making Changes

1. **Read relevant docs** - Check `docs/` for security/validation patterns
2. **Implement change** - Edit commands, skills, or scripts
3. **Test locally** - Use `claude --plugin-dir .` to test
4. **Validate** - Run validation checks if available
5. **Update version** - Follow SemVer in `plugin.json`
6. **Document** - Update CHANGELOG for breaking changes

### Version Management

Follow semantic versioning:
- **PATCH** (0.1.0 → 0.1.1): Bug fixes
- **MINOR** (0.1.0 → 0.2.0): New features
- **MAJOR** (0.1.0 → 1.0.0): Breaking changes

Reference `docs/plugin-lifecycle.md` for full deprecation policy.

---

## Testing

### Local Testing

```bash
# Start Claude Code with plugin
claude --plugin-dir .

# Test commands
/or-models
/or-set anthropic/claude-sonnet-4
/or-status
```

### Validation

If plugin-validator is installed:

```bash
# Validate plugin
claude --plugin-dir ~/.claude/plugins/plugin-validator -- eval '/plugin-validator:validate .'

# Specific checks
claude --plugin-dir ~/.claude/plugins/plugin-validator -- eval '/plugin-validator:validate . --check manifest'
```

---

## Security Considerations

This plugin:
- Makes HTTPS requests to `api.openrouter.ai`
- Reads/writes to `~/.openrouter-plugin/` cache directory
- Does not execute arbitrary user commands
- Does not access files outside plugin directories

See `docs/plugin-security.md` for full security analysis.

---

## Related Documentation

- **OpenRouter API**: https://openrouter.ai/docs
- **Claude Code Plugins**: https://code.claude.com/docs/en/plugins
- **Model Reference**: https://openrouter.ai/models

---

**Last Updated**: 2026-02-16
**Maintainer**: Justin Rich
