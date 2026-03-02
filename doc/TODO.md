# Development Roadmap

This document is the central roadmap for Aegir Hostmaster. It covers system-level features, cross-component work, and architectural improvements.

**Component-specific roadmaps**:
- **Backend (Provision)**: [vendor/argopecten/aegir-provision/doc/roadmap.md](../vendor/argopecten/aegir-provision/doc/roadmap.md)
- **Theme (Eldir)**: [web/themes/contrib/aegir-eldir/doc/TODO.md](../web/themes/contrib/aegir-eldir/doc/TODO.md)

---

## Completed

### Extension System (January 31, 2026) ✅

- Event system: 51 lifecycle events via Symfony EventDispatcher (14 operations)
- Service plugin system: `HttpServiceInterface`, `DbServiceInterface`, `SslServiceInterface`, `CronServiceInterface` + `ServiceRegistry`
- Template override system: priority-based `TemplateRenderer` with MD5 caching

### Technical Debt Refactoring (January 31, 2026) ✅

- Value objects: `DatabaseCredentials`, `ServerPaths`, `ApacheVhostConfig`, `CronJobConfig`
- SQL injection fixed: `MySqlService` uses PDO with prepared statements
- Template caching: MD5-based with mtime invalidation
- `ProvisionManager` namespace moved to `Aegir\Provision`

### Task Queue (January 29, 2026) ✅

- Automatic task creation on entity save
- Task retry logic with exponential backoff
- Task cancellation with process killing
- Streaming output for real-time logs
- Task queue management UI with auto-refresh

---

## High Priority

### 1. Testing Infrastructure

**Status**: ⏳ Not started — 0% coverage across all components
**Complexity**: High

| Area | Target |
|---|---|
| Provision core classes | Context, ContextRepository, AliasStore, PlatformRoot, TemplateRenderer |
| Provision managers | All 11 managers + ProvisionManager |
| Provision services | ApacheService, MySqlService, SettingsWriter, SslManager, SystemCronService |
| Provision commands | All 17 command classes |
| Event system | Validate/before/after/rollback for all operations |
| Frontend services | All manager services + ContextRegistry |
| Frontend entities | All entity CRUD operations |
| Integration | Full workflows: install, backup/restore, migrate, clone |

**Infrastructure needed**:
- Docker Compose test environment (Apache 2.4+, MySQL 8.0+, PHP 8.3-FPM)
- GitHub Actions CI/CD (PHP 8.3/8.4 matrix, Drush 13.7+)
- PHPStan level 8 + PHP_CodeSniffer PSR-12
- Target: 85%+ code coverage for provision

### 2. PHP-FPM Per-Site Pools

**Status**: ⏳ Not implemented
**Complexity**: High

Per-site PHP-FPM pool management for process isolation and resource limits.

- [ ] Create `PhpFpmServiceInterface` and `PhpFpmService`
- [ ] Pool config templates (`resources/templates/php-fpm/pool.tpl.php`)
- [ ] Update Apache vhost templates for per-site FPM sockets
- [ ] Pool lifecycle in InstallationManager (create/remove on install/enable/disable/delete)
- [ ] Pool verification in VerificationManager
- [ ] Per-site resource limits (`pm.max_children`, `memory_limit`, `open_basedir`)

### 3. Context Schema Validation

**Status**: ⏳ Not implemented
**Complexity**: Medium

- [ ] JSON Schema for server, platform, and site contexts
- [ ] `ContextValidator` class (`src/Core/ContextValidator.php`)
- [ ] Validate on `provision:save` and `ContextRepository::save()`
- [ ] Clear per-field error messages

### 4. Git Platform Clone — Architecture Fix

**Status**: ⏳ Broken — violates Entity → Task → Queue → Backend principle
**Complexity**: Medium

`PlatformManager::cloneGitRepository()` runs `exec('git clone')` + `exec('composer install')` synchronously from the frontend HTTP request. This must be moved to the backend via the task queue.

**Current (broken)**: Form save → `PlatformManager::cloneGitRepository()` via `exec()` → synchronous clone
**Correct**: Form save → entity with `platform_type=git` + `git_url` → lifecycle hook → `TaskManager::createTask($platform, 'clone')` → queue → `BackendInvoker` → `provision:clone`

**Problems**: HTTP timeout on large repos, runs as www-data not aegir, no task log, no retry/cancel, bypasses queue.

- [ ] Create `provision:clone` command in backend (git clone + composer install + provision:save + provision:verify)
- [ ] Add `git_url` property to platform context schema
- [ ] Remove `exec()` calls from `PlatformManager::cloneGitRepository()`
- [ ] Form save: create entity only (no clone), queue `clone` task via lifecycle hook
- [ ] Add `clone` to `PlatformLifecycleHooks` task type handling
- [ ] Stream git/composer output to task log

**Files**:
- `hosting_platform/src/Service/PlatformManager.php` — remove `cloneGitRepository()` exec calls
- `hosting_platform/src/Form/HostingPlatformForm.php` — form save must not clone
- `hosting_platform/src/Hook/PlatformLifecycleHooks.php` — add clone task creation
- `vendor/argopecten/aegir-provision/src/Command/` — new `ProvisionCloneCommands.php`

### 5. Frontend Architecture Borderline Cases

**Status**: ⏳ Not started
**Complexity**: Low–Medium

Issues found during architecture audit (March 2026). Not violations per se, but non-ideal patterns.

- [ ] `PlatformManager::ensurePlatformsDirectoryExists()` — runs `mkdir(/var/aegir/platforms)` in constructor on every service instantiation; move to installer/recipe
- [ ] `HostingFeaturesForm` → `FeatureManager::applyEnabledFeatures()` — synchronous `moduleInstaller->install()/uninstall()` during HTTP request; could timeout with many modules; consider a task-based approach
- [ ] `PlatformLockForm` / `PlatformUnlockForm` — direct entity status change without task; non-uniform vs all other operations; acceptable for now but fragile if lock/unlock gains backend side-effects
- [ ] `PackageDiscovery::discover()` — scans platform filesystem (RecursiveDirectoryIterator + file_get_contents) from frontend; no callers yet (dead code); should be invoked from backend verify task when needed

### 6. Security Hardening

**Status**: Partial (DB credential isolation, SSL, file perms, PDO prepared statements)
**Complexity**: Medium

- [ ] Security headers in Apache vhost templates (CSP, HSTS, X-Frame-Options)
- [ ] Audit logging for all provision operations
- [ ] Encrypt database passwords in context YAML storage
- [ ] Rate limiting / idempotency guards
- [ ] Backup integrity validation (checksums)

---

## Medium Priority

### 7. Drupal Recipes

**Status**: ⏳ Not started
**Complexity**: Medium

Modernize installation with Drupal Recipes — composable, reusable configuration packages replacing installation profiles.

#### Why Recipes

| Aspect | Recipe | Installation Profile |
|---|---|---|
| Apply to existing sites | ✅ Yes | ❌ One-time only |
| Multiple per site | ✅ Stackable | ❌ One per site |
| Reapply after update | ✅ Yes | ❌ No |
| Drupal 11 alignment | ✅ Modern approach | ⚠️ Legacy |

#### Planned Recipes

| Recipe | Location | Purpose |
|---|---|---|
| `aegir-hostmaster` | `recipes/aegir-hostmaster/` | Core: install all hosting modules, set permissions, configure theme |
| `aegir-development` | `recipes/aegir-development/` | Dev tools: devel, webprofiler, verbose logging, no CSS aggregation |
| `aegir-production` | `recipes/aegir-production/` | Production: CSS/JS aggregation, error hiding, backup settings |
| `aegir-multiserver` | `recipes/aegir-multiserver/` | Distributed: remote server support, SSH |

#### Base Recipe Structure (`recipes/aegir-hostmaster/recipe.yml`)

```yaml
name: Aegir Hostmaster
description: 'Aegir hosting control panel for Drupal 11'
type: Site configuration

install:
  - hosting
  - hosting_site
  - hosting_platform
  - hosting_server
  - hosting_task
  - hosting_client

config:
  import:
    hosting: '*'
    hosting_site: '*'
    hosting_platform: '*'
    hosting_server: '*'
    hosting_task: '*'
    hosting_client: '*'

  actions:
    system.theme:
      simple_config_update:
        default: 'eldir'
        admin: 'eldir'

    user.role.hosting_admin:
      ensure_exists:
        id: hosting_admin
        label: 'Hosting Administrator'
      grantPermissions:
        - 'administer hosting'
        - 'create hosting sites'
        - 'view hosting tasks'
```

#### Hybrid Installation Flow

```
install.sh
  ├── System checks (PHP, MySQL, Apache)
  ├── Infrastructure setup (database, directories, permissions)
  ├── drush site:install minimal
  ├── drush recipe recipes/aegir-hostmaster    ← Recipes handle Drupal config
  ├── drush recipe recipes/aegir-{environment} ← Optional environment recipe
  └── drush hosting:setup                       ← Backend context init
```

#### Tasks

- [ ] Export current configuration and analyze needs
- [ ] Create `aegir-hostmaster` recipe with module list, config, permissions
- [ ] Create `aegir-development` recipe
- [ ] Create `aegir-production` recipe
- [ ] Create `aegir-multiserver` recipe
- [ ] Update `install.sh` to use `drush site:install minimal` + `drush recipe`
- [ ] Test fresh install, recipe composition, and in-place application
- [ ] Write recipe documentation in `recipes/README.txt`

### 8. Backup Improvements

**Status**: Basic implementation exists
**Complexity**: Medium

- [ ] Backup scheduling (daily, weekly, monthly)
- [ ] Retention policies
- [ ] Incremental backups
- [ ] Remote backup storage (S3, FTP)
- [ ] Backup encryption
- [ ] Backup browser UI

### 9. Task Queue Enhancements

**Status**: Working with standard Drupal Queue API
**Complexity**: High

- [ ] Multiple queue types (tasks, backups, SSL renewals)
- [ ] Per-queue frequency configuration UI
- [ ] Queue statistics dashboard
- [ ] Task priority system
- [ ] Task dependencies / chaining

### 10. Migration from Aegir 3.x

**Status**: ⏳ Not started
**Complexity**: High

- [ ] Migration Drush commands
- [ ] Import D7 sites as D11 entities
- [ ] Convert D7 contexts to D11 format
- [ ] Migrate client data and task history
- [ ] Migration guide

### 11. Remote Server Support

**Status**: ⏳ Not started
**Complexity**: Very High

- [ ] SSH service layer
- [ ] Remote command execution
- [ ] SSH key management
- [ ] rsync for file operations
- [ ] Remote MySQL access

---

## Future Enhancements

### Multi-Tenancy
- Client resource quotas
- Client API access tokens
- Usage statistics dashboard
- Billing integration

### Monitoring & Alerts
- Site uptime monitoring
- Disk space alerts
- Performance metrics
- Email/Slack notifications

### API
- REST API for all operations
- GraphQL API
- Webhook system
- CI/CD pipeline integration

### Infrastructure
- Docker/container support
- Kubernetes integration
- CDN / load balancer support
- Auto-scaling

### Documentation
- API documentation (PHPDoc)
- Video tutorials
- Troubleshooting guides
- Migration guides

---

## Architecture Improvements

### Service Layer (Low Priority)

Extension system is complete. Remaining improvements:
- Manager interfaces for better testability
- Typed custom exceptions with error codes
- Command bus pattern (future)
- Middleware for cross-cutting concerns (future)

---

## Contributing

1. **Pick a task** from this file or a component roadmap
2. **Read the docs**: [HOME.md](HOME.md), [Backend.md](Backend.md), [Frontend.md](Frontend.md)
3. **Follow conventions**: PSR-12, `declare(strict_types=1)`, `final` by default
4. **Write tests** with your changes
5. **Update docs** and submit a PR

### Priority Legend
- **High**: Critical for core functionality or security
- **Medium**: Important but not blocking
- **Future**: Nice to have

### Complexity Legend
- **Low**: Hours · **Medium**: Days · **High**: Week+ · **Very High**: Multi-week
