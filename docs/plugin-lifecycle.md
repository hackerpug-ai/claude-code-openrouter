# Claude Code Plugin Lifecycle & Distribution Guide

**Purpose**: Version management, deprecation, and distribution standards for Claude Code plugins.

**Audience**: Plugin developers, marketplace maintainers, enterprise distributors

**Version**: 1.0 | **Last Updated**: 2026-02-16

---

## Overview

This guide establishes standards for plugin lifecycle management, including semantic versioning, deprecation processes, dependency management, error handling, and marketplace distribution. Following these standards ensures plugins can be reliably distributed, updated, and maintained across enterprise environments.

**Lifecycle Goals**:
- **Predictable versioning** - Users understand update impact
- **Graceful deprecation** - Breaking changes are communicated in advance
- **Clear dependencies** - External requirements are documented
- **Stable error handling** - Failures are actionable and recoverable
- **Reliable distribution** - Updates can be deployed safely

---

## 1. Version Management

### Semantic Versioning (SemVer)

Plugins MUST follow Semantic Versioning 2.0.0: `MAJOR.MINOR.PATCH`

```
MAJOR.MINOR.PATCH[-PRERELEASE][+BUILD]

Example: 2.1.3-beta.2+20240216
```

#### Version Number Rules

| Version Component | When to Increment | Impact |
|-------------------|-------------------|--------|
| **MAJOR** | Incompatible API changes, removed features | May break existing workflows |
| **MINOR** | New features, backward-compatible additions | Safe to upgrade |
| **PATCH** | Bug fixes, backward-compatible fixes | Always safe to upgrade |

#### Version Examples

```json
// ✅ CORRECT - Semantic versions
"1.0.0"          // First stable release
"1.2.3"          // Patch release
"2.0.0"          // Major version with breaking changes
"2.1.0-beta.1"   // Pre-release for testing
"3.0.0-rc.2"     // Release candidate

// ❌ INCORRECT - Non-semantic versions
"1.0"            // Missing PATCH
"v1.0.0"         // No 'v' prefix
"latest"         // Not a version number
"1.0.0.0"        // Too many components
```

### Version Declaration

Declare version in `plugin.json`:

```json
{
  "name": "example-plugin",
  "version": "2.1.0",
  "description": "Example plugin with proper versioning"
}
```

**NOTE**: If version is set in both `plugin.json` and marketplace entry, `plugin.json` takes priority.

### Pre-Release Versions

Use pre-release versions for testing:

```json
// Alpha releases - Early development, may be unstable
"version": "2.0.0-alpha.1"
"version": "2.0.0-alpha.2"

// Beta releases - Feature complete, testing needed
"version": "2.0.0-beta.1"
"version": "2.0.0-beta.2"

// Release candidates - Ready for production unless bugs found
"version": "2.0.0-rc.1"
"version": "2.0.0-rc.2"

// Stable release
"version": "2.0.0"
```

### Build Metadata

Build metadata is ignored for version ordering but can be useful:

```json
"version": "1.2.3+20240216"
"version": "1.2.3+commit.abc123"
"version": "2.0.0-beta.1+build.456"
```

---

## 2. Breaking Change Documentation

### Breaking Change Policy

**Breaking changes require**:
1. MAJOR version increment
2. Documentation in CHANGELOG
3. Migration guide for users
4. Minimum 3-month notice before removal

### Breaking Change Examples

| Change Type | Is Breaking? | Example |
|-------------|--------------|---------|
| Removed command | ✅ YES | Removed `/or-models --legacy` flag |
| Changed command syntax | ✅ YES | `/or-set MODEL` now requires `--model` flag |
| New required field | ✅ YES | `permissions` now required in manifest |
| Removed skill | ✅ YES | `openrouter:legacy-models` skill removed |
| New optional field | ❌ NO | Added `icon` field to manifest |
| New command | ❌ NO | Added `/or-compare` command |
| Bug fix | ❌ NO | Fixed cache invalidation bug |

### CHANGELOG Format

```markdown
# Changelog

## [2.0.0] - 2024-02-16

### ⚠️ Breaking Changes

- **Removed**: `/or-set` no longer accepts positional model argument
  - **Migration**: Use `/or-set --model <model-id>` instead
  - **Reason**: Consistent flag-based interface for future enhancements
- **Changed**: Model cache format updated (incompatible with v1.x)
  - **Migration**: Clear cache with `/or-models --clear-cache` after upgrade
  - **Reason**: Support for model pricing and capability metadata

### Added

- New `/or-compare` command to compare models side-by-side
- Model pricing information in `/or-models` output

### Fixed

- Cache now respects TTL correctly
- API key validation shows helpful error message

## [1.2.0] - 2024-01-15

### Added

- Search by provider with `/or-models --provider`
- Cost tracking features

### Fixed

- Fixed crash when API returns empty model list

## [1.1.0] - 2024-01-01

### Added

- Initial release
- `/or-models`, `/or-set`, `/or-status` commands
```

### Migration Guide Template

```markdown
# Migration Guide: v1.x → v2.0

## Overview

Version 2.0 includes breaking changes to improve consistency and enable new features. Most users can migrate in under 5 minutes.

## Breaking Changes

### 1. Command Syntax Changes

**Old behavior**:
```bash
/or-set anthropic/claude-sonnet-4
```

**New behavior**:
```bash
/or-set --model anthropic/claude-sonnet-4
```

**Action required**: Update any scripts that use `/or-set` with positional arguments.

### 2. Cache Incompatibility

Version 2.0 uses a new cache format. Old caches will be ignored.

**Action required**: After upgrading, run:
```bash
/or-models --clear-cache
/or-models --refresh
```

## Rollback Instructions

If you need to rollback to v1.x:

```bash
claude plugin install openrouter-plugin@v1
```

## Questions?

See the [full documentation](https://github.com/example/docs) or [open an issue](https://github.com/example/issues).
```

---

## 3. Deprecation Process

### Deprecation Timeline

```
┌─────────────────────────────────────────────────────────┐
│  Phase 1: Announce Deprecation                         │
│  • Document deprecated feature                          │
│  • Add warnings when feature is used                   │
│  • Provide migration path                              │
└────────────┬────────────────────────────────────────────┘
             │
             ▼ 3+ months minimum
┌─────────────────────────────────────────────────────────┐
│  Phase 2: Default-Off                                  │
│  • Feature disabled by default                          │
│  • Opt-in flag to enable                               │
│  • Continued warnings                                  │
└────────────┬────────────────────────────────────────────┘
             │
             ▼ 1-2 months
┌─────────────────────────────────────────────────────────┐
│  Phase 3: Removal                                      │
│  • Feature removed in next MAJOR release               │
│  • Migration guide in CHANGELOG                        │
└─────────────────────────────────────────────────────────┘
```

### Deprecation Warning Pattern

Add warnings to deprecated features:

```bash
# commands/legacy-models.sh
#!/bin/bash

# ⚠️ DEPRECATED: This command is deprecated and will be removed in v2.0
# Use /or-models --search instead
# Migration guide: https://docs.example.com/migrate-v2

echo "WARNING: /or-legacy is deprecated. Use /or-models --search." >&2
echo "This command will be removed in version 2.0 (est. June 2024)." >&2
echo ""

# Continue with deprecated behavior...
```

### Deprecation in Marketplace

Mark deprecated versions in marketplace:

```json
{
  "plugins": [
    {
      "id": "example-plugin",
      "version": "1.5.0",
      "deprecated": {
        "message": "Version 1.x is deprecated. Please upgrade to 2.0.",
        "migrationUrl": "https://docs.example.com/migrate-v2",
        "sunsetDate": "2024-06-01"
      }
    }
  ]
}
```

---

## 4. Dependency Declaration

### Dependency Schema

Declare external dependencies in `plugin.json`:

```json
{
  "name": "example-plugin",
  "version": "1.0.0",
  "dependencies": {
    "claude": ">= 1.0.33",
    "commands": {
      "git": ">= 2.0.0",
      "node": ">= 18.0.0 < 21.0.0"
    },
    "mcpServers": {
      "@example/database": "^2.1.0"
    },
    "environment": {
      "OPENROUTER_API_KEY": {
        "description": "OpenRouter API key for model access",
        "required": true,
        "documentationUrl": "https://openrouter.ai/keys"
      }
    }
  }
}
```

### Version Constraints

Use semantic version ranges:

| Constraint | Meaning | Example |
|------------|---------|---------|
| `^1.2.3` | Compatible with >= 1.2.3, < 2.0.0 | `^2.1.0` |
| `~1.2.3` | Compatible with >= 1.2.3, < 1.3.0 | `~2.1.0` |
| `>= 1.2.3` | Greater than or equal to | `>= 1.0.33` |
| `< 2.0.0` | Less than | `< 21.0.0` |
| `*` | Any version | (not recommended) |

### Conflict Resolution

When dependency conflicts occur:

1. **Claude Code version** - Minimum version required
2. **Command dependencies** - Check if command exists and meets version
3. **MCP servers** - Use exact versions or caret ranges
4. **Environment** - Document required variables

```bash
# Example dependency check in install script
check_dependencies() {
  # Check Claude Code version
  CLAUDE_VERSION=$(claude --version | awk '{print $3}')
  if ! semver_GE "$CLAUDE_VERSION" "1.0.33"; then
    echo "ERROR: Claude Code 1.0.33 or later required" >&2
    exit 1
  fi

  # Check required commands
  if ! command -v git >/dev/null 2>&1; then
    echo "ERROR: git not found. Please install git 2.0.0 or later." >&2
    exit 1
  fi

  # Check environment variables
  if [[ -z "${OPENROUTER_API_KEY:-}" ]]; then
    echo "WARNING: OPENROUTER_API_KEY not set" >&2
    echo "Set it with: export OPENROUTER_API_KEY='sk-...'" >&2
  fi
}
```

### Optional Dependencies

Mark optional features:

```json
{
  "dependencies": {
    "required": {
      "claude": ">= 1.0.33"
    },
    "optional": {
      "docker": {
        "description": "Required for container-based deployments",
        "version": ">= 20.0.0",
        "features": ["deployment"]
      }
    }
  }
}
```

---

## 5. Error Handling

### Hook Failure Propagation

When hooks fail, provide clear error messages:

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

### Error Message Standards

**Good error messages include**:
1. What went wrong (specific error)
2. Why it happened (context)
3. How to fix it (actionable steps)

```bash
# ❌ BAD ERROR
echo "Error occurred" >&2
exit 1

# ✅ GOOD ERROR
echo "ERROR: Failed to fetch models from OpenRouter API" >&2
echo "" >&2
echo "Possible causes:" >&2
echo "  1. OPENROUTER_API_KEY is not set" >&2
echo "  2. Network connectivity issue" >&2
echo "  3. OpenRouter API is down" >&2
echo "" >&2
echo "To fix:" >&2
echo "  1. Check API key: echo \$OPENROUTER_API_KEY" >&2
echo "  2. Test connectivity: curl https://openrouter.ai/api/v1/models" >&2
echo "  3. View logs: tail -f ~/.openrouter-plugin/logs/fetch.log" >&2
exit 1
```

### Retry Behavior

Document retry logic for transient failures:

```bash
# Retry with exponential backoff
fetch_with_retry() {
  local max_attempts=3
  local attempt=1
  local wait_time=1

  while [[ $attempt -le $max_attempts ]]; do
    if curl -sSf "$URL"; then
      return 0
    fi

    if [[ $attempt -lt $max_attempts ]]; then
      echo "WARNING: Fetch failed (attempt $attempt/$max_attempts), retrying in ${wait_time}s..." >&2
      sleep "$wait_time"
      wait_time=$((wait_time * 2))
    fi

    attempt=$((attempt + 1))
  done

  echo "ERROR: Failed after $max_attempts attempts" >&2
  return 1
}
```

### Error Categories

| Category | Exit Code | User Action |
|----------|-----------|-------------|
| **User error** | 1 | Fix input and retry |
| **Configuration** | 2 | Update settings |
| **Network** | 3 | Check connection or retry |
| **Permission** | 4 | Fix file permissions |
| **Dependency** | 5 | Install missing dependency |
| **Bug** | 10 | Report issue |

---

## 6. Marketplace Distribution

### Marketplace Schema

```json
{
  "$schema": "https://code.claude.com/schemas/marketplace.json",
  "marketplace": {
    "id": "username/marketplace",
    "name": "User's Plugins",
    "description": "Collection of Claude Code plugins",
    "homepage": "https://github.com/username/plugins",
    "plugins": [
      {
        "id": "plugin-name",
        "name": "Plugin Display Name",
        "description": "Brief description for marketplace UI",
        "version": "1.0.0",
        "author": "Author Name",
        "homepage": "https://github.com/user/plugin",
        "source": "./plugins/my-plugin",
        "license": "MIT",
        "keywords": ["tag1", "tag2"],
        "categories": ["productivity", "developer-tools"],
        "requirements": {
          "api": {
            "EXAMPLE_API_KEY": {
              "description": "API key for Example service",
              "optional": false,
              "link": "https://example.com/keys"
            }
          }
        },
        "permissions": {
          "network": {
            "domains": ["api.example.com"],
            "description": "Fetches data from Example API"
          }
        },
        "deprecated": false
      }
    ]
  }
}
```

### Update Mechanism

Plugins update through marketplace refresh:

```bash
# Check for updates
claude plugin check-updates

# Update specific plugin
claude plugin update plugin-name

# Update all plugins
claude plugin update --all
```

### Version Discovery

Marketplaces advertise available versions:

```json
{
  "plugins": [
    {
      "id": "example-plugin",
      "versions": [
        {
          "version": "2.0.0",
          "stable": true,
          "released": "2024-02-16",
          "checksum": "sha256:abc123..."
        },
        {
          "version": "2.1.0-beta.1",
          "stable": false,
          "released": "2024-02-10",
          "checksum": "sha256:def456..."
        }
      ]
    }
  ]
}
```

### Trust & Reputation

For enterprise distribution, consider:

```json
{
  "plugins": [
    {
      "id": "enterprise-plugin",
      "trust": {
        "verified": true,
        "signature": "-----BEGIN PGP SIGNATURE-----\n...",
        "publisher": "Acme Corp",
        "securityAudit": "https://example.com/audit-report.pdf"
      },
      "reputation": {
        "downloads": 10000,
        "rating": 4.8,
        "reviews": 250
      }
    }
  ]
}
```

---

## 7. Release Process

### Pre-Release Checklist

Before releasing a new version:

- [ ] Version updated in `plugin.json`
- [ ] CHANGELOG updated with all changes
- [ ] All tests pass
- [ ] Documentation updated
- [ ] Breaking changes documented with migration guide
- [ ] Security review completed (for MAJOR releases)
- [ ] Dependencies verified and updated
- [ ] Marketplace entry updated
- [ ] Release tagged in git

### Release Commands

```bash
# 1. Update version
npm version patch  # or minor, or major

# 2. Update CHANGELOG
# Edit CHANGELOG.md manually

# 3. Commit changes
git add plugin.json CHANGELOG.md
git commit -m "Release v1.2.3"

# 4. Create tag
git tag v1.2.3
git push origin main --tags

# 5. Update marketplace
# Edit marketplace.json with new version

# 6. Test installation
claude plugin install my-plugin@v1.2.3
```

### Automated Release

Consider GitHub Actions for automated releases:

```yaml
# .github/workflows/release.yml
name: Release

on:
  push:
    tags:
      - 'v*'

jobs:
  release:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - name: Validate plugin
        run: |
          claude plugin validate . || exit 1
      - name: Create GitHub Release
        uses: actions/create-release@v1
        env:
          GITHUB_TOKEN: ${{ secrets.GITHUB_TOKEN }}
        with:
          tag_name: ${{ github.ref }}
          release_name: Release ${{ github.ref }}
          body: |
            See CHANGELOG.md for details.
```

---

## 8. Migration Period

### Timeline Standards

| Change Type | Minimum Notice | Recommended Notice |
|-------------|----------------|-------------------|
| Bug fix | 0 days | N/A |
| New feature | 0 days | N/A |
| Deprecation | 3 months | 6 months |
| Breaking change | 3 months | 6 months |
| Removal | 6 months | 12 months |

### Communication Channels

Announce changes through:

1. **CHANGELOG.md** - Primary source of truth
2. **Release notes** - GitHub releases
3. **Deprecation warnings** - In-plugin warnings
4. **Documentation** - Updated guides

### Grace Period Example

```
v1.5.0 (2024-01-01) - Announce deprecation of --legacy flag
  ├─ v1.6.0 (2024-02-01) - Default flag to off, warn on use
  ├─ v1.7.0 (2024-03-01) - Continue warnings
  ├─ v1.8.0 (2024-04-01) - Final warning before removal
  └─ v2.0.0 (2024-06-01) - Remove --legacy flag
```

---

## References

- **Semantic Versioning**: https://semver.org/
- **Keep a Changelog**: https://keepachangelog.com/
- **Plugin Reference**: https://code.claude.com/docs/en/plugins-reference
- **Marketplace Guide**: https://code.claude.com/docs/en/plugin-marketplaces

---

**Version**: 1.0 | **Last Updated**: 2026-02-16 | **Maintainer**: Plugin Distribution Team
