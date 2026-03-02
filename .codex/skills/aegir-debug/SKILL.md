---
name: aegir-debug
description: Troubleshooting workflow for Aegir task queue, context aliases, provision commands, and infrastructure checks.
---

# Aegir Debug

Use this skill when investigating Aegir failures.

## Workflow

1. Inspect context aliases (Drush + YAML + DB).
2. Check task queue state and task logs.
3. Validate backend provision command behavior.
4. Verify infrastructure (Apache, vhosts, DB connectivity).
5. Isolate root cause before changing code.

## Important

- Known issue: lock flow can fail if abstract event classes are instantiated.

## Reference

Read full diagnostics: `references/source-command.md`
