# Backend Component — Aegir Provision System

The Backend component is a **Drush 13 extension** that automates infrastructure operations. It creates Apache vhosts, manages MySQL databases, installs Drupal sites, handles SSL certificates, manages cron jobs, and generates configuration files.

## Table of Contents

- [Overview](#overview)
- [Source Tree](#source-tree)
- [Context System](#context-system)
- [ProvisionManager & Managers](#provisionmanager--managers)
- [Service Architecture](#service-architecture)
- [Drush Commands](#drush-commands)
- [Event System](#event-system)
- [Configuration & Templates](#configuration--templates)
- [Development Guidelines](#development-guidelines)

## Overview

**Package**: `argopecten/aegir-provision`
**Location**: `vendor/argopecten/aegir-provision/`
**Namespace**: `Aegir\Provision`
**Requirements**: PHP 8.3+, Drush 13.7+, Symfony 7.0+

**Key Principle**: The backend operates **exclusively on contexts** — it never directly accesses the Drupal database.

### At a Glance

| Metric | Count |
|---|---|
| Command classes | 17 (+ 1 trait) |
| Lifecycle event constants | 51 |
| Manager classes | 11 (+ ProvisionManager) |
| Service interfaces | 4 |
| Service implementations | 5 (+ ServiceRegistry) |
| Value objects | 4 |
| Event classes | 10 |
| Core infrastructure classes | 7 |

### Status

- ✅ All core commands implemented
- ✅ Event system complete (51 lifecycle events via Symfony EventDispatcher)
- ✅ Service plugin system with interface contracts + ServiceRegistry
- ✅ Template override system with priority-based TemplateRenderer
- ✅ Value objects: `DatabaseCredentials`, `ServerPaths`, `ApacheVhostConfig`, `CronJobConfig`
- ✅ SQL injection mitigated: MySqlService uses PDO with prepared statements
- ❌ Testing: No tests exist (0% coverage)

## Source Tree

```
src/
├── ProvisionManager.php              # Central orchestrator
├── Config/
│   └── TemplateRenderer.php          # PHP template rendering, MD5-based caching
├── Core/
│   ├── AliasStore.php                # YAML read/write for drush/sites/aegir/
│   ├── ConfigPaths.php               # Path calculation for server configs
│   ├── Context.php                   # Final class — immutable identity, mutable props
│   ├── ContextRepository.php         # Load/save/delete contexts
│   ├── ContextType.php               # Enum: SERVER, PLATFORM, SITE
│   ├── Filesystem.php                # Wraps Symfony Filesystem with logging
│   ├── PlatformRoot.php              # Auto-detect /web, /docroot, /html layouts
│   ├── ProcessRunner.php             # External command execution (Symfony Process)
│   └── ValueObject/
│       ├── ApacheVhostConfig.php     # Validated vhost configuration
│       ├── CronJobConfig.php         # Cron job definition
│       ├── DatabaseCredentials.php   # Type-safe database configuration
│       └── ServerPaths.php           # Validated server filesystem paths
├── Drush/
│   ├── ProvisionServiceRegistry.php  # Auto-discovery and registration
│   └── Commands/
│       ├── ProvisionAutowireTrait.php
│       ├── ProvisionSaveCommands.php
│       ├── ProvisionVerifyCommands.php
│       ├── ProvisionInstallCommands.php
│       ├── ProvisionImportCommands.php
│       ├── ProvisionBackupCommands.php
│       ├── ProvisionRestoreCommands.php
│       ├── ProvisionDeployCommands.php
│       ├── ProvisionMigrateCommands.php
│       ├── ProvisionCloneCommands.php
│       ├── ProvisionEnableCommands.php
│       ├── ProvisionDisableCommands.php
│       ├── ProvisionLockCommands.php
│       ├── ProvisionUnlockCommands.php
│       ├── ProvisionDeleteCommands.php
│       ├── ProvisionLoginResetCommands.php
│       ├── ProvisionCronCommands.php
│       └── BackendParseCommands.php
├── Event/
│   ├── ProvisionEvents.php           # 51 event name constants
│   ├── ProvisionEvent.php            # Abstract base event
│   ├── InstallEvent.php
│   ├── VerifyEvent.php
│   ├── BackupEvent.php
│   ├── RestoreEvent.php
│   ├── DeployEvent.php
│   ├── MigrateEvent.php
│   ├── CloneEvent.php
│   ├── DeleteEvent.php
│   └── CronEvent.php
├── Manager/
│   ├── VerificationManager.php       # verifyServer(), verifyPlatform(), verifySite()
│   ├── InstallationManager.php       # install(), enable(), disable()
│   ├── BackupRestoreManager.php      # backup(), restore(), deploy()
│   ├── MigrationManager.php          # migrate() with old/new platform tracking
│   ├── CloneManager.php              # cloneSite() with source/target
│   ├── DeleteManager.php             # delete() with file/database cleanup
│   ├── LockManager.php               # lock(), unlock() for all context types
│   ├── DatabaseManager.php           # Database credential generation
│   ├── CronManager.php               # Cron job management
│   ├── ContextLoader.php             # YAML context loading
│   └── PathResolver.php              # Path resolution
└── Service/
    ├── ServiceRegistry.php           # Manages available implementations
    ├── HttpServiceInterface.php
    ├── DbServiceInterface.php
    ├── SslServiceInterface.php
    ├── CronServiceInterface.php
    ├── Http/
    │   └── ApacheService.php         # Vhost management, PHP-FPM, reload
    ├── Db/
    │   └── MySqlService.php          # PDO-based, prepared statements, mysqldump
    ├── Ssl/
    │   └── SslManager.php            # Let's Encrypt → Cloudflare → self-signed
    ├── Cron/
    │   └── SystemCronService.php     # crontab with # AEGIR {id} markers
    └── Drupal/
        └── SettingsWriter.php        # Generate settings.php from template
```

## Context System

### What is a Context?

A `Context` (final class, `src/Core/Context.php`) represents an infrastructure component.

**Identity is immutable** — `name()` and `type()` are set at construction with no setters.
**Properties are mutable** — `get($key)`, `set($key, $value)`, `all()`, `toArray()`.
Some properties (e.g., `root`, `server`) are fixed by convention once set.

```php
final class Context {
    private string $name;
    private string $type;
    private array $data;

    public function __construct(string $name, string $type, array $data = [])
    public function name(): string          // stripped of leading @
    public function alias(): string         // '@' . name
    public function type(): string          // 'server', 'platform', 'site'
    public function get(string $key, mixed $default = null): mixed
    public function set(string $key, mixed $value): void
    public function all(): array
    public function toArray(): array
}
```

No typed subclasses exist — type is a string (`ContextType` enum: `SERVER`, `PLATFORM`, `SITE`).

### Context Types

#### Server Context

Represents a service provider (Apache, MySQL, etc.).

```yaml
# drush/sites/aegir/server_master.site.yml
server_master:
  provision:
    aegir_root: /home/aegir
    remote_host: aegir
    script_user: aegir
    http_service_type: apache
    http_port: 80
    context_type: server
  host: aegir
  user: aegir
```

Key properties: `aegir_root`, `http_service_type`, `db_service_type`, `http_port`, `context_type`

#### Platform Context

Represents a Drupal codebase/distribution.

```yaml
# drush/sites/aegir/platform_drupal11.site.yml
platform_drupal11:
  provision:
    context_type: platform
    server: server_master
    root: /var/aegir/platforms/drupal-11
    web_server: server_master
  root: /var/aegir/platforms/drupal-11/web
```

Key properties: `root` (platform base, parent of `web/`), `server`, `web_server`

The docroot is auto-detected by `PlatformRoot` — supports `/web`, `/docroot`, `/html` layouts.

#### Site Context

Represents an installed Drupal site.

```yaml
# drush/sites/aegir/example.com.site.yml
example.com:
  provision:
    context_type: site
    platform: platform_drupal11
    db_server: server_aegir_db
    uri: example.com
    root: /var/aegir/platforms/drupal-11
    db_name: example_com
    db_user: example_com_user
    db_passwd: generated_password
    profile: standard
    language: en
  root: /var/aegir/platforms/drupal-11/web
  uri: example.com
```

Key properties: `platform`, `db_server`, `uri`, `db_name`, `db_passwd` (note: not `db_password`)

### Storage

All context YAML files live in `drush/sites/aegir/` with the `.site.yml` extension. The `AliasStore` class handles reading and writing. Provision-specific data is stored under the `provision:` block; standard Drush alias keys (`root`, `uri`, `host`, `user`) sit at the root level.

Configuration directory structure (server `config_path`):
```
{config_path}/apache/
├── vhost.d/          # Active HTTP vhosts
├── vhost_ssl.d/      # Active HTTPS vhosts
├── disabled.d/       # Disabled site vhosts
└── platform.d/       # Platform-level includes
```

### Context Hierarchy

```
Site → Platform (via 'platform') + Server (via 'db_server')
Platform → Server (via 'server', 'web_server')
Server → standalone, hosts services
```

Cross-references use `@` prefix in code (e.g., `"@server_master"`) but are stored without `@` in YAML.

## ProvisionManager & Managers

### ProvisionManager

`src/ProvisionManager.php` — central orchestrator for all backend operations.

**Responsibilities**:
- Load and validate contexts via `ContextRepository`
- Dispatch operations to specialized managers
- Coordinate multi-service operations
- Dispatch lifecycle events via Symfony EventDispatcher

### Specialized Managers

| Manager | File | Key Methods |
|---|---|---|
| `VerificationManager` | `src/Manager/VerificationManager.php` | `verifyServer()`, `verifyPlatform()`, `verifySite()` |
| `InstallationManager` | `src/Manager/InstallationManager.php` | `install()`, `enable()`, `disable()` |
| `BackupRestoreManager` | `src/Manager/BackupRestoreManager.php` | `backup()`, `restore()`, `deploy()` |
| `MigrationManager` | `src/Manager/MigrationManager.php` | `migrate()` with old/new platform |
| `CloneManager` | `src/Manager/CloneManager.php` | `cloneSite()` with source/target |
| `DeleteManager` | `src/Manager/DeleteManager.php` | `delete()` with file/database cleanup |
| `LockManager` | `src/Manager/LockManager.php` | `lock()`, `unlock()` |
| `DatabaseManager` | `src/Manager/DatabaseManager.php` | Credential generation |
| `CronManager` | `src/Manager/CronManager.php` | Cron job management |
| `ContextLoader` | `src/Manager/ContextLoader.php` | YAML context loading |
| `PathResolver` | `src/Manager/PathResolver.php` | Path resolution |

## Service Architecture

### Service Interfaces

Services are type-safe via interfaces. The `ServiceRegistry` manages available implementations.

| Interface | Purpose | Default Implementation |
|---|---|---|
| `HttpServiceInterface` | Web server ops (vhost, reload) | `ApacheService` |
| `DbServiceInterface` | Database ops (create, grant, dump) | `MySqlService` |
| `SslServiceInterface` | SSL certificate resolution | `SslManager` |
| `CronServiceInterface` | Cron job management | `SystemCronService` |

### ApacheService

**File**: `src/Service/Http/ApacheService.php`

- `createVhost()` / `removeVhost()` — generate/enable Apache vhost configs
- `enableSite()` / `disableSite()` — move vhost between `vhost.d/` and `disabled.d/`
- `reloadService()` — reload Apache after config changes
- Templates in `resources/templates/apache/`

### MySqlService

**File**: `src/Service/Db/MySqlService.php`

Uses PDO with prepared statements (SQL injection mitigated).

- `ensureDatabase()` — create database (utf8mb4)
- `ensureUser()` / `grant()` — create user and grant privileges
- `dropDatabase()` / `dropUser()` — cleanup on delete
- `dump()` — `mysqldump` with optional gzip
- `import()` — import SQL dump

### SettingsWriter

**File**: `src/Service/Drupal/SettingsWriter.php`

Generates `settings.php` from PHP templates in `resources/templates/drupal/`.

### SslManager

**File**: `src/Service/Ssl/SslManager.php`

Priority: Let's Encrypt → Cloudflare → self-signed certificate.

### SystemCronService

**File**: `src/Service/Cron/SystemCronService.php`

Manages crontab entries with `# AEGIR {id}` markers for identification.

### Value Objects

Immutable data containers in `src/Core/ValueObject/`:

| Class | Purpose |
|---|---|
| `DatabaseCredentials` | host, port, name, username, password, driver |
| `ServerPaths` | aegirRoot, configPath, backupPath, platformsPath |
| `ApacheVhostConfig` | serverName, documentRoot, port, serverAliases |
| `CronJobConfig` | Cron job definition |

### Infrastructure Classes

| Class | File | Purpose |
|---|---|---|
| `Filesystem` | `src/Core/Filesystem.php` | Wraps Symfony Filesystem with logging |
| `ProcessRunner` | `src/Core/ProcessRunner.php` | External command execution (Symfony Process) |
| `ConfigPaths` | `src/Core/ConfigPaths.php` | Path calculation for server/context configs |
| `PlatformRoot` | `src/Core/PlatformRoot.php` | Auto-detect `/web`, `/docroot`, `/html` layouts |
| `ContextRepository` | `src/Core/ContextRepository.php` | Load/save/delete contexts |
| `AliasStore` | `src/Core/AliasStore.php` | YAML read/write for `drush/sites/aegir/` |
| `TemplateRenderer` | `src/Config/TemplateRenderer.php` | PHP template rendering with MD5-based caching |

## Drush Commands

### Command Structure

All commands are Drush 13.7+ style classes in `src/Drush/Commands/`, extending `DrushCommands` and using PHP 8 `#[CLI\Command]` attributes. Auto-discovered via `ProvisionAutowireTrait` and `ProvisionServiceRegistry`.

Commands accept context name **without** the `@` prefix. Exit codes follow Symfony Console conventions.

```php
#[CLI\Command(name: 'provision:install', aliases: ['provision-install'])]
#[CLI\Argument(name: 'contextName', description: 'Context name (without @)')]
public function install(string $contextName): void {
    $this->provisionManager->install($contextName);
    $this->io()->success("Site installed: {$contextName}");
}
```

### Command Reference

| Command | Class | Description |
|---|---|---|
| `provision:save` | ProvisionSaveCommands | Create/update/delete context |
| `provision:verify` | ProvisionVerifyCommands | Verify server/platform/site config |
| `provision:install` | ProvisionInstallCommands | Install a Drupal site |
| `provision:import` | ProvisionImportCommands | Import existing Drupal site |
| `provision:backup` | ProvisionBackupCommands | Backup site (DB + files) |
| `provision:restore` | ProvisionRestoreCommands | Restore site from backup |
| `provision:deploy` | ProvisionDeployCommands | Deploy backup to existing site |
| `provision:migrate` | ProvisionMigrateCommands | Migrate site to different platform |
| `provision:clone` | ProvisionCloneCommands | Clone site to new context |
| `provision:enable` | ProvisionEnableCommands | Enable (activate) a site |
| `provision:disable` | ProvisionDisableCommands | Disable (deactivate) a site |
| `provision:lock` | ProvisionLockCommands | Lock context (maintenance mode) |
| `provision:unlock` | ProvisionUnlockCommands | Unlock context |
| `provision:delete` | ProvisionDeleteCommands | Delete context and resources |
| `provision:login-reset` | ProvisionLoginResetCommands | Reset admin login link |
| `provision:cron` | ProvisionCronCommands | Manage cron jobs (add/delete) |
| `backend:parse` | BackendParseCommands | Parse Drush backend output |

### Key Operations

#### `provision:verify`

Validates and repairs configuration:

```bash
drush provision:verify server_master   # Verify server
drush provision:verify platform_d11    # Verify platform
drush provision:verify example.com     # Verify site
```

Site verify: ensure directories → regenerate `settings.php` → regenerate vhost → reload Apache.

#### `provision:install`

Installs a new site: create MySQL DB + user → generate `settings.php` → create vhost → `drush site:install` → enable vhost.

```bash
drush provision:install example.com
```

#### `provision:save`

Creates or updates a context:

```bash
drush provision:save server_master --type=server \
  --data='{"aegir_root":"/var/aegir","http_service_type":"apache"}'

drush provision:save example.com --type=site \
  --data='{"platform":"platform_d11","db_server":"server_master"}'
```

#### `provision:backup`

Backup site database and files. Output: `{backup_path}/backups/{name}-YYYYMMDD-HHMMSS.tar.gz`

#### `provision:migrate`

```bash
drush provision:migrate example.com new_platform_d11
```

Updates context → regenerates settings.php and vhost → runs `drush updatedb` → verifies.

## Event System

Symfony EventDispatcher integrated in ProvisionManager and all specialized managers.

### Event Lifecycle

**51 event constants** defined in `ProvisionEvents`, organized by phase:

| Phase | Purpose | Count |
|---|---|---|
| `VALIDATE_*` | Can block/abort operations before start | 12 |
| `BEFORE_*` | Pre-operation hooks (modify event data) | 12 |
| `AFTER_*` | Post-operation hooks | 12 |
| `ROLLBACK_*` | Fire on exceptions | 7 + 4 cron + 4 cron = 15 |

**Operations covered**: install, verify, backup, restore, deploy, migrate, clone, delete, enable, disable, lock, unlock, cron-add, cron-delete

**Rollback** events fire for: install, verify, backup, restore, deploy, migrate, clone + all cron operations. Enable/disable/lock/unlock have no rollback.

### Event Classes

All extend the abstract `ProvisionEvent`:

| Class | Used By |
|---|---|
| `InstallEvent` | install operations |
| `VerifyEvent` | verify operations |
| `BackupEvent` | backup operations |
| `RestoreEvent` | restore operations |
| `DeployEvent` | deploy operations |
| `MigrateEvent` | migrate operations |
| `CloneEvent` | clone operations |
| `DeleteEvent` | delete operations |
| `CronEvent` | cron-add, cron-delete operations |

### Example Event Subscriber

```php
use Symfony\Component\EventDispatcher\EventSubscriberInterface;
use Aegir\Provision\Event\ProvisionEvents;
use Aegir\Provision\Event\VerifyEvent;

class CustomVerifySubscriber implements EventSubscriberInterface
{
    public static function getSubscribedEvents(): array
    {
        return [
            ProvisionEvents::AFTER_VERIFY => 'onAfterVerify',
        ];
    }

    public function onAfterVerify(VerifyEvent $event): void
    {
        // Custom post-verify logic
    }
}
```

### Template Override System

`TemplateRenderer` (`src/Config/TemplateRenderer.php`) provides priority-based PHP template rendering with MD5 caching. Third-party code can register template directories with higher priority to override default templates.

## Configuration & Templates

### Template Location

Default templates live in `resources/templates/`:

```
resources/templates/
├── apache/
│   ├── vhost.tpl.php          # HTTP vhost
│   └── vhost_ssl.tpl.php      # HTTPS vhost
└── drupal/
    └── settings.php.tpl.php   # Drupal settings.php
```

### ServiceRegistry

```php
$registry = $provisionManager->getServiceRegistry();

// Register a custom service implementation
$registry->register('http', 'nginx', new NginxService(...));
$registry->setDefault('http', 'nginx');
```

Per-server service type is determined by the context's `http_service_type` / `db_service_type` properties.

## Development Guidelines

### Key Rules

- Backend **never** accesses the Drupal database — only YAML contexts
- All operations go through ProvisionManager → specialized managers
- Service implementations must implement the corresponding interface
- Events fire in order: VALIDATE → BEFORE → (operation) → AFTER; ROLLBACK on exception
- Context names: no `@` prefix in storage, use `@` in cross-references
- Command arguments: context name without `@`
- All PHP files use `declare(strict_types=1)` and `final` by default

### Adding a New Command

1. Create class in `src/Drush/Commands/` extending `DrushCommands`
2. Use `ProvisionAutowireTrait`
3. Add `#[CLI\Command]` and `#[CLI\Argument]` attributes
4. Delegate to ProvisionManager method
5. Add lifecycle events in the corresponding manager

### Adding a New Service

1. Identify interface in `src/Service/`
2. Create implementation in `src/Service/{Type}/`
3. Implement all interface methods
4. Register in ServiceRegistry

---

**Related**: [HOME.md](HOME.md) · [Frontend.md](Frontend.md) · [Theme.md](Theme.md) · [provision-d11.md](../vendor/argopecten/aegir-provision/doc/provision-d11.md)
