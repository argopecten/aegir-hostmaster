# Drupal Recipes Implementation for Aegir

## Overview

Implement Drupal Recipes to modernize Aegir installation and configuration management. Recipes provide composable, reusable configuration packages without the lock-in of installation profiles.

## Benefits

- **Reusability**: Apply recipes to existing sites, not just during installation
- **Modularity**: Compose multiple recipes for different configurations
- **Maintainability**: Declarative YAML instead of bash scripts for Drupal configuration
- **Flexibility**: Different recipe combinations for dev/staging/production
- **Testing**: Leverage Drupal core recipe testing infrastructure

## Implementation Phases

### Phase 1: Extract Configuration ⏳

1. **Export current configuration**
   ```bash
   drush config:export --destination=/tmp/aegir-config
   ```

2. **Analyze configuration needs**
   - Module installation list
   - Permission assignments
   - Role definitions
   - Theme settings
   - Hosting module configurations

3. **Document current install.sh behavior**
   - What happens during Drupal site:install
   - What configuration is applied post-install
   - What system-level setup occurs

### Phase 2: Create Base Recipe ⏳

**Location**: `recipes/aegir-hostmaster/`

**Files to create**:

1. **recipe.yml** - Main recipe definition
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
       
       user.role.authenticated:
         grantPermissions:
           - 'access hosting dashboard'
       
       user.role.hosting_admin:
         ensure_exists:
           id: hosting_admin
           label: 'Hosting Administrator'
         grantPermissions:
           - 'administer hosting'
           - 'create hosting sites'
           - 'view hosting tasks'
   ```

2. **README.md** - Recipe documentation

3. **config/** - Configuration imports (if needed)

### Phase 3: Create Environment Recipes ⏳

#### Development Recipe
**Location**: `recipes/aegir-development/`

```yaml
name: Aegir Development
description: 'Development tools for Aegir system'
type: Development

install:
  - devel
  - devel_generate
  - webprofiler
  - admin_toolbar
  - admin_toolbar_tools

config:
  actions:
    system.performance:
      simple_config_update:
        css.preprocess: false
        js.preprocess: false
    
    system.logging:
      simple_config_update:
        error_level: 'verbose'
```

#### Production Recipe
**Location**: `recipes/aegir-production/`

```yaml
name: Aegir Production
description: 'Security and performance configuration for production'
type: Production

config:
  actions:
    system.performance:
      simple_config_update:
        css.preprocess: true
        js.preprocess: true
        cache.page.max_age: 3600
    
    system.logging:
      simple_config_update:
        error_level: 'hide'
    
    hosting.settings:
      simple_config_update:
        backup_enabled: true
        backup_retention_days: 30
```

#### Multi-Server Recipe
**Location**: `recipes/aegir-multiserver/`

```yaml
name: Aegir Multi-Server
description: 'Enable distributed hosting infrastructure'
type: Infrastructure

install:
  - hosting_server_remote
  - hosting_ssh

config:
  import:
    hosting_server_remote: '*'
  
  actions:
    hosting.settings:
      simple_config_update:
        remote_enabled: true
        ssh_key_path: '/var/aegir/.ssh/id_rsa'
```

### Phase 4: Update Installation Script ⏳

**Modify**: `install.sh`

```bash
# After database setup, before current Drupal install

# Install Drupal with minimal profile
echo -e "${YELLOW}Installing Drupal...${NC}"
drush site:install minimal \
  --db-url="mysql://${AEGIR_DB_USER}:${AEGIR_DB_PASS}@${AEGIR_DB_HOST}/${AEGIR_DB_NAME}" \
  --site-name="Aegir Hosting System" \
  --account-mail="${ADMIN_EMAIL}" \
  --yes

# Apply Aegir Hostmaster recipe
echo -e "${YELLOW}Applying Aegir configuration...${NC}"
drush recipe ../recipes/aegir-hostmaster

# Optional: Apply environment-specific recipe
if [ "$AEGIR_ENV" = "development" ]; then
  echo -e "${YELLOW}Applying development configuration...${NC}"
  drush recipe ../recipes/aegir-development
elif [ "$AEGIR_ENV" = "production" ]; then
  echo -e "${YELLOW}Applying production configuration...${NC}"
  drush recipe ../recipes/aegir-production
fi

# Post-recipe backend configuration
echo -e "${YELLOW}Setting up Aegir backend...${NC}"
drush hosting:setup
```

### Phase 5: Testing & Documentation ⏳

1. **Test recipe application**
   - Fresh Drupal install → Apply recipe
   - Verify all modules enabled
   - Verify permissions set correctly
   - Verify theme applied
   - Verify hosting entities available

2. **Test recipe composition**
   ```bash
   # Test development stack
   drush site:install minimal
   drush recipe recipes/aegir-hostmaster
   drush recipe recipes/aegir-development
   
   # Test production stack
   drush site:install minimal
   drush recipe recipes/aegir-hostmaster
   drush recipe recipes/aegir-production
   
   # Test multi-server stack
   drush site:install minimal
   drush recipe recipes/aegir-hostmaster
   drush recipe recipes/aegir-multiserver
   ```

3. **Update documentation**
   - Installation guide with recipe options
   - Developer guide for creating custom recipes
   - Migration guide for existing Aegir installations

## Recipe Use Cases

### **Use Case 1: Fresh Installation**
```bash
./install.sh
# Script now uses recipe internally
```

### **Use Case 2: Add Aegir to Existing Drupal Site**
```bash
# Site already exists, add Aegir capabilities
drush recipe recipes/aegir-hostmaster
drush hosting:setup
```

### **Use Case 3: Switch Environment**
```bash
# Convert development to production
drush recipe recipes/aegir-production
```

### **Use Case 4: Enable Multi-Server**
```bash
# Add distributed hosting capabilities
drush recipe recipes/aegir-multiserver
```

### **Use Case 5: Update Configuration**
```bash
# After updating recipe.yml, reapply
drush recipe recipes/aegir-hostmaster --force
```

## Architecture Integration

### What Recipes Handle
✅ Drupal module installation (hosting_*, core modules)  
✅ Configuration import (entity types, views, permissions)  
✅ Role and permission setup  
✅ Theme configuration  
✅ System settings (caching, logging, performance)  
✅ Hosting-specific settings  

### What install.sh Still Handles
✅ System requirements validation (PHP, MySQL, Apache)  
✅ Database creation and user grants  
✅ File system permissions (aegir:www-data)  
✅ Apache/web server configuration  
✅ Provision/Drush backend setup  
✅ Context initialization  
✅ SSL certificate setup  
✅ Cron configuration  

### Hybrid Approach
```
┌─────────────────────────────────────────┐
│          install.sh                      │
│  ┌─────────────────────────────────┐   │
│  │ System Checks                    │   │
│  │ - PHP version                    │   │
│  │ - Required extensions            │   │
│  │ - MySQL connectivity             │   │
│  └─────────────────────────────────┘   │
│                ↓                         │
│  ┌─────────────────────────────────┐   │
│  │ Infrastructure Setup             │   │
│  │ - Database creation              │   │
│  │ - Directories & permissions      │   │
│  │ - Apache vhost template          │   │
│  └─────────────────────────────────┘   │
│                ↓                         │
│  ┌─────────────────────────────────┐   │
│  │ Drupal Base Install              │   │
│  │ - drush site:install minimal     │   │
│  └─────────────────────────────────┘   │
│                ↓                         │
│  ┌─────────────────────────────────┐   │
│  │ Apply Recipe                     │   │
│  │ - drush recipe aegir-hostmaster  │   │
│  │   • Module installation          │   │
│  │   • Configuration import         │   │
│  │   • Permissions setup            │   │
│  │   • Theme application            │   │
│  └─────────────────────────────────┘   │
│                ↓                         │
│  ┌─────────────────────────────────┐   │
│  │ Backend Configuration            │   │
│  │ - drush hosting:setup            │   │
│  │ - Context creation               │   │
│  │ - Queue worker setup             │   │
│  └─────────────────────────────────┘   │
└─────────────────────────────────────────┘
```

## Comparison: Recipes vs Installation Profile

| Aspect | Recipe | Installation Profile |
|--------|--------|---------------------|
| **Application timing** | After site install | During site install |
| **Multiple applications** | ✅ Yes - reapply anytime | ❌ No - one-time only |
| **Update existing site** | ✅ Yes | ❌ No |
| **Removable** | ✅ Possible | ❌ Permanent |
| **Compose multiple** | ✅ Yes - stack recipes | ❌ One profile per site |
| **Backend integration** | ➖ Still needs install.sh | ➖ Still needs install.sh |
| **Testing** | ✅ Drupal core infrastructure | ⚠️ Custom testing needed |
| **Documentation** | ✅ Declarative YAML | ⚠️ PHP code |
| **Drupal 11 alignment** | ✅ Modern approach | ⚠️ Legacy pattern |

## Migration Path for Existing Aegir Installations

### Option 1: Fresh Installation (Recommended)
1. Export hosting data from old installation
2. Install new Aegir using recipe-based install.sh
3. Import hosting data

### Option 2: In-Place Recipe Application
```bash
# Backup first!
drush sql:dump > backup.sql

# Apply recipe to running Aegir site
drush recipe recipes/aegir-hostmaster --force

# Verify configuration
drush config:status
drush hosting:verify
```

## File Structure

```
recipes/
├── README.txt                        # Overview of Aegir recipes
├── aegir-hostmaster/                 # Core Aegir functionality
│   ├── recipe.yml                    # Main recipe definition
│   ├── README.md                     # Recipe documentation
│   └── config/                       # Optional config imports
│       └── install/
│           ├── hosting.settings.yml
│           └── user.role.hosting_admin.yml
├── aegir-development/                # Development environment
│   ├── recipe.yml
│   └── README.md
├── aegir-production/                 # Production hardening
│   ├── recipe.yml
│   └── README.md
└── aegir-multiserver/                # Distributed hosting
    ├── recipe.yml
    └── README.md
```

## Acceptance Criteria

- [ ] Base recipe (`aegir-hostmaster`) created and tested
- [ ] Environment recipes created (development, production)
- [ ] Multi-server recipe created
- [ ] install.sh updated to use recipes
- [ ] Documentation updated (README.txt, INSTALL.md)
- [ ] Test suite for recipe application
- [ ] Migration guide for existing installations
- [ ] Recipe composition tested (multiple recipes applied)
- [ ] CI/CD pipeline tests recipe installation

## Related Documentation

- [Drupal Recipes Documentation](https://www.drupal.org/docs/extending-drupal/contributed-modules/distributions-and-recipes)
- [ARCHITECTURE.md](.github/ARCHITECTURE.md) - System architecture
- [README.txt](README.txt) - Current installation guide
- [install.sh](install.sh) - Current installation script

## Questions to Resolve

1. **Should recipes include sample data?**
   - Default server entity (localhost)
   - Example platform configurations
   - Demo site (optional)

2. **How to handle environment-specific settings?**
   - Environment variables in recipe.yml?
   - Separate recipes per environment?
   - Post-recipe configuration script?

3. **Recipe versioning strategy?**
   - Version in recipe.yml name?
   - Git tags for recipe releases?
   - Compatibility matrix with Aegir versions?

4. **Backend recipe integration?**
   - Can recipe trigger `drush hosting:setup`?
   - Should backend setup be separate step?
   - Recipe for Provision configuration?

## Future Enhancements

- **Recipe marketplace**: Publish Aegir recipes to Drupal.org
- **Custom site recipes**: Users create recipes for their hosting patterns
- **Recipe bundles**: Meta-recipes that apply multiple recipes
- **Recipe generator**: UI for creating custom Aegir recipes
- **Recipe rollback**: Undo recipe application
- **Recipe validation**: Lint/test recipes before application
