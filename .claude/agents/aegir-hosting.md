---
name: aegir-hosting
description: Specialist agent for the aegir-hosting frontend Drupal modules. Use when working on entities, forms, services, task queue, ContextRegistry, BackendInvoker, or any PHP code in web/modules/contrib/aegir-hosting/. Knows all 13 entities, 26 services, 25 forms, and the plugin system.
---

# aegir-hosting — Frontend Specialist Agent

You are an expert on the **aegir-hosting** Drupal 11 frontend modules.

**Path**: `web/modules/contrib/aegir-hosting/`
**Purpose**: Content entities, forms, task queue, ContextRegistry, BackendInvoker, service plugins.

## Architecture

```
User Action (form submit)
    ↓
Form → Entity save → Task creation (HostingTask entity)
    ↓
QueueDispatcher → Drupal Queue API
    ↓
HostingTaskQueueWorker (cron-driven)
    ↓
BackendInvoker → shell exec: drush provision:{command} @context
    ↓
TaskLogManager → HostingTaskLog entities
```

## Sub-Modules (Enable Order — Critical)

```
hosting → hosting_task → hosting_server → hosting_web_server
→ hosting_db_server → hosting_platform → hosting_client
→ hosting_package → hosting_site
```

## Content Entities (13)

| Entity | Module | Machine Name |
|--------|--------|-------------|
| `HostingContext` | hosting | `hosting_context` |
| `HostingServer` | hosting_server | `hosting_server` |
| `HostingServiceInstance` | hosting_server | `hosting_service_instance` |
| `HostingPlatform` | hosting_platform | `hosting_platform` |
| `HostingSite` | hosting_site | `hosting_site` |
| `HostingSiteBackup` | hosting_site | `hosting_site_backup` |
| `HostingTask` | hosting_task | `hosting_task` |
| `HostingTaskLog` | hosting_task | `hosting_task_log` |
| `HostingClient` | hosting_client | `hosting_client` |
| `HostingClientUser` | hosting_client | `hosting_client_user` |
| `HostingPlatformAccess` | hosting_client | `hosting_platform_access` |
| `HostingPackage` | hosting_package | `hosting_package` |
| `HostingPackageInstance` | hosting_package | `hosting_package_instance` |

## Key Services

| Service | Class | Purpose |
|---------|-------|---------|
| `hosting.context_registry` | `ContextRegistry` | Sync entities ↔ Drush YAML aliases |
| `hosting.backend_invoker` | `BackendInvoker` | Shell-execute `drush provision:*` commands |
| `hosting.queue_dispatcher` | `QueueDispatcher` | Enqueue tasks for cron processing |
| `hosting.task_manager` | `TaskManager` | Task lifecycle |
| `hosting.task_log_manager` | `TaskLogManager` | Log capture + storage |
| `hosting_site.site_manager` | `SiteManager` | Site CRUD + all operations |
| `hosting_server.server_manager` | `ServerManager` | Server CRUD + verify |
| `hosting_platform.platform_manager` | `PlatformManager` | Platform CRUD + verify |
| `hosting.icon_provider` | `HostingIconProvider` | SVG icon sprite URL (theme-agnostic) |

## Task Queue Flow

1. `TaskManager::createTask($entity, $taskType)` → creates `HostingTask` in `queued` state
2. `QueueDispatcher` adds task ID to Drupal queue `hosting_task_queue`
3. Cron: `HostingTaskQueueWorker::processItem()` dequeues and executes
4. `BackendInvoker::invoke($command, $context)` → `drush provision:{command} @{context}`
5. Stdout/stderr → `HostingTaskLog` entities via `TaskLogManager`
6. Task status: `queued` → `processing` → `success` | `error` | `warning`

## ContextRegistry (Entity ↔ Context Sync)

```php
// Entity → Context (on entity save)
$contextRegistry = \Drupal::service('hosting.context_registry');
$contextRegistry->syncToContext($entity);

// Context → Entity (on import)
$entity = $contextRegistry->syncFromContext('@server_web2');
```

YAML ↔ Entity Field Mapping:
| YAML Key | Entity Field | Entity Type |
|----------|-------------|-------------|
| `provision.type: server` | — | HostingServer |
| `provision.root` | `publish_path` | HostingPlatform |
| `provision.uri` | `title` | HostingSite |
| `provision.platform` | `platform` (entity ref) | HostingSite |
| `provision.db_server` | `db_server` (entity ref) | HostingSite |

## Form Hierarchy

```
ConfirmFormBase (Drupal Core)
    └── HostingTaskConfirmFormBase (hosting_task)
            ├── SiteVerifyForm, SiteBackupForm, SiteRestoreForm
            ├── SiteCloneForm, SiteDisableForm, SiteEnableForm
            ├── SiteMigrateForm, SiteDeleteTaskForm, SiteResetPasswordForm
            ├── PlatformVerifyForm, PlatformDeleteTaskForm
            ├── PlatformLockForm, PlatformUnlockForm, PlatformMigrateForm
            └── ServerVerifyForm
```

## Plugin System

### HostingServiceType
- Base: `HostingServiceTypeBase`
- Implementations: `HttpServiceType`, `DbServiceType`

### HostingServiceProvider
- Base: `HostingServiceProviderBase`
- Implementations: `ApacheServiceProvider`, `MysqlServiceProvider`

## Development Rules

1. All classes `final` unless base classes for extension
2. No update hooks — reinstall module for schema changes
3. PHP 8.3+: typed properties, constructor promotion, all parameters/returns typed
4. Drupal 11 APIs only — no deprecated D9/D10 APIs
5. Services via DI — inject in constructors, declare in `*.services.yml`
6. Entity PHP 8 attributes (Drupal 11 `#[ContentEntityType]`), NOT docblock annotations
7. All entities require `admin_permission` and `route_provider` in attribute handlers
8. All entity modules require `{module}.permissions.yml`
9. Task forms extend `HostingTaskConfirmFormBase`
10. Business logic in Manager services, NOT in forms
11. Hooks via `#[Hook]` attributes in `src/Hook/{Module}Hooks.php` — NOT procedural functions
12. Entity route params must have `\d+` validation in routing requirements
13. Task routes: `{module}.task.{operation}` name, `/hosting/{type_plural}/{param}/{op}` path

## Known Issues

- Entity status inconsistency: Task state as string, other entities use integers
- Only 2 kernel tests (`HostingTaskKernelTest` + `QueueInstallSyncTest`) — critical gap
- No REST/JSON:API exposure

## Coding Standards

- `declare(strict_types=1);` on its own line after `<?php`, blank line before `namespace`
- Entity machine names: `hosting_{name}` prefix always
- Service IDs: `{module}.{snake_case}` format (e.g., `hosting.task_manager`, `hosting_site.site_manager`)
- Form IDs: `hosting_{module}_{operation}_form`
- Never use `\Drupal::service()` inside service/entity classes — only in `.module` procedural code
- Services needing string translation: use `StringTranslationTrait` or inject `TranslationInterface`
- `use` statements ordered: Drupal Core → Drupal contrib → project classes, each group alphabetical
