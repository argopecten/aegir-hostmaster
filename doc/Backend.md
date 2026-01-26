# Backend Component - Aegir Provision System

The **Backend** component is a Drush extension that automates infrastructure operations. It handles the actual work of creating Apache vhosts, MySQL databases, installing Drupal sites, and managing the file system.

## Table of Contents

- [Overview](#overview)
- [Context System](#context-system)
- [Service Architecture](#service-architecture)
- [Drush Commands](#drush-commands)
- [Operations](#operations)
- [Configuration Management](#configuration-management)
- [Development Guidelines](#development-guidelines)

## Overview

**Location**: `drush/Commands/contrib/aegir-provision/`

**Purpose**: Provides infrastructure automation for Aegir hosting operations.

**Key Responsibilities**:
- Read contexts from YAML aliases
- Execute infrastructure operations (install, verify, delete, etc.)
- Manage Apache vhosts and MySQL databases
- Generate Drupal settings.php files
- Handle SSL certificates
- Perform file system operations

**Key Principle**: The backend operates **exclusively on contexts** - it never directly accesses the Drupal database.

## Context System

### What is a Context?

A **context** is an immutable data structure representing an infrastructure component. Contexts are stored as Drush alias YAML files in `~/.drush/sites/`.

### Context Types

#### Site Context

Represents a Drupal site installation.

**File**: `~/.drush/sites/example.com.site.yml`

```yaml
type: site
parent: platform_d11
db_server: server_master
web_server: server_master
uri: example.com
root: /var/aegir/platforms/drupal-11
site_path: sites/example.com
db_name: example_com
db_user: example_com
db_password: secret123
profile: standard
language: en
```

**Key Properties**:
- `type` - Always "site"
- `parent` - Platform context name
- `uri` - Primary domain name
- `db_server` - Database server context
- `web_server` - Web server context
- `root` - Drupal codebase path
- `site_path` - Sites directory relative path

#### Platform Context

Represents a Drupal codebase/distribution.

**File**: `~/.drush/sites/platform_d11.platform.yml`

```yaml
type: platform
web_server: server_master
root: /var/aegir/platforms/drupal-11
publish_path: web
```

**Key Properties**:
- `type` - Always "platform"
- `web_server` - Web server context
- `root` - Absolute file system path
- `publish_path` - Public directory (web/ or docroot/)

#### Server Context

Represents a service provider (Apache, MySQL, etc.).

**File**: `~/.drush/sites/server_master.server.yml`

```yaml
type: server
services:
  web:
    type: apache
    restart_command: sudo systemctl reload apache2
    config_path: /etc/apache2/sites-available
  db:
    type: mysql
    host: localhost
    port: 3306
    root_password: secret
```

**Key Properties**:
- `type` - Always "server"
- `services` - Service configuration array

### Context Loading

```php
/**
 * Load a context by name.
 */
$context = \Drush\Drush::aliasManager()->get('@example.com');

/**
 * Get context properties.
 */
$uri = $context->get('uri');
$root = $context->get('root');
$db_name = $context->get('db_name');
```

## Service Architecture

### ProvisionManager

**Purpose**: Central orchestrator for all backend operations.

**Class**: `Drupal\provision\ProvisionManager`

**Responsibilities**:
- Load and validate contexts
- Dispatch operations to appropriate services
- Coordinate multi-service operations
- Handle transaction rollback

**Example**:
```php
class ProvisionManager {
  public function install(Context $context): ProvisionResult {
    // Validate context
    $this->validateContext($context);
    
    // Get required services
    $webService = $this->getService($context, 'web');
    $dbService = $this->getService($context, 'db');
    
    // Execute operation
    try {
      $dbService->createDatabase($context);
      $webService->createVhost($context);
      $this->installDrupal($context);
      
      return ProvisionResult::success('Site installed');
    }
    catch (\Exception $e) {
      $this->rollback($context);
      return ProvisionResult::error($e->getMessage());
    }
  }
}
```

### Service Classes

Services handle specific infrastructure concerns.

#### ApacheService

**Purpose**: Manage Apache web server configuration.

**Key Methods**:

```php
class ApacheService {
  /**
   * Creates Apache vhost configuration.
   */
  public function createVhost(Context $context): void {
    $vhost_content = $this->generateVhostConfig($context);
    $vhost_path = $this->getVhostPath($context);
    
    file_put_contents($vhost_path, $vhost_content);
    
    // Enable site
    $this->execute("sudo a2ensite {$context->get('uri')}");
    
    // Reload Apache
    $this->reloadApache();
  }
  
  /**
   * Generates vhost configuration content.
   */
  protected function generateVhostConfig(Context $context): string {
    $root = $context->get('root');
    $publish = $context->get('publish_path', '');
    $docroot = rtrim("$root/$publish", '/');
    
    return <<<EOT
<VirtualHost *:80>
  ServerName {$context->get('uri')}
  DocumentRoot $docroot
  
  <Directory $docroot>
    Options FollowSymLinks
    AllowOverride All
    Require all granted
  </Directory>
  
  <FilesMatch \.php$>
    SetHandler "proxy:unix:/run/php/php8.3-fpm.sock|fcgi://localhost"
  </FilesMatch>
  
  ErrorLog \${APACHE_LOG_DIR}/{$context->get('uri')}-error.log
  CustomLog \${APACHE_LOG_DIR}/{$context->get('uri')}-access.log combined
</VirtualHost>
EOT;
  }
}
```

#### MysqlService

**Purpose**: Manage MySQL database operations.

**Key Methods**:

```php
class MysqlService {
  /**
   * Creates database and user for a site.
   */
  public function createDatabase(Context $context): void {
    $db_name = $context->get('db_name');
    $db_user = $context->get('db_user');
    $db_pass = $context->get('db_password');
    
    // Create database
    $this->query("CREATE DATABASE IF NOT EXISTS `{$db_name}`");
    
    // Create user and grant privileges
    $this->query("CREATE USER IF NOT EXISTS '{$db_user}'@'localhost' IDENTIFIED BY '{$db_pass}'");
    $this->query("GRANT ALL PRIVILEGES ON `{$db_name}`.* TO '{$db_user}'@'localhost'");
    $this->query("FLUSH PRIVILEGES");
  }
  
  /**
   * Drops database and user.
   */
  public function deleteDatabase(Context $context): void {
    $db_name = $context->get('db_name');
    $db_user = $context->get('db_user');
    
    $this->query("DROP DATABASE IF EXISTS `{$db_name}`");
    $this->query("DROP USER IF EXISTS '{$db_user}'@'localhost'");
  }
  
  /**
   * Executes MySQL query using root credentials.
   */
  protected function query(string $sql): void {
    $root_password = $this->getServerContext()->get('services.db.root_password');
    
    $command = sprintf(
      'mysql -u root -p%s -e %s',
      escapeshellarg($root_password),
      escapeshellarg($sql)
    );
    
    $this->execute($command);
  }
}
```

#### SiteService

**Purpose**: Manage Drupal site operations.

**Key Methods**:

```php
class SiteService {
  /**
   * Installs Drupal site.
   */
  public function installSite(Context $context): void {
    $root = $context->get('root');
    $uri = $context->get('uri');
    $profile = $context->get('profile', 'standard');
    
    // Generate settings.php
    $this->generateSettings($context);
    
    // Run Drupal installation
    $this->execute([
      'drush',
      'site:install',
      $profile,
      "--root={$root}",
      "--uri={$uri}",
      "--db-url=mysql://{$context->get('db_user')}:{$context->get('db_password')}@localhost/{$context->get('db_name')}",
      '--account-name=admin',
      '--account-pass=' . $this->generatePassword(),
      '-y',
    ]);
  }
  
  /**
   * Generates settings.php file.
   */
  protected function generateSettings(Context $context): void {
    $site_path = $context->get('root') . '/' . $context->get('site_path');
    $settings_path = $site_path . '/settings.php';
    
    $settings = $this->generateSettingsContent($context);
    
    // Ensure directory exists
    if (!is_dir($site_path)) {
      mkdir($site_path, 0755, true);
    }
    
    // Write settings.php
    file_put_contents($settings_path, $settings);
    chmod($settings_path, 0444); // Read-only
  }
  
  /**
   * Generates settings.php content.
   */
  protected function generateSettingsContent(Context $context): string {
    $db_name = $context->get('db_name');
    $db_user = $context->get('db_user');
    $db_pass = $context->get('db_password');
    
    return <<<PHP
<?php
/**
 * @file
 * Aegir-generated Drupal settings file.
 * 
 * DO NOT EDIT THIS FILE MANUALLY.
 * It will be regenerated by Aegir verify tasks.
 */

\$databases['default']['default'] = [
  'database' => '$db_name',
  'username' => '$db_user',
  'password' => '$db_pass',
  'host' => 'localhost',
  'port' => '3306',
  'driver' => 'mysql',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
];

\$settings['hash_salt'] = '{$this->generateHashSalt()}';
\$settings['trusted_host_patterns'] = [
  '^{$context->get('uri')}$',
];
\$settings['file_private_path'] = 'sites/{$context->get('uri')}/private';
\$config_directories['sync'] = 'sites/{$context->get('uri')}/config/sync';

// Include local settings if present
if (file_exists(\$app_root . '/' . \$site_path . '/local.settings.php')) {
  include \$app_root . '/' . \$site_path . '/local.settings.php';
}
PHP;
  }
}
```

## Drush Commands

### Command Structure

All Provision commands follow a consistent pattern:

```php
/**
 * @command provision-install
 * @param string $target Site alias (@example.com)
 * @usage provision-install @example.com
 *   Install a Drupal site
 */
public function install(string $target) {
  $context = $this->loadContext($target);
  $result = $this->provisionManager->install($context);
  
  if ($result->isSuccess()) {
    $this->io()->success($result->getMessage());
  }
  else {
    throw new \Exception($result->getError());
  }
}
```

### Available Commands

#### `provision-install`

Installs a new Drupal site.

```bash
drush provision-install @example.com
```

**Operations**:
1. Validate context
2. Create MySQL database
3. Create Apache vhost
4. Generate settings.php
5. Run `drush site:install`
6. Set file permissions

#### `provision-verify`

Verifies and repairs site configuration.

```bash
drush provision-verify @example.com
```

**Operations**:
1. Check database connectivity
2. Verify vhost configuration
3. Check file permissions
4. Regenerate settings.php
5. Run `drush updatedb`
6. Clear caches

#### `provision-delete`

Removes a site and all associated data.

```bash
drush provision-delete @example.com
```

**Operations**:
1. Backup database (optional)
2. Drop MySQL database
3. Remove Apache vhost
4. Delete site files
5. Remove context file

**Flags**:
- `--no-backup` - Skip database backup
- `--keep-files` - Don't delete site files

#### `provision-clone`

Clones a site to a new domain.

```bash
drush provision-clone @example.com @new-example.com
```

**Operations**:
1. Create new database
2. Copy database content
3. Create new vhost
4. Copy site files
5. Update settings.php
6. Run updatedb
7. Clear caches

#### `provision-migrate`

Migrates a site to a different platform.

```bash
drush provision-migrate @example.com --platform=platform_d12
```

**Operations**:
1. Create backup
2. Copy site files to new platform
3. Update vhost document root
4. Update settings.php paths
5. Run updatedb
6. Clear caches
7. Verify new installation

#### `provision-backup`

Creates a backup of site files and database.

```bash
drush provision-backup @example.com
```

**Operations**:
1. Export database to SQL dump
2. Create tarball of site files
3. Store in backup directory
4. Log backup metadata

**Output**: `backup-example.com-20260126-123456.tar.gz`

#### `provision-restore`

Restores a site from backup.

```bash
drush provision-restore @example.com --backup-file=/path/to/backup.tar.gz
```

**Operations**:
1. Extract backup tarball
2. Import database dump
3. Restore site files
4. Regenerate settings.php
5. Clear caches

## Operations

### Operation Lifecycle

```
1. Command Invocation
   ↓
2. Context Loading & Validation
   ↓
3. Service Discovery
   ↓
4. Pre-operation Checks
   ↓
5. Operation Execution
   ↓
6. Post-operation Verification
   ↓
7. Result Logging
```

### Error Handling

```php
class ProvisionManager {
  public function execute(string $operation, Context $context): ProvisionResult {
    $transaction = new Transaction();
    
    try {
      // Begin transaction
      $transaction->begin();
      
      // Execute operation
      $this->$operation($context);
      
      // Commit if successful
      $transaction->commit();
      
      return ProvisionResult::success("Operation completed");
    }
    catch (\Exception $e) {
      // Rollback on failure
      $transaction->rollback();
      
      $this->logger->error($e->getMessage());
      return ProvisionResult::error($e->getMessage());
    }
  }
}
```

### Rollback Support

```php
class Transaction {
  protected $actions = [];
  
  public function addRollback(callable $rollback): void {
    $this->actions[] = $rollback;
  }
  
  public function rollback(): void {
    // Execute rollback actions in reverse order
    foreach (array_reverse($this->actions) as $action) {
      try {
        $action();
      }
      catch (\Exception $e) {
        $this->logger->error('Rollback failed: ' . $e->getMessage());
      }
    }
  }
}
```

## Configuration Management

### Server Configuration

Server contexts define how services are configured:

```yaml
# server_master.server.yml
type: server
services:
  web:
    type: apache
    restart_command: sudo systemctl reload apache2
    config_path: /etc/apache2/sites-available
    enabled_path: /etc/apache2/sites-enabled
    php_version: 8.3
    
  db:
    type: mysql
    host: localhost
    port: 3306
    root_password: !vault |
      $ANSIBLE_VAULT;1.1;AES256
      ...encrypted...
    
  ssl:
    type: letsencrypt
    email: admin@example.com
    staging: false
```

### Path Configuration

```php
class ConfigPaths {
  public function vhostPath(Context $server, Context $site): string {
    $config_path = $server->get('services.web.config_path');
    return "{$config_path}/{$site->get('uri')}.conf";
  }
  
  public function sitePath(Context $site): string {
    return "{$site->get('root')}/sites/{$site->get('uri')}";
  }
  
  public function backupPath(Context $site): string {
    return "/var/aegir/backups/{$site->get('uri')}";
  }
}
```

## Development Guidelines

### Service Development

**DO**:
- ✓ Read all configuration from contexts
- ✓ Use service abstraction for operations
- ✓ Return ProvisionResult objects
- ✓ Log all operations
- ✓ Support rollback transactions

**DON'T**:
- ✗ Access Drupal database directly
- ✗ Hardcode paths or credentials
- ✗ Use global variables
- ✗ Skip error handling
- ✗ Leave orphaned resources

### Context Management

**DO**:
- ✓ Validate context before operations
- ✓ Use immutable context objects
- ✓ Load contexts via alias manager
- ✓ Check for required properties

**DON'T**:
- ✗ Modify context YAML from backend
- ✗ Store @ prefix in context data
- ✗ Assume optional properties exist
- ✗ Cache context objects

### Command Development

**DO**:
- ✓ Follow `provision-*` naming pattern
- ✓ Accept site alias as argument
- ✓ Provide clear usage examples
- ✓ Validate inputs
- ✓ Return meaningful exit codes

**DON'T**:
- ✗ Accept entity IDs (use aliases)
- ✗ Skip pre-flight checks
- ✗ Ignore command options
- ✗ Suppress error output

## Testing

### Context Testing

```php
class ContextTest extends TestCase {
  public function testSiteContext() {
    $context = new SiteContext([
      'uri' => 'example.com',
      'root' => '/var/aegir/platforms/d11',
      'db_name' => 'example_com',
    ]);
    
    $this->assertEquals('site', $context->getType());
    $this->assertEquals('example.com', $context->get('uri'));
  }
}
```

### Service Testing

```php
class ApacheServiceTest extends TestCase {
  public function testVhostGeneration() {
    $service = new ApacheService();
    $context = $this->createMockContext();
    
    $vhost = $service->generateVhostConfig($context);
    
    $this->assertStringContainsString('ServerName example.com', $vhost);
    $this->assertStringContainsString('DocumentRoot', $vhost);
  }
}
```

## Next Steps

- **[Frontend Documentation](Frontend.md)** - Learn about hosting entities
- **[Theme Documentation](Theme.md)** - Explore the Eldir theme
- **[Architecture Overview](HOME.md)** - Return to main documentation

---

**Questions?** Check the [provision AI instructions](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md) for detailed technical guidance.
