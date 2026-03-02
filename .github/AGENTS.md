# Aegir Hostmaster — AI Agent Guide

> **Aegir Hostmaster** is a Drupal 11 hosting automation platform managing multi-site Drupal infrastructure across servers, platforms, and sites via a queue-based architecture.
>
> **Note**: `AGENTS.md` is a project convention file, not a universal standard automatically read by all coding agents. Some agents use it only when explicitly configured.

## Project Structure (4 Git Repositories)

| Repo | Local Path | Purpose |
|------|-----------|---------|
| **aegir-hostmaster** | `/var/aegir/drupal/aegir-2601/` | Main Composer project, scripts, orchestration |
| **aegir-hosting** | `web/modules/contrib/aegir-hosting/` | Frontend — Drupal 11 modules (entities, forms, task queue) |
| **aegir-provision** | `vendor/argopecten/aegir-provision/` | Backend — Drush 13 extension (infrastructure automation) |
| **aegir-eldir** | `web/themes/contrib/aegir-eldir/` | Theme — Twig templates, CSS, JS |

Each repo has its own `.github/AGENTS.md` (context) and `.github/SKILLS.md` (task instructions).

Components are Git submodules. Composer installs `argopecten/*` from **source** on the `dev-dev/d11-new` branch.

## System Requirements

| Component | Version |
|-----------|---------|
| OS | Ubuntu 24.04 LTS |
| PHP | 8.3+ with FPM |
| Web Server | Apache 2.4+ (mod_rewrite, mod_ssl, mod_proxy_fcgi, mod_headers) |
| Database | MySQL 8.0+ / MariaDB 10.6+ |
| CMS | Drupal 11.x |
| Drush | 13.7+ |
| Composer | 2.x |

## Three-Tier Architecture

```
┌──────────────────────────────────────────────────────────────┐
│  FRONTEND (aegir-hosting)                                     │
│  Entities → Forms → ContextRegistry → YAML aliases            │
│  HostingSite · HostingPlatform · HostingServer (13 entities)  │
└───────────────────────┬──────────────────────────────────────┘
                        ↓  TaskManager → QueueWorker → BackendInvoker
┌──────────────────────────────────────────────────────────────┐
│  BACKEND (aegir-provision)                                    │
│  19 Drush commands → ProvisionManager → 11 Managers           │
│  ServiceRegistry: Apache · MySQL · SSL · Cron                 │
└───────────────────────┬──────────────────────────────────────┘
                        ↓
┌──────────────────────────────────────────────────────────────┐
│  INFRASTRUCTURE                                               │
│  Apache vhosts · MySQL databases · settings.php · SSL certs   │
│  Ubuntu 24.04 · PHP-FPM 8.3 · filesystem                     │
└──────────────────────────────────────────────────────────────┘
```

## Key Concepts

### Context
A `final` data bag (`Context` class) with **immutable identity** (`name()`, `type()` — set at construction, no setters) and **mutable properties** (`get($key)`, `set($key, $value)`, `toArray()`). Some properties (e.g., `root`, `server`) are fixed by convention once set. Stored as Drush YAML aliases in `drush/sites/aegir/`. Three types: `server`, `platform`, `site`. No typed subclasses — type is inferred from properties.

### Entity ↔ Context Bridge
`ContextRegistry` service (433 lines) maintains bidirectional sync:
- Entity save → `saveContextToBackend()` → writes YAML alias + calls `provision:save`
- Entity delete → `deleteContextFromBackend()` → removes alias

### Task Queue
Operations flow: Entity save → `TaskManager::createTask()` → Drupal queue → `HostingTaskQueueWorker` → `BackendInvoker::invokeStreaming()` → `drush provision:{type} {context}`. Three scheduling modes: serial, batch (`pcntl_fork()`), spread. Exponential backoff retry ($2^n \times 60$s, max 3). Cancel via SIGTERM/SIGKILL.

**Critical principle**: Forms NEVER directly call Provision. All operations go through Entity → Task → Queue → Backend.

### Naming Conventions
- Sites: domain directly (`example.com`)
- Platforms: `platform_` prefix (`platform_d11`)
- Servers: `server_` prefix (`server_master`)
- No `@` prefix in database storage
- Routes: `entity.hosting_{type}.{operation}`
- Services: `hosting.{name}` or `hosting_{module}.{name}`

## Data Flow: Site Creation

1. User submits `HostingSiteForm`
2. `SiteManager` validates domain (format + uniqueness)
3. Entity saved → `HostingSite::postSave()`
4. `SiteLifecycleHooks` (via `#[Hook]`) triggers `ContextRegistry::saveContextToBackend()`
5. YAML alias written to `drush/sites/aegir/{domain}.site.yml`
6. `provision:save {domain} --type=site --data={json}` executed
7. `TaskManager::createTask($site, 'install')` queues install task
8. `QueueWorker` → `BackendInvoker::invokeStreaming('provision:install {domain}')`
9. `ProvisionManager` → `InstallationManager` → creates DB, settings.php, vhost, runs `drush site:install`
10. Task log streamed via `TaskLogManager`, status updated on completion

## Development Rules

1. **Breaking changes allowed** — Drupal 7→11 modernization, no backward compat
2. **No update hooks** — unless explicitly requested
3. **Documentation on request only** — don't auto-update docs after changes
4. **Modern PHP 8.3+** — typed properties, attributes, enums, `final` classes, `readonly` where appropriate
5. **Idempotent commands** — all provision commands safe to run repeatedly
6. **Manager services own business logic** — forms delegate validation/logic to managers
7. **`#[Hook]` attributes** over procedural hooks (Drupal 11 pattern)

## Anti-Patterns

```php
// ❌ Direct context manipulation from frontend
file_put_contents("drush/sites/aegir/example.com.site.yml", $yaml);
// ✅ Entity save triggers automatic sync
$site = HostingSite::create(['domain' => 'example.com', ...]); $site->save();

// ❌ Call backend directly from form
public function submitForm() { shell_exec('drush provision:install example.com'); }
// ✅ Queue task through TaskManager
public function submitForm() { $this->taskManager->createTask($entity, 'install'); }

// ❌ Business logic in form
public function validateForm() { if (!preg_match('/^[a-z0-9.-]+$/', $domain)) { ... } }
// ✅ Delegate to manager
public function validateForm() { if (!$this->siteManager->isDomainValid($domain)) { ... } }

// ❌ Store @ prefix
$entity->set('context_name', '@example.com');
// ✅ Store canonical name
$entity->set('context_name', 'example.com');

// ❌ Hardcode theme name for icon sprite path
$theme_path = $container->get('extension.list.theme')->getPath('aegir_eldir');
// ✅ Use the centralized icon provider service
$spriteUrl = $container->get('hosting.icon_provider')->getSpriteUrl();

// ❌ Drupal APIs in provision (backend is standalone, no Drupal bootstrap)
\Drupal::service('some.service');
// ✅ Use Symfony components, ProcessRunner, YAML aliases
```

## Known Issues

- **`scripts/update.sh`** hardcodes `web/sites/default/settings.php` — fails on non-default site dirs (current install uses `web/sites/aegir.local/`)
- **`LockManager.php`** instantiates abstract `ProvisionEvent` class — PHP Fatal Error at runtime; needs concrete `LockEvent`/`UnlockEvent`
- **`BackendInvokerInterface`** only declares `invoke()` but concrete class also has `invokeStreaming()` — callers depend on concrete class
- **Status type inconsistency**: `HostingTask` uses strings ('queued', 'processing', 'success'), other entities use integers (0, 1, -1, -2)
- **CSS duplication**: `.hosting-entity-chip`, `.hosting-panel`, `.hosting-status-badge` defined in both `components.css` and `aegir.css` with conflicting styles

## Component Quick Links

| Component | AGENTS.md | SKILLS.md |
|-----------|-----------|-----------|
| Hosting (Frontend) | `web/modules/contrib/aegir-hosting/.github/AGENTS.md` | `web/modules/contrib/aegir-hosting/.github/SKILLS.md` |
| Provision (Backend) | `vendor/argopecten/aegir-provision/.github/AGENTS.md` | `vendor/argopecten/aegir-provision/.github/SKILLS.md` |
| Eldir (Theme) | `web/themes/contrib/aegir-eldir/.github/AGENTS.md` | `web/themes/contrib/aegir-eldir/.github/SKILLS.md` |

## File Permissions

| Target | Owner | Group | Mode |
|--------|-------|-------|------|
| Config files | aegir | www-data | 0640 |
| Apache vhosts | root | root | 0644 |
| Platform dirs | aegir | www-data | 0755 |
| Public files | aegir | www-data | 0775 |
| Private files | aegir | www-data | 0770 |
| settings.php | aegir | www-data | 0440 |
| SSL keys | aegir | aegir | 0600 |
