# Claude Code Plugin Security Guide

**Purpose**: Security best practices and patterns for Claude Code plugin development.

**Audience**: Plugin developers, security reviewers, enterprise distributors

**Version**: 1.0 | **Last Updated**: 2026-02-16

---

## Overview

This guide establishes security standards for Claude Code plugins to ensure enterprise-ready distribution. Plugins extend Claude Code with custom capabilities including shell commands, subprocess execution, file system access, and network operations—all of which require careful security considerations.

**Key Principles**:
- **Explicit permission declarations** - Users should understand what a plugin can do
- **Principle of least privilege** - Plugins should request only necessary capabilities
- **Sandboxed execution** - Hook commands run in controlled environments
- **Supply chain security** - Dependencies and updates must be verifiable

---

## 1. Plugin Security Model

### Capability Declarations

Plugins must declare their required capabilities through a **permissions manifest**. This allows users to review security implications before installation.

```json
{
  "name": "example-plugin",
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
      "allowed": ["git", "node"],
      "blocked": ["rm -rf", "eval"]
    },
    "environment": {
      "required": ["PATH"],
      "optional": ["CUSTOM_API_KEY"]
    }
  }
}
```

### Sandboxing Boundaries

Claude Code implements several layers of sandboxing for plugins:

| Layer | Boundary | Enforcement |
|-------|----------|-------------|
| **Path traversal** | Cannot access files outside `${CLAUDE_PLUGIN_ROOT}` unless symlinked | Plugin cache copying mechanism |
| **Command execution** | Hook commands run with user's shell permissions | User must approve commands |
| **Network access** | No implicit restrictions; plugins declare intended usage | Self-reported in manifest |
| **Environment** | Inherits user's environment; may expose secrets | Documentation warnings required |

### Execution Contexts

Different plugin components execute in different security contexts:

```typescript
// Context 1: Skills (Model-invoked, no direct system access)
// SAFE: Claude decides when to invoke based on task context
skills/my-skill/SKILL.md → LLM interpretation only

// Context 2: Hook Commands (User shell, full permissions)
// RISKY: Runs with user's permissions, can access any file
hooks/hooks.json → command: "${CLAUDE_PLUGIN_ROOT}/scripts/deploy.sh"

// Context 3: MCP Servers (Subprocess, can use tools)
// RISKY: Can access external APIs and filesystem
.mcp.json → command: "node server.js"

// Context 4: LSP Servers (Subprocess, code intelligence)
// MEDIUM: Primarily read-only but can execute code
.lsp.json → command: "gopls"
```

---

## 2. Permission Manifest Schema

The `permissions` field in `plugin.json` declares plugin capabilities.

### Complete Schema

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

### Field Descriptions

#### fileSystem

Declares file system access patterns.

```json
{
  "fileSystem": {
    "read": ["${CLAUDE_PLUGIN_ROOT}/data", "${CLAUDE_PLUGIN_ROOT}/config/*.json"],
    "write": ["${CLAUDE_PLUGIN_ROOT}/cache"],
    "description": "Reads model data and caches results locally"
  }
}
```

**Best practices**:
- Use `${CLAUDE_PLUGIN_ROOT}` for all plugin-relative paths
- Declare specific directories, not wildcards like `/**`
- Document why write access is needed

#### network

Declares network connectivity requirements.

```json
{
  "network": {
    "domains": ["api.openrouter.ai", "github.com"],
    "protocols": ["https"],
    "description": "Fetches model metadata from OpenRouter API"
  }
}
```

**Best practices**:
- Specify exact domains, not `*.example.com`
- Require HTTPS for all external communications
- Document what data is sent/received

#### subprocess

Declares command execution permissions.

```json
{
  "subprocess": {
    "allowed": ["git", "npm", "node"],
    "blocked": ["rm -rf", "eval", "> /dev/"],
    "description": "Runs git operations and npm scripts for deployment"
  }
}
```

**Best practices**:
- Allow specific commands, not generic shells
- Block dangerous patterns (`eval`, `rm -rf`)
- Use absolute paths or `${CLAUDE_PLUGIN_ROOT}` for custom scripts

#### environment

Declares environment variable requirements.

```json
{
  "environment": {
    "required": ["OPENROUTER_API_KEY"],
    "optional": ["MODEL_CACHE_TTL"],
    "description": "API key for model fetching, optional cache duration"
  }
}
```

**Best practices**:
- Distinguish required vs. optional variables
- Document where users should set variables (`.zshrc`, `settings.json`)
- Never suggest hardcoding secrets in plugin files

---

## 3. Security Best Practices

### Input Validation Patterns

From `SECURITY-PATTERNS.md` - adapt OWASP patterns for plugin hooks:

#### Pattern 1: Validate Hook Input

```bash
# ❌ WRONG - Unvalidated input
command: "echo $HOOK_INPUT | jq '.file_path' | xargs cat"

# ✅ CORRECT - Validate and sanitize
command: """
  # Extract file path safely
  FILE=$(echo "$HOOK_INPUT" | jq -r '.tool_input.file_path // empty')
  # Verify it's within plugin root
  if [[ "$FILE" != "${CLAUDE_PLUGIN_ROOT}"* ]]; then
    echo "Error: Path outside plugin root" >&2
    exit 1
  fi
  cat "$FILE"
"""
```

#### Pattern 2: Allowlist Commands

```bash
# ❌ WRONG - Arbitrary command execution
command: "jq -r '.command' <<< '$HOOK_INPUT' | sh"

# ✅ CORRECT - Command allowlist
command: """
  CMD=$(jq -r '.command' <<< "$HOOK_INPUT")
  case "$CMD" in
    git-status|git-log|npm-test)
      $CMD
      ;;
    *)
      echo "Error: Command not allowed: $CMD" >&2
      exit 1
      ;;
  esac
"""
```

### Secret Management

**Never commit secrets to git.** Use environment variables:

```json
// ❌ WRONG - Hardcoded secret
{
  "mcpServers": {
    "api": {
      "env": {
        "API_KEY": "sk_live_abc123..." // COMMITTED SECRET!
      }
    }
  }
}

// ✅ CORRECT - Environment variable reference
{
  "mcpServers": {
    "api": {
      "env": {
        "API_KEY": "${OPENROUTER_API_KEY}" // From user environment
      }
    }
  }
}
```

**Documentation pattern**:
```markdown
## Setup

1. Generate an API key at https://example.com/keys
2. Add to your shell profile (~/.zshrc or ~/.bashrc):

```bash
export EXAMPLE_API_KEY="sk-your-key-here"
```

3. Restart your shell or run `source ~/.zshrc`
```

### Code Signing Requirements

For enterprise distribution, plugins should include:

1. **Author verification** - `author` field with email/URL
2. **Repository linkage** - `repository` field in `plugin.json`
3. **License declaration** - SPDX identifier in `license` field
4. **Checksum verification** - Marketplace should verify published checksums

```json
{
  "name": "enterprise-plugin",
  "author": {
    "name": "Security Team",
    "email": "[email protected]"
  },
  "homepage": "https://docs.example.com/plugin",
  "repository": "https://github.com/example/plugin",
  "license": "MIT"
}
```

### Supply Chain Security

#### Dependency Declaration

Plugins should declare external dependencies:

```json
{
  "dependencies": {
    "mcpServers": {
      "database": {
        "command": "npx",
        "args": ["@example/mcp-postgres@^2.1.0"],
        "version": ">= 2.1.0 < 3.0.0"
      }
    }
  }
}
```

#### Update Security

When distributing via marketplace:
- Sign new releases with GPG keys
- Publish checksums for verification
- Use semantic versioning for breaking change detection

---

## 4. Vulnerability Disclosure

### Reporting Process

For security issues in this plugin:

1. **Do not open public issues**
2. Email: `[email protected]`
3. Include: Plugin version, reproduction steps, impact assessment
4. Response within 48 hours

### Security Review Checklist

Before releasing a plugin:

- [ ] All paths use `${CLAUDE_PLUGIN_ROOT}`
- [ ] No hardcoded secrets or API keys
- [ ] Hook commands validate input
- [ ] Dangerous shell patterns are blocked
- [ ] Network access is declared and HTTPS-only
- [ ] File system access is scoped to plugin directories
- [ ] Dependencies are pinned to specific versions
- [ ] Error messages don't leak sensitive information

---

## 5. ${CLAUDE_PLUGIN_ROOT} Security

### Path Validation

**Critical**: Always use `${CLAUDE_PLUGIN_ROOT}` for plugin-relative paths.

```json
// ❌ WRONG - Assumes installation location
{
  "hooks": {
    "PostToolUse": [{
      "command": "/usr/local/lib/my-plugin/scripts/process.sh" // Hardcoded!
    }]
  }
}

// ✅ CORRECT - Works from any installation location
{
  "hooks": {
    "PostToolUse": [{
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/process.sh" // Relative!
    }]
  }
}
```

### Race Condition Prevention

When writing to cache files:

```bash
# ❌ VULNERABLE - Race condition on cache file
CACHE_FILE="${CLAUDE_PLUGIN_ROOT}/cache/models.json"
echo "$DATA" > "$CACHE_FILE"

# ✅ SECURE - Atomic write with temp file
CACHE_FILE="${CLAUDE_PLUGIN_ROOT}/cache/models.json"
CACHE_DIR="$(dirname "$CACHE_FILE")"
TEMP_FILE="$(mktemp "${CACHE_DIR}/models.XXXXXX.json")"
echo "$DATA" > "$TEMP_FILE"
mv "$TEMP_FILE" "$CACHE_FILE"
```

### Fallback Behavior

Handle missing `${CLAUDE_PLUGIN_ROOT}` gracefully:

```bash
# Check if variable is set
if [[ -z "${CLAUDE_PLUGIN_ROOT:-}" ]]; then
  echo "Error: CLAUDE_PLUGIN_ROOT not set" >&2
  echo "This script must be run from within Claude Code" >&2
  exit 1
fi

# Verify directory exists
if [[ ! -d "$CLAUDE_PLUGIN_ROOT" ]]; then
  echo "Error: Plugin root not found: $CLAUDE_PLUGIN_ROOT" >&2
  exit 1
fi
```

---

## 6. Common Security Pitfalls

### Pitfall 1: Unrestricted Command Execution

```bash
# ❌ DANGEROUS - Executes arbitrary code
command: "eval $(jq -r '.script' <<< '$HOOK_INPUT')"

# ✅ SAFE - Validated command selection
command: """
  SCRIPT=$(jq -r '.script' <<< '$HOOK_INPUT')
  case "$SCRIPT" in
    format|lint|test)
      "${CLAUDE_PLUGIN_ROOT}/scripts/${SCRIPT}.sh"
      ;;
    *)
      echo "Invalid script: $SCRIPT" >&2
      exit 1
      ;;
  esac
"""
```

### Pitfall 2: Path Traversal

```bash
# ❌ VULNERABLE - Can read any file via ../../../etc/passwd
command: "cat $(jq -r '.file' <<< '$HOOK_INPUT')"

# ✅ SECURE - Validates path is within plugin root
command: """
  FILE=$(jq -r '.file' <<< '$HOOK_INPUT')
  REAL_FILE="$(cd "$CLAUDE_PLUGIN_ROOT" && realpath "$FILE")"
  REAL_ROOT="$(realpath "$CLAUDE_PLUGIN_ROOT")"
  if [[ "$REAL_FILE" != "$REAL_ROOT"* ]]; then
    echo "Error: Path outside plugin root" >&2
    exit 1
  fi
  cat "$REAL_FILE"
"""
```

### Pitfall 3: Information Leakage

```bash
# ❌ LEAKS - Exposes full error context
command: """
  npm install 2>&1 || {
    echo "Failed: $?"
    echo "Check logs at: $(pwd)/npm-debug.log"
    exit 1
  }
"""

# ✅ SANITIZED - Generic error, logs internally
command: """
  npm install >> "${CLAUDE_PLUGIN_ROOT}/logs/npm.log" 2>&1 || {
    echo "Installation failed. Check plugin logs." >&2
    exit 1
  }
"""
```

---

## 7. OWASP Top 10 for Plugins

Adapted from `SECURITY-PATTERNS.md`:

| OWASP Category | Plugin Impact | Mitigation |
|----------------|---------------|------------|
| **A01: Broken Access Control** | Hook commands access resources without validation | Validate all paths against `${CLAUDE_PLUGIN_ROOT}` |
| **A03: Injection** | User input in hook commands causes code injection | Use `jq` for JSON parsing, never `eval` |
| **A05: Security Misconfiguration** | Debug mode exposes sensitive data | Check environment before logging details |
| **A06: Vulnerable Components** | Outdated MCP servers have known CVEs | Pin dependency versions in marketplace |
| **A08: Data Integrity Failures** | Downloaded scripts not verified | Use checksums for external resources |
| **A09: Logging Failures** | API keys logged in debug output | Redact secrets from logs before output |

---

## 8. Security Review Template

Use this template when reviewing plugins for security issues:

```markdown
## Security Review: [Plugin Name]

**Reviewer**: [Name]
**Date**: [YYYY-MM-DD]
**Plugin Version**: [X.Y.Z]

### Capability Audit
- [ ] File system access declared and scoped
- [ ] Network access declared and HTTPS-only
- [ ] Subprocess execution uses allowlists
- [ ] Environment variables documented

### Code Review
- [ ] All paths use `${CLAUDE_PLUGIN_ROOT}`
- [ ] Hook commands validate input
- [ ] No hardcoded secrets
- [ ] Error messages sanitized

### Supply Chain
- [ ] Dependencies pinned to versions
- [ ] Repository linked and accessible
- [ ] License declared
- [ ] Author contact provided

### Findings
| Severity | Issue | Location | Recommendation |
|----------|-------|----------|----------------|
| Critical | [Description] | [File:Line] | [Fix] |
| High | [Description] | [File:Line] | [Fix] |

### Approval Status
- [ ] **APPROVED** - No critical issues, all high issues addressed
- [ ] **CONDITIONAL** - Address high-priority issues before distribution
- [ ] **REJECTED** - Critical issues present
```

---

## References

- **Security Patterns**: `SECURITY-PATTERNS.md` - OWASP Top 10 implementation patterns
- **OWASP Top 10 2021**: https://owasp.org/Top10/
- **Claude Code Hooks**: https://code.claude.com/docs/en/hooks-guide
- **Plugin Reference**: https://code.claude.com/docs/en/plugins-reference

---

**Version**: 1.0 | **Last Updated**: 2026-02-16 | **Maintainer**: Plugin Security Team
