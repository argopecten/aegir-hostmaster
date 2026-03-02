---
name: aegir-coding-standards
description: Project-wide coding standards for aegir-hosting, aegir-provision, and aegir-eldir. Use before implementing or reviewing code.
---

# Aegir Coding Standards

Use this skill before coding, refactoring, and code review.

## Workflow

1. Identify component (hosting/provision/eldir).
2. Apply shared PHP rules (strict types, final-by-default, full typing).
3. Apply component-specific rules.
4. Run pre-commit standards checklist.

## Important

- Drupal 11 `#[Hook]` classes over procedural hooks.
- Drush 13 conventions in provision package.

## Reference

Read full standards: `references/source-command.md`
