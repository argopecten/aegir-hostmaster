---
name: aegir-create-drush-command
description: Create new Drush 13 provision:* commands in aegir-provision with proper bootstrap, event lifecycle, and manager delegation.
---

# Aegir Create Drush Command

Use this skill to add or extend `provision:*` commands.

## Workflow

1. Define command contract and target contexts.
2. Create command class in `src/Drush/Commands`.
3. Add event constants/classes if needed.
4. Implement manager operation with event lifecycle.
5. Verify Drush discovery and runtime behavior.

## Important

- No `drush.services.yml`.
- No `$this->io()` in Drush 13.

## Reference

Read full template: `references/source-command.md`
