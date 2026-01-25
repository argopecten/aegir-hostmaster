# Aegir Provision D11 - AI Coding Agent Instructions

## Project Overview
This is a **Drupal 11 site managed by Aegir Provision**, a hosting automation backend system. The codebase combines a standard Drupal 11 installation with the Aegir Provision D11 Drush extension for managing multi-site hosting infrastructure.

**Architecture**: Aegir uses a context-based system (servers, platforms, sites) where Drush commands automate web hosting tasks (site install, migrate, backup, restore, SSL configuration).

## Critical Directory Structure

```
/var/www/drupal/aegir-2601/          # Project root
├── web/                              # Drupal docroot (web-facing files)
│   ├── core/                         # Drupal 11 core (managed by Composer)
│   ├── modules/
│   │   ├── contrib/                  # Contributed modules
│   │   └── aegir-hosting/hosting/    # Hostmaster frontend modules
│   │       ├── src/                  # Core services (ContextRegistry, BackendInvoker)
│   │       ├── hosting_site/         # Site entity and management
│   │       ├── hosting_platform/     # Platform entity and management
│   │       ├── hosting_server/       # Server entity and services
│   │       ├── hosting_task/         # Task queue and worker
│   │       └── doc/                  # Module architecture documentation
│   ├── themes/
│   │   └── aegir-eldir/              # Aegir Hostmaster theme
│   │       ├── templates/            # Twig templates (hosting-specific)
│   │       ├── css/                  # Aegir UI styling
│   │       ├── eldir.theme           # Preprocess hooks, theme logic
│   │       └── doc/                  # Theme architecture documentation
│   ├── sites/aegir.local/            # Site-specific configs (settings.php)
│   └── index.php                     # Drupal entry point
├── vendor/aegir-provision/           # Aegir Provision D11 Drush extension
│   ├── src/Commands/                 # Drush 13 commands (provision-*)
│   ├── src/Provision/                # ProvisionManager orchestrates tasks
│   ├── src/Service/                  # Http (Apache), Db (MySQL), SSL services
│   ├── src/Core/                     # Context, ContextRepository, Filesystem
│   └── doc/                          # Architecture documentation
│       ├── provision-d11.md          # System architecture (current)
│       ├── provision-d7.md           # Legacy Drupal 7 docs (reference only)
│       └── README.md                 # Documentation index
├── recipes/                          # Drupal 11 recipe packages
└── composer.json                     # Project dependencies

**Key insight**: This is NOT just a Drupal site - it's a hosting management platform. Don't suggest standard Drupal development workflows without considering Aegir's hosting automation layer.
```

## Context System (Core Concept)

Aegir operates on **three context types** stored as Drush YAML aliases in `~/.drush/sites/`:

- **Server**: Infrastructure node with services (http/db), stores paths (`aegir_root`, `config_path`)
- **Platform**: Drupal codebase directory (`root` path), references server
- **Site**: Individual Drupal site (`uri`, `platform`, `db_*` credentials)

**File**: [src/Core/Context.php](vendor/aegir-provision/src/Core/Context.php) - Immutable context data structure  
**File**: [src/Core/ContextRepository.php](vendor/aegir-provision/src/Core/ContextRepository.php) - Load/save via AliasStore

Example context reference: `@example.com` (site), `@aegir.local` (platform), `@server_master` (server)

## Provision Commands Workflow

All hosting tasks use `drush provision-*` commands defined in [src/Commands/ProvisionCommands.php](vendor/aegir-provision/src/Commands/ProvisionCommands.php):

```bash
# Core operations (orchestrated by ProvisionManager)
drush provision-verify @context      # Regenerate configs, verify state
drush provision-install @site.com    # Install Drupal site
drush provision-migrate @site.com @new_platform
drush provision-backup @site.com     # Database + files backup
drush provision-clone @site.com @clone.com
```

**File**: [src/Provision/ProvisionManager.php](vendor/aegir-provision/src/Provision/ProvisionManager.php) (773 lines) - Central orchestration for verify/install/migrate/backup/restore operations.

## Service Architecture

Services handle infrastructure resources. Key implementations:

- **ApacheService** ([Service/Http/ApacheService.php](vendor/aegir-provision/src/Service/Http/ApacheService.php)): Generates vhost configs in `{config_path}/apache/{vhost.d, vhost_ssl.d, platform.d}`, manages SSL certificates via SslManager
- **MySqlService** ([Service/Db/MySqlService.php](vendor/aegir-provision/src/Service/Db/MySqlService.php)): Database/user creation, grants, dump/restore using mysql CLI
- **SettingsWriter** ([Service/Drupal/SettingsWriter.php](vendor/aegir-provision/src/Service/Drupal/SettingsWriter.php)): Generates Drupal `settings.php` with database credentials

Services use **template rendering** ([Config/TemplateRenderer.php](vendor/aegir-provision/src/Config/TemplateRenderer.php)) for Apache vhosts and Drupal settings.

## Development Conventions

### Composer Package Management
- **Never manually edit** `web/core/`, `web/modules/contrib/`, or `vendor/` - managed by Composer
- Add modules: `composer require drupal/module_name`
- Custom code belongs in: `web/modules/custom/`, `web/themes/custom/`
- Recipes (Drupal 11 feature): `composer require drupal/recipe_name` → installed to `recipes/`

### Drupal Settings Pattern
Site settings in [web/sites/aegir.local/settings.php](web/sites/aegir.local/settings.php) are **generated by Provision**. Local overrides should go in `local.settings.php` (not version controlled).

### Drush 13 Integration
- Commands registered via [drush.services.yml](vendor/aegir-provision/drush.services.yml) using `drush.command` tag
- Use Drush attributes (`#[CLI\Command]`, `#[CLI\Argument]`) for command definitions
- Provision commands extend `Drush\Commands\DrushCommands`

### File Paths and Security
- Use absolute paths via `ConfigPaths` service ([src/Core/ConfigPaths.php](vendor/aegir-provision/src/Core/ConfigPaths.php))
- File permissions: configs 0644, directories 0750, scripts 0755
- Web server user group: `web_group` context property (typically `www-data`)

## Architecture Documentation

**Essential reading**: [vendor/aegir-provision/doc/provision-d11.md](vendor/aegir-provision/doc/provision-d11.md) (457 lines) - Comprehensive system architecture, context schemas, config generation, hostmaster integration, PHP 8.3+ and Drupal 11 compatibility notes.

**Component documentation**: Each major component has a `doc/` subdirectory:
- [src/Commands/doc/](vendor/aegir-provision/src/Commands/doc/) - Drush command implementations
- [src/Core/doc/](vendor/aegir-provision/src/Core/doc/) - Core abstractions (Context, Filesystem, etc.)
- [src/Provision/doc/](vendor/aegir-provision/src/Provision/doc/) - Provision manager orchestration
- [src/Service/doc/](vendor/aegir-provision/src/Service/doc/) - Service layer (HTTP, DB, SSL, Drupal)
- [src/Config/doc/](vendor/aegir-provision/src/Config/doc/) - Configuration and templates

## Common Gotchas

1. **Don't confuse contexts**: A site context requires both platform and server contexts to exist
2. **Config regeneration**: After modifying context data, run `drush provision-verify @context` to regenerate vhosts/settings
3. **Multisite aliasing**: Apache vhost must match site URI; check `web/sites/sites.php` for multisite routing
4. **SSL certificate paths**: Managed by SslManager, auto-provisioned during verify with `ssl_enabled=true`
5. **Database credentials**: Generated by MySqlService during site install, stored in context and settings.php

## Anti-Patterns to Avoid

### ❌ Don't bypass the entity layer
```php
// WRONG: Direct context manipulation from forms
$contextRepo->save($context->set('domain', $value));

// CORRECT: Use entity fields
$entity->set('domain', $value);
$entity->save();  // Triggers entity hooks → context sync
```

### ❌ Don't create forms without manager services
```php
// WRONG: Business logic in form
public function validateForm() {
  if (!filter_var($domain, FILTER_VALIDATE_DOMAIN)) { ... }
}

// CORRECT: Delegate to injected manager service
public function validateForm() {
  if (!$this->siteManager->isDomainValid($domain)) { ... }
}
```

### ❌ Don't reference contexts with `@` in entity storage
```php
// WRONG: Store alias format in database
$entity->set('context_name', '@example.com');

// CORRECT: Store canonical name (HostingContext standard)
$entity->set('context_name', 'example.com');  // No @ prefix
```

### ❌ Don't skip field definitions for entity properties
```php
// WRONG: Add entity properties without BaseFieldDefinition
class HostingSite extends ContentEntityBase {
  public $domain;  // No field definition
}

// CORRECT: Define via baseFieldDefinitions()
$fields['domain'] = BaseFieldDefinition::create('string')
  ->setLabel(t('Domain'))
  ->setRequired(TRUE)
  ->setDisplayOptions('form', [...]);
```

### ❌ Don't hardcode paths - use services
```php
// WRONG: Hardcode config paths
$vhost = '/var/aegir/config/apache/vhost.d/site.conf';

// CORRECT: Use ConfigPaths service
$vhost = $this->paths->serverConfigPath($server) . '/apache/vhost.d/site.conf';
```

## Testing and Debugging

- **Verify context state**: `drush provision-verify @context` (regenerates all configs)
- **Check Apache configs**: Inspect `{config_path}/apache/vhost.d/*.conf`
- **Database connectivity**: MySqlService uses environment vars for credentials (see `mysqlEnv()` method)
- **Drush cache**: Clear with `drush cache:rebuild` if context changes don't apply

## Hostmaster Frontend Integration (aegir-hosting modules)

**Critical**: The Drupal 11 frontend in [web/modules/aegir-hosting/hosting/](web/modules/aegir-hosting/hosting/) defines the canonical data model. All forms and views MUST interact with these entities, not raw context data.

**Module Structure**: The `hosting` module contains all submodules as subdirectories:
- `hosting/` - Core services, context registry, backend invoker, queue dispatcher
- `hosting/hosting_site/` - Site entity and management
- `hosting/hosting_platform/` - Platform entity and management  
- `hosting/hosting_server/` - Server entity and services
- `hosting/hosting_task/` - Task queue and worker
- `hosting/hosting_client/` - Client entity and permissions
- `hosting/hosting_package/` - Package tracking
- `hosting/hosting_db_server/` - Database server specifics
- `hosting/hosting_web_server/` - Web server specifics

**Documentation Structure**: Each module has a `doc/` subdirectory containing:
- `*-d11-sad.md` - System Architecture Document for Drupal 11 (current implementation)
- `*-d7.md` - Legacy documentation for Drupal 7 (source code no longer present, kept for reference)
- `README.md` - Documentation index and notes

### Architecture Overview

The frontend/backend integration follows a **queue-based task dispatch** pattern:

```
User Action → Entity CRUD → Context Sync → Task Creation → Queue → Worker → Backend Command → Result
```

**Key Services**:
- `hosting.context_registry` - Synchronizes entities to Drush aliases
- `hosting_task.manager` - Creates and executes tasks
- `hosting.backend_invoker` - Shells out to Drush commands
- `hosting_task` queue - Asynchronous task execution

### Data Flow Example (Site Creation)

1. **User submits form** → `HostingSiteForm::save()`
2. **Entity saved** → `HostingSite` entity stored in database
3. **Context registry** → `ContextRegistry::register()` creates `HostingContext` record linking entity to context name
4. **Alias generation** → Context data written to `~/.drush/sites/{context_name}.site.yml`
5. **Task queued** → `TaskManager::createTask('example.com', 'install')` creates `HostingTask` entity
6. **Queue processes** → `HostingTaskQueueWorker` picks up task
7. **Backend invoked** → `BackendInvoker::invoke('provision-install', ['example.com'])`
8. **Drush executes** → `drush provision-install @example.com` runs
9. **Result captured** → stdout/stderr logged to `HostingTaskLog`
10. **Task completed** → `HostingTask` status updated to 'success' or 'failed'

### Context Registry Pattern

The `ContextRegistry` service ([hosting/src/Service/ContextRegistry.php](web/modules/aegir-hosting/hosting/src/Service/ContextRegistry.php)) maintains the entity ↔ context mapping:

```php
// Register entity with context name (no @ prefix)
$registry = \Drupal::service('hosting.context_registry');
$registry->register('example.com', 'hosting_site', $site->id());

// Creates HostingContext record:
// - context_name: 'example.com'
// - entity_type: 'hosting_site'
// - entity_id: 123

// Also creates path alias: /hosting/c/example.com → /hosting/sites/123
```

**When to sync**: Entity presave/postsave hooks should trigger `register()` to keep contexts updated with entity changes.

### Backend Invoker Contract

The `BackendInvoker` ([hosting/src/Service/BackendInvoker.php](web/modules/aegir-hosting/hosting/src/Service/BackendInvoker.php)) executes Drush commands:

```php
public function invoke(string $command, array $args = [], array $options = [], ?string $alias = NULL): array
```

**Configuration** (via `hosting.settings`):
- `backend.drush_path` - Path to Drush binary (default: 'drush')
- `backend.alias` - Optional server alias (e.g., '@server_master')

**Command construction**:
```bash
{drush_path} {alias?} {command} {args...} {--options...}
# Example: drush @server_master provision-install example.com --client_email=admin@example.com
```

**Return structure**:
```php
[
  'output' => string,      // stdout
  'error' => string,       // stderr
  'exit_code' => int,      // 0 = success, non-zero = failure
]
```

### Task Manager Workflow

The `TaskManager` ([hosting/hosting_task/src/Service/TaskManager.php](web/modules/aegir-hosting/hosting/hosting_task/src/Service/TaskManager.php)) orchestrates task execution:

```php
// Create task
$task = $task_manager->createTask(
  'example.com',           // context_name (no @)
  'install',               // task_type
  ['client_email' => 'admin@example.com'],  // args (optional)
  ['force-reinstall' => TRUE]                // options (optional)
);

// Task entity fields:
// - command: 'provision-install'  (auto-prefixed)
// - context_name: 'example.com'   (stored without @)
// - status: 'queued' → 'processing' → 'success'/'failed'
// - started: timestamp
// - completed: timestamp
```

**Queue execution** (`HostingTaskQueueWorker`):
1. Picks task from `hosting_task` queue
2. Calls `TaskManager::runTaskId($task_id)`
3. Updates task status to 'processing'
4. Invokes backend command via `BackendInvoker`
5. Logs output to `HostingTaskLog` entities
6. Updates task status based on exit code
7. Sets completion timestamp

### Entity Field → Context Property Mappings

Frontend entities use different field names than backend contexts:

| Entity Type | Entity Field | Context Property | Notes |
|-------------|--------------|------------------|-------|
| HostingSite | `domain` | `uri` | Primary site identifier |
| HostingSite | `platform` (ref) | `platform` | Context name of platform |
| HostingSite | `db_server` (ref) | `db_server` | Context name of DB server |
| HostingPlatform | `publish_path` | `root` | Absolute path to Drupal root |
| HostingServer | `hostname` | `remote_host` | Server hostname/IP |
| HostingServer | Services | `http_service_type`, `db_service_type` | Service type strings |

**Synchronization responsibility**: Entity save handlers or event subscribers must translate entity fields to context properties when writing Drush aliases.

### Entity Architecture

Core entities map to Provision contexts with specific relationships:

- **HostingSite** ([hosting/hosting_site/src/Entity/HostingSite.php](web/modules/aegir-hosting/hosting/hosting_site/src/Entity/HostingSite.php)) → `@site.com` context
  - Fields: `domain`, `platform` (ref), `db_server` (ref), `profile` (ref), `db_name`, `language`, `status`, `cron_key`
  - Manager service: `hosting_site.manager` ([SiteManager.php](web/modules/aegir-hosting/hosting/hosting_site/src/Service/SiteManager.php))
  
- **HostingPlatform** ([hosting/hosting_platform/src/Entity/HostingPlatform.php](web/modules/aegir-hosting/hosting/hosting_platform/src/Entity/HostingPlatform.php)) → `@platform.local` context
  - Fields: `publish_path` (maps to Provision `root`), `server` (ref), `packages`
  
- **HostingServer** ([hosting/hosting_server/src/Entity/HostingServer.php](web/modules/aegir-hosting/hosting/hosting_server/src/Entity/HostingServer.php)) → `@server_master` context
  - Fields: `hostname` (maps to Provision `remote_host`), services via `HostingServiceInstance`
  
- **HostingContext** ([hosting/src/Entity/HostingContext.php](web/modules/aegir-hosting/hosting/src/Entity/HostingContext.php)) - Registry linking entities to context names
  - Fields: `context_name`, `entity_type`, `entity_id`
  - Service: `hosting.context_registry` ([ContextRegistry.php](web/modules/aegir-hosting/hosting/src/Service/ContextRegistry.php))

- **HostingTask** ([hosting/hosting_task/src/Entity/HostingTask.php](web/modules/aegir-hosting/hosting/hosting_task/src/Entity/HostingTask.php)) - Task queue records
  - Manager: `hosting_task.manager` ([TaskManager.php](web/modules/aegir-hosting/hosting/hosting_task/src/Service/TaskManager.php))
  - Backend execution: `hosting.backend_invoker` ([BackendInvoker.php](web/modules/aegir-hosting/hosting/src/Service/BackendInvoker.php))

### Form Implementation Pattern

Forms MUST extend `ContentEntityForm` and interact with entity fields, not direct context manipulation:

```php
// CORRECT: Use entity fields and manager services
class HostingSiteForm extends ContentEntityForm {
  protected SiteManager $siteManager;  // Inject domain-specific services
  
  public function validateForm(array &$form, FormStateInterface $form_state): void {
    $domain = $this->getFieldValue($form_state->getValue('domain'));
    $domain = $this->siteManager->normalizeDomain($domain);  // Use service layer
    
    if (!$this->siteManager->isDomainValid($domain)) {
      $form_state->setErrorByName('domain', $this->t('Invalid domain'));
    }
  }
}

// WRONG: Don't directly call ProvisionManager or manipulate contexts
// Forms should work through Drupal entity/field APIs
```

### Entity → Context Sync Flow

1. **User submits form** → Entity saved via ContentEntityForm
2. **Entity presave/save hooks** → Trigger context synchronization (via `hosting.context_registry`)
3. **ContextRegistry** → Writes Drush alias YAML to `~/.drush/sites/{context_name}.site.yml`
4. **Task creation** → `TaskManager::createTask()` queues `provision-*` command
5. **Backend execution** → `BackendInvoker` runs Drush command, ProvisionManager reads context from alias

**Pain point**: Incomplete forms may skip entity field definitions or bypass manager services, causing context/entity desync. Always validate forms reference all required entity fields with proper widgets.

## Integration Points

- **Backend dispatch**: `hosting.backend_invoker` shells out to Drush with context names (no `@` prefix in task records)
- **Context mapping**: Frontend `context_name` must match backend Drush alias names exactly
- **Remote execution**: Server contexts support SSH-based operations (`remote_host`, `script_user` properties)
- **Backup storage**: Configurable via `backup_path` server property, includes database dumps + files

## Common Task Examples

### How to Add a New Site

**Frontend (Entity API)**:
```php
// Create site entity with required fields
$site = \Drupal::entityTypeManager()
  ->getStorage('hosting_site')
  ->create([
    'domain' => 'example.com',
    'platform' => $platform_entity->id(),      // Reference to HostingPlatform
    'db_server' => $db_server_entity->id(),    // Reference to HostingServer
    'profile' => $profile_package_entity->id(), // Reference to HostingPackage
    'language' => 'en',
  ]);
$site->save();  // Triggers context sync via HostingContext registry

// Queue installation task
$task_manager = \Drupal::service('hosting_task.manager');
$task_manager->createTask($site, 'install', ['client_email' => 'admin@example.com']);
```

**Backend (Drush command)**:
```bash
# Direct provision command (bypasses frontend)
drush provision-save example.com --type=site \
  --data='{"uri":"example.com","platform":"platform_name","db_server":"server_master","profile":"standard"}'
drush provision-install @example.com
```

### How to Migrate a Site Between Platforms

**Frontend**:
```php
// Load site entity and change platform reference
$site = \Drupal::entityTypeManager()
  ->getStorage('hosting_site')
  ->load($site_id);

$site->set('platform', $new_platform_entity->id());
$site->save();

// Queue migrate task with target platform context name
$task_manager = \Drupal::service('hosting_task.manager');
$task_manager->createTask($site, 'migrate', [
  'target_platform' => $new_platform_context_name,  // e.g., 'platform_d11'
]);
```

**Backend**:
```bash
# Migrate preserves site data, moves to new platform
drush provision-migrate @example.com @new_platform_name
drush provision-verify @example.com  # Regenerate configs
```

### How to Create a New Platform

**Frontend**:
```php
// Create platform entity
$platform = \Drupal::entityTypeManager()
  ->getStorage('hosting_platform')
  ->create([
    'name' => 'Drupal 11 Platform',
    'publish_path' => '/var/aegir/platforms/drupal-11',  // Maps to Provision 'root'
    'server' => $web_server_entity->id(),
  ]);
$platform->save();

// Queue verify task to scan packages
$task_manager = \Drupal::service('hosting_task.manager');
$task_manager->createTask($platform, 'verify');
```

**Backend**:
```bash
# Create platform context and verify
drush provision-save platform_d11 --type=platform \
  --data='{"root":"/var/aegir/platforms/drupal-11","server":"server_master"}'
drush provision-verify @platform_d11  # Scans Drupal installation
```

### How to Enable SSL for a Site

**Frontend**:
```php
// Update site entity with SSL flags
$site = \Drupal::entityTypeManager()
  ->getStorage('hosting_site')
  ->load($site_id);

// Add SSL-related fields to site context data
$context_data = [
  'ssl_enabled' => TRUE,
  'ssl_redirect' => TRUE,  // Force HTTPS
];

// Store in site entity (custom field or context data)
// Then queue verify task
$task_manager = \Drupal::service('hosting_task.manager');
$task_manager->createTask($site, 'verify');
```

**Backend**:
```bash
# Update site context with SSL flags
drush provision-save example.com \
  --data='{"ssl_enabled":true,"ssl_redirect":true}'

# Verify regenerates vhost with SSL config
drush provision-verify @example.com
# Creates/updates: {config_path}/apache/vhost_ssl.d/example.com.conf
```

### How to Backup and Restore a Site

**Frontend**:
```php
// Queue backup task
$task_manager = \Drupal::service('hosting_task.manager');
$backup_task = $task_manager->createTask($site, 'backup');

// After backup completes, get backup file from task log
// Queue restore task with backup file path
$restore_task = $task_manager->createTask($site, 'restore', [
  'backup_file' => '/var/aegir/backups/example.com-20260124.tar.gz',
]);
```

**Backend**:
```bash
# Create backup (database + files)
drush provision-backup @example.com
# Output: /var/aegir/backups/example.com-20260124-123456.tar.gz

# Restore from backup
drush provision-restore @example.com /var/aegir/backups/example.com-20260124.tar.gz

# Clone site (backup + deploy to new name)
drush provision-clone @example.com @staging.example.com @platform_d11
```

### How to Debug Context/Entity Sync Issues

```bash
# Check if context exists in Drush aliases
drush site:alias @example.com

# View context data
cat ~/.drush/sites/example.com.site.yml

# Check entity ↔ context mapping
drush sql:query "SELECT * FROM hosting_context WHERE context_name='example.com'"

# Force context sync from entity
drush eval "\$site = \Drupal::entityTypeManager()->getStorage('hosting_site')->load($id); \$site->save();"

# Verify regenerates all configs
drush provision-verify @example.com
```

## Operational Requirements & System Setup

### Current Mode: Filesystem Permissions

**File Ownership Model**:
- **Aegir user** (typically `aegir`): Owns all Aegir root directories and platform code
- **Web server group** (typically `www-data`): Group ownership for web-accessible files
- **Drupal sites**: Files within `sites/*/files` must be writable by web server

**Permission Patterns** (enforced by [Filesystem.php](vendor/aegir-provision/src/Core/Filesystem.php)):
```php
// Directory permissions
0750  // Config directories (apache/vhost.d, backup_path)
0755  // Platform/site paths (Drupal root)
0770  // Private files directory
0775  // Public files directory
0700  // SSL certificate storage

// File permissions
0640  // Default for generated config files
0644  // Apache vhosts, general configs
0664  // Drupal settings.php (readable by web server)
```

**Critical Paths** (from server context):
- `aegir_root` - Base directory (e.g., `/var/aegir`)
- `config_path` - Apache configs (`{aegir_root}/config`)
- `backup_path` - Site backups (`{aegir_root}/backups`)
- `clients_path` - Client data (`{aegir_root}/clients`)
- `platforms_path` - Platform symlinks (`{aegir_root}/platforms`)

**Current Pain Points**:
- Manual `chown`/`chmod` required after platform deployment
- No automated permission fixing for remote servers
- Referenced but missing: `/usr/local/bin/fix-drupal-platform-ownership.sh` helper script

### Current Mode: Cron Setup

**Queue Dispatch Architecture**:
1. **System cron** triggers `drush hosting:dispatch` (recommended: every minute)
2. **QueueDispatcher** ([hosting/src/Service/QueueDispatcher.php](web/modules/aegir-hosting/hosting/src/Service/QueueDispatcher.php)) checks queue schedules
3. **QueueRunner** processes items via `HostingTaskQueueWorker`
4. Tasks execute backend commands asynchronously

**Setup Command**:
```bash
drush hosting:setup
# Enables dispatch, displays cron recommendation
# Output: "Cron should run `drush hosting:dispatch` every minute."
```

**Cron Entry** (current recommendation):
```cron
* * * * * cd /var/www/drupal/aegir-2601 && drush hosting:dispatch >> /var/log/aegir/dispatch.log 2>&1
```

**Configuration** ([hosting/src/Form/HostingSettingsForm.php](web/modules/aegir-hosting/hosting/src/Form/HostingSettingsForm.php)):
- `hosting.settings.dispatch_enabled` - Enable/disable queue processing
- `hosting.settings.cron_method` - Method selection (drush/systemd/etc)
- Per-queue settings: frequency, items per run, thread limits

**Current Pain Points**:
- Requires root/sudo access to install system cron
- Single-server assumption (no distributed queue workers)
- No systemd timer alternative documented
- Log rotation not automated

### Future Mode Proposals (FMO)

#### 1. **Permission Management via Systemd User Services**

**Proposal**: Replace manual permission fixing with systemd path units that trigger permission reconciliation.

**Benefits**:
- Automatic permission fixing on file changes
- No root cron required
- Per-platform isolation
- Audit trail via journalctl

**Implementation**:
```ini
# /etc/systemd/system/aegir-platform@.path
[Path]
PathChanged=/var/aegir/platforms/%i
Unit=aegir-platform@%i.service

[Install]
WantedBy=multi-user.target

# /etc/systemd/system/aegir-platform@.service
[Service]
Type=oneshot
User=aegir
Group=www-data
ExecStart=/usr/local/bin/aegir-fix-permissions.sh %i
```

**Migration Path**:
1. Create standardized permission script in `vendor/aegir-provision/resources/scripts/`
2. Add Drush command `drush provision:install-systemd` to generate unit files
3. Document in [vendor/aegir-provision/doc/provision-d11.md](vendor/aegir-provision/doc/provision-d11.md)

#### 2. **Queue Processing via Systemd Timers**

**Proposal**: Replace cron with systemd timers for queue dispatch.

**Benefits**:
- Native logging to journalctl
- Better failure handling and restart policies
- Resource limits (CPU/memory) per timer
- User-level timers (no root required with `--user` flag)

**Implementation**:
```ini
# ~/.config/systemd/user/aegir-dispatch.timer
[Timer]
OnCalendar=*:*:0/60  # Every minute
AccuracySec=1s
Persistent=true

[Install]
WantedBy=timers.target

# ~/.config/systemd/user/aegir-dispatch.service
[Service]
Type=oneshot
WorkingDirectory=/var/www/drupal/aegir-2601
ExecStart=/usr/bin/drush hosting:dispatch
StandardOutput=journal
StandardError=journal
```

**Migration Path**:
1. Add `drush hosting:install-timer` command to generate user timer files
2. Update [HostingCommands.php](web/modules/aegir-hosting/hosting/src/Commands/HostingCommands.php) with `hosting:install-timer` subcommand
3. Detect systemd availability and offer choice in setup wizard

#### 3. **Containerized Backend Execution**

**Proposal**: Execute `provision-*` commands in ephemeral containers for isolation.

**Benefits**:
- Eliminates permission conflicts
- Reproducible backend environment
- Remote execution via container runtime APIs
- No SSH key management required

**Implementation**:
```php
// BackendInvoker with container support
public function invoke(string $command, array $args = [], array $options = [], ?string $alias = NULL): array {
  if ($this->config->get('backend.use_containers')) {
    return $this->invokeContainer($command, $args, $options, $alias);
  }
  // ... existing shell execution
}

private function invokeContainer(string $command, array $args, array $options, ?string $alias): array {
  $image = $this->config->get('backend.container_image') ?: 'aegir/provision:latest';
  $cmd = [
    'podman', 'run', '--rm',
    '-v', $this->platformRoot . ':/platform:ro',
    '-v', $this->aegirRoot . ':/aegir',
    $image,
    'drush', $command, ...$args
  ];
  // Execute via ProcessRunner
}
```

**Migration Path**:
1. Create `aegir/provision-runtime` container image with Drush + Provision
2. Add `backend.use_containers` config option
3. Update [BackendInvoker.php](web/modules/aegir-hosting/hosting/src/Service/BackendInvoker.php) with container support
4. Document in copilot-instructions.md

#### 4. **Automated Setup Script**

**Proposal**: Single command setup for all operational requirements.

**Implementation**:
```bash
#!/bin/bash
# install-aegir-ops.sh
set -e

# Check for systemd
if command -v systemctl &> /dev/null; then
  echo "Installing systemd timers..."
  drush hosting:install-timer --user
else
  echo "Installing cron entry..."
  drush hosting:install-cron
fi

# Setup log rotation
cat > /etc/logrotate.d/aegir << EOF
/var/log/aegir/*.log {
  daily
  rotate 7
  compress
  delaycompress
  notifempty
  create 0640 aegir aegir
  sharedscripts
}
EOF

# Install permission helper
drush provision:install-permission-script

echo "Aegir operational setup complete!"
```

**Migration Path**:
1. Add script to `vendor/aegir-provision/resources/install/`
2. Create Drush commands: `hosting:install-cron`, `hosting:install-timer`, `provision:install-permission-script`
3. Update setup documentation in [README.md](vendor/aegir-provision/README.md)

### Migration Strategy: Current → Future

**Phase 1: Compatibility Layer** (Q1 2026)
- Add systemd detection without breaking cron-based installs
- Implement permission helper script, document manual installation
- Add config flags for new features (disabled by default)

**Phase 2: Default to Modern** (Q2 2026)
- Make systemd timers default for new installs
- Auto-detect and suggest container runtime if available
- Migrate existing cron-based installs via upgrade command

**Phase 3: Deprecate Legacy** (Q3 2026)
- Mark cron-based dispatch as deprecated
- Remove manual permission fixing recommendations
- Container-first for remote server execution

## Aegir Eldir Theme (Presentation Layer)

**Purpose**: The Eldir theme ([web/themes/aegir-eldir/](web/themes/aegir-eldir/)) is the official presentation layer for Aegir Hostmaster, providing the visual interface and user experience for all hosting management operations.

**Documentation**: [web/themes/aegir-eldir/doc/eldir-d11.md](web/themes/aegir-eldir/doc/eldir-d11.md) - Complete theme architecture including templates, preprocess hooks, CSS organization, and Aegir-specific UI patterns.

### Theme Architecture Overview

The theme is tightly integrated with hosting entities, providing specialized rendering for:

1. **Hosting entity displays** - Custom templates for sites, platforms, servers, tasks
2. **Task visualization** - Real-time queue status, task logs, and progress indicators
3. **Info tables** - Structured property displays using `item_info_listing` theme hook
4. **Context-aware navigation** - Dynamic menus based on entity type and state
5. **Admin workflows** - Streamlined forms and actions for common operations

**Key Files**:
- [eldir.theme](web/themes/aegir-eldir/eldir.theme) (417 lines) - Preprocess hooks and theme logic
- [eldir.info.yml](web/themes/aegir-eldir/eldir.info.yml) - Theme metadata, regions, libraries
- [templates/](web/themes/aegir-eldir/templates/) - Twig templates for entities and layouts

### Theme-Module Integration Pattern

The theme consumes data from hosting modules through standard Drupal rendering:

```
Entity Render → Preprocess (eldir.theme) → Twig Template → HTML Output
```

**Entity-specific preprocessing**:
```php
// eldir.theme adds metadata attributes for all hosting entities
function eldir_preprocess_entity__hosting_client(&$variables) {
  eldir_add_entity_metadata_attributes($variables);
  // Adds: data-entity-type, data-entity-id, data-view-mode, data-entity-bundle
}

// Similar hooks exist for hosting_task and other entity types
```

**Hosting-specific templates**:
- `hosting-server.html.twig` - Server entity display with service status
- `hosting-queues-table.html.twig` - Task queue table
- `hosting-service-status-cell.html.twig` - Service status indicators
- `item-info-listing.html.twig` - Structured property tables (custom theme hook)

### Custom Theme Hook: item_info_listing

The theme defines a custom rendering pattern for Aegir entity properties:

```php
// In eldir.theme
function eldir_theme($existing, $type, $theme, $path) {
  return [
    'item_info_listing' => [
      'render element' => 'info_listing',
      'template' => 'item-info-listing',
    ],
  ];
}

// Usage in module code (should be implemented but may be missing):
$build['info'] = [
  '#theme' => 'item_info_listing',
  '#items' => [
    ['title' => 'Domain', 'value' => 'example.com'],
    ['title' => 'Platform', 'value' => 'Drupal 11'],
  ],
];
```

**Template structure** ([templates/item-info-listing.html.twig](web/themes/aegir-eldir/templates/item-info-listing.html.twig)):
```twig
{# Renders as table with .hosting-info-table class #}
<table class="hosting-info-table">
  {% for item in items %}
    <tr>
      <td class="item-title">{{ item.title }}</td>
      <td class="item-value">{{ item.value }}</td>
    </tr>
  {% endfor %}
</table>
```

### CSS Architecture and Selectors

The theme preserves legacy selectors from Drupal 7 for backward compatibility with Aegir modules:

**Critical CSS classes** (hosting modules may depend on these):
- Layout: `#page-wrapper`, `.limiter`, `#page`, `#main`, `#right.sidebar`
- Navigation: `#navigation`, `#main-menu`, `#secondary-menu`, `.breadcrumb`
- Console: `#console`, `.messages`, `.error`, `.warning`, `.ok`
- Hosting entities: `.hosting-info-table`, `.hosting-button-enabled`, `.hosting-button-disabled`
- Task system: `#hosting-task-log`, `.hosting-local-tasks`, `.hosting-form`
- Entity types: `.ntype-<type>` (e.g., `.ntype-task`, `.ntype-site`, `.ntype-platform`)

**CSS organization** ([css/](web/themes/aegir-eldir/css/)):
- `base.css` - Typography, reset, form controls
- `layout.css` - Page structure, grid, responsive breakpoints
- `components.css` - Tabs, menus, blocks, buttons, tables
- `aegir.css` - Aegir-specific UI (task tables, info listings, queue forms)

### Preprocess Hooks for Hosting Integration

Key preprocessing functions that enhance hosting entity displays:

```php
// Add 'aegir' body class and path-based classes
function eldir_preprocess_html(&$variables);

// Set up tabs, breadcrumb, and page title with entity type labels
function eldir_preprocess_page(&$variables);

// Add type label to node titles (e.g., "Platform: Drupal 11")
function eldir_preprocess_node(&$variables);

// Convert Aegir info render arrays to item_info_listing structure
function eldir_preprocess_item_info_listing(&$variables);

// Add .hosting-* classes to forms, tables, menus
function eldir_preprocess_form(&$variables);
function eldir_preprocess_table(&$variables);
function eldir_preprocess_menu__main(&$variables);
function eldir_preprocess_menu_local_tasks(&$variables);
```

### Missing and Incomplete Implementations

**1. Entity View Display Integration (CRITICAL)**

**Problem**: Hosting modules define entity view displays but may not properly invoke `item_info_listing` theme hook.

**Expected pattern** (in module entity view builders):
```php
// CORRECT: Use theme system for structured property display
public function viewMultiple(array $entities = []) {
  $build = [];
  foreach ($entities as $entity) {
    $build[$entity->id()] = [
      'info' => [
        '#theme' => 'item_info_listing',
        '#items' => [
          ['title' => $this->t('Name'), 'value' => $entity->label()],
          ['title' => $this->t('Status'), 'value' => $entity->get('status')->value],
        ],
      ],
    ];
  }
  return $build;
}
```

**Anti-pattern** (currently may exist):
```php
// WRONG: Bypass theme system, hardcode HTML
$build['info'] = [
  '#markup' => '<table class="hosting-info-table">...</table>',
];
```

**Files to check**:
- [hosting_site/src/Entity/HostingSite.php](web/modules/aegir-hosting/hosting/hosting_site/src/Entity/HostingSite.php)
- [hosting_platform/src/Entity/HostingPlatform.php](web/modules/aegir-hosting/hosting/hosting_platform/src/Entity/HostingPlatform.php)
- [hosting_server/src/Entity/HostingServer.php](web/modules/aegir-hosting/hosting/hosting_server/src/Entity/HostingServer.php)
- Entity view builders in each hosting submodule

**2. Theme Suggestions for Entity Types**

**Problem**: No `hook_theme_suggestions_HOOK_alter()` implementations to provide Aegir-specific template suggestions.

**Missing implementation** (should be in [eldir.theme](web/themes/aegir-eldir/eldir.theme)):
```php
/**
 * Implements hook_theme_suggestions_node_alter().
 */
function eldir_theme_suggestions_node_alter(array &$suggestions, array $variables) {
  $node = $variables['elements']['#node'];
  $view_mode = $variables['elements']['#view_mode'];
  
  // Add suggestions for Aegir entity node types
  // Allows templates like: node--hosting-site--full.html.twig
  if (str_starts_with($node->bundle(), 'hosting_')) {
    $suggestions[] = 'node__' . $node->bundle();
    $suggestions[] = 'node__' . $node->bundle() . '__' . $view_mode;
  }
}

/**
 * Implements hook_theme_suggestions_page_alter().
 */
function eldir_theme_suggestions_page_alter(array &$suggestions, array $variables) {
  $route_name = \Drupal::routeMatch()->getRouteName();
  
  // Add suggestions for hosting routes
  // Allows templates like: page--hosting-sites.html.twig
  if (str_starts_with($route_name, 'entity.hosting_')) {
    $route_parts = explode('.', $route_name);
    $suggestions[] = 'page__hosting';
    if (isset($route_parts[1])) {
      $suggestions[] = 'page__' . str_replace('_', '__', $route_parts[1]);
    }
  }
}
```

**3. Single Directory Components (SDC)**

**Status**: Documented as "open implementation decision" in architecture docs.

**Proposal**: Create SDC components for reusable Aegir UI elements:
```
web/themes/aegir-eldir/components/
├── server-status/
│   ├── server-status.component.yml
│   ├── server-status.twig
│   └── server-status.css
├── task-log/
│   ├── task-log.component.yml
│   ├── task-log.twig
│   └── task-log.css
└── info-table/
    ├── info-table.component.yml
    ├── info-table.twig
    └── info-table.css
```

**Benefits**:
- Encapsulated styles per component
- Reusable across entity types
- Better separation of concerns
- Easier testing and documentation

**Migration path**: Start with `info-table` component to replace current `item_info_listing` theme hook.

**4. JavaScript Integration**

**Current state**: No JavaScript files in theme directory.

**Missing implementations**:
- Real-time task queue updates (AJAX polling)
- Task log auto-scroll and filtering
- Collapsible info table sections
- Server service status indicators (live updates)
- Form validation for site/platform creation

**Proposed structure**:
```javascript
// js/aegir-tasks.js
(function ($, Drupal) {
  'use strict';
  
  Drupal.behaviors.aegirTaskQueue = {
    attach: function (context, settings) {
      // Poll task queue status every 10 seconds
      // Update task status badges without page reload
    }
  };
  
  Drupal.behaviors.aegirTaskLog = {
    attach: function (context, settings) {
      // Auto-scroll task log output
      // Filter log by severity (errors, warnings, info)
    }
  };
})(jQuery, Drupal);
```

**Library definition** (add to [eldir.libraries.yml](web/themes/aegir-eldir/eldir.libraries.yml)):
```yaml
aegir-tasks:
  version: 1.x
  js:
    js/aegir-tasks.js: {}
  dependencies:
    - core/drupal
    - core/jquery
```

**5. Responsive Design and Breakpoints**

**Current state**: [eldir.breakpoints.yml](web/themes/aegir-eldir/eldir.breakpoints.yml) exists but implementation unclear.

**Missing mobile optimizations**:
- Task queue tables should collapse to cards on mobile
- Info tables should stack title/value vertically on small screens
- Navigation menu should be responsive hamburger menu
- Server list should be scrollable/swipeable on mobile

**Recommended breakpoints**:
```yaml
# eldir.breakpoints.yml
eldir.mobile:
  label: Mobile
  mediaQuery: 'all and (max-width: 640px)'
  weight: 0
  multipliers:
    - 1x
eldir.tablet:
  label: Tablet
  mediaQuery: 'all and (min-width: 641px) and (max-width: 1024px)'
  weight: 1
  multipliers:
    - 1x
eldir.desktop:
  label: Desktop
  mediaQuery: 'all and (min-width: 1025px)'
  weight: 2
  multipliers:
    - 1x
```

**6. Theme Settings UI**

**Current implementation**: [eldir.theme](web/themes/aegir-eldir/eldir.theme) defines settings form alter.

**Incomplete settings**:
- `use_svg_logo` - Implemented in form, not used in templates
- `wide_layout` - Implemented and working (adds `body.wide` class)
- `main_menu_name` / `secondary_menu_name` - Defined but not used in rendering

**Fix required** (in [templates/page.html.twig](web/themes/aegir-eldir/templates/page.html.twig)):
```twig
{# Use SVG logo if setting enabled and available #}
{% if logo %}
  {% set logo_path = use_svg_logo ? logo|replace({'.png': '.svg'}) : logo %}
  <img src="{{ logo_path }}" alt="{{ site_name }}" class="logo" />
{% endif %}
```

### Theme-Module Communication Checklist

When creating new hosting entities or features, ensure:

- ✅ Entity defines proper view displays (full, teaser, default)
- ✅ View builders use `#theme => 'item_info_listing'` for property displays
- ✅ Forms include proper `#form_id` for theme preprocessing
- ✅ Routes follow `entity.hosting_*` naming convention
- ✅ CSS classes follow `.hosting-*` naming pattern
- ✅ Theme suggestions added for custom templates
- ✅ JavaScript behaviors registered with `Drupal.behaviors`
- ✅ Responsive considerations for mobile/tablet views

### Pain Points and Common Issues

**1. Hardcoded HTML in modules**: Some modules may bypass `item_info_listing` and output raw HTML tables. Always use render arrays with `#theme`.

**2. Missing template suggestions**: Without proper `hook_theme_suggestions_HOOK_alter()` implementations, custom templates won't be discovered.

**3. CSS class conflicts**: Aegir-specific classes (`.hosting-*`) must be preserved for backward compatibility with D7 modules that haven't been fully ported.

**4. JavaScript dependency**: AJAX task updates require consistent HTML structure. Changes to task templates must maintain `.task-status`, `.task-log-output` classes.

**5. Entity display modes**: Not all hosting entities define proper view displays. May default to generic rendering without using theme hooks.

### Development Workflow

When working on theme changes:

1. **Check documentation**: [web/themes/aegir-eldir/doc/eldir-d11.md](web/themes/aegir-eldir/doc/eldir-d11.md)
2. **Test entity displays**: View site, platform, server, task entities in full and teaser modes
3. **Verify theme hooks**: `drush theme:debug` to see which templates are used
4. **Clear cache**: `drush cache:rebuild` after theme file changes
5. **Check CSS selectors**: Inspect HTML to ensure `.hosting-*` classes are present
6. **Test responsive**: Use browser dev tools to test mobile/tablet breakpoints

## Key Files for Reference

- [composer.json](composer.json) - Package dependencies, installer paths, Drupal scaffold config
- [vendor/aegir-provision/README.md](vendor/aegir-provision/README.md) - Provision installation and usage overview
- Context implementations: [Context.php](vendor/aegir-provision/src/Core/Context.php), [ContextType.php](vendor/aegir-provision/src/Core/ContextType.php)
- Command surface: [ProvisionCommands.php](vendor/aegir-provision/src/Commands/ProvisionCommands.php)
- Theme architecture: [web/themes/aegir-eldir/doc/eldir-d11.md](web/themes/aegir-eldir/doc/eldir-d11.md)
