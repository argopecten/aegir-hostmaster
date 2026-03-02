# Aegir YAML Context Alias

Create, inspect, or troubleshoot Drush YAML context alias files for Aegir.

## File Location

`drush/sites/aegir/{context_name}.site.yml`

## Context Types and YAML Format

### Server Context

```yaml
server_master:
  provision:
    context_type: server
    aegir_root: /home/aegir
    remote_host: hostname
    script_user: aegir
    http_service_type: apache
    http_port: 80
    db_service_type: mysql
    db_port: 3306
    master_db_user: aegir_user
    master_db_passwd: password
  host: hostname
  user: aegir
```

### Platform Context

```yaml
platform_d11:
  provision:
    context_type: platform
    aegir_root: /home/aegir
    server: "@server_master"
    web_server: "@server_master"
    root: /var/aegir/platforms/drupal11
  root: /var/aegir/platforms/drupal11
  host: hostname
  user: aegir
```

### Site Context

```yaml
site.example.com:
  provision:
    context_type: site
    aegir_root: /home/aegir
    platform: "@platform_d11"
    db_server: "@server_master"
    uri: site.example.com
    profile: standard
    language: en
  uri: http://site.example.com
  root: /var/aegir/platforms/drupal11
  host: hostname
  user: aegir
```

## Naming Rules

| Context Type | Naming Pattern | Example |
|-------------|----------------|---------|
| Server | `server_{sanitized_hostname}` | `server_master` |
| Platform | sanitized platform name with `platform_` prefix | `platform_d11` |
| Site | domain directly (NO `@` prefix in storage) | `example.com` |

## Inspecting Contexts

```bash
# Via Drush (preferred — includes merged data)
drush site:alias @server_master
drush site:alias @example.com

# Raw YAML file
cat drush/sites/aegir/server_master.site.yml
cat drush/sites/aegir/example.com.site.yml

# All contexts
ls drush/sites/aegir/

# Check via database
drush sql:query "SELECT * FROM hosting_context"
```

## Creating via provision:save

```bash
# Create/update a server context
drush provision:save @server_master --type=server \
  --data='{"http_service_type":"apache","db_service_type":"mysql"}'

# Create/update a platform context
drush provision:save @platform_d11 --type=platform \
  --data='{"root":"/var/aegir/platforms/drupal11","server":"@server_master"}'

# Create/update a site context
drush provision:save @example.com --type=site \
  --data='{"platform":"@platform_d11","db_server":"@server_master","uri":"example.com"}'
```

## Context Hierarchy

```
Site (@example.com)
  └── platform: @platform_d11
        └── server: @server_master (HTTP)
  └── db_server: @server_master (DB)
```

References always use `@` prefix in YAML values. Storage (database, PHP) uses canonical name WITHOUT `@`.

Inspect or create the context alias files as described by the user. Always verify with `drush site:alias` after creation.
