# Aegir Update Workflow

Update Aegir Hostmaster to the latest code.

## Steps

Run these commands in order:

```bash
# 1. Backup database
drush sql:dump --result-file=~/backup-$(date +%Y%m%d).sql

# 2. Enable maintenance mode
drush state:set system.maintenance_mode 1 --input-format=integer

# 3. Update dependencies
composer update --no-interaction --prefer-dist --optimize-autoloader

# 4. Run database updates
drush updatedb -y

# 5. Rebuild cache
drush cr

# 6. Export config
drush config:export -y

# 7. Run cron
drush cron

# 8. Disable maintenance mode
drush state:set system.maintenance_mode 0 --input-format=integer

# 9. Check for security vulnerabilities
drush pm:security

# 10. Verify status
drush status
```

## Known Bug in scripts/update.sh

`scripts/update.sh` checks `web/sites/default/settings.php` but the current install uses `web/sites/aegir.local/settings.php`. Run the commands above manually instead.

## After Update

Verify the Aegir hosting system is working:
```bash
drush hosting:dispatch
drush queue:list
drush pm:list --type=module --status=enabled | grep hosting
```

Execute the update workflow above, verifying each step succeeds before continuing.
