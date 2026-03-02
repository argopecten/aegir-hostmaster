# Aegir Skills Playbook (Codex)

Source: `.github/SKILLS.md`

## install

When: fresh server setup.

- Run: `sudo bash scripts/install.sh`
- Supports: `--dry-run`, `--skip-db`, `--db-pass`, `--force`, `--webserver`, `--config`
- Module enable order:
  `hosting hosting_task hosting_server hosting_web_server hosting_db_server hosting_platform hosting_client hosting_package hosting_site`

## update

When: upgrading code/dependencies.

- Preferred manual sequence:
  `drush sql:dump` -> maintenance on -> `composer update` -> `drush updatedb` -> `drush cr` -> `drush config:export` -> `drush cron` -> maintenance off -> security/status checks.
- If non-default site directory is used, do not rely on `scripts/update.sh` without verifying paths.

## cross-repo

When: a feature touches hosting/provision/theme together.

- Commit inside each component repo first.
- Then commit updated submodule pointers in root repo.
- Active branch convention: `dev/d11-new` (Composer ref appears as `dev-dev/d11-new`).

## yaml-context

When: authoring or debugging alias files.

- Path: `drush/sites/aegir/{context}.site.yml`
- Types: `server`, `platform`, `site`
- Validate via: `drush site:alias @name`

## debug

When: investigating task/queue/context/backend failures.

- Context checks: `drush site:alias`, inspect YAML, SQL mapping.
- Queue checks: `drush queue:list`, targeted task run, inspect task logs.
- Backend checks: run `provision:*` directly; validate Apache and generated vhosts.

## recipes

When: implementing Drupal recipes.

- Current state: placeholder only.
- Target flow: prefer recipe-driven install over manual module enable once recipes exist.

## wiki-sync

When: publishing docs.

- `doc/*.md` syncs to GitHub Wiki via `.github/workflows/sync-wiki.yml`.
- Edit `doc/` in repo, not wiki directly.

## coding-standards

Always enforce:

- `declare(strict_types=1);` in standard PHP files.
- `final` by default; typed params/returns.
- Drupal 11 `#[Hook]` classes, not procedural hooks.
- No `\Drupal::service()` in classes; use DI.
- Provision commands: Drush 13 patterns (`provision:*`, bootstrap none, no `$this->io()`).
- Theme: BEM, CSS variables, `once()` in behaviors, WCAG AA.

