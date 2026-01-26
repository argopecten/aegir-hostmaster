# Aegir Hostmaster - AI Coding Agent Instructions

## Project Overview

**Aegir Hostmaster** is a complete Drupal hosting automation platform running on Drupal 11. It combines three distinct components into an integrated system for managing multi-site Drupal infrastructure:

1. **Frontend (aegir-hosting)** - Drupal 11 modules providing the entity layer, forms, and task management
2. **Backend (aegir-provision)** - Drush 13 extension automating infrastructure operations  
3. **Theme (aegir-eldir)** - Drupal 11 theme providing the hosting management UI

**System Architecture**: Entity-driven frontend with queue-based backend dispatch. User actions on Drupal entities (sites, platforms, servers) trigger tasks that execute Provision commands via Drush, operating on immutable context data stored as YAML aliases.

**Target Environment**: Ubuntu 24.04 LTS, PHP 8.3+, Apache 2.4+ with PHP-FPM, MySQL 8.0+, Drupal 11

## Documentation Structure

This project uses **distributed documentation** - each component has its own AI instructions:

- **[drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md](drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)** - Backend/Provision system (contexts, services, Drush commands)
- **[web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md](web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)** - Frontend/Entity system (entities, forms, task queue)
- **[web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md](web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)** - Theme/UI system (templates, CSS, JavaScript)
- **[TODO-RECIPES.md](.github/TODO-RECIPES.md)** - Drupal Recipes implementation plan (modernize installation)

**This document** covers overarching architecture, integration points, and cross-cutting concerns.


## System Architecture

### Three-Tier Design

```
┌─────────────────────────────────────────────────────────────┐
│                    DRUPAL 11 FRONTEND                        │
│                  (aegir-hosting modules)                     │
│                                                              │
│  User Interface → Entities → Forms → Task Creation          │
│     HostingSite, HostingPlatform, HostingServer            │
│                         ↓                                    │
│                  ContextRegistry                             │
│                 (Entity ↔ Context Sync)                      │
│                         ↓                                    │
│                 Drush Alias YAML                             │
│            ~/.drush/sites/*.site.yml                        │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    TASK QUEUE LAYER                          │
│                                                              │
│  Task Queue → Queue Worker → BackendInvoker                 │
│                         ↓                                    │
│              Shell Execute: drush provision-*                │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│                    DRUSH BACKEND                             │
│                  (aegir-provision extension)                 │
│                                                              │
│  Drush Commands → ProvisionManager → Services                │
│     provision-install, provision-verify, etc.               │
│                         ↓                                    │
│  Apache vhosts • MySQL databases • settings.php • SSL       │
└─────────────────────────────────────────────────────────────┘
                          ↓
┌─────────────────────────────────────────────────────────────┐
│               INFRASTRUCTURE LAYER                           │
│                                                              │
│   Apache 2.4 + PHP-FPM 8.3 • MySQL 8.0 • File System       │
│   Ubuntu 24.04 LTS                                           │
└─────────────────────────────────────────────────────────────┘
```

### Key Concepts

**Context**: Immutable data structure representing infrastructure components (server, platform, site). Stored as Drush YAML aliases in `~/.drush/sites/`. Backend operates exclusively on contexts.

**Entity**: Drupal content entity representing hosting objects. Provides forms, validation, access control. Frontend operates exclusively on entities.

**Context Registry**: Bidirectional mapping service maintaining entity ↔ context synchronization. Writes Drush alias YAML when entities save.

**Task**: Queued operation that bridges frontend and backend. Creates via entity save hooks, executes via queue worker calling BackendInvoker, which shells out to Drush provision commands.

### Data Flow Example (Site Creation)

1. User submits site creation form → `HostingSiteForm::save()`
2. Entity validation (domain format, uniqueness) via `SiteManager`
3. Entity saved to database → `HostingSite::postSave()`
4. Context sync triggered → `ContextRegistry::register('example.com', 'hosting_site', 123)`
5. Drush alias written → `~/.drush/sites/example.com.site.yml`
6. Task queued → `TaskManager::createTask($site, 'install')`
7. Queue worker picks task → `HostingTaskQueueWorker::processItem()`
8. Backend invoked → `BackendInvoker::invoke('install', ['example.com'])`
9. Drush executes → `drush provision-install @example.com`
10. ProvisionManager orchestrates → Database creation, settings.php, vhost, `drush site:install`
11. Result logged → `HostingTaskLog` entities
12. Task completed → `HostingTask` status updated

**Critical Principle**: Forms NEVER directly manipulate contexts or call Provision. All operations go through: Entity → Task → Queue → Backend.


## Integration Points

### Frontend → Backend Communication

**ContextRegistry Service** ([hosting/src/Service/ContextRegistry.php](web/modules/contrib/aegir-hosting/src/Service/ContextRegistry.php)):
- Translates entity fields to context properties
- Writes Drush alias YAML to `~/.drush/sites/`
- Maintains HostingContext entity (entity_type, entity_id, context_name)
- Creates path aliases (/hosting/c/{context_name})

**Field → Property Mappings**:
| Entity Type | Entity Field | Context Property |
|-------------|--------------|------------------|
| HostingSite | domain | uri |
| HostingSite | platform (ref) | platform (name) |
| HostingSite | db_server (ref) | db_server (name) |
| HostingPlatform | publish_path | root |
| HostingServer | hostname | remote_host |

**BackendInvoker Service** ([hosting/src/Service/BackendInvoker.php](web/modules/contrib/aegir-hosting/src/Service/BackendInvoker.php)):
- Executes `drush provision-*` commands via Process API
- Configurable Drush path and server alias
- Returns `['output' => string, 'error' => string, 'exit_code' => int]`
- Timeout handling (default 1 hour)

### Backend → Infrastructure Communication

**Service Layer** (see [Provision AI-INSTRUCTIONS.md](drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)):
- **ApacheService**: Generates vhosts, manages SSL, reloads Apache
- **MySqlService**: Database CRUD, user grants, dump/restore
- **SettingsWriter**: Generates Drupal settings.php with credentials
- **Filesystem**: File operations with proper permissions (aegir:www-data)

**Configuration Templates** (Twig):
- Apache vhost (HTTP + HTTPS)
- PHP-FPM pools (future)
- Drupal settings.php

### Theme → Module Communication

**Custom Theme Hook** ([eldir/templates/item-info-listing.html.twig](web/themes/contrib/aegir-eldir/templates/item-info-listing.html.twig)):
```php
// In module view builder
$build['info'] = [
  '#theme' => 'item_info_listing',
  '#title' => 'Site Information',
  '#items' => [
    ['title' => 'Domain', 'value' => 'example.com'],
    ['title' => 'Platform', 'value' => $platform_link],
  ],
];
```

**Preprocess Integration** ([eldir.theme](web/themes/contrib/aegir-eldir/eldir.theme)):
- Adds entity metadata attributes (data-entity-type, data-entity-id)
- Adds `.hosting-*` CSS classes
- Enhances page title with entity type labels

**CSS Selector Contract**:
Modules must use these CSS classes for theme compatibility:
- `.hosting-info-table` - Property tables
- `.hosting-form` - All hosting forms
- `.hosting-button-enabled`, `.hosting-button-disabled` - Action buttons
- `.ntype-site`, `.ntype-platform`, `.ntype-server`, `.ntype-task` - Entity type indicators

## Development Workflow


### Component-Specific Development

See repository-specific AI instructions for detailed guidance:

- **Backend development**: [Provision AI-INSTRUCTIONS.md](drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
  - Adding new services
  - Creating provision commands
  - Working with contexts
  - Template development

- **Frontend development**: [Hosting AI-INSTRUCTIONS.md](web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
  - Creating entities
  - Building forms with manager services
  - Task system integration
  - Entity ↔ Context synchronization

- **Theme development**: [Eldir AI-INSTRUCTIONS.md](web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)
  - Template creation
  - CSS architecture
  - JavaScript behaviors
  - Responsive design

### Cross-Cutting Conventions

**Composer Package Management**:
- Never manually edit `web/core/`, `web/modules/contrib/`, `vendor/`
- Add modules: `composer require drupal/module_name`
- Custom code: `web/modules/custom/`, `web/themes/custom/`
- Drupal recipes: `composer require drupal/recipe_name`

**Settings Pattern**:
- Managed sites: settings.php generated by Provision (DO NOT EDIT)
- Developer overrides: `local.settings.php` (not version controlled)
- Hostmaster site: Standard Drupal configuration management

**Naming Conventions**:
- Context names: Lowercase, no spaces, no @ prefix in storage
  - Sites: Use domain (example.com)
  - Platforms: Prefix with 'platform_' (platform_d11)
  - Servers: Prefix with 'server_' (server_master)
- Entity IDs: Standard Drupal entity ID format
- Routes: `entity.hosting_{type}.{operation}` format
- Services: `hosting.{service_name}` or `hosting_{module}.{service}`

**File Permissions** (Ubuntu 24.04 LTS):
- Owner: `aegir` user
- Group: `www-data` group
- Directories: 0750 (configs), 0755 (platforms), 0775 (public files)
- Files: 0640 (configs), 0644 (vhosts), 0664 (settings.php)
- SSL keys: 0600 (secure)

## Common Anti-Patterns

### ❌ Don't bypass abstraction layers

```php
// WRONG: Direct context manipulation from frontend
file_put_contents("~/.drush/sites/example.com.site.yml", yaml_emit($data));

// CORRECT: Use entity API
$site = HostingSite::create(['domain' => 'example.com', ...]);
$site->save();  // Triggers automatic context sync
```

```php
// WRONG: Call backend directly from form
public function submitForm() {
  shell_exec('drush provision-install example.com');
}

// CORRECT: Queue task through TaskManager
public function submitForm() {
  $this->taskManager->createTask($entity, 'install');
}
```

### ❌ Don't store @ prefix in database

```php
// WRONG: Store alias format
$entity->set('context_name', '@example.com');

// CORRECT: Store canonical name
$entity->set('context_name', 'example.com');
```

### ❌ Don't hardcode paths or services

```php
// WRONG: Hardcode infrastructure
$vhost = '/var/aegir/config/apache/vhost.d/site.conf';
exec("mysql -u root -p{$pass} ...");

// CORRECT: Use service abstractions
$vhost = $this->configPaths->vhostPath($server, $site);
$this->dbService->createDatabase($site);
```

### ❌ Don't skip manager services in forms

```php
// WRONG: Business logic in form validation
public function validateForm() {
  if (!preg_match('/^[a-z0-9.-]+$/', $domain)) { ... }
}

// CORRECT: Delegate to manager service
public function validateForm() {
  if (!$this->siteManager->isDomainValid($domain)) { ... }
}
```

### ❌ Don't bypass theme system

```twig
{# WRONG: Hardcode HTML #}
<table class="hosting-info-table">
  <tr><td>Domain</td><td>{{ domain }}</td></tr>
</table>

{# CORRECT: Use theme hook #}
{{ {'#theme': 'item_info_listing', '#items': items} }}
```

## System Requirements

**Operating System**: Ubuntu 24.04 LTS (ONLY - no multi-distro support)

**PHP**: 8.3+ with extensions:
- php8.3-cli, php8.3-fpm
- php8.3-mysql, php8.3-gd, php8.3-curl, php8.3-xml, php8.3-mbstring, php8.3-zip

**Web Server**: Apache 2.4+ with modules:
- mod_rewrite, mod_ssl, mod_proxy_fcgi, mod_headers

**Database**: MySQL 8.0+ or MariaDB 10.6+

**Drupal**: 11.x

**Drush**: 13.x

**System Tools**: tar, gzip, rsync, openssl

## Debugging and Testing

### Context Inspection

```bash
# View context as Drush sees it
drush site:alias @example.com

# View raw context YAML
cat ~/.drush/sites/example.com.site.yml

# Check entity ↔ context mapping
drush sql:query "SELECT * FROM hosting_context WHERE context_name='example.com'"

# Force context regeneration
drush hosting:sync-contexts
```

### Task Debugging

```bash
# View task queue
drush queue:list hosting_task

# Manually run a task
drush php:eval "\Drupal::service('hosting_task.manager')->runTaskId(123);"

# View task logs
drush sql:query "SELECT * FROM hosting_task_log WHERE task_id=123"

# Enable dispatch
drush hosting:setup

# Test dispatch
drush hosting:dispatch
```

### Backend Testing

```bash
# Verify context (regenerate configs)
drush provision-verify @example.com

# Check Apache config syntax
sudo apache2ctl -t

# Check Apache vhosts
ls -la /var/aegir/config/apache/vhost.d/
cat /var/aegir/config/apache/vhost.d/example.com.conf

# Test database connectivity
mysql -u example_com_user -p example_com
```

### Frontend Testing

```bash
# Clear Drupal cache
drush cache:rebuild

# Check entity definitions
drush entity:info

# View field definitions
drush field:info hosting_site

# Test form validation
# Use UI or write PHPUnit tests

# Check permissions
drush user:role:list
```

## Future Development Goals

### High Priority (Core Functionality)

**Backend (Provision)**:
1. PHP-FPM pool per-site configuration
2. Let's Encrypt ACME v2 integration with auto-renewal
3. Context schema validation (JSON Schema)
4. Operation rollback/transaction system
5. PostgreSQL service implementation

**Frontend (Hosting)**:
6. Complete entity field definitions (all fields properly defined)
7. Manager services for all entities (business logic separation)
8. Task priority and dependency system
9. Client entity and permissions
10. Package tracking and update notifications

**Theme (Eldir)**:
11. Complete JavaScript implementation (task queue updates, log filtering)
12. Mobile responsive optimization
13. Theme suggestions (hook_theme_suggestions_HOOK_alter)
14. Accessibility improvements (WCAG 2.1 AA)
15. Single Directory Components (SDC) migration

### Medium Priority (Enhanced Features)

**Backend**:
16. Nginx service as Apache alternative
17. Remote server execution via SSH
18. Backup compression and remote storage (S3)
19. Database replication support
20. Performance monitoring and metrics

**Frontend**:
21. Site cloning workflow
22. Platform migration workflow
23. Bulk operations (enable/disable/migrate many sites)
24. Import/export functionality
25. REST API for external integrations

**Theme**:
26. Dark mode support
27. CSS custom properties (theming system)
28. Advanced filtering and search
29. Drag-and-drop task reordering
30. Style guide / component library

### Low Priority (Advanced Features)

31. Container-based backend execution
32. Distributed queue workers (multi-server)
33. High availability / failover configuration
34. Billing system integration
35. Automated scaling and self-healing

## Breaking Changes Allowed

Since this is a modernization project for Drupal 11, **breaking changes from Drupal 7 Aegir are acceptable**:

- Remove Drupal 7 compatibility code
- Change database schema (provide update hooks)
- Rename entities, fields, or services
- Change context property names
- Modify task queue architecture
- Remove obsolete features
- Change URL patterns
- Update theme selectors (with migration guide)

**Migration Strategy**: Document changes clearly but do not maintain backward compatibility with Aegir 3.x (Drupal 7).

## Key Files Reference

### Configuration
- [composer.json](composer.json) - Package dependencies, installer paths
- [drush/drush.yml](drush/drush.yml) - Drush configuration
- [.gitignore](.gitignore) - Version control exclusions

### Backend (Provision)
- [drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md](drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md) - Complete backend documentation
- [drush/Commands/contrib/aegir-provision/src/Commands/ProvisionCommands.php](drush/Commands/contrib/aegir-provision/src/Commands/ProvisionCommands.php) - Drush commands
- [drush/Commands/contrib/aegir-provision/src/Provision/ProvisionManager.php](drush/Commands/contrib/aegir-provision/src/Provision/ProvisionManager.php) - Central orchestrator
- [drush/Commands/contrib/aegir-provision/src/Core/Context.php](drush/Commands/contrib/aegir-provision/src/Core/Context.php) - Context data structure

### Frontend (Hosting)
- [web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md](web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md) - Complete frontend documentation
- [web/modules/contrib/aegir-hosting/src/Service/ContextRegistry.php](web/modules/contrib/aegir-hosting/src/Service/ContextRegistry.php) - Entity ↔ Context sync
- [web/modules/contrib/aegir-hosting/src/Service/BackendInvoker.php](web/modules/contrib/aegir-hosting/src/Service/BackendInvoker.php) - Backend command execution
- [web/modules/contrib/aegir-hosting/hosting_task/src/Service/TaskManager.php](web/modules/contrib/aegir-hosting/hosting_task/src/Service/TaskManager.php) - Task management

### Theme (Eldir)
- [web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md](web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md) - Complete theme documentation
- [web/themes/contrib/aegir-eldir/eldir.theme](web/themes/contrib/aegir-eldir/eldir.theme) - Preprocess hooks
- [web/themes/contrib/aegir-eldir/templates/item-info-listing.html.twig](web/themes/contrib/aegir-eldir/templates/item-info-listing.html.twig) - Custom theme hook
- [web/themes/contrib/aegir-eldir/css/aegir.css](web/themes/contrib/aegir-eldir/css/aegir.css) - Hosting-specific styles
