---
name: aegir-cross-repo
description: Cross-repository workflow for changes spanning hostmaster, hosting module, provision backend, and eldir theme.
---

# Aegir Cross-Repo

Use this skill when a task touches multiple repositories/submodules.

## Workflow

1. Map requested change to affected components.
2. Implement and commit in each component repository.
3. Commit submodule pointer updates in root repository.

## Important

- Preserve architecture boundary: forms must not call provision directly.

## Reference

Read full workflow: `references/source-command.md`
