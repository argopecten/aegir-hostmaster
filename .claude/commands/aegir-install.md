# Aegir Fresh Installation

Perform a fresh Aegir Hostmaster installation on this server.

## Prerequisites Check

First verify prerequisites are met:
- Root/sudo access available
- PHP ≥ 8.3 installed (with FPM)
- `composer`, `mysql`, `openssl` installed
- Apache 2.4+ with mod_rewrite, mod_ssl, mod_proxy_fcgi, mod_headers

## Run Installer

```bash
sudo bash scripts/install.sh
```

## Installer Phases (10)

1. `check_prerequisites` — validates PHP, creates `aegir` user if absent
2. `setup_database` — creates MySQL database + user (credentials → `~/.aegir.db.conf`, chmod 600)
3. `install_dependencies` — `composer install` + `composer drupal:scaffold`
4. `create_directories` — `web/sites/{SITE_DIR}/files`, `private`, `tmp`, `config/sync`
5. `install_drupal` — `drush site:install standard` (15-minute timeout)
6. `fix_file_permissions` — aegir:www-data ownership, 775/664
7. `enable_aegir_modules` — enables 9 modules in dependency order
8. `clear_cache` — `drush cr`
9. `configure_webserver` — Apache vhost with security headers
10. `enable_dispatch_cron` — installs crontab via `drush hosting:dispatch-enable`

## Module Enable Order (Critical)

```bash
# Canonical Drush 13 command:
drush pm:enable hosting hosting_task hosting_server hosting_web_server hosting_db_server hosting_platform hosting_client hosting_package hosting_site -y

# 'drush en' is a still-supported alias for drush pm:enable, also valid:
# drush en hosting hosting_task ... -y
```

## Installer Flags

| Flag | Purpose |
|------|---------|
| `--dry-run` | Show what would be done without executing |
| `--skip-db` | Skip database creation (use existing) |
| `--db-pass PASSWORD` | Provide MySQL root password |
| `--force` | Overwrite existing installation |
| `--webserver apache\|skip` | Configure Apache or skip |
| `--config FILE` | Load config from file |

## Environment Variables

Override any setting: `AEGIR_HOSTNAME`, `AEGIR_DB_NAME`, `AEGIR_DB_USER`, `AEGIR_DB_PASS`, `AEGIR_DB_HOST`, `AEGIR_DB_PORT`, `AEGIR_EMAIL`

## Multi-Site Note

If `AEGIR_HOSTNAME != aegir.local`, site directory becomes `web/sites/{AEGIR_HOSTNAME}/` and a `sites.php` mapping is created. Current install uses `web/sites/aegir.local/`.

Execute the installation steps as described above, checking each phase completes successfully before proceeding.
