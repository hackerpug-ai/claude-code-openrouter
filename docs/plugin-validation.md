# Claude Code Plugin Validation Guide

**Purpose**: Validation and testing standards for Claude Code plugins.

**Audience**: Plugin developers, QA engineers, validation tool authors

**Version**: 1.0 | **Last Updated**: 2026-02-16

---

## Overview

This guide establishes validation and testing requirements for Claude Code plugins to ensure quality, compatibility, and security. Proper validation prevents common issues like malformed manifests, broken hooks, missing dependencies, and security vulnerabilities.

**Validation Goals**:
- **Schema compliance** - Manifests match expected structure
- **Path resolution** - All referenced files exist and are accessible
- **Semantic versioning** - Version numbers follow SemVer
- **Hook functionality** - Event handlers execute correctly
- **MCP compatibility** - Servers start and respond to protocol
- **Security standards** - No dangerous patterns or exposed secrets

---

## 1. Manifest Validation

### Required Fields

The `plugin.json` manifest must include:

```json
{
  "name": "plugin-name",           // REQUIRED: Kebab-case identifier
  "version": "1.0.0",               // REQUIRED: Semantic version
  "description": "Brief description" // REQUIRED: User-facing explanation
}
```

### Validation Rules

#### Rule 1: Name Format (CRITICAL)

Plugin names must be:
- Kebab-case (lowercase with hyphens)
- 3-42 characters
- Start with a letter
- Contain only letters, numbers, and hyphens

```bash
# ✅ VALID
"my-plugin"
"openrouter-integration"
"deployment-tools-v2"

# ❌ INVALID
"MyPlugin"              // Not kebab-case
"my_plugin"             // Underscore not allowed
"123-plugin"            // Must start with letter
"my"                    // Too short (<3 chars)
"this-is-a-very-long-plugin-name-that-exceeds-maximum-allowed-length"
```

**Exit code**: 1 (Critical error)

#### Rule 2: Semantic Versioning (CRITICAL)

Versions must follow SemVer 2.0.0: `MAJOR.MINOR.PATCH`

```bash
# ✅ VALID
"1.0.0"
"2.1.3"
"0.4.0-beta.1"
"3.0.0-rc.2"

# ❌ INVALID
"1.0"                   // Missing PATCH
"v1.0.0"                // No 'v' prefix
"1.0.0.0"               // Too many parts
"latest"                // Not a version
```

**Exit code**: 1 (Critical error)

#### Rule 3: Naming Conflicts (WARNING)

Plugin names should not conflict with built-in commands:

```bash
# ⚠️ WARNING - Conflicts with built-in
"help"
"debug"
"plugin"

# ✅ SAFE - Unique namespace
"my-help"
"plugin-helper"
"debug-tools"
```

**Exit code**: 2 (Warning)

### Schema Compliance

Validate against the JSON schema:

```json
{
  "$schema": "http://json-schema.org/draft-07/schema#",
  "type": "object",
  "required": ["name", "version"],
  "properties": {
    "name": {
      "type": "string",
      "pattern": "^[a-z][a-z0-9-]{2,41}[a-z0-9]$"
    },
    "version": {
      "type": "string",
      "pattern": "^(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)(?:-((?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*)(?:\\.(?:0|[1-9]\\d*|\\d*[a-zA-Z-][0-9a-zA-Z-]*))*))?(?:\\+([0-9a-zA-Z-]+(?:\\.[0-9a-zA-Z-]+)*))?$"
    },
    "description": {
      "type": "string",
      "maxLength": 200
    },
    "author": {
      "type": "object",
      "properties": {
        "name": { "type": "string" },
        "email": { "type": "string", "format": "email" },
        "url": { "type": "string", "format": "uri" }
      }
    },
    "commands": {
      "type": ["string", "array"],
      "items": { "type": "string" }
    },
    "skills": {
      "type": ["string", "array"],
      "items": { "type": "string" }
    },
    "hooks": {
      "type": ["string", "array", "object"]
    },
    "mcpServers": {
      "type": ["string", "array", "object"]
    },
    "lspServers": {
      "type": ["string", "array", "object"]
    }
  }
}
```

---

## 2. Path Resolution Validation

### ${CLAUDE_PLUGIN_ROOT} Usage

All paths must use the `${CLAUDE_PLUGIN_ROOT}` variable:

```json
// ❌ INVALID - Hardcoded absolute path
{
  "hooks": {
    "PostToolUse": [{
      "command": "/usr/local/lib/plugin/scripts/process.sh"
    }]
  }
}

// ✅ VALID - Uses plugin root variable
{
  "hooks": {
    "PostToolUse": [{
      "command": "${CLAUDE_PLUGIN_ROOT}/scripts/process.sh"
    }]
  }
}
```

**Exit code**: 1 (Critical error)

### Path Format Rules

1. **Relative paths only** - All paths must start with `./` or use `${CLAUDE_PLUGIN_ROOT}`
2. **No parent traversal** - Paths cannot contain `../`
3. **Existence verification** - Referenced files must exist

```bash
# ✅ VALID
"./scripts/deploy.sh"
"${CLAUDE_PLUGIN_ROOT}/commands/status.md"
"./custom/agents/reviewer.md"

# ❌ INVALID
"../shared-utils/format.sh"            // Parent traversal
"/usr/local/bin/script.sh"             // Absolute path
"${CLAUDE_PLUGIN_ROOT}/../external.sh" // Parent via variable
"./scripts/missing.sh"                 // File doesn't exist
```

**Exit code**: 1 (Critical error)

### File Existence Checks

Validate all referenced files exist:

```bash
# Check command files
for cmd in "${commands[@]}"; do
  if [[ ! -f "${PLUGIN_ROOT}/${cmd}" ]]; then
    echo "ERROR: Command file not found: ${cmd}" >&2
    exit 1
  fi
done

# Check hook scripts
for hook_entry in "${hooks[@]}"; do
  cmd=$(jq -r '.command' <<< "$hook_entry")
  # Remove ${CLAUDE_PLUGIN_ROOT} prefix for checking
  cmd_path="${cmd#\${CLAUDE_PLUGIN_ROOT\}/}"
  if [[ ! -f "${PLUGIN_ROOT}/${cmd_path}" ]]; then
    echo "ERROR: Hook script not found: ${cmd_path}" >&2
    exit 1
  fi
done
```

---

## 3. Hook Validation

### Hook Configuration Structure

Hooks in `hooks.json` must follow the correct structure:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/pre-write.sh"
          }
        ]
      }
    ]
  }
}
```

### Validation Checks

#### Check 1: Valid Event Names (CRITICAL)

Only documented hook events are allowed:

```bash
# ✅ VALID EVENTS
PreToolUse
PostToolUse
PostToolUseFailure
PermissionRequest
UserPromptSubmit
Notification
Stop
SubagentStart
SubagentStop
SessionStart
SessionEnd
TeammateIdle
TaskCompleted
PreCompact

# ❌ INVALID EVENTS
BeforeToolUse          // Typo - should be PreToolUse
AfterWrite             // Not a standard event
ToolUseSuccess         // Wrong naming
```

**Exit code**: 1 (Critical error)

#### Check 2: Hook Types (CRITICAL)

Only valid hook types are allowed:

```bash
# ✅ VALID TYPES
"command"
"prompt"
"agent"

# ❌ INVALID TYPES
"script"
"exec"
"run"
```

**Exit code**: 1 (Critical error)

#### Check 3: Command Path Resolution (CRITICAL)

Hook commands must resolve to executable files:

```bash
# Validate command exists and is executable
validate_hook_command() {
  local cmd="$1"
  local plugin_root="$2"

  # Extract path from ${CLAUDE_PLUGIN_ROOT}
  local cmd_path="${cmd#\${CLAUDE_PLUGIN_ROOT\}/}"
  local full_path="${plugin_root}/${cmd_path}"

  if [[ ! -f "$full_path" ]]; then
    echo "ERROR: Hook command not found: $cmd_path" >&2
    return 1
  fi

  if [[ ! -x "$full_path" ]]; then
    echo "WARNING: Hook command not executable: $cmd_path" >&2
    echo "Run: chmod +x '$full_path'" >&2
    return 2
  fi

  return 0
}
```

**Exit code**: 1 (Critical error if not found), 2 (Warning if not executable)

#### Check 4: Timeout Values (WARNING)

Hook timeouts should be reasonable (1-300 seconds):

```bash
# ✅ REASONABLE TIMEOUTS
30      // 30 seconds - quick operation
120     // 2 minutes - moderate operation
300     // 5 minutes - maximum reasonable

# ⚠️ SUSPICIOUS TIMEOUTS
0       // No timeout - may hang indefinitely
600     // 10 minutes - excessive for typical hook
3600    // 1 hour - almost certainly wrong
```

**Exit code**: 2 (Warning)

### Hook Syntax Validation

Validate JSON syntax:

```bash
validate_hooks_json() {
  local hooks_file="$1"

  if [[ ! -f "$hooks_file" ]]; then
    echo "ERROR: hooks.json not found: $hooks_file" >&2
    return 1
  fi

  # Check JSON syntax
  if ! jq empty "$hooks_file" 2>/dev/null; then
    echo "ERROR: Invalid JSON in hooks.json" >&2
    jq . "$hooks_file" 2>&1 | head -5 >&2
    return 1
  fi

  # Validate structure
  if ! jq '.hooks | type == "object"' "$hooks_file" >/dev/null 2>&1; then
    echo "ERROR: hooks.json missing 'hooks' object" >&2
    return 1
  fi

  return 0
}
```

---

## 4. MCP Server Validation

### MCP Configuration Structure

```json
{
  "mcpServers": {
    "server-name": {
      "command": "node",
      "args": ["${CLAUDE_PLUGIN_ROOT}/servers/mcp.js"],
      "env": {
        "API_KEY": "${EXAMPLE_API_KEY}"
      }
    }
  }
}
```

### Validation Checks

#### Check 1: Command Availability (CRITICAL)

MCP server commands must be available in PATH or plugin root:

```bash
validate_mcp_command() {
  local cmd="$1"
  local plugin_root="$2"

  # Check if command exists in PATH
  if command -v "$cmd" >/dev/null 2>&1; then
    return 0
  fi

  # Check if command is relative to plugin root
  local cmd_path="${cmd#\${CLAUDE_PLUGIN_ROOT\}/}"
  if [[ -f "${plugin_root}/${cmd_path}" ]]; then
    return 0
  fi

  echo "ERROR: MCP command not found: $cmd" >&2
  return 1
}
```

**Exit code**: 1 (Critical error)

#### Check 2: Args Array Format (CRITICAL)

MCP args must be an array:

```json
// ✅ VALID
{
  "args": ["--config", "file.json", "--verbose"]
}

// ❌ INVALID
{
  "args": "--config file.json --verbose"  // String, not array
}
```

**Exit code**: 1 (Critical error)

#### Check 3: Environment Variables (WARNING)

Environment variables should use `${VAR}` syntax for user-provided values:

```json
// ✅ GOOD - References environment variable
{
  "env": {
    "API_KEY": "${OPENROUTER_API_KEY}"
  }
}

// ⚠️ WARNING - Hardcoded value (may be intentional for defaults)
{
  "env": {
    "CACHE_DIR": "/tmp/mcp-cache"
  }
}

// ❌ BAD - Hardcoded secret
{
  "env": {
    "API_KEY": "sk_live_abc123..."  // NEVER DO THIS
  }
}
```

**Exit code**: 2 (Warning for hardcoded non-secrets), 1 (Error for hardcoded secrets)

#### Check 4: Protocol Compliance (SKIPPED)

Full MCP protocol validation requires starting the server:

```bash
# This check is optional and may be skipped for fast validation
validate_mcp_protocol() {
  local server_config="$1"

  # Start server and verify it responds to initialize
  # This requires significant time and resources
  # Exit code 3 indicates "skipped"
  return 3
}
```

**Exit code**: 3 (Skipped - requires runtime verification)

---

## 5. Testing Requirements

### Unit Tests for Hooks

Hook scripts should include test coverage:

```bash
# test-hooks.sh - Example test suite
#!/bin/bash

set -e

PLUGIN_ROOT="${1:-.}"
HOOKS_FILE="${PLUGIN_ROOT}/hooks/hooks.json"

test_hook_exists() {
  if [[ ! -f "$HOOKS_FILE" ]]; then
    echo "FAIL: hooks.json not found"
    exit 1
  fi
  echo "PASS: hooks.json exists"
}

test_hook_syntax() {
  if ! jq empty "$HOOKS_FILE" 2>/dev/null; then
    echo "FAIL: Invalid JSON in hooks.json"
    exit 1
  fi
  echo "PASS: hooks.json has valid JSON"
}

test_hook_events() {
  local events
  events=$(jq -r '.hooks | keys[]' "$HOOKS_FILE")
  for event in $events; do
    case "$event" in
      PreToolUse|PostToolUse|SessionStart|SessionStart)
        echo "PASS: Valid event: $event"
        ;;
      *)
        echo "FAIL: Invalid event: $event"
        exit 1
        ;;
    esac
  done
}

# Run tests
test_hook_exists
test_hook_syntax
test_hook_events

echo "All hook tests passed!"
```

### Integration Tests

Test plugin loading in Claude Code:

```bash
# test-loading.sh - Verify plugin loads correctly
#!/bin/bash

set -e

PLUGIN_DIR="${1:-.}"

echo "Testing plugin loading..."

# Start Claude Code with plugin
timeout 10s claude --plugin-dir "$PLUGIN_DIR" --debug 2>&1 | \
  grep -q "loading plugin.*$(basename "$PLUGIN_DIR")" || {
  echo "FAIL: Plugin did not load"
  exit 1
}

echo "PASS: Plugin loaded successfully"
```

### Cross-Platform Testing

Test on multiple platforms:

| Platform | Test Command | Expected Behavior |
|----------|--------------|-------------------|
| macOS | `claude --plugin-dir .` | Loads without errors |
| Linux | `claude --plugin-dir .` | Loads without errors |
| Windows (WSL) | `claude.exe --plugin-dir .` | Loads without errors |

### Automated Test Commands

```bash
# Run all validation checks
claude plugin validate --strict

# Run specific checks
claude plugin validate --check manifest
claude plugin validate --check hooks
claude plugin validate --check mcp

# Skip optional checks
claude plugin validate --skip protocol
```

---

## 6. Automated Validation CLI

### Command Specification

```bash
claude plugin validate [options] [plugin-path]
```

#### Options

| Option | Description | Default |
|--------|-------------|---------|
| `--strict` | Treat warnings as errors | Warnings allowed |
| `--check <type>` | Run specific check only | All checks |
| `--skip <type>` | Skip specific check | None skipped |
| `--format <json|text>` | Output format | text |
| `--quiet` | Only show errors | Show all output |

#### Check Types

| Type | Description | Exit Code on Fail |
|------|-------------|-------------------|
| `manifest` | Validate plugin.json | 1 (Critical) |
| `paths` | Verify file paths | 1 (Critical) |
| `hooks` | Check hook configuration | 1 (Critical) |
| `mcp` | Validate MCP servers | 1 (Critical) |
| `security` | Scan for security issues | 2 (Warning) |
| `protocol` | Test MCP protocol compliance | 3 (Skipped) |

### Exit Codes

| Code | Meaning | Action |
|------|---------|--------|
| 0 | All validations pass | Plugin is ready |
| 1 | Critical error | Cannot install |
| 2 | Warning | Can install with `--force` |
| 3 | Skipped | Optional check not run |

### Example Output

```
$ claude plugin validate ./my-plugin

✓ Manifest: Valid JSON structure
✓ Manifest: Semantic version 1.2.3
✓ Manifest: Kebab-case name
✓ Paths: All files exist
✓ Paths: No parent traversal
✓ Paths: Uses ${CLAUDE_PLUGIN_ROOT}
✓ Hooks: Valid event names
✓ Hooks: Command paths resolve
⚠ Hooks: Script not executable (run: chmod +x scripts/format.sh)
✓ MCP: Commands available in PATH
✓ MCP: Args array format
⚠ MCP: Hardcoded environment value (CACHE_DIR)

Validation: PASSED with 2 warnings
Run with --force to install despite warnings, or fix issues above.
```

### JSON Output Format

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
    },
    {
      "check": "mcp",
      "message": "Hardcoded environment value",
      "location": "mcpServers.server.env.CACHE_DIR",
      "fix": "Use ${CACHE_DIR} environment variable instead"
    }
  ],
  "skipped": [
    {
      "check": "protocol",
      "reason": "Requires runtime verification"
    }
  ],
  "summary": {
    "total": 11,
    "passed": 9,
    "warnings": 2,
    "failed": 0
  }
}
```

---

## 7. Validation Checklist

Use this checklist before releasing a plugin:

### Manifest
- [ ] `name` is kebab-case, 3-42 characters
- [ ] `version` follows SemVer (X.Y.Z)
- [ ] `description` is under 200 characters
- [ ] JSON syntax is valid
- [ ] No conflicting built-in names

### Paths
- [ ] All paths use `${CLAUDE_PLUGIN_ROOT}`
- [ ] No parent traversal (`../`)
- [ ] All referenced files exist
- [ ] Hook scripts are executable (`chmod +x`)

### Hooks
- [ ] Event names are valid
- [ ] Hook types are valid (`command`, `prompt`, `agent`)
- [ ] Command paths resolve correctly
- [ ] Timeout values are reasonable (1-300s)
- [ ] `hooks.json` has valid JSON

### MCP Servers
- [ ] Commands exist in PATH or plugin root
- [ ] `args` is an array, not a string
- [ ] No hardcoded secrets in `env`
- [ ] Environment variables use `${VAR}` syntax

### Security
- [ ] No hardcoded API keys or secrets
- [ ] File system access scoped to plugin directories
- [ ] Network access declared and HTTPS-only
- [ ] Dangerous shell patterns blocked

### Testing
- [ ] Unit tests pass for hook scripts
- [ ] Plugin loads in Claude Code
- [ ] Tested on target platforms
- [ ] Documentation matches actual behavior

---

## 8. Common Validation Errors

### Error: "Invalid JSON syntax"

**Cause**: Malformed JSON in `plugin.json` or `hooks.json`

**Fix**: Use `jq .` to validate syntax:
```bash
jq . < .claude-plugin/plugin.json
jq . < hooks/hooks.json
```

### Error: "Command not found"

**Cause**: Hook command or MCP command doesn't exist

**Fix**: Verify the file exists and path is correct:
```bash
ls -la "${CLAUDE_PLUGIN_ROOT}/scripts/script.sh"
which node
```

### Error: "Path outside plugin root"

**Cause**: Using `../` to traverse outside plugin directory

**Fix**: Keep all files within plugin directory or use symlinks

### Error: "Missing required field"

**Cause**: `name` or `version` missing from `plugin.json`

**Fix**: Add required fields:
```json
{
  "name": "my-plugin",
  "version": "1.0.0"
}
```

---

## References

- **Schema Compatibility**: `SCHEMA-COMPATIBILITY-CHECKLIST.md` - Schema evolution patterns
- **Plugin Security**: `plugin-security.md` - Security best practices
- **Plugin Reference**: https://code.claude.com/docs/en/plugins-reference
- **JSON Schema**: http://json-schema.org/

---

**Version**: 1.0 | **Last Updated**: 2026-02-16 | **Maintainer**: Plugin Validation Team
