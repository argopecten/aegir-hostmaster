# Frontend Component — Aegir Hosting Modules

The Frontend component provides the Drupal 11 interface for Aegir. It consists of a suite of modules that handle entity management, forms, task queuing, context synchronization, and backend communication.

## Table of Contents

- [Overview](#overview)
- [Module Structure](#module-structure)
- [Entity Architecture](#entity-architecture)
- [Task Queue System](#task-queue-system)
- [Services](#services)
- [Forms](#forms)
- [Context Registry](#context-registry)
- [Plugin System](#plugin-system)
- [Drush Commands](#drush-commands)
- [Development Guidelines](#development-guidelines)

## Overview

**Location**: `web/modules/contrib/aegir-hosting/`
**Namespace**: `Drupal\hosting` (core), `Drupal\hosting_{module}` (submodules)

### At a Glance

| Metric | Count |
|---|---|
| Submodules | 8 (+ parent `hosting`) |
| Entity types | 12 |
| Form classes | 25 |
| Registered services | ~33 |
| `.services.yml` files | 11 |
| Plugin managers | 2 |
| Drush command classes | 3 |

## Module Structure

### Core Module: `hosting`

Base module providing shared services, the HostingContext entity, and administrative forms.

**Key classes**:
- `src/Entity/HostingContext.php` — Entity ↔ context name mapping
- `src/Entity/HostingContextInterface.php` — Shared interface
- `src/Service/ContextRegistry.php` — Bidirectional entity ↔ context sync
- `src/Service/BackendInvoker.php` — Drush command execution
- `src/Service/QueueDispatcher.php` — Task queue orchestration
- `src/Form/HostingSettingsForm.php` — Admin settings
- `src/Form/HostingFeaturesForm.php` — Feature/module management
- `src/Form/HostingQueuesForm.php` — Queue configuration

### Submodules

Submodules are **peer directories** (not nested under `modules/`):

| Module | Directory | Purpose |
|---|---|---|
| `hosting_site` | `hosting_site/` | Site entity, forms, domain validation, lifecycle tasks |
| `hosting_platform` | `hosting_platform/` | Platform entity, path management, verification |
| `hosting_server` | `hosting_server/` | Server entity, service instances, plugin system |
| `hosting_task` | `hosting_task/` | Task entity, queue worker, task logging |
| `hosting_client` | `hosting_client/` | Client entity, multi-tenancy, access control |
| `hosting_package` | `hosting_package/` | Package tracking, version discovery |
| `hosting_db_server` | `hosting_db_server/` | Database server resolution, credentials |
| `hosting_web_server` | `hosting_web_server/` | Web server configuration |

Each submodule has its own `.info.yml`, `.services.yml`, and standard Drupal module structure.

## Entity Architecture

### Entity Types

| Entity Type ID | Class | Module | Purpose |
|---|---|---|---|
| `hosting_site` | `HostingSite` | hosting_site | Drupal site installation |
| `hosting_site_backup` | `HostingSiteBackup` | hosting_site | Backup record |
| `hosting_platform` | `HostingPlatform` | hosting_platform | Drupal codebase/distribution |
| `hosting_server` | `HostingServer` | hosting_server | Service provider |
| `hosting_service_instance` | `HostingServiceInstance` | hosting_server | Service config on a server |
| `hosting_task` | `HostingTask` | hosting_task | Queued operation |
| `hosting_task_log` | `HostingTaskLog` | hosting_task | Task execution log entry |
| `hosting_client` | `HostingClient` | hosting_client | Client/organization |
| `hosting_client_user` | `HostingClientUser` | hosting_client | Client ↔ user mapping |
| `hosting_package` | `HostingPackage` | hosting_package | Tracked Drupal package |
| `hosting_package_instance` | `HostingPackageInstance` | hosting_package | Package on a platform |
| `hosting_context` | `HostingContext` | hosting | Entity ↔ context name mapping |

### Handler Classes

Most entities have dedicated handler classes:

- **ListBuilder** — Entity listing pages (e.g., `HostingSiteListBuilder`)
- **ViewBuilder** — Entity view rendering (e.g., `HostingSiteViewBuilder`)
- **Access** — Access control (e.g., `HostingPlatformAccess`)

### HostingContextInterface

All hosting entities implement a common interface:

```php
interface HostingContextInterface extends ContentEntityInterface {
    public function getContextName(): string;
    public function getContextType(): string;
    public function toContext(): array;
}
```

### Core Entities in Detail

#### HostingSite

- **Domain** — primary domain name
- **Platform** — entity reference to hosting_platform
- **Database server** — entity reference to hosting_server
- **Status** — enabled / disabled / deleted
- **Install profile**, **language**, **client** (owner)

#### HostingPlatform

- **Root path** — file system path to Drupal codebase
- **Web server** — entity reference to hosting_server
- **Status** — enabled / disabled / locked / deleted

#### HostingServer

- **Hostname** — server hostname
- **Service instances** — references to hosting_service_instance entities
- **Service types**: web (Apache/Nginx), db (MySQL), ssl, cron

#### HostingTask

- **Type** — install, verify, delete, clone, migrate, backup, restore, etc.
- **Target entity** — the hosting entity this task operates on
- **Status** — queued, processing, completed, error
- **Log entries** — via HostingTaskLog child entities

## Task Queue System

### Task Lifecycle

```
1. Entity operation triggers task creation (hook or form)
        ↓
2. QueueDispatcher inserts task into Drupal queue
        ↓
3. Cron runs → HostingTaskQueueWorker processes task
        ↓
4. BackendInvoker shells out: drush provision:{operation} {context_name}
        ↓
5. TaskManager updates task status from exit code + output
```

### Queue Worker

**Plugin ID**: `hosting_task`

```php
#[QueueWorker(
    id: 'hosting_task',
    title: new TranslatableMarkup('Hosting task queue'),
    cron: ['time' => 60]
)]
class HostingTaskQueueWorker extends QueueWorkerBase {
    public function processItem($data): void {
        $this->taskManager->runTaskId((int) $data['task_id']);
    }
}
```

The `cron: ['time' => 60]` annotation tells Drupal to process this queue for up to 60 seconds per cron run.

### Triggering Queue Processing

**Automatic** (system cron):
```bash
*/5 * * * * cd /var/aegir/aegir-2601 && ./vendor/bin/drush cron
```

**Manual** (immediate):
```bash
drush hosting:task-run
```

### Task Types

| Type | Description | Backend Command |
|---|---|---|
| install | Install new site | `provision:install` |
| verify | Verify configuration | `provision:verify` |
| delete | Delete site/platform | `provision:delete` |
| clone | Clone site | `provision:clone` |
| migrate | Migrate to new platform | `provision:migrate` |
| backup | Backup site | `provision:backup` |
| restore | Restore from backup | `provision:restore` |
| deploy | Deploy backup | `provision:deploy` |
| enable | Enable site | `provision:enable` |
| disable | Disable site | `provision:disable` |
| lock | Lock context | `provision:lock` |
| unlock | Unlock context | `provision:unlock` |
| login-reset | Reset admin login | `provision:login-reset` |

### Comparison with Drupal 7 Aegir

| Feature | D7 Aegir | D11 Aegir |
|---|---|---|
| Cron trigger | `drush @hostmaster hosting-dispatch` | `drush cron` |
| Queue system | Custom dispatcher | Drupal Queue API |
| Multiple queues | Yes (tasks, backups, stats) | Single queue (tasks) |
| Queue admin UI | `/admin/hosting/queues` | Configuration form |
| Task streaming | No | Yes (real-time output) |
| Task retry | Basic | Exponential backoff |

## Services

### Core Services (hosting.services.yml)

| Service ID | Class | Purpose |
|---|---|---|
| `hosting.context_registry` | `ContextRegistry` | Entity ↔ context synchronization |
| `hosting.backend_invoker` | `BackendInvoker` | Shell execution of Drush provision commands |
| `hosting.queue_dispatcher` | `QueueDispatcher` | Task queue orchestration |
| `hosting.queue_runner` | `QueueRunner` | Queue processing |
| `hosting.feature_manager` | `FeatureManager` | Feature/module management |
| `hosting.sidebar_builder` | `SidebarBuilder` | Sidebar content assembly |
| `hosting.icon_provider` | `HostingIconProvider` | SVG icon sprite URL resolution (theme-agnostic) |

### Per-Module Services

| Module | Key Services |
|---|---|
| hosting_site | `hosting_site.manager`, `hosting_site.domain_validator`, `hosting_site.backup_manager` |
| hosting_platform | `hosting_platform.manager` |
| hosting_server | `hosting.service_manager`, `hosting.server_manager`, `hosting.ip_manager` |
| hosting_task | `hosting.task_manager`, `hosting.task_log_manager`, `hosting.task_availability_resolver`, `hosting.task_log_builder` |
| hosting_client | `hosting_client.manager`, `hosting_client.access_manager` |
| hosting_package | `hosting_package.version_parser`, `hosting_package.discovery`, `hosting_package.sync`, `hosting_package.comparison` |
| hosting_db_server | `hosting_db_server.resolver`, `hosting_db_server.credentials` |

## Forms

### Form Classes by Module

| Module | Forms |
|---|---|
| **hosting** | `HostingSettingsForm`, `HostingFeaturesForm`, `HostingQueuesForm` |
| **hosting_site** | `HostingSiteForm`, `SiteBackupForm`, `SiteCloneForm`, `SiteDeleteTaskForm`, `SiteDisableForm`, `SiteEnableForm`, `SiteMigrateForm`, `SiteResetPasswordForm`, `SiteRestoreForm`, `SiteVerifyForm` |
| **hosting_platform** | `HostingPlatformForm`, `PlatformDeleteTaskForm`, `PlatformLockForm`, `PlatformMigrateForm`, `PlatformUnlockForm`, `PlatformVerifyForm` |
| **hosting_server** | `HostingServerForm`, `HostingServiceInstanceForm`, `ServerVerifyForm` |
| **hosting_client** | `HostingClientForm`, `HostingClientSettingsForm` |
| **hosting_task** | `HostingTaskConfirmFormBase` |

Task operation forms (verify, backup, clone, etc.) are confirm forms that create a HostingTask entity on submission.

## Context Registry

`ContextRegistry` (`src/Service/ContextRegistry.php`) is the bridge between Drupal entities and provision contexts.

### Bidirectional Sync

- **Entity save** → `saveContextToBackend()`:
  1. Converts entity fields to context array via `toContext()`
  2. Writes YAML alias to `drush/sites/aegir/{name}.site.yml`
  3. Calls `drush provision:save {name}` via BackendInvoker

- **Entity delete** → `deleteContextFromBackend()`:
  1. Removes YAML alias file
  2. Optionally calls `drush provision:delete {name}`

### HostingContext Entity

The `hosting_context` entity stores the mapping between a Drupal entity (type + ID) and its context name. This enables lookups in both directions:

- Given a Drupal entity → find its context name
- Given a context name → find the corresponding entity

## Plugin System

The hosting_server module provides two Drupal plugin managers:

### HostingServiceTypeManager

Manages service type definitions (http, db, ssl, cron). Plugins live in `Plugin/HostingServiceType/`.

### HostingServiceProviderManager

Manages service provider implementations (Apache, MySQL, etc.). Plugins live in `Plugin/HostingServiceProvider/`.

Both extend `DefaultPluginManager` and use standard Drupal plugin discovery with annotations/attributes.

## Drush Commands

| Command Class | Service ID | Module | Key Commands |
|---|---|---|---|
| `HostingCommands` | `hosting.commands` | hosting | `hosting:task-run`, queue management |
| `HostingTaskCommands` | `hosting_task.commands` | hosting_task | Task execution, status |
| `HostingServerCommands` | `hosting_server.commands` | hosting_server | Server management |

Registered via `drush.services.yml` in each module.

## Development Guidelines

### Key Rules

- Entities use Drupal's content entity system (not config entities)
- All backend operations go through the task queue — never call provision commands directly from form submit handlers
- ContextRegistry handles entity ↔ context sync automatically
- Forms for task operations extend confirm form patterns
- Service IDs follow `hosting.{name}` or `hosting_{module}.{name}` convention

### Adding a New Entity

1. Define entity class in `src/Entity/` implementing `HostingContextInterface`
2. Create list builder and view builder
3. Add form class in `src/Form/`
4. Define routes, links, and permissions
5. Add entity ↔ context mapping in `ContextRegistry`
6. Create task forms for entity operations

### Adding a New Task Type

1. Define form extending confirm form base
2. Route the form
3. Implement task creation in form submit handler
4. Ensure BackendInvoker maps to the correct `provision:{operation}` command

---

**Related**: [HOME.md](HOME.md) · [Backend.md](Backend.md) · [Theme.md](Theme.md) · [hosting-d11.md](../web/modules/contrib/aegir-hosting/doc/hosting-d11.md)
