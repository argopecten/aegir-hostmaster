# Aegir Hostmaster Context (Codex)

Source: `.github/AGENTS.md`

## Scope

This repository orchestrates a 4-repo Drupal 11 hosting stack:

- Main: `/var/aegir/drupal/aegir-2601/`
- Frontend module: `web/modules/contrib/aegir-hosting/`
- Backend drush package: `vendor/argopecten/aegir-provision/`
- Theme: `web/themes/contrib/aegir-eldir/`

## Architecture

1. Frontend (entities/forms/services) writes intent.
2. Task queue executes operations asynchronously.
3. Backend `provision:*` commands perform infrastructure changes.

Critical pipeline:

`Entity -> TaskManager -> QueueWorker -> BackendInvoker -> provision:*`

Never bypass queueing from forms.

## Core Rules

- Breaking changes are allowed (no backward-compat requirement).
- Do not add update hooks unless explicitly requested.
- Use modern PHP 8.3+ patterns and strict typing.
- Keep backend operations idempotent.
- Business logic belongs in manager services, not forms.

## Context Naming

- Site: `example.com`
- Platform: `platform_*`
- Server: `server_*`
- Store canonical names without `@`.

## Known Project Hazards

- `scripts/update.sh` assumes `web/sites/default/settings.php`; current install may use `web/sites/aegir.local/settings.php`.
- `BackendInvokerInterface` does not fully reflect streaming invocations.
- Task status representation differs between entities (string vs int).
- Provision lock flow has abstract event-instantiation risk in `LockManager.php`.

## Boundaries by Component

- `aegir-hosting`: Drupal entities/forms/task orchestration.
- `aegir-provision`: Drush commands/managers/events, no Drupal runtime APIs.
- `aegir-eldir`: Twig/CSS/JS presentation.
- root repo: install/update scripts and cross-repo wiring.

