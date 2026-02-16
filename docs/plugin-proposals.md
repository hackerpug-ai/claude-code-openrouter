# Claude Code Plugin Documentation Proposals

**Purpose**: Ready-to-merge documentation proposals for official Claude Code plugin docs.

**Version**: 1.0 | **Last Updated**: 2026-02-16

---

## Overview

This document contains proposals for additions to the official Claude Code plugin documentation. Each section is formatted as copy-paste ready markdown with suggested placement in the existing docs.

**Submit to**: https://github.com/anthropics/claude-code-docs/issues

---

## Proposal 1: Security Section Addition

**Location**: New section after "Develop more complex plugins"
**URL**: https://code.claude.com/docs/en/plugins#security

```markdown
### Security

Plugins extend Claude Code with powerful capabilities including shell commands, file system access, and network operations. Follow these security best practices to ensure your plugin is safe for distribution.

#### Permission Manifest

Declare your plugin's capabilities using a `permissions` field in `plugin.json`:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "permissions": {
    "fileSystem": {
      "read": ["${CLAUDE_PLUGIN_ROOT}/data"],
      "write": ["${CLAUDE_PLUGIN_ROOT}/cache"]
    },
    "network": {
      "domains": ["api.example.com"],
      "protocols": ["https"]
    },
    "subprocess": {
      "allowed": ["git", "node"]
    }
  }
}
```

#### ${CLAUDE_PLUGIN_ROOT} Security

Always use the `${CLAUDE_PLUGIN_ROOT}` environment variable for plugin-relative paths. This ensures your plugin works regardless of installation location:

```json
// ❌ WRONG - Hardcoded path
{
  "hooks": {
    "PostToolUse": [{
      "command": "/usr/local/lib/plugin/scripts/format.sh"
    }]
  }
}

// ✅ CORRECT - Uses plugin root
{
  "hooks": {
    "PostToolUse": [{
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh"
    }]
  }
}
```

#### Secret Management

Never commit secrets to your plugin. Use environment variables:

```json
// ❌ WRONG - Hardcoded API key
{
  "mcpServers": {
    "api": {
      "env": {
        "API_KEY": "sk_live_abc123..."
      }
    }
  }
}

// ✅ CORRECT - Environment variable
{
  "mcpServers": {
    "api": {
      "env": {
        "API_KEY": "${MY_API_KEY}"
      }
    }
  }
}
```

Document required environment variables in your README:

```markdown
## Setup

1. Generate an API key at https://example.com/keys
2. Add to ~/.zshrc:

```bash
export MY_API_KEY="sk-your-key-here"
```

3. Restart your shell
```

#### Input Validation

Validate all input in hook scripts:

```bash
# Extract file path safely
FILE=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')

# Verify it's within plugin root
if [[ "$FILE" != "${CLAUDE_PLUGIN_ROOT}"* ]]; then
  echo "Error: Path outside plugin root" >&2
  exit 1
fi

# Process the file
cat "$FILE"
```

#### Security Checklist

Before releasing your plugin:

- [ ] All paths use `${CLAUDE_PLUGIN_ROOT}`
- [ ] No hardcoded secrets or API keys
- [ ] Hook commands validate input
- [ ] File system access scoped to plugin directories
- [ ] Network access declared and HTTPS-only
- [ ] Dangerous shell patterns blocked (eval, rm -rf)
```

---

## Proposal 2: Validation Section Addition

**Location**: New section after "Debug plugin issues"
**URL**: https://code.claude.com/docs/en/plugins#validation

```markdown
### Validate Your Plugin

Use the `plugin validate` command to check your plugin for common issues before distributing:

```bash
claude plugin validate ./my-plugin
```

#### Validation Checks

The validator checks:

| Check | Description | Exit Code on Fail |
|-------|-------------|-------------------|
| **Manifest** | JSON syntax, required fields, semantic version | 1 (Critical) |
| **Paths** | File existence, ${CLAUDE_PLUGIN_ROOT} usage, no parent traversal | 1 (Critical) |
| **Hooks** | Valid event names, command path resolution | 1 (Critical) |
| **MCP** | Command availability, args array format | 1 (Critical) |
| **Security** | No hardcoded secrets, dangerous patterns | 2 (Warning) |

#### Output Format

```
$ claude plugin validate ./my-plugin

✓ Manifest: Valid JSON structure
✓ Manifest: Semantic version 1.2.3
✓ Paths: All files exist
✓ Hooks: Command paths resolve
⚠ Hooks: Script not executable (run: chmod +x scripts/format.sh)
✓ MCP: Commands available in PATH

Validation: PASSED with 1 warning
Run with --force to install despite warnings.
```

#### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | All validations pass | Plugin is ready |
| 1 | Critical error | Cannot install |
| 2 | Warning | Can install with `--force` |
| 3 | Skipped | Optional check not run |

#### JSON Output

For CI/CD integration, use JSON output:

```bash
claude plugin validate ./my-plugin --format json
```

Returns:

```json
{
  "status": "passed",
  "errors": [],
  "warnings": [
    {
      "check": "hooks",
      "message": "Script not executable",
      "location": "scripts/format.sh",
      "fix": "chmod +x scripts/format.sh"
    }
  ],
  "summary": {
    "total": 8,
    "passed": 7,
    "warnings": 1,
    "failed": 0
  }
}
```
```

---

## Proposal 3: Error Handling Specification

**Location**: Add to "Hooks reference" section
**URL**: https://code.claude.com/docs/en/hooks-reference#error-handling

```markdown
### Error Handling

Hooks can specify error handling behavior:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh",
            "onError": {
              "action": "continue",
              "message": "Formatting failed but continuing. Run manually: npm run format"
            }
          }
        ]
      }
    ]
  }
}
```

#### Error Actions

| Action | Behavior |
|--------|----------|
| `fail` | Stop execution and show error (default) |
| `continue` | Continue despite error, show warning |
| `silent` | Continue without showing error |

#### Error Messages

Hooks should provide actionable error messages:

```bash
# ❌ BAD - Unhelpful error
echo "Error occurred" >&2
exit 1

# ✅ GOOD - Actionable error
echo "ERROR: Failed to fetch models from API" >&2
echo "" >&2
echo "To fix:" >&2
echo "  1. Check API key: echo \$API_KEY" >&2
echo "  2. Test connectivity: curl https://api.example.com/health" >&2
echo "  3. View logs: tail -f ${CLAUDE_PLUGIN_ROOT}/logs/error.log" >&2
exit 1
```

#### Exit Code Best Practices

| Exit Code | Meaning | Usage |
|-----------|---------|-------|
| 0 | Success | Normal completion |
| 1 | User error | Invalid input, retry with fix |
| 2 | Configuration | Update settings |
| 3 | Network error | Transient, can retry |
| 4 | Permission | Fix file permissions |
| 5 | Missing dependency | Install required tool |
| 10 | Bug | Report to plugin author |
```

---

## Proposal 4: Dependency Manifest Schema

**Location**: Add to "Plugin manifest schema" section
**URL**: https://code.claude.com/docs/en/plugins-reference#dependencies

```markdown
### Dependencies

Plugins can declare external dependencies:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "dependencies": {
    "claude": ">= 1.0.33",
    "commands": {
      "git": ">= 2.0.0",
      "node": ">= 18.0.0"
    },
    "mcpServers": {
      "@example/database": "^2.1.0"
    },
    "environment": {
      "EXAMPLE_API_KEY": {
        "description": "API key for Example service",
        "required": true,
        "documentationUrl": "https://example.com/docs/api-keys"
      }
    }
  }
}
```

#### Dependency Fields

| Field | Type | Description |
|-------|------|-------------|
| `claude` | string | Minimum Claude Code version |
| `commands` | object | Required shell commands with version constraints |
| `mcpServers` | object | MCP server dependencies with version constraints |
| `environment` | object | Required/optional environment variables |

#### Version Constraints

| Constraint | Meaning | Example |
|------------|---------|---------|
| `^1.2.3` | Compatible with >= 1.2.3, < 2.0.0 | `^2.1.0` |
| `~1.2.3` | Compatible with >= 1.2.3, < 1.3.0 | `~2.1.0` |
| `>= 1.2.3` | Greater than or equal to | `>= 1.0.33` |
| `< 2.0.0` | Less than | `< 21.0.0` |

#### Environment Variable Schema

```json
{
  "VARIABLE_NAME": {
    "description": "Human-readable description",
    "required": true,
    "optional": false,
    "documentationUrl": "https://example.com/docs"
  }
}
```
```

---

## Proposal 5: Migration Guide Section

**Location**: New section before "Next steps"
**URL**: https://code.claude.com/docs/en/plugins#migration

```markdown
### Migrating Between Plugin Versions

When updating to a new major version, follow these steps:

#### 1. Check for Breaking Changes

Review the CHANGELOG for breaking changes:

```bash
# View changelog for a plugin
claude plugin changelog plugin-name
```

#### 2. Backup Your Configuration

Before upgrading, backup your settings:

```bash
# Backup user settings
cp ~/.claude/settings.json ~/.claude/settings.json.backup

# Backup project settings
cp .claude/settings.json .claude/settings.json.backup
```

#### 3. Update the Plugin

```bash
# Update to latest version
claude plugin update plugin-name

# Or install specific version
claude plugin install plugin-name@2.0.0
```

#### 4. Fix Breaking Changes

Common migration patterns:

**Command syntax changes**:
```bash
# Old syntax (v1.x)
/or-set anthropic/claude-sonnet-4

# New syntax (v2.x)
/or-set --model anthropic/claude-sonnet-4
```

**Configuration changes**:
```json
// Old configuration (v1.x)
{
  "pluginSettings": {
    "legacy": true
  }
}

// New configuration (v2.x)
{
  "pluginSettings": {
    "features": {
      "legacyMode": false
    }
  }
}
```

#### 5. Clear Caches (if needed)

Some plugins require cache clearing after major upgrades:

```bash
# Clear plugin cache
claude plugin clear-cache plugin-name

# Or use plugin command
/plugin-name:clear-cache
```

#### 6. Verify Installation

Test that the plugin works correctly:

```bash
# Check plugin status
claude plugin status plugin-name

# Test plugin commands
/plugin-name:help
```

#### Rollback if Needed

If you encounter issues, rollback to the previous version:

```bash
# Rollback to previous version
claude plugin install plugin-name@1.9.0

# Restore backup settings
cp ~/.claude/settings.json.backup ~/.claude/settings.json
```
```

---

## Proposal 6: Permissions Field Specification

**Location**: Add to "Complete schema" section
**URL**: https://code.claude.com/docs/en/plugins-reference#permissions

```markdown
### Permissions

The `permissions` field declares plugin capabilities for security transparency:

```json
{
  "permissions": {
    "fileSystem": {
      "read": ["string|array"],
      "write": ["string|array"],
      "description": "string"
    },
    "network": {
      "domains": ["string|array"],
      "protocols": ["string|array"],
      "description": "string"
    },
    "subprocess": {
      "allowed": ["string|array"],
      "blocked": ["string|array"],
      "description": "string"
    },
    "environment": {
      "required": ["string|array"],
      "optional": ["string|array"],
      "description": "string"
    }
  }
}
```

#### Permission Fields

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `fileSystem.read` | array | Paths plugin reads from | `["${CLAUDE_PLUGIN_ROOT}/data"]` |
| `fileSystem.write` | array | Paths plugin writes to | `["${CLAUDE_PLUGIN_ROOT}/cache"]` |
| `network.domains` | array | Domains plugin contacts | `["api.example.com"]` |
| `network.protocols` | array | Protocols plugin uses | `["https"]` |
| `subprocess.allowed` | array | Commands plugin may run | `["git", "npm"]` |
| `subprocess.blocked` | array | Commands blocked by plugin | `["rm -rf", "eval"]` |
| `environment.required` | array | Required environment variables | `["API_KEY"]` |
| `environment.optional` | array | Optional environment variables | `["DEBUG"]` |

#### Best Practices

- Use `${CLAUDE_PLUGIN_ROOT}` for all plugin-relative paths
- Specify exact domains, not wildcards
- Require HTTPS for all network access
- Block dangerous shell patterns (`eval`, `rm -rf`)
- Document why each permission is needed
```

---

## Proposal 7: Deprecation Policy Addition

**Location**: Add to "Version management" section
**URL**: https://code.claude.com/docs/en/plugins-reference#deprecation

```markdown
### Deprecation Policy

When deprecating features or releasing breaking changes:

#### Timeline

- **Announcement**: Declare deprecation with warning messages
- **Grace Period**: Minimum 3 months before removal
- **Removal**: Remove in next MAJOR version

#### Deprecation Process

1. **Add warnings** to deprecated features:

```bash
# commands/legacy-feature.sh
echo "WARNING: --legacy flag is deprecated and will be removed in v2.0" >&2
echo "Use --new-feature instead. See: https://docs.example.com/migrate-v2" >&2
```

2. **Document in CHANGELOG**:

```markdown
## [2.0.0] - 2024-06-01

### ⚠️ Breaking Changes

- **Removed**: `--legacy` flag (deprecated since v1.5.0)
  - **Migration**: Use `--new-feature` instead
```

3. **Provide migration guide** with clear examples:

```markdown
# Migration: v1.x → v2.0

## Legacy Flag Removal

Old: `/plugin --legacy value`
New: `/plugin --new-feature value`
```

#### User Communication

Communicate deprecations through:

- In-plugin warnings when deprecated feature is used
- CHANGELOG entries announcing deprecation
- Documentation updates with migration guides
- Release notes for affected versions
```

---

## Issue Template

Use this template when submitting proposals:

```markdown
## Plugin Documentation Proposal

### Summary
[One-line description of what you're proposing]

### Proposed Section
[Link to existing section where this should be added]

### Content
[Paste the markdown content from above proposals]

### Rationale
[Why this addition is needed]

### Examples
[Real-world examples where this would help]

### Additional Notes
[Any other context]
```

---

## Submission Process

1. **Choose a proposal** from above
2. **Format for GitHub** using the issue template
3. **Submit to** https://github.com/anthropics/claude-code-docs/issues
4. **Reference** this document for full context
5. **Tag** with `documentation` and `plugin` labels

---

**Version**: 1.0 | **Last Updated**: 2026-02-16 | **Status**: Ready for Submission
