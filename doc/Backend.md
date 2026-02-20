# Backend Component - Aegir Provision System

The **Backend** component is a Drush extension that automates infrastructure operations. It handles the actual work of creating Apache vhosts, MySQL databases, installing Drupal sites, and managing the file system.

## Table of Contents

- [Overview](#overview)
- [Context System](#context-system)
- [Service Architecture](#service-architecture)
- [Drush Commands](#drush-commands)
- [Extension System](#extension-system)
- [Operations](#operations)
- [Configuration Management](#configuration-management)
- [Development Guidelines](#development-guidelines)

## Overview

**Package**: `argopecten/aegir-provision`  
**Location**: `vendor/argopecten/aegir-provision/`  
**Namespace**: `Aegir\Provision`  
**Requirements**: PHP 8.3+, Drush 13.7+, Symfony 7.0+

**Purpose**: Provides infrastructure automation for Aegir hosting operations.

**Key Responsibilities**:
- Read contexts from YAML aliases (`~/.drush/sites/aegir/`)
- Execute infrastructure operations (install, verify, delete, etc.)
- Manage Apache vhosts and MySQL databases
- Generate Drupal settings.php files using PHP templates
- Handle SSL certificates
- Perform file system operations via Symfony Filesystem
- Dispatch lifecycle events for extension integration
- Support pluggable service implementations via ServiceRegistry

**Key Principle**: The backend operates **exclusively on contexts** - it never directly accesses the Drupal database.

**Architecture** (as of January 31, 2026):
- ✅ All 16 core commands implemented (`ProvisionSave`, `ProvisionVerify`, etc.)
- ✅ Event system complete: 52 lifecycle events via Symfony EventDispatcher
- ✅ Service plugin system: interface contracts + `ServiceRegistry`
- ✅ Template override system: priority-based `TemplateRenderer`
- ✅ Value objects: `DatabaseCredentials`, `ServerPaths`, `ApacheVhostConfig`
- ✅ SQL injection mitigated: `MySqlService` uses PDO with prepared statements
- ❌ Testing: NO tests exist (critical gap, 0% coverage)

## Context System

### What is a Context?

A **context** is an immutable data structure representing an infrastructure component. Contexts are stored as Drush alias YAML files in `~/.drush/sites/aegir/`. Context data is stored under the `provision:` key within each alias file.

### Context Types

#### Site Context

Represents a Drupal site installation.

**File**: `~/.drush/sites/aegir/example.com.site.yml`

```yaml
# Drush alias wrapper (used by Drush to bootstrap the site)
root: /var/aegir/platforms/drupal-11/web
uri: example.com
# Provision-specific data stored under 'provision:' key
provision:
  type: site
  platform: platform_d11
  db_server: server_master
  uri: example.com
  root: /var/aegir/platforms/drupal-11
  db_name: example_com
  db_user: example_com_user
  db_passwd: secret123
  profile: standard
  language: en
```

**Key Properties**:
- `type` - Always "site"
- `platform` - Platform context name
- `uri` - Primary domain name
- `db_server` - Database server context
- `root` - Drupal codebase path (platform root, not docroot)
- `db_passwd` - Database password (note: `db_passwd`, not `db_password`)

#### Platform Context

Represents a Drupal codebase/distribution.

**File**: `~/.drush/sites/aegir/platform_d11.site.yml`

```yaml
# Drush alias wrapper
root: /var/aegir/platforms/drupal-11/web
# Provision-specific data
provision:
  type: platform
  server: server_master
  root: /var/aegir/platforms/drupal-11
  drupal_version: 11
```

**Key Properties**:
- `type` - Always "platform"
- `server` - Server context name
- `root` - Absolute path to platform base (parent of `web/` or `docroot/`)
- Docroot is auto-detected by `PlatformRoot` (`/web`, `/docroot`, `/html` layouts)

#### Server Context

Represents a service provider (Apache, MySQL, etc.).

**File**: `~/.drush/sites/aegir/server_master.site.yml`

```yaml
# Drush alias wrapper
host: localhost
user: aegir
# Provision-specific data
provision:
  type: server
  aegir_root: /var/aegir
  web_service_type: apache
  db_service_type: mysql
  http_port: 80
  https_port: 443
  web_group: www-data
  db_host: localhost
  db_port: 3306
  db_root_password: secret
  config_path: /var/aegir/.config
```

**Key Properties**:
- `type` - Always "server"
- `aegir_root` - Base path for Aegir data (`/var/aegir`)
- `web_service_type` - HTTP service implementation (`apache`, `nginx`)
- `db_service_type` - Database service implementation (`mysql`)
- `config_path` - Where Provision writes server-level config

### Context Storage

Contexts are stored in `~/.drush/sites/aegir/` as YAML files. The `AliasStore` class (`src/Core/AliasStore.php`) handles reading and writing. The path can be overridden via the `DRUSH_SITE_ALIAS_PATH` environment variable.

Configuration directory structure (under `server.config_path`):
```
{config_path}/apache/
├── vhost.d/          # Active HTTP vhosts
├── vhost_ssl.d/      # Active HTTPS vhosts
├── disabled.d/       # Disabled site vhosts
└── platform.d/       # Platform-level includes
```

### Context Loading

```php
// Load context via ContextRepository
$repo = new ContextRepository(new AliasStore());
$context = $repo->load('example.com');

// Get context properties
$uri = $context->getData()['uri'];
$root = $context->getData()['root'];
$platform = $context->getData()['platform'];
```

Context management via CLI:
```bash
# Create/update a context
drush provision:save example.com --type=site \
  --data='{"platform":"platform_d11","db_server":"server_master"}'

# Load context details
drush provision:status example.com
```

## Service Architecture

### ProvisionManager

**Purpose**: Central orchestrator for all backend operations.

**Class**: `Aegir\Provision\ProvisionManager`  
**File**: `src/ProvisionManager.php`

**Responsibilities**:
- Load and validate contexts via `ContextRepository`
- Dispatch operations to specialized manager classes
- Coordinate multi-service operations
- Dispatch lifecycle events via Symfony `EventDispatcher`

**Operation methods**: `verify()`, `install()`, `backup()`, `restore()`, `deploy()`, `migrate()`, `cloneSite()`, `enable()`, `disable()`, `lock()`, `unlock()`, `delete()`, `loginReset()`

### Specialized Managers

Operations are split across purpose-specific manager classes under `src/Manager/`:

| Manager | Responsibilities |
|---|---|
| `VerificationManager` | `verifyServer()`, `verifyPlatform()`, `verifySite()` |
| `InstallationManager` | `install()`, `enable()`, `disable()` |
| `BackupRestoreManager` | `backup()`, `restore()`, `deploy()` |
| `MigrationManager` | `migrate()` with old/new platform tracking |
| `CloneManager` | `cloneSite()` with source/target tracking |
| `DeleteManager` | `delete()` with file/database cleanup |
| `LockManager` | `lock()`, `unlock()` for all context types |
| `DatabaseManager` | Database credential generation |

### Service Interfaces & ServiceRegistry

Services are type-safe via interfaces. The `ServiceRegistry` (`src/Service/ServiceRegistry.php`) manages available implementations.

**Interfaces**:
- `HttpServiceInterface` - Web server operations (vhost management, reload)
- `DbServiceInterface` - Database operations (create, grant, dump, import)
- `SslServiceInterface` - SSL certificate resolution

**Default implementations**:
- `ApacheService` implements `HttpServiceInterface`
- `MySqlService` implements `DbServiceInterface`
- `SslManager` implements `SslServiceInterface`

**ServiceRegistry usage**:
```php
$registry = $provisionManager->getServiceRegistry();

// Register a custom Nginx service
$registry->register('http', 'nginx', new NginxService(...));
$registry->setDefault('http', 'nginx');

// Or per-server via context data:
// provision:save server_master --data='{"http_service_type":"nginx"}'
```

### Value Objects

Immutable data containers defined in `src/Core/ValueObject/`:

```php
// DatabaseCredentials - type-safe database configuration
new DatabaseCredentials(
    host: 'localhost',
    port: 3306,
    name: 'example_com',
    username: 'example_com_user',
    password: 'generated_password',
    driver: 'mysql'
);

// ServerPaths - validated server filesystem paths
new ServerPaths(
    aegirRoot: '/var/aegir',
    configPath: '/var/aegir/.config',
    backupPath: '/var/aegir/backups',
    platformsPath: '/var/aegir/platforms'
);

// ApacheVhostConfig - validated vhost configuration
new ApacheVhostConfig(
    serverName: 'example.com',
    documentRoot: '/var/aegir/platforms/drupal-11/web',
    port: 80,
    serverAliases: ['www.example.com']
);
```

### Service Classes

#### ApacheService

**Class**: `Aegir\Provision\Service\Http\ApacheService`  
**File**: `src/Service/Http/ApacheService.php`

**Key operations**:
- `createVhost()` / `removeVhost()` - Generate and enable Apache vhost configs
- `enableSite()` / `disableSite()` - Move vhost between `vhost.d/` and `disabled.d/`
- `reloadService()` - Reload Apache after config changes
- Templates: `resources/templates/apache/vhost.tpl.php`, `vhost_ssl.tpl.php`

**Generated vhost example**:
```apache
<VirtualHost *:80>
  ServerName example.com
  DocumentRoot /var/aegir/platforms/drupal-11/web

  <Directory /var/aegir/platforms/drupal-11/web>
    Options -Indexes +FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>

  <FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php8.3-fpm-example.sock|fcgi://localhost"
  </FilesMatch>

  ErrorLog ${APACHE_LOG_DIR}/example.com-error.log
  CustomLog ${APACHE_LOG_DIR}/example.com-access.log combined
</VirtualHost>
```

#### MySqlService

**Class**: `Aegir\Provision\Service\Db\MySqlService`  
**File**: `src/Service/Db/MySqlService.php`

Uses **PDO with prepared statements** (SQL injection mitigated as of January 31, 2026).

**Key operations**:
- `ensureDatabase()` - Create database if not exists (utf8mb4)
- `ensureUser()` / `grant()` - Create MySQL user and grant privileges
- `dropDatabase()` / `dropUser()` - Remove database and user on delete
- `dump()` - `mysqldump` backup with optional gzip compression
- `import()` - Import SQL dump file

#### SettingsWriter

**Class**: `Aegir\Provision\Service\Drupal\SettingsWriter`  
**File**: `src/Service/Drupal/SettingsWriter.php`

Generates `settings.php` from templates in `resources/templates/drupal/`. Replaces the old `SiteService.generateSettings()` pattern.

#### SslManager

**Class**: `Aegir\Provision\Service\Ssl\SslManager`  
**File**: `src/Service/Ssl/SslManager.php`

Implements `SslServiceInterface` for certificate management and Let's Encrypt integration.

### Infrastructure Classes

| Class | File | Purpose |
|---|---|---|
| `Filesystem` | `src/Core/Filesystem.php` | Wraps Symfony Filesystem with logging |
| `ProcessRunner` | `src/Core/ProcessRunner.php` | External command execution (Symfony Process) |
| `ConfigPaths` | `src/Core/ConfigPaths.php` | Path calculation for server/context configs |
| `PlatformRoot` | `src/Core/PlatformRoot.php` | Auto-detect `/web`, `/docroot`, `/html` layouts |
| `ContextRepository` | `src/Core/ContextRepository.php` | Load/save/delete contexts |
| `AliasStore` | `src/Core/AliasStore.php` | YAML read/write for `~/.drush/sites/aegir/` |
| `TemplateRenderer` | `src/Config/TemplateRenderer.php` | PHP template rendering with MD5-based caching |

## Drush Commands

### Command Structure

All Provision commands are Drush 13.7+ style classes in `src/Drush/Commands/`, extending `DrushCommands` and using PHP 8 `#[CLI\Command]` attributes. Commands are auto-discovered and registered via `ProvisionAutowireTrait` and `ProvisionServiceRegistry`.

```php
use Drush\Attributes as CLI;
use Drush\Commands\DrushCommands;

class ProvisionInstallCommands extends DrushCommands {
    use ProvisionAutowireTrait;

    #[CLI\Command(name: 'provision:install', aliases: ['provision-install'])]
    #[CLI\Argument(name: 'contextName', description: 'Context name (without @)')]
    public function install(string $contextName): void {
        $context = $this->provisionManager->getContextRepository()->load($contextName);
        $this->provisionManager->install($contextName);
        $this->io()->success("Site installed: {$contextName}");
    }
}
```

Commands accept `context_name` **without** the `@` prefix. Exit codes follow standard Symfony Console conventions (`Command::SUCCESS` / `Command::FAILURE`).

### Available Commands (all 16)

| Command | Class file | Description |
|---|---|---|
| `provision:save` | `ProvisionSaveCommands.php` | Create/update/delete context |
| `provision:verify` | `ProvisionVerifyCommands.php` | Verify server/platform/site config |
| `provision:install` | `ProvisionInstallCommands.php` | Install a Drupal site |
| `provision:import` | `ProvisionImportCommands.php` | Import existing Drupal site |
| `provision:backup` | `ProvisionBackupCommands.php` | Backup site (DB + files) |
| `provision:restore` | `ProvisionRestoreCommands.php` | Restore site from backup |
| `provision:deploy` | `ProvisionDeployCommands.php` | Deploy backup to existing site |
| `provision:migrate` | `ProvisionMigrateCommands.php` | Migrate site to different platform |
| `provision:clone` | `ProvisionCloneCommands.php` | Clone site to new context |
| `provision:enable` | `ProvisionEnableCommands.php` | Enable (activate) a site |
| `provision:disable` | `ProvisionDisableCommands.php` | Disable (deactivate) a site |
| `provision:lock` | `ProvisionLockCommands.php` | Lock site (maintenance mode) |
| `provision:unlock` | `ProvisionUnlockCommands.php` | Unlock site |
| `provision:delete` | `ProvisionDeleteCommands.php` | Delete context and resources |
| `provision:login-reset` | `ProvisionLoginResetCommands.php` | Reset admin login link |
| `backend:parse` | `BackendParseCommands.php` | Parse Drush backend output |

### Key Command Details

#### `provision:save`

Create or update a context.

```bash
drush provision:save server_master --type=server \
  --data='{"aegir_root":"/var/aegir","web_service_type":"apache","db_service_type":"mysql"}'

drush provision:save platform_d11 --type=platform \
  --data='{"root":"/var/aegir/platforms/drupal-11","server":"server_master"}'

drush provision:save example.com --type=site \
  --data='{"platform":"platform_d11","db_server":"server_master"}'
```

#### `provision:verify`

Validate and repair configuration for a context.

```bash
drush provision:verify server_master   # Verify server
drush provision:verify platform_d11   # Verify platform
drush provision:verify example.com    # Verify site
```

**Operations for site verify**:
1. Ensure directory structure
2. Regenerate `settings.php`
3. Regenerate Apache vhost config
4. Reload Apache

#### `provision:install`

Install a new Drupal site.

```bash
drush provision:install example.com
```

**Operations**:
1. Create MySQL database and user
2. Generate `settings.php`
3. Generate Apache vhost
4. Run `drush site:install`
5. Enable site vhost

#### `provision:backup`

Backup site database and files.

```bash
drush provision:backup example.com
```

**Output**: tarball stored in `{backup_path}/backups/example.com-YYYYMMDD-HHMMSS.tar.gz`

#### `provision:migrate`

Migrate a site to a different platform.

```bash
drush provision:migrate example.com new_platform_d11
```

**Operations**:
1. Update site context pointing to new platform
2. Regenerate `settings.php` and vhost
3. Run `drush updatedb`
4. Verify new installation

#### `provision:clone`

Clone a site to a new context.

```bash
drush provision:clone example.com clone.example.com
```

#### `provision:delete`

Delete a context and optionally its resources.

```bash
drush provision:delete example.com
```

**Flags**:
- `--no-backup` - Skip database backup before deletion
- `--keep-files` - Do not delete site files

## Extension System

The extension system (completed January 31, 2026) allows third-party code to integrate with provision operations without modifying core.

### Event System

**Infrastructure**: Symfony `EventDispatcher` integrated in `ProvisionManager` and all specialized managers.

**52 lifecycle events** defined in `ProvisionEvents` constants, covering every operation:
- `VALIDATE_*` - Can block/abort operations before they start
- `BEFORE_*` - Pre-operation hooks (modify event data)
- `AFTER_*` - Post-operation hooks (receive context after operation)
- `ROLLBACK_*` - Fire on exceptions (verify, backup, deploy, migrate, clone, install)

**Operations covered**: `install`, `delete`, `verify`, `backup`, `restore`, `deploy`, `migrate`, `cloneSite`, `enable`, `disable`, `lock`, `unlock`

**Event classes**: `InstallEvent`, `VerifyEvent`, `BackupEvent`, `RestoreEvent`, `MigrateEvent`, `CloneEvent`, `DeleteEvent`, `DeployEvent`

**Example subscriber**:
```php
use Symfony\Component\EventDispatcher\EventSubscriberInterface;

class CustomValidationSubscriber implements EventSubscriberInterface {
    public static function getSubscribedEvents(): array {
        return [
            ProvisionEvents::VALIDATE_INSTALL => 'onValidateInstall',
            ProvisionEvents::AFTER_INSTALL    => 'onAfterInstall',
        ];
    }

    public function onValidateInstall(InstallEvent $event): void {
        // Abort operation by throwing an exception
        if (!$this->isAllowed($event->getContextName())) {
            throw new \RuntimeException('Installation not allowed.');
        }
    }

    public function onAfterInstall(InstallEvent $event): void {
        // Post-install logic (e.g., send notification)
    }
}
```

See `examples/CustomValidationSubscriber.php` for a complete working example.

### Service Plugin System

Alternative service implementations (e.g., Nginx instead of Apache) can be registered at runtime via `ServiceRegistry`.

**Interfaces** in `src/Service/`:
- `HttpServiceInterface` - `createVhost()`, `removeVhost()`, `enableSite()`, `disableSite()`, `reloadService()`
- `DbServiceInterface` - `ensureDatabase()`, `dropDatabase()`, `dump()`, `import()`
- `SslServiceInterface` - `resolveCertificate()`, `getCertPath()`

**Example Nginx service** is provided at `examples/NginxService.php` implementing `HttpServiceInterface`.

**Registration patterns**:
```php
// Via Drush service provider (recommended)
$registry->register('http', 'nginx', new NginxService(...));
$registry->setDefault('http', 'nginx');

// Via context (per-server override)
// provision:save server_master --data='{"http_service_type":"nginx"}'
```

### Template Override System

Custom Apache vhosts and Drupal settings templates can override core templates without modifying the package.

**Priority-based loading** via `TemplateRenderer::registerTemplatePath()`:
- Priority `0` = Core templates (default)
- Priority `50` = Extension templates
- Priority `100` = User customizations
- Priority `200+` = Development overrides

```php
// Register in an event subscriber
$templates->registerTemplatePath('/path/to/custom/templates', 100);

// Template resolution is automatic - checks custom paths first, then core
$vhost = $templates->render('apache/vhost.tpl.php', [
    'server_name' => 'example.com',
    'docroot' => '/var/aegir/platforms/drupal-11/web',
]);

// Debug which template will be used
$path = $templates->getTemplatePath('apache/vhost.tpl.php');
```

**Template caching**: `TemplateRenderer` caches parsed templates using MD5 hash of path + file modification time, with automatic invalidation on file change.

Example templates and registration patterns are in `examples/templates/` and `examples/CustomTemplateRegistration.php`.

For full documentation see `doc/guides/extension-system.md`.

## Operations

### Operation Lifecycle

```
1. Command Invocation
   ↓
2. Context Loading (ContextRepository)
   ↓
3. Event: VALIDATE_* (may abort)
   ↓
4. Event: BEFORE_*
   ↓
5. Operation Execution (specialized manager)
   ↓
6. Event: AFTER_*
   ↓
7. Context Save + Result Logging
```

On exception: `ROLLBACK_*` event fires before re-throwing.

### Error Handling

All managers follow the pattern:

```php
try {
    $event = new OperationEvent('validate', $contextName);
    $this->dispatcher->dispatch($event, ProvisionEvents::VALIDATE_INSTALL);

    $event = new OperationEvent('before', $contextName);
    $this->dispatcher->dispatch($event, ProvisionEvents::BEFORE_INSTALL);

    // ... operation logic ...

    $event = new OperationEvent('after', $contextName);
    $this->dispatcher->dispatch($event, ProvisionEvents::AFTER_INSTALL);

} catch (\Exception $e) {
    $event = new OperationEvent('rollback', $contextName, ['exception' => $e]);
    $this->dispatcher->dispatch($event, ProvisionEvents::ROLLBACK_INSTALL);
    throw $e;
}
```

### Key Workflow Summaries

| Operation | Steps |
|---|---|
| **verify** | Load context → Ensure dirs → Write settings.php → Write vhost → Reload Apache |
| **install** | Create DB/user → Write settings.php → Write vhost → `drush site:install` → Enable vhost |
| **backup** | `mysqldump` → tar site files → store in `{backup_path}/backups/` |
| **restore** | Extract tarball → Import SQL → Regenerate settings.php |
| **migrate** | Update context platform → Regenerate configs → `drush updatedb` |
| **clone** | Copy DB → Copy files → Create new context → Write settings.php/vhost |
| **enable** | Move vhost from `disabled.d/` to `vhost.d/` → Reload Apache |
| **disable** | Move vhost to `disabled.d/` → Reload Apache |
| **delete** | Backup → Drop DB + user → Remove vhost → Delete files → Delete context |

## Configuration Management

### Server Configuration

Server contexts define how services are configured. Key provision-specific fields:

```yaml
provision:
  type: server
  aegir_root: /var/aegir
  web_service_type: apache   # or: nginx
  db_service_type: mysql
  http_port: 80
  https_port: 443
  web_group: www-data
  db_host: localhost
  db_port: 3306
  db_root_password: secret
  config_path: /var/aegir/.config
  backup_path: /var/aegir/backups
```

### Path Configuration

`ConfigPaths` (`src/Core/ConfigPaths.php`) centralizes path resolution:

```php
$paths = new ConfigPaths($serverContext);

$paths->vhostPath('example.com');   // {config_path}/apache/vhost.d/example.com.conf
$paths->vhostSslPath('example.com'); // {config_path}/apache/vhost_ssl.d/example.com.conf
$paths->disabledPath('example.com'); // {config_path}/apache/disabled.d/example.com.conf
$paths->backupPath('example.com');   // {backup_path}/backups/example.com/
```

### Docroot Detection

`PlatformRoot` (`src/Core/PlatformRoot.php`) auto-detects the Drupal public directory:
- Checks for `/web` (Composer standard)
- Checks for `/docroot` (legacy Acquia-style)
- Checks for `/html` (alternative)
- Falls back to platform root itself

## Development Guidelines

### Service Development

**DO**:
- ✓ Read all configuration from contexts
- ✓ Implement service interfaces (`HttpServiceInterface`, `DbServiceInterface`, `SslServiceInterface`)
- ✓ Register custom services via `ServiceRegistry`
- ✓ Use `ProcessRunner` for external commands (not `shell_exec`)
- ✓ Use `Filesystem` for file operations (not raw `file_put_contents`)
- ✓ Dispatch events using the provided `EventDispatcher`
- ✓ Log all operations

**DON'T**:
- ✗ Access Drupal database directly
- ✗ Hardcode paths or credentials
- ✗ Use global variables or static state
- ✗ Skip error handling
- ✗ Leave orphaned resources on failure

### Context Management

**DO**:
- ✓ Validate context type before operations
- ✓ Use `ContextRepository` to load/save contexts
- ✓ Use `DatabaseCredentials` and other value objects for type safety
- ✓ Check for required properties (graceful missing-key handling)

**DON'T**:
- ✗ Modify context YAML files manually during operations
- ✗ Store `@` prefix in context data (frontend strips it)
- ✗ Assume optional properties exist
- ✗ Cache context objects across requests

### Command Development

**DO**:
- ✓ Follow `provision:*` naming convention (colon, not hyphen)
- ✓ Extend `DrushCommands` and use `ProvisionAutowireTrait`
- ✓ Use `#[CLI\Command]` attributes (not docblock annotations)
- ✓ Accept `context_name` argument without `@` prefix
- ✓ Return meaningful exit codes (`Command::SUCCESS` / `Command::FAILURE`)

**DON'T**:
- ✗ Use the old `@command` docblock annotation style
- ✗ Accept entity IDs (use context names)
- ✗ Use interactive prompts (commands run from queue workers)
- ✗ Suppress error output

## Testing

> ⚠️ **CRITICAL GAP**: No tests exist. 0% code coverage. This is the top blocker for 1.0 release.

### Planned Test Organization

```
tests/
├── Unit/
│   ├── Core/       # Context, ContextRepository, AliasStore, PlatformRoot
│   ├── Manager/    # All manager classes
│   ├── Service/    # ApacheService, MySqlService, SettingsWriter, SslManager
│   └── Config/     # TemplateRenderer, override priority
├── Integration/
│   ├── Command/    # All 16 Drush commands
│   └── Workflow/   # Full install/backup/migrate/clone flows
├── fixtures/   # Context YAML, template files
└── docker/     # docker-compose for Apache + MySQL test stack
```

**Coverage targets**: Core classes 90%+, Managers 85%+, Services 80%+, Commands 75%+, Overall 85%+

See `doc/roadmap.md` for detailed testing requirements and CI/CD pipeline plan.

## Next Steps

- **[Frontend Documentation](Frontend.md)** - Learn about hosting entities
- **[Theme Documentation](Theme.md)** - Explore the Eldir theme
- **[Architecture Overview](HOME.md)** - Return to main documentation
- **[Provision Roadmap](../vendor/argopecten/aegir-provision/doc/roadmap.md)** - Detailed status and priorities
- **[Extension System Guide](../vendor/argopecten/aegir-provision/doc/guides/extension-system.md)** - Creating extensions
- **[Manual Testing Guide](../vendor/argopecten/aegir-provision/doc/manual-testing.md)** - Testing Provision commands

---

**Questions?** Check the [provision roadmap](../vendor/argopecten/aegir-provision/doc/roadmap.md) for detailed technical guidance.
