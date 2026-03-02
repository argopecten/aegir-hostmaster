---
name: aegir-create-entity
description: Create Drupal 11 hosting entities using attributes, route provider conventions, permissions, and lifecycle hooks.
---

# Aegir Create Entity

Use this skill for new content entities in `aegir-hosting`.

## Workflow

1. Define entity type and module ownership.
2. Create entity class + fields + handlers.
3. Add list/view builders and permissions.
4. Add custom routes with numeric ID requirements.
5. Implement lifecycle hooks in Hook classes.

## Important

- Entity names use `hosting_*` conventions.
- No update hooks unless explicitly requested.

## Reference

Read full scaffold: `references/source-command.md`
