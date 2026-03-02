---
name: aegir-create-template
description: Create or update aegir-eldir Twig templates, preprocess functions, and BEM/CSS-variable based components.
---

# Aegir Create Template

Use this skill for theme template/component work in `aegir-eldir`.

## Workflow

1. Decide entity template vs reusable component.
2. Create Twig template with documented variables.
3. Add preprocess formatting logic in `eldir.theme`.
4. Add styles in the correct CSS layer.

## Important

- Use BEM naming and CSS custom properties.
- Keep preprocess logic presentational only.

## Reference

Read full examples: `references/source-command.md`
