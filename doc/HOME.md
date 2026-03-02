# Aegir Hostmaster — Architecture Overview

Aegir Hostmaster is a Drupal hosting automation platform built on Drupal 11. It manages the full lifecycle of Drupal sites — provisioning, verification, backup, migration, cloning, and deletion — across multiple platforms and servers.

## Table of Contents

- [System Overview](#system-overview)
- [Three-Tier Architecture](#three-tier-architecture)
- [Key Concepts](#key-concepts)
- [Data Flow](#data-flow)
- [Component Documentation](#component-documentation)
- [System Requirements](#system-requirements)
- [Development Principles](#development-principles)

## System Overview

### Core Components

Aegir consists of three integrated components, each in its own Git repository:

| Component | Repository | Location | Purpose |
|---|---|---|---|
| **[Frontend](Frontend.md)** | aegir-hosting | `web/modules/contrib/aegir-hosting/` | Drupal 11 entities, forms, task queue, services |
| **[Backend](Backend.md)** | aegir-provision | `vendor/argopecten/aegir-provision/` | Drush 13 extension — infrastructure automation |
| **[Theme](Theme.md)** | aegir-eldir | `web/themes/contrib/aegir-eldir/` | Eldir theme — hosting management UI |

All three ship as Composer dependencies of the **aegir-hostmaster** root project.

### Supported Environment

| Requirement | Version |
|---|---|
| Operating System | Ubuntu 24.04 LTS |
| PHP | 8.3+ with FPM |
| Web Server | Apache 2.4+ with `mod_rewrite`, `mod_ssl`, `mod_proxy_fcgi` |
| Database | MySQL 8.0+ or MariaDB 10.6+ |
| Drupal | 11.x |
| Drush | 13.7+ |
| Composer | 2.x |

## Three-Tier Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                    DRUPAL 11 FRONTEND                         │
│                  (aegir-hosting modules)                      │
│                                                               │
│  User Interface → Entities → Forms → Task Creation            │
│  8 submodules · 12 entity types · 25 forms · 2 plugin mgrs   │
│                         ↓                                     │
│                  ContextRegistry                              │
│                (Entity ↔ Context Sync)                        │
│                         ↓                                     │
│                 Drush Alias YAML                              │
│              drush/sites/aegir/*.site.yml                     │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                    TASK QUEUE LAYER                           │
│                                                               │
│  Task Queue → QueueWorker → BackendInvoker                   │
│                         ↓                                     │
│             Shell Execute: drush provision:*                  │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                    DRUSH BACKEND                              │
│                (aegir-provision extension)                    │
│                                                               │
│  17 command classes · 51 lifecycle events                     │
│  11 managers · 4 service interfaces · 6 implementations      │
│                         ↓                                     │
│  Apache vhosts · MySQL databases · settings.php · SSL · Cron │
└──────────────────────────────────────────────────────────────┘
                          ↓
┌──────────────────────────────────────────────────────────────┐
│                  INFRASTRUCTURE LAYER                         │
│  Ubuntu 24.04 · Apache 2.4 · PHP-FPM 8.3 · MySQL 8.0       │
└──────────────────────────────────────────────────────────────┘
```

### Layer Responsibilities

#### 1. Frontend Layer (Drupal 11)

- **Purpose**: User interface and data management
- **Components**: Entities, forms, views, permissions, Drupal plugin system
- **Key Services**: `hosting.context_registry`, `hosting.backend_invoker`, `hosting.queue_dispatcher`, `hosting.task_manager`
- **Storage**: Drupal database for entity data; Drush YAML aliases for context sync

#### 2. Task Queue Layer

- **Purpose**: Asynchronous operation execution
- **Components**: Drupal Queue API, `HostingTaskQueueWorker` plugin
- **Function**: Converts entity operations into Drush backend commands
- **Trigger**: System cron (`drush cron`) or manual (`drush hosting:task-run`)

#### 3. Backend Layer (Provision)

- **Purpose**: Infrastructure automation — operates exclusively on contexts, never touches the Drupal database
- **Components**: Drush commands, ProvisionManager, service classes, event system
- **Key Services**: ApacheService, MySqlService, SslManager, SettingsWriter, SystemCronService
- **Storage**: YAML contexts in `drush/sites/aegir/`

#### 4. Infrastructure Layer

- **Purpose**: The actual hosting environment automated by the backend
- **Components**: Apache vhosts, MySQL databases, file system, SSL certificates, cron jobs

## Key Concepts

### Context

A `final` class (`Aegir\Provision\Core\Context`) representing an infrastructure component.

**Identity** is **immutable** — `name()` and `type()` are set at construction with no setters. **Properties** are **mutable** — `get($key)`, `set($key, $value)`, `all()`, `toArray()`. Some properties (e.g., `root`, `server`) are fixed by convention once set.

**Three context types**:

| Type | Naming Convention | Example | Represents |
|---|---|---|---|
| `server` | `server_*` | `server_master` | Service provider (Apache, MySQL) |
| `platform` | `platform_*` | `platform_drupal11` | Drupal codebase/distribution |
| `site` | domain name | `example.com` | Installed Drupal site |

**Storage**: YAML files in `drush/sites/aegir/{name}.site.yml` under a `provision:` key block, managed by `AliasStore`.

No typed subclasses exist — type is a string property. Cross-references use `@` prefix (e.g., `"@server_master"`).

### Context Hierarchy

```
Site → references Platform (via 'platform' key) + Server (via 'db_server')
Platform → references Server (via 'server', 'web_server')
Server → standalone, hosts services (http, db, ssl, cron)
```

### Entity

Drupal content entities representing hosting objects in the frontend:

| Entity Type | Entity Class | Purpose |
|---|---|---|
| `hosting_site` | `HostingSite` | Site with domain, platform, db server refs |
| `hosting_platform` | `HostingPlatform` | Drupal codebase with root path, server ref |
| `hosting_server` | `HostingServer` | Server with service instances |
| `hosting_task` | `HostingTask` | Queued operation (install, verify, etc.) |
| `hosting_task_log` | `HostingTaskLog` | Task execution log entries |
| `hosting_client` | `HostingClient` | Client/organization for multi-tenancy |
| `hosting_client_user` | `HostingClientUser` | Client ↔ user association |
| `hosting_package` | `HostingPackage` | Tracked Drupal package |
| `hosting_package_instance` | `HostingPackageInstance` | Package installed on a platform |
| `hosting_service_instance` | `HostingServiceInstance` | Service config on a server |
| `hosting_site_backup` | `HostingSiteBackup` | Backup record for a site |
| `hosting_context` | `HostingContext` | Entity ↔ context name mapping |

### Context Registry

The `ContextRegistry` service maintains bidirectional entity ↔ context synchronization:

- **Entity save** → `saveContextToBackend()` → writes YAML alias + calls `provision:save`
- **Entity delete** → `deleteContextFromBackend()` → removes alias

### Task

A queued operation bridging frontend and backend:

1. Entity save hooks create a `HostingTask` entity
2. `QueueDispatcher` inserts it into the Drupal queue
3. Cron triggers `HostingTaskQueueWorker`
4. `BackendInvoker` shells out to `drush provision:{operation} {context_name}`
5. `TaskManager` updates task status based on exit code

**Task types**: install, verify, delete, clone, migrate, backup, restore, deploy, enable, disable, lock, unlock, login-reset

## Data Flow

### Example: Creating a New Site

```
1. User fills "Add Site" form with domain, platform, db server
        ↓
2. HostingSite entity created and saved
        ↓
3. ContextRegistry writes YAML alias to drush/sites/aegir/{domain}.site.yml
        ↓
4. Entity save hook creates HostingTask (type: install)
        ↓
5. QueueDispatcher enqueues the task
        ↓
6. Cron → QueueWorker → BackendInvoker:
   drush provision:install {domain}
        ↓
7. ProvisionManager orchestrates:
   - MySqlService creates database + user
   - SettingsWriter generates settings.php
   - ApacheService creates vhost config
   - ApacheService reloads Apache
   - Drupal site:install runs
        ↓
8. Task status updated (completed/error), entity status updated
```

## Component Documentation

### Detailed Guides

| Guide | Content |
|---|---|
| [Frontend.md](Frontend.md) | Entity architecture, forms, task queue, manager services, submodules |
| [Backend.md](Backend.md) | Context system, Drush commands, services, events, extension system |
| [Theme.md](Theme.md) | Templates, CSS, JavaScript, preprocess functions, responsive design |
| [TODO.md](TODO.md) | Development roadmap across all components |

### Component-Specific Documentation

Each component repository has its own `doc/` folder:

- **Backend**: [vendor/argopecten/aegir-provision/doc/](../vendor/argopecten/aegir-provision/doc/) — provision-d11.md, architecture.md, roadmap.md, manual-testing.md
- **Frontend**: [web/modules/contrib/aegir-hosting/doc/](../web/modules/contrib/aegir-hosting/doc/) — hosting-d11.md
- **Theme**: [web/themes/contrib/aegir-eldir/doc/](../web/themes/contrib/aegir-eldir/doc/) — eldir-d11.md, TODO.md

### For AI Coding Agents

Each repository has `.github/AGENTS.md` (architecture context) and `.github/SKILLS.md` (actionable procedures):

| Repo | AGENTS.md | SKILLS.md |
|---|---|---|
| Main | [.github/AGENTS.md](../.github/AGENTS.md) | [.github/SKILLS.md](../.github/SKILLS.md) |
| Backend | [provision/.github/AGENTS.md](../vendor/argopecten/aegir-provision/.github/AGENTS.md) | [provision/.github/SKILLS.md](../vendor/argopecten/aegir-provision/.github/SKILLS.md) |
| Frontend | [hosting/.github/AGENTS.md](../web/modules/contrib/aegir-hosting/.github/AGENTS.md) | [hosting/.github/SKILLS.md](../web/modules/contrib/aegir-hosting/.github/SKILLS.md) |
| Theme | [eldir/.github/AGENTS.md](../web/themes/contrib/aegir-eldir/.github/AGENTS.md) | [eldir/.github/SKILLS.md](../web/themes/contrib/aegir-eldir/.github/SKILLS.md) |

See also [AI-DOCUMENTATION.md](AI-DOCUMENTATION.md) for a full overview of AI agent documentation.

## System Requirements

### PHP Extensions

```
php8.3-cli php8.3-fpm php8.3-mysql php8.3-gd php8.3-curl
php8.3-xml php8.3-mbstring php8.3-zip
```

### Apache Modules

```
mod_rewrite  mod_ssl  mod_proxy_fcgi  mod_headers
```

### Database Privileges

The Aegir MySQL user needs `CREATE DATABASE`, `CREATE USER`, and `GRANT OPTION` privileges to provision sites.

### System Tools

`tar`, `gzip` (backups), `rsync` (file sync), `openssl` (SSL), `crontab` (cron management)

## Development Principles

### Separation of Concerns

| Layer | Must | Must Not |
|---|---|---|
| **Frontend** | Use entities + task queue for operations | Directly modify infrastructure |
| **Backend** | Operate exclusively on YAML contexts | Access the Drupal database |
| **Theme** | Use preprocess for data preparation | Implement business logic |

### Naming Conventions

| Item | Pattern | Example |
|---|---|---|
| Context (site) | domain name | `example.com` |
| Context (platform) | `platform_*` | `platform_drupal11` |
| Context (server) | `server_*` | `server_master` |
| Entity route | `entity.hosting_{type}.{op}` | `entity.hosting_site.edit_form` |
| Service ID | `hosting.{name}` or `hosting_{module}.{name}` | `hosting.context_registry` |
| Provision command | `provision:{operation}` | `provision:verify` |

### Breaking Changes Policy

Since this is a Drupal 11 rewrite, **breaking changes from Drupal 7 Aegir are acceptable**. No backward compatibility with Aegir 3.x (Drupal 7) is maintained. All changes should be documented but migration support is not required.

---

**Next**: [Frontend.md](Frontend.md) · [Backend.md](Backend.md) · [Theme.md](Theme.md) · [TODO.md](TODO.md)
