# Frontend Component - Aegir Hosting Modules

The **Frontend** component provides the Drupal 11 interface for Aegir. It consists of a suite of modules that handle entity management, forms, task queuing, and user interactions.

## Table of Contents

- [Overview](#overview)
- [Module Structure](#module-structure)
- [Entity Architecture](#entity-architecture)
- [Task Queue System](#task-queue-system)
- [Manager Services](#manager-services)
- [Forms and Validation](#forms-and-validation)
- [Context Registry](#context-registry)
- [Drush Commands](#drush-commands)
- [Development Guidelines](#development-guidelines)

## Overview

**Location**: `web/modules/contrib/aegir-hosting/`

**Purpose**: Provides the Drupal-based frontend interface for managing hosting infrastructure.

**Key Responsibilities**:
- Entity definitions (sites, platforms, servers)
- Forms and validation
- Task queue management
- Backend communication
- Access control
- User interface integration

## Module Structure

### Core Module: `hosting`

**Purpose**: Base module providing core functionality

**Key Components**:
- `HostingContext` entity - Entity ↔ Context registry
- `ContextRegistry` service - Context synchronization
- `BackendInvoker` service - Drush command execution
- `QueueDispatcher` service - Task queue orchestration
- `HostingCommands` - Drush commands (`hosting:*`)
- `HostingSettingsForm` - Admin settings

**Services**:
```yaml
# hosting.services.yml
services:
  hosting.context_registry:
    class: Drupal\hosting\Service\ContextRegistry
    arguments: ['@entity_type.manager', '@file_system', '@logger.factory']
  
  hosting.backend_invoker:
    class: Drupal\hosting\Service\BackendInvoker
    arguments: ['@logger.factory']
  
  hosting.queue_dispatcher:
    class: Drupal\hosting\Service\QueueDispatcher
    arguments: ['@queue', '@entity_type.manager']
```

### Sub-modules

#### `hosting_site`
**Purpose**: Site entity and management

**Key Files**:
- `src/Entity/HostingSite.php` - Site entity definition
- `src/Form/HostingSiteForm.php` - Site create/edit form
- `src/Service/SiteManager.php` - Business logic service
- `hosting_site.routing.yml` - Route definitions
- `hosting_site.links.task.yml` - Entity operation links

**Features**:
- Site creation and management
- Domain validation
- Platform association
- Database server configuration
- Clone and migrate operations

#### `hosting_platform`
**Purpose**: Platform entity and management

**Key Files**:
- `src/Entity/HostingPlatform.php` - Platform entity definition
- `src/Form/HostingPlatformForm.php` - Platform create/edit form
- `src/Service/PlatformManager.php` - Business logic service

**Features**:
- Drupal distribution tracking
- File system path management
- Platform verification
- Site listing
- Update status monitoring

#### `hosting_server`
**Purpose**: Server entity and service management

**Key Files**:
- `src/Entity/HostingServer.php` - Server entity definition
- `src/Entity/HostingServiceInstance.php` - Service configuration
- `src/Form/HostingServerForm.php` - Server create/edit form
- `src/Service/ServerManager.php` - Business logic service

**Features**:
- Web server management (Apache, Nginx)
- Database server management (MySQL, PostgreSQL)
- Service type abstraction
- Remote server support (future)

#### `hosting_task`
**Purpose**: Task queue and execution

**Key Files**:
- `src/Entity/HostingTask.php` - Task entity definition
- `src/Entity/HostingTaskLog.php` - Task log storage
- `src/Service/TaskManager.php` - Task orchestration
- `src/Plugin/QueueWorker/HostingTaskQueueWorker.php` - Queue worker

**Features**:
- Asynchronous task execution
- Task logging and status tracking
- Queue management
- Task chaining and dependencies (future)

#### `hosting_client`
**Purpose**: Client management and multi-tenancy

**Key Files**:
- `src/Entity/HostingClient.php` - Client entity definition
- `src/Form/HostingClientForm.php` - Client create/edit form
- `src/Service/ClientManager.php` - Business logic service

**Features**:
- Client organization management
- Site ownership
- Quota management (future)
- Access control integration

#### `hosting_package`
**Purpose**: Package and distribution tracking

**Key Files**:
- `src/Entity/HostingPackage.php` - Package entity definition
- `src/Service/PackageManager.php` - Package discovery

**Features**:
- Drupal core version tracking
- Module version tracking
- Update status monitoring
- Security advisory integration (future)

## Entity Architecture

### Entity Design Pattern

**Base Interface**: `HostingContextInterface`

All hosting entities implement a common interface:

```php
interface HostingContextInterface extends ContentEntityInterface {
  /**
   * Gets the context name.
   */
  public function getContextName(): string;
  
  /**
   * Gets the context type.
   */
  public function getContextType(): string;
  
  /**
   * Converts entity to context array.
   */
  public function toContext(): array;
}
```

### Site Entity

**Entity ID**: `hosting_site`

**Key Fields**:
- `field_hosting_domain` - Site domain name
- `field_hosting_platform` - Reference to platform entity
- `field_hosting_db_server` - Reference to database server
- `field_hosting_status` - Enabled/disabled/deleted
- `field_hosting_install_profile` - Drupal installation profile
- `field_hosting_language` - Default language
- `field_hosting_client` - Reference to client (owner)

**Methods**:
```php
class HostingSite extends ContentEntityBase implements HostingContextInterface {
  public function getContextName(): string {
    return $this->get('field_hosting_domain')->value;
  }
  
  public function toContext(): array {
    return [
      'type' => 'site',
      'uri' => $this->get('field_hosting_domain')->value,
      'parent' => $this->getPlatform()->getContextName(),
      'db_server' => $this->getDbServer()->getContextName(),
      'web_server' => $this->getWebServer()->getContextName(),
      'root' => $this->getPlatform()->get('field_hosting_root')->value,
    ];
  }
}
```

### Platform Entity

**Entity ID**: `hosting_platform`

**Key Fields**:
- `field_hosting_name` - Platform name
- `field_hosting_root` - File system path
- `field_hosting_web_server` - Reference to web server
- `field_hosting_status` - Enabled/disabled/deleted
- `field_hosting_publish_path` - Public directory path

**Context Example**:
```yaml
# platform_d11.platform.yml
type: platform
root: /var/aegir/platforms/drupal-11
web_server: server_master
publish_path: web
```

### Server Entity

**Entity ID**: `hosting_server`

**Key Fields**:
- `field_hosting_name` - Server name
- `field_hosting_hostname` - Server hostname
- `field_hosting_services` - Service configuration (web, db, etc.)
- `field_hosting_remote` - Is remote server (future)

**Service Configuration**:
```php
$services = [
  'web' => [
    'type' => 'apache',
    'restart_command' => 'sudo systemctl reload apache2',
    'vhost_path' => '/etc/apache2/sites-available',
  ],
  'db' => [
    'type' => 'mysql',
    'db_host' => 'localhost',
    'db_port' => 3306,
  ],
];
```

## Task Queue System

### Task Lifecycle

```
1. Task Creation (Entity Save Hook)
   ↓
2. Queue Insertion (QueueDispatcher)
   ↓
3. Cron Processing (QueueWorker)
   ↓
4. Backend Invocation (BackendInvoker)
   ↓
5. Status Update (TaskManager)
```

### Task Creation

Tasks are automatically created via entity save hooks:

```php
/**
 * Implements hook_ENTITY_TYPE_insert().
 */
function hosting_site_hosting_site_insert(HostingSite $site) {
  $task = HostingTask::create([
    'type' => 'install',
    'target_entity_type' => 'hosting_site',
    'target_entity_id' => $site->id(),
    'status' => 'queued',
  ]);
  $task->save();
}
```

### Queue Worker

**Plugin ID**: `hosting_task_queue_worker`

```php
/**
 * @QueueWorker(
 *   id = "hosting_task_queue_worker",
 *   title = @Translation("Hosting Task Queue Worker"),
 *   cron = {"time" => 60}
 * )
 */
class HostingTaskQueueWorker extends QueueWorkerBase {
  public function processItem($data) {
    $task = HostingTask::load($data->task_id);
    
    // Update status
    $task->set('status', 'processing');
    $task->save();
    
    // Execute backend command
    $result = $this->backendInvoker->execute(
      'provision-' . $task->get('type')->value,
      '@' . $task->getTargetEntity()->getContextName()
    );
    
    // Update task with result
    $task->set('status', $result['success'] ? 'completed' : 'error');
    $task->set('log', $result['output']);
    $task->save();
  }
}
```

### Task Types

| Task Type | Description | Command |
|-----------|-------------|---------|
| `install` | Install new site | `provision-install` |
| `verify` | Verify configuration | `provision-verify` |
| `delete` | Delete site | `provision-delete` |
| `clone` | Clone site | `provision-clone` |
| `migrate` | Migrate to new platform | `provision-migrate` |
| `backup` | Backup site | `provision-backup` |
| `restore` | Restore from backup | `provision-restore` |

## Manager Services

Manager services encapsulate business logic and validation.

### SiteManager Service

**Service ID**: `hosting_site.site_manager`

**Responsibilities**:
- Domain validation
- Site status management
- Clone/migrate coordination
- Backup management

**Example**:
```php
class SiteManager {
  public function isDomainValid(string $domain): bool {
    // Validate domain format
    if (!preg_match('/^[a-z0-9.-]+\.[a-z]{2,}$/i', $domain)) {
      return FALSE;
    }
    
    // Check if domain already exists
    $existing = $this->entityTypeManager
      ->getStorage('hosting_site')
      ->loadByProperties(['field_hosting_domain' => $domain]);
    
    return empty($existing);
  }
  
  public function cloneSite(HostingSite $source, string $new_domain): HostingSite {
    // Create new site entity
    $clone = $source->createDuplicate();
    $clone->set('field_hosting_domain', $new_domain);
    $clone->save();
    
    // Create clone task
    $task = HostingTask::create([
      'type' => 'clone',
      'target_entity' => $clone,
      'source_entity' => $source,
    ]);
    $task->save();
    
    return $clone;
  }
}
```

### PlatformManager Service

**Service ID**: `hosting_platform.platform_manager`

**Responsibilities**:
- Path validation
- Drupal detection
- Site listing
- Platform verification

### ServerManager Service

**Service ID**: `hosting_server.server_manager`

**Responsibilities**:
- Service validation
- Connection testing
- Configuration generation
- Service restart coordination

## Forms and Validation

### Form Design Pattern

**Base Class**: `ContentEntityForm`

```php
class HostingSiteForm extends ContentEntityForm {
  public function form(array $form, FormStateInterface $form_state) {
    $form = parent::form($form, $form_state);
    
    // Add custom form elements
    $form['domain_validation'] = [
      '#type' => 'item',
      '#markup' => '<div id="domain-validation"></div>',
    ];
    
    return $form;
  }
  
  public function validateForm(array &$form, FormStateInterface $form_state) {
    parent::validateForm($form, $form_state);
    
    $domain = $form_state->getValue('field_hosting_domain')[0]['value'];
    
    // Delegate validation to manager service
    if (!$this->siteManager->isDomainValid($domain)) {
      $form_state->setError(
        $form['field_hosting_domain'],
        $this->t('This domain is already in use or invalid.')
      );
    }
  }
}
```

### Validation Rules

**Domain Names**:
- Lowercase alphanumeric with dots and hyphens
- Valid TLD required
- Unique across all sites

**File Paths**:
- Absolute paths only
- Must be readable/writable
- Must contain valid Drupal installation

**Server Names**:
- Alphanumeric with underscores
- Prefix conventions: `server_*`

## Context Registry

### Purpose

The Context Registry maintains bidirectional synchronization between Drupal entities and Drush contexts (YAML aliases).

### Service Definition

**Service ID**: `hosting.context_registry`

**Class**: `Drupal\hosting\Service\ContextRegistry`

### Key Methods

```php
class ContextRegistry {
  /**
   * Writes entity data to YAML context file.
   */
  public function writeContext(HostingContextInterface $entity): void {
    $context_name = $entity->getContextName();
    $context_data = $entity->toContext();
    
    $yaml_path = $this->getContextPath($context_name, $entity->getContextType());
    $this->fileSystem->saveData(
      Yaml::encode($context_data),
      $yaml_path,
      FileSystemInterface::EXISTS_REPLACE
    );
  }
  
  /**
   * Reads context data from YAML file.
   */
  public function readContext(string $context_name, string $type): array {
    $yaml_path = $this->getContextPath($context_name, $type);
    
    if (!file_exists($yaml_path)) {
      throw new \Exception("Context not found: $context_name");
    }
    
    return Yaml::parseFile($yaml_path);
  }
  
  /**
   * Gets the file path for a context.
   */
  protected function getContextPath(string $name, string $type): string {
    return sprintf(
      '%s/.drush/sites/%s.%s.yml',
      $this->getHomeDirectory(),
      $name,
      $type
    );
  }
}
```

### Integration with Entities

```php
/**
 * Implements hook_ENTITY_TYPE_presave().
 */
function hosting_hosting_site_presave(HostingSite $site) {
  // Write context before saving entity
  \Drupal::service('hosting.context_registry')->writeContext($site);
}

/**
 * Implements hook_ENTITY_TYPE_delete().
 */
function hosting_hosting_site_delete(HostingSite $site) {
  // Remove context file when entity is deleted
  \Drupal::service('hosting.context_registry')->deleteContext(
    $site->getContextName(),
    'site'
  );
}
```

## Drush Commands

### Frontend Drush Commands

**Command File**: `src/Commands/HostingCommands.php`

**Available Commands**:

#### `hosting:sync-contexts`
Synchronizes contexts from YAML files to entities.

```bash
drush hosting:sync-contexts
```

**Use Case**: Import existing Aegir 3.x sites into Aegir 4.x

#### `hosting:verify-all`
Queues verify tasks for all hosting entities.

```bash
drush hosting:verify-all --entity-type=site
```

#### `hosting:task-run`
Processes queued tasks immediately (without waiting for cron).

```bash
drush hosting:task-run
```

## Development Guidelines

### Entity Development

**DO**:
- ✓ Use field API for all entity properties
- ✓ Implement `HostingContextInterface`
- ✓ Delegate business logic to manager services
- ✓ Use entity query for data access
- ✓ Provide entity operation links

**DON'T**:
- ✗ Store @ prefix in database
- ✗ Hardcode paths or service names
- ✗ Bypass abstraction layers
- ✗ Implement business logic in forms
- ✗ Access context files directly

### Form Development

**DO**:
- ✓ Extend `ContentEntityForm`
- ✓ Use manager services for validation
- ✓ Provide clear error messages
- ✓ Use AJAX for dynamic updates
- ✓ Follow Drupal form API patterns

**DON'T**:
- ✗ Put validation logic in form class
- ✗ Directly execute backend commands
- ✗ Skip CSRF token validation
- ✗ Hardcode form element values

### Service Development

**DO**:
- ✓ Inject dependencies via constructor
- ✓ Use dependency injection
- ✓ Follow single responsibility principle
- ✓ Provide interfaces for testability
- ✓ Log all operations

**DON'T**:
- ✗ Use static methods
- ✗ Access global state directly
- ✗ Mix concerns in one service
- ✗ Skip error handling

## Testing

### Unit Tests

**Location**: `tests/src/Unit/`

**Example**:
```php
class SiteManagerTest extends UnitTestCase {
  public function testDomainValidation() {
    $manager = new SiteManager(...);
    
    $this->assertTrue($manager->isDomainValid('example.com'));
    $this->assertFalse($manager->isDomainValid('invalid'));
    $this->assertFalse($manager->isDomainValid('UPPERCASE.COM'));
  }
}
```

### Functional Tests

**Location**: `tests/src/Functional/`

**Example**:
```php
class SiteCreationTest extends BrowserTestBase {
  public function testCreateSite() {
    $admin = $this->drupalCreateUser(['administer sites']);
    $this->drupalLogin($admin);
    
    $this->drupalGet('/admin/hosting/sites/add');
    $this->assertSession()->statusCodeEquals(200);
    
    $this->submitForm([
      'field_hosting_domain[0][value]' => 'test.example.com',
      'field_hosting_platform' => 1,
    ], 'Save');
    
    $this->assertSession()->pageTextContains('Site created');
  }
}
```

## Next Steps

- **[Backend Documentation](Backend.md)** - Learn about the provision system
- **[Theme Documentation](Theme.md)** - Explore the Eldir theme
- **[Architecture Overview](HOME.md)** - Return to main documentation

---

**Questions?** Check the [hosting module AI instructions](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md) for detailed technical guidance.
