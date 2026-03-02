# Aegir Hostmaster — AI Agent Skills

> Portable instruction sets for AI agents performing project-wide tasks.
>
> **Note**: `SKILLS.md` is a project convention file, not a universal standard automatically read by all coding agents. Some agents use it only when explicitly configured.

---

## Skill: Fresh Installation

**When**: Setting up Aegir Hostmaster on a new server.

### Steps

1. Ensure prerequisites: root/sudo access, PHP ≥8.3, `composer`, `mysql`, `openssl` installed
2. Run installer:
   ```bash
   sudo bash scripts/install.sh
   ```
3. The script executes 10 phases automatically:
   - `check_prerequisites` — validates PHP, creates `aegir` user if absent
   - `setup_database` — creates MySQL database + user (credentials saved to `~/.aegir.db.conf`, chmod 600)
   - `install_dependencies` — `composer install` + `composer drupal:scaffold`
   - `create_directories` — `web/sites/{SITE_DIR}/files`, `private`, `tmp`, `config/sync`
   - `install_drupal` — `drush site:install standard` (15-minute timeout)
   - `fix_file_permissions` — aegir:www-data ownership, 775/664
   - `enable_aegir_modules` — enables 9 modules in dependency order (see below)
   - `clear_cache` — `drush cr`
   - `configure_webserver` — creates Apache vhost with security headers, enables mod_rewrite + mod_headers
   - `enable_dispatch_cron` — installs crontab entry via `drush hosting:dispatch-enable`

### Flags

| Flag | Purpose |
|------|---------|
| `--dry-run` | Show what would be done without executing |
| `--skip-db` | Skip database creation (use existing) |
| `--db-pass PASSWORD` | Provide MySQL root password |
| `--force` | Overwrite existing installation |
| `--webserver apache\|skip` | Configure Apache or skip webserver setup |
| `--config FILE` | Load config from file |

### Environment Variables

All config is overridable: `AEGIR_HOSTNAME`, `AEGIR_DB_NAME`, `AEGIR_DB_USER`, `AEGIR_DB_PASS`, `AEGIR_DB_HOST`, `AEGIR_DB_PORT`, `AEGIR_EMAIL`.

### Multi-Site Logic

If `AEGIR_HOSTNAME != aegir.local`, the site directory becomes `web/sites/{AEGIR_HOSTNAME}/` instead of `web/sites/default/`, and a `sites.php` mapping is created. Current installation uses `web/sites/aegir.local/`.

---

## Skill: Module Enable Order

**When**: Enabling Aegir modules manually or debugging dependency issues.

Enable in this exact order (each depends on predecessors):

```
hosting → hosting_task → hosting_server → hosting_web_server → hosting_db_server → hosting_platform → hosting_client → hosting_package → hosting_site
```

Run:
```bash
drush en hosting hosting_task hosting_server hosting_web_server hosting_db_server hosting_platform hosting_client hosting_package hosting_site -y
```

---

## Skill: Update Workflow

**When**: Updating Aegir to latest code.

### Steps

1. Run `scripts/update.sh` (or manually):
   ```bash
   drush sql:dump --result-file=~/backup-$(date +%Y%m%d).sql
   drush state:set system.maintenance_mode 1 --input-format=integer
   composer update --no-interaction --prefer-dist --optimize-autoloader
   drush updatedb -y
   drush cr
   drush config:export -y
   drush cron
   drush state:set system.maintenance_mode 0 --input-format=integer
   drush pm:security
   drush status
   ```

### Known Bug

`scripts/update.sh` checks `web/sites/default/settings.php` but current install uses `web/sites/aegir.local/settings.php`. Run the commands manually instead if using a non-default site directory.

---

## Skill: Cross-Repository Development

**When**: Implementing features that span multiple components.

### Git Submodule Commit Workflow

```bash
# 1. Work in component repo
cd web/modules/contrib/aegir-hosting
git checkout -b feature-branch
# ... make changes ...
git add . && git commit -m "Add feature in hosting"

# 2. Repeat for other components if needed
cd ../../../../vendor/argopecten/aegir-provision
git add . && git commit -m "Add feature in provision"

# 3. Return to main repo, stage submodule updates
cd /var/aegir/drupal/aegir-2601
git add web/modules/contrib/aegir-hosting vendor/argopecten/aegir-provision
git commit -m "Add feature across hosting + provision"
```

### Branch Convention

All repos use `dev-dev/d11-new` as the active development branch.

### Composer Notes

- `argopecten/*` packages install from **source** (Git clone, editable)
- Everything else installs from **dist** (zip download)
- Custom repos defined in root `composer.json` pointing to GitHub

---

## Skill: YAML Context Alias Authoring

**When**: Manually creating or inspecting context alias files.

### File Location

`drush/sites/aegir/{context_name}.site.yml`

### Format

```yaml
context_name:
  provision:
    context_type: server|platform|site
    aegir_root: /home/aegir
    remote_host: hostname
    script_user: aegir
    # Service-specific keys:
    http_service_type: apache     # (servers with HTTP)
    http_port: 80
    db_service_type: mysql        # (servers with DB)
    db_port: 3306
    master_db_user: username
    master_db_passwd: password
  # Standard Drush alias keys:
  host: hostname
  user: aegir
  uri: http://domain.com          # (sites only)
  root: /path/to/drupal/web       # (sites/platforms)
```

### Naming Rules

- Server: `server_{sanitized_hostname}` (server ID 1 is always `server_master`)
- Platform: sanitized platform name
- Site: domain value directly

---

## Skill: Debugging

**When**: Troubleshooting Aegir operations.

### Context Inspection

```bash
# View context as Drush sees it
drush site:alias @example.com

# View raw YAML
cat drush/sites/aegir/example.com.site.yml

# Check entity↔context mapping in database
drush sql:query "SELECT * FROM hosting_context WHERE context_name='example.com'"
```

### Task Debugging

```bash
# List queue
drush queue:list

# Manually run a specific task
drush php:eval "\Drupal::service('hosting.task_manager')->runTaskId(123);"

# View task logs
drush sql:query "SELECT * FROM hosting_task_log WHERE task__target_id=123 ORDER BY timestamp"

# Enable/test dispatch
drush hosting:dispatch-enable
drush hosting:dispatch
```

### Backend Testing

```bash
# Test a provision command directly
drush provision:verify @example.com

# Check Apache config syntax
sudo apache2ctl -t

# List vhosts
ls -la /var/aegir/config/apache/vhost.d/

# Test MySQL connectivity
drush provision:save @test_server --type=server --data='{"db_service_type":"mysql"}'
```

### Frontend Testing

```bash
drush cr                    # Clear cache
drush entity:updates        # Check pending entity updates
drush pm:list --type=module --status=enabled | grep hosting  # List enabled hosting modules
```

---

## Skill: Recipes Development

**When**: Implementing Drupal Recipes for Aegir (currently placeholder only).

### Current Status

`recipes/` directory contains only `README.txt`. The full implementation plan is in [doc/TODO.md](../doc/TODO.md#5-drupal-recipes):

1. `recipes/aegir-hostmaster/` — Core recipe (module install, permissions, theme)
2. `recipes/aegir-development/` — Dev tools (devel, webprofiler, verbose logging)
3. `recipes/aegir-production/` — Production hardening (caching, log suppression)
4. `recipes/aegir-multiserver/` — Distributed hosting (SSH, remote servers)

### Migration Target

Replace `drush site:install standard` + manual module enable with `drush site:install minimal` + `drush recipe recipes/aegir-hostmaster`.

---

## Skill: GitHub Wiki Sync

**When**: Understanding how documentation publishing works.

`.github/workflows/sync-wiki.yml` auto-syncs `doc/*.md` to GitHub Wiki on pushes to `main`, `master`, or `dev/d11-new` branches. Only `doc/` changes trigger the workflow. Never edit the wiki directly — always edit `doc/` in the repo.

---

## Skill: Coding Standards (Project-Wide)

### PHP

- PHP 8.3+ features: typed properties, named arguments, enums, `match`, `readonly`
- All new classes should be `final` unless designed for extension
- Value objects: `final readonly class` with constructor promotion
- Use `#[Hook]` attributes over procedural `hook_*()` functions (Drupal 11)
- Manager services encapsulate business logic; forms only delegate
- Backend (provision): no Drupal API access — standalone Drush package

### CSS

- CSS custom properties (variables) for all design tokens in `variables.css`
- BEM methodology for all new hosting components: `.block__element--modifier`
- Mobile-first responsive design
- WCAG AA compliance required (color contrast, ARIA)

### JavaScript

- `Drupal.behaviors` with `once()` for AJAX safety
- ES6+ syntax
- Progressive enhancement (functional without JS)
- `data-*` attributes for JS hooks, not CSS classes

### Naming

- Entity machine names: `hosting_{type}` (e.g., `hosting_site`)
- Service IDs: `hosting.{name}` or `hosting_{module}.{name}`
- Drush commands: `provision:{operation}` (colon syntax, not dashes)
- CSS classes: `.hosting-{block}__element--modifier`
- Template files: `hosting-{type}.html.twig`
