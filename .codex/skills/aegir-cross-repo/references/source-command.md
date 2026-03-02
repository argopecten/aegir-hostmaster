# Aegir Cross-Repository Development

Implement a feature or fix that spans multiple Aegir component repositories.

## Repository Structure

| Repo | Local Path | Branch |
|------|-----------|--------|
| aegir-hostmaster | `/var/aegir/drupal/aegir-2601/` | `dev/d11-new` |
| aegir-hosting | `web/modules/contrib/aegir-hosting/` | `dev/d11-new` |
| aegir-provision | `vendor/argopecten/aegir-provision/` | `dev/d11-new` |
| aegir-eldir | `web/themes/contrib/aegir-eldir/` | `dev/d11-new` |

## Git Submodule Commit Workflow

```bash
# 1. Work in the hosting component
cd web/modules/contrib/aegir-hosting
git checkout -b feature/your-feature
# ... make changes ...
git add -p && git commit -m "feat(hosting): describe change"

# 2. Work in the provision component (if needed)
cd ../../../../vendor/argopecten/aegir-provision
git checkout -b feature/your-feature
# ... make changes ...
git add -p && git commit -m "feat(provision): describe change"

# 3. Work in the theme component (if needed)
cd ../../../../web/themes/contrib/aegir-eldir
git checkout -b feature/your-feature
# ... make changes ...
git add -p && git commit -m "feat(eldir): describe change"

# 4. Return to main repo and stage submodule pointer updates
cd /var/aegir/drupal/aegir-2601
git add web/modules/contrib/aegir-hosting
git add vendor/argopecten/aegir-provision
git add web/themes/contrib/aegir-eldir
git commit -m "feat: add feature across hosting + provision + eldir"
```

## Composer Notes

- `argopecten/*` packages install from **source** (Git clone, editable)
- Everything else installs from **dist** (zip download)
- Custom repos defined in root `composer.json` pointing to GitHub

## Architecture Boundaries

Before implementing, identify which components are affected:

| If you need to... | Work in |
|-------------------|---------|
| Add/modify Drupal entities, forms, services | aegir-hosting |
| Add/modify Drush `provision:*` commands | aegir-provision |
| Add/modify templates, CSS, JS | aegir-eldir |
| Add install scripts, update scripts | aegir-hostmaster |

## Critical Rule

**Forms NEVER call Provision directly.** Always: Entity → Task (TaskManager) → Queue → Backend.

Implement the cross-repository changes described by the user. Check component boundaries, make changes in the correct repos, and commit following the workflow above.
