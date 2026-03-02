---
name: aegir-install
description: Fresh Aegir Hostmaster installation workflow. Use for new server setup, prerequisite checks, running scripts/install.sh, and verifying the 10 installation phases.
---

# Aegir Install

Use this skill when the user asks to install Aegir Hostmaster from scratch.

## Workflow

1. Validate prerequisites (PHP/Composer/MySQL/Apache).
2. Run `sudo bash scripts/install.sh` with relevant flags.
3. Confirm each install phase succeeds.
4. Validate enabled modules and dispatch cron setup.

## Important

- Module enable order is strict.
- Current installs may use `web/sites/aegir.local/` instead of `web/sites/default/`.

## Reference

Read full runbook: `references/source-command.md`
