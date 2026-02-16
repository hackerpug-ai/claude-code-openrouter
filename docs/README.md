# Claude Code Plugin Documentation

This directory contains supplemental documentation for Claude Code plugin development, focusing on security, validation, and lifecycle management.

## Documents

### [plugin-security.md](./plugin-security.md)
Comprehensive security guide covering:
- Permission manifest schema
- Capability declarations
- ${CLAUDE_PLUGIN_ROOT} security patterns
- Secret management
- OWASP Top 10 for plugins
- Security review template

**Audience**: Plugin developers, security reviewers, enterprise distributors

### [plugin-validation.md](./plugin-validation.md)
Validation and testing standards covering:
- Manifest validation rules
- Path resolution validation
- Hook validation
- MCP server validation
- Testing requirements
- Automated validation CLI specification

**Audience**: Plugin developers, QA engineers, validation tool authors

### [plugin-lifecycle.md](./plugin-lifecycle.md)
Version management and distribution covering:
- Semantic versioning
- Breaking change documentation
- Deprecation process
- Dependency declaration
- Error handling standards
- Marketplace distribution

**Audience**: Plugin developers, marketplace maintainers, enterprise distributors

### [plugin-proposals.md](./plugin-proposals.md)
Ready-to-merge proposals for official Claude Code docs:
- Security section addition
- Validation section addition
- Error handling specification
- Dependency manifest schema
- Migration guide section
- Permissions field specification
- Deprecation policy addition

**Status**: Ready for submission to https://github.com/anthropics/claude-code-docs/issues

## Usage

### For Plugin Developers

1. **Read Security Guide** - Understand security model before coding
2. **Follow Validation Guide** - Validate your plugin before release
3. **Reference Lifecycle Guide** - Follow versioning and deprecation standards

### For Security Reviewers

Use the [Security Review Template](./plugin-security.md#8-security-review-template) when reviewing plugins.

### For Marketplace Maintainers

Use the [Validation Checklist](./plugin-validation.md#7-validation-checklist) when evaluating plugins for distribution.

## Related Resources

- **Claude Code Plugin Docs**: https://code.claude.com/docs/en/plugins
- **Plugin Reference**: https://code.claude.com/docs/en/plugins-reference
- **Security Patterns**: `SECURITY-PATTERNS.md` (if available in brain/docs/)
- **Schema Compatibility**: `SCHEMA-COMPATIBILITY-CHECKLIST.md` (if available in brain/docs/)

## Contributing

When updating documentation:
1. Keep formatting consistent with existing docs
2. Include version and last updated date
3. Cross-reference related sections
4. Add practical examples from real plugins

## Version

**Documentation Version**: 1.0
**Last Updated**: 2026-02-16
**Maintainer**: Plugin Documentation Team
