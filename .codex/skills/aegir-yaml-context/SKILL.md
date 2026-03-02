---
name: aegir-yaml-context
description: Manage and validate Aegir YAML context aliases under drush/sites/aegir for server, platform, and site contexts.
---

# Aegir YAML Context

Use this skill for context alias authoring, inspection, and repair.

## Workflow

1. Determine context type: server/platform/site.
2. Create or update alias YAML with correct keys.
3. Validate naming conventions.
4. Verify with `drush site:alias`.

## Important

- Use canonical names without `@` for storage; `@` is used in references.

## Reference

Read full examples: `references/source-command.md`
