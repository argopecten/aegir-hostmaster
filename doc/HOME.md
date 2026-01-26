# Aegir Hostmaster - Architecture Overview

Welcome to the Aegir Hostmaster documentation! This page provides a comprehensive overview of the system architecture and how the components work together.

## Table of Contents

- [System Overview](#system-overview)
- [Three-Tier Architecture](#three-tier-architecture)
- [Key Concepts](#key-concepts)
- [Data Flow](#data-flow)
- [Component Documentation](#component-documentation)
- [Integration Points](#integration-points)
- [System Requirements](#system-requirements)

## System Overview

**Aegir Hostmaster** is a complete Drupal hosting automation platform running on Drupal 11. It provides a unified interface for managing multiple Drupal sites across multiple platforms and servers.

### Core Components

Aegir consists of three distinct but tightly integrated components:

1. **[Frontend (aegir-hosting)](Frontend.md)** - Drupal 11 modules providing the entity layer, forms, and task management
2. **[Backend (aegir-provision)](Backend.md)** - Drush 13 extension automating infrastructure operations
3. **[Theme (aegir-eldir)](Theme.md)** - Drupal 11 theme providing the hosting management UI

### Supported Environment

- **Operating System**: Ubuntu 24.04 LTS (primary support)
- **PHP**: 8.3+ with required extensions
- **Web Server**: Apache 2.4+ with PHP-FPM
- **Database**: MySQL 8.0+ or MariaDB 10.6+
- **Drupal**: 11.x
- **Drush**: 13.x

## Three-Tier Architecture

Aegir uses a layered architecture that separates concerns and enables distributed hosting:

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

### Layer Responsibilities

#### 1. Frontend Layer (Drupal 11)
- **Purpose**: User interface and data management
- **Components**: Entities, forms, views, permissions
- **Key Services**: ContextRegistry, BackendInvoker, QueueDispatcher
- **Storage**: Drupal database (entity data)

#### 2. Task Queue Layer
- **Purpose**: Asynchronous operation execution
- **Components**: Queue API, QueueWorker plugins
- **Function**: Bridge between frontend and backend
- **Execution**: Converts entity operations to Drush commands

#### 3. Backend Layer (Provision)
- **Purpose**: Infrastructure automation
- **Components**: Drush commands, services, context system
- **Key Services**: ApacheService, MysqlService, SiteService
- **Storage**: YAML contexts in `~/.drush/sites/`

#### 4. Infrastructure Layer
- **Purpose**: Actual hosting environment
- **Components**: Web server, database server, file system
- **Management**: Automated by backend layer

## Key Concepts

### Context

**Definition**: An immutable data structure representing infrastructure components.

**Types**:
- **Site Context** - Represents a Drupal site (e.g., `example.com`)
- **Platform Context** - Represents a Drupal codebase (e.g., `platform_d11`)
- **Server Context** - Represents a service provider (e.g., `server_master`)

**Storage**: YAML files in `~/.drush/sites/`

**Example** (`example.com.site.yml`):
```yaml
type: site
parent: platform_d11
db_server: server_master
web_server: server_master
uri: example.com
root: /var/aegir/platforms/drupal-11
```

### Entity

**Definition**: A Drupal content entity representing hosting objects.

**Types**:
- **HostingSite** - Frontend representation of a site
- **HostingPlatform** - Frontend representation of a platform
- **HostingServer** - Frontend representation of a server

**Purpose**: Provides forms, validation, access control, and UI

### Context Registry

**Definition**: Bidirectional mapping service maintaining entity ↔ context synchronization.

**Functions**:
- Writes Drush alias YAML when entities save
- Reads context data for entity display
- Maintains naming consistency
- Handles entity-to-context conversion

### Task

**Definition**: A queued operation that bridges frontend and backend.

**Lifecycle**:
1. Created via entity save hooks
2. Queued in Drupal queue system
3. Executed by QueueWorker plugin
4. Invokes BackendInvoker service
5. Shells out to Drush provision command
6. Updates task status based on result

**Types**: install, verify, delete, clone, migrate, backup, restore

## Data Flow

### Example: Creating a New Site

1. **User Action** (Frontend)
   - Admin fills out "Add Site" form
   - Enters domain, platform, database info

2. **Entity Creation** (Frontend)
   ```php
   $site = HostingSite::create([
     'label' => 'example.com',
     'field_hosting_domain' => 'example.com',
     'field_hosting_platform' => $platform_id,
   ]);
   $site->save();
   ```

3. **Context Synchronization** (Frontend)
   ```php
   // ContextRegistry writes YAML
   // ~/.drush/sites/example.com.site.yml
   ```

4. **Task Creation** (Frontend)
   ```php
   // Entity save hook creates task
   $task = HostingTask::create([
     'type' => 'install',
     'target_entity' => $site,
   ]);
   ```

5. **Queue Processing** (Task Layer)
   ```php
   // QueueWorker picks up task
   $this->backendInvoker->execute(
     'provision-install',
     '@example.com'
   );
   ```

6. **Backend Execution** (Backend)
   ```bash
   # Drush command executes
   drush provision-install @example.com
   ```

7. **Infrastructure Changes** (Backend)
   - Apache vhost created
   - MySQL database created
   - Drupal site installed
   - settings.php generated

8. **Task Completion** (Frontend)
   - Task status updated
   - Entity status updated
   - User notified

## Component Documentation

### Detailed Component Guides

Each component has comprehensive documentation:

- **[Frontend Guide](Frontend.md)** - Entity architecture, forms, task management, manager services
- **[Backend Guide](Backend.md)** - Context system, services, Drush commands, operations
- **[Theme Guide](Theme.md)** - Templates, CSS architecture, JavaScript, components

### Component-Specific AI Instructions

For developers and AI agents, each component has detailed technical instructions:

- **Backend**: [drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
- **Frontend**: [web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
- **Theme**: [web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)

### Architectural Documentation

- **[Root Architecture](../.github/ARCHITECTURE.md)** - Overarching architecture, integration points, cross-cutting concerns
- **[Recipes TODO](../.github/TODO-RECIPES.md)** - Drupal Recipes implementation plan

## Integration Points

### Frontend → Backend Communication

**Mechanism**: BackendInvoker service shells out to Drush commands

**Process**:
1. Frontend creates task entity
2. QueueWorker processes task
3. BackendInvoker builds Drush command
4. Shell execution via `drush provision-*`
5. Output captured and logged

**Example**:
```php
$result = $this->backendInvoker->execute(
  'provision-verify',
  '@example.com',
  ['--context_type=site']
);
```

### Backend → Infrastructure Communication

**Mechanism**: Service classes write configuration files and execute system commands

**Examples**:
- **Apache**: Writes vhost configs to `/etc/apache2/sites-available/`
- **MySQL**: Executes `CREATE DATABASE`, `GRANT` statements
- **File System**: Creates directories, sets permissions
- **SSL**: Generates certificates, configures HTTPS

### Theme → Module Communication

**Mechanism**: Preprocess functions and render arrays

**Key CSS Classes**:
- `.ntype-site`, `.ntype-platform`, `.ntype-server` - Entity type indicators
- `.hosting-status-enabled`, `.hosting-status-disabled` - Status indicators
- `.hosting-button-enabled`, `.hosting-button-disabled` - Action buttons

**JavaScript Integration**:
- Task queue live updates
- Log output filtering and formatting
- AJAX form enhancements

## System Requirements

### Operating System

**Primary**: Ubuntu 24.04 LTS

**Note**: While Aegir may work on other Linux distributions, development and testing focus on Ubuntu 24.04 LTS for consistency.

### PHP Requirements

**Version**: 8.3 or higher

**Required Extensions**:
- `php8.3-cli` - Command-line interface
- `php8.3-fpm` - FastCGI Process Manager
- `php8.3-mysql` - MySQL database support
- `php8.3-gd` - Image manipulation
- `php8.3-curl` - HTTP client
- `php8.3-xml` - XML processing
- `php8.3-mbstring` - Multi-byte string handling
- `php8.3-zip` - ZIP archive handling

### Web Server

**Apache 2.4+** with modules:
- `mod_rewrite` - URL rewriting
- `mod_ssl` - HTTPS support
- `mod_proxy_fcgi` - PHP-FPM integration
- `mod_headers` - HTTP header manipulation

**Alternative**: Nginx support is planned but not currently implemented.

### Database

**MySQL 8.0+** or **MariaDB 10.6+**

**Required Privileges**:
- CREATE DATABASE
- CREATE USER
- GRANT OPTION

### Development Tools

- **Composer** 2.x - Dependency management
- **Git** - Version control
- **Drush** 13.x - Drupal CLI (included via Composer)

### System Tools

- `tar` - Archive creation
- `gzip` - Compression
- `rsync` - File synchronization
- `openssl` - SSL certificate generation

## Development Principles

### Separation of Concerns

**Frontend**: Never directly modify infrastructure
- Use entity API for data management
- Use task queue for operations
- Use BackendInvoker for backend communication

**Backend**: Never directly access Drupal database
- Read contexts from YAML
- Write results to task logs
- Return status codes

**Theme**: Never implement business logic
- Use preprocess for data preparation
- Use render arrays from modules
- Use CSS classes for module integration

### Naming Conventions

**Context Names**:
- Sites: Use domain (e.g., `example.com`)
- Platforms: Prefix with `platform_` (e.g., `platform_d11`)
- Servers: Prefix with `server_` (e.g., `server_master`)
- **Important**: No @ prefix in storage

**Entity IDs**:
- Standard Drupal entity ID format
- Numeric auto-increment IDs

**Routes**:
- Format: `entity.hosting_{type}.{operation}`
- Example: `entity.hosting_site.edit_form`

### Breaking Changes Policy

Since this is a modernization project for Drupal 11, **breaking changes from Drupal 7 Aegir are acceptable**:

- ✓ Remove Drupal 7 compatibility code
- ✓ Change database schema (provide update hooks)
- ✓ Rename entities, fields, or services
- ✓ Change context property names
- ✓ Modify task queue architecture
- ✓ Remove obsolete features
- ✓ Change URL patterns
- ✓ Update theme selectors (with migration guide)

**Migration Strategy**: Document changes clearly but do not maintain backward compatibility with Aegir 3.x (Drupal 7).

## Next Steps

- **[Frontend Documentation](Frontend.md)** - Learn about hosting modules and entities
- **[Backend Documentation](Backend.md)** - Understand the provision system
- **[Theme Documentation](Theme.md)** - Explore the Eldir theme
- **[Development TODO](TODO.md)** - See what's planned for the future

---

**Questions?** Check our [community resources](https://aegirproject.org) or [open an issue](https://github.com/aegir-project/aegir).
