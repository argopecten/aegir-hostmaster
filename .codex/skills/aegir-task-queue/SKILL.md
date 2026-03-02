---
name: aegir-task-queue
description: Implement queue-backed operations from Drupal forms through TaskManager to provision backend commands.
---

# Aegir Task Queue

Use this skill to add background operations.

## Workflow

1. Define task type and corresponding `provision:*` command.
2. Add frontend task confirm form.
3. Add route using `{module}.task.{operation}` conventions.
4. Add availability rules when needed.
5. Verify queue execution and task logs.

## Important

- Never invoke provision commands directly from forms.

## Reference

Read full integration guide: `references/source-command.md`
