---
name: aegir-update
description: Update workflow for Aegir Hostmaster. Use for safe dependency updates, maintenance mode handling, database updates, and post-update verification.
---

# Aegir Update

Use this skill for update and upgrade operations.

## Workflow

1. Backup DB.
2. Enable maintenance mode.
3. Run Composer update.
4. Run Drupal DB/cache/config/cron steps.
5. Disable maintenance mode.
6. Run security and status checks.

## Important

- Verify site directory path before using `scripts/update.sh`.

## Reference

Read full runbook: `references/source-command.md`
