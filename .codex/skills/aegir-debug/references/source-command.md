# Aegir Debug

Diagnose and debug Aegir operations. Investigate the issue described by the user and work through these diagnostic steps systematically.

## Context Inspection

```bash
# View context as Drush sees it (Drush 13: site:alias is canonical)
drush site:alias @example.com
drush site:alias @example.com --format=yaml   # Force YAML output format
drush site:alias @example.com --format=json   # Force JSON output format

# List all known aliases
drush site:alias                              # All aliases
drush site:alias --filter=example            # Filter by name

# View raw YAML alias file on disk
cat drush/sites/aegir/example.com.site.yml

# Check entity↔context mapping in database
drush sql:query "SELECT * FROM hosting_context WHERE context_name='example.com'"
```

## Task Queue Debugging

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

## Backend (Provision) Testing

```bash
# List all available provision commands (Drush 13)
drush list --filter=provision

# Test a provision command directly
drush provision:verify @example.com

# Run with full debug output (Drush 13: --debug sets verbosity to debug level)
drush provision:verify @server_master --debug -vvv 2>&1 | tee /tmp/provision-debug.log

# Check Apache config syntax
sudo apache2ctl -t

# List vhosts
ls -la /var/aegir/config/apache/vhost.d/

# Test MySQL connectivity
drush provision:save @test_server --type=server --data='{"db_service_type":"mysql"}'
```

## Frontend Testing

```bash
drush cr                    # Clear cache (alias for drush cache:rebuild)
drush pm:list --type=module --status=enabled | grep hosting

# Check for pending entity schema changes (drush entity:updates removed in Drush 11)
drush php:eval "print_r(\Drupal::entityDefinitionUpdateManager()->getChangeSummary());"

# Apply pending entity schema changes (since project avoids update hooks, reinstall instead)
drush pm:uninstall {module} -y && drush pm:enable {module} -y
```

## Common Failure Points

| Symptom | Cause | Fix |
|---------|-------|-----|
| Task stays `queued` | Cron not running | `drush cron` or check crontab |
| Task goes to `error` | Backend command failed | Check task logs for stderr |
| No YAML file | ContextRegistry didn't sync | Call `$contextRegistry->syncToContext($entity)` |
| "Context not found" | Missing YAML alias | Run `provision:save` first |
| "Service not registered" | Missing service key in context | Add `http_service`, `db_service` to YAML |
| Apache won't reload | Syntax error in vhost | `sudo apache2ctl configtest` |
| DB connection refused | Wrong credentials | Check `db_host`, `db_port`, `db_user` keys |
| Permission denied | File ownership | Check `aegir` user owns paths, `www-data` group |
| Template not used | Wrong filename | Check hyphens vs underscores |
| JS not attaching | Missing `once()` | Check `context` scoping in behavior |

## LockManager Known Bug

`LockManager.php` instantiates abstract `ProvisionEvent` directly — PHP Fatal Error at runtime. If lock operations crash, the fix is to create concrete `LockEvent`/`UnlockEvent` classes extending `ProvisionEvent`.

Diagnose the issue described by the user using the commands and reference above. Run diagnostic commands, interpret output, and identify the root cause before suggesting fixes.
