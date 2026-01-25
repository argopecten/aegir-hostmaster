The Aegir Hosting System (Drupal 11)
=====================================

Aegir is a powerful hosting platform for managing multiple Drupal sites. This 
repository provides a modern Composer-based Drupal 11 installation that deploys 
the complete Aegir hosting system.

The Aegir system consists of:
- **Hosting framework** (front end) - Drupal-based UI for managing sites
- **Provision framework** (backend) - Drush-based site provisioning system

Architecture
------------
The front end and back end are designed to work together, with each front end
able to drive multiple back ends for distributed hosting infrastructure.

Installation
------------

### Prerequisites
- PHP 8.3 or higher
- MySQL/MariaDB database server
- Apache or Nginx web server
- Composer
- Git

### Quick Start

1. Clone this repository:
   ```bash
   git clone <repository-url> aegir
   cd aegir
   ```

2. Run the installation script:
   ```bash
   ./install.sh
   ```

   The script will:
   - Verify system requirements
   - Install all Composer dependencies
   - Set up the database
   - Install Drupal 11
   - Enable and configure Aegir modules
   - Create necessary directories and configuration files

3. Configure your web server to point to the `web/` directory

4. Access your Aegir installation and get admin login link:
   ```bash
   ./vendor/bin/drush user:login
   ```

### Manual Installation

If you prefer to install manually:

1. Install dependencies:
   ```bash
   composer install
   ```

2. Create database and configure credentials in `web/sites/default/settings.php`

3. Install Drupal:
   ```bash
   ./vendor/bin/drush site:install standard
   ```

4. Enable Aegir modules:
   ```bash
   ./vendor/bin/drush pm:enable hosting hosting_task hosting_client \
     hosting_db_server hosting_package hosting_platform hosting_site \
     hosting_web_server hosting_server hosting_clone hosting_migrate -y
   ```

Updating
--------

To update your Aegir installation to the latest version:

```bash
./update.sh
```

The update script will:
- Put the site in maintenance mode
- Update all Composer dependencies
- Run database updates
- Clear caches
- Export configuration
- Bring the site back online

Project Structure
-----------------

```
aegir/
├── web/                    # Drupal web root (document root)
│   ├── core/              # Drupal core
│   ├── modules/           # Contributed and custom modules
│   ├── themes/            # Contributed and custom themes
│   ├── profiles/          # Installation profiles
│   └── sites/             # Site configuration and files
├── vendor/                # Composer dependencies
├── config/                # Configuration sync directory
├── drush/                 # Drush commands and configuration
├── composer.json          # Project dependencies
├── install.sh             # Installation script
├── update.sh              # Update script
└── README.txt             # This file
```

Configuration
-------------

### Database Credentials
Database credentials are stored in:
- `web/sites/default/settings.php` - Main Drupal configuration
- `~/.aegir.db.conf` - Backup credentials (created by install.sh)

### Environment Variables
You can customize the installation by setting these environment variables 
before running install.sh:

- `AEGIR_USER` - System user (default: aegir)
- `AEGIR_HOME` - Home directory (default: /var/aegir)
- `AEGIR_DB_USER` - Database user (default: aegir)
- `AEGIR_DB_NAME` - Database name (default: aegir)
- `AEGIR_DB_HOST` - Database host (default: localhost)
- `AEGIR_HOSTNAME` - Aegir hostname (default: aegir.local)
- `ADMIN_EMAIL` - Admin email address

Resources
---------

- **Aegir Project**: http://aegirproject.org
- **Community Portal**: http://community.aegirproject.org
- **Documentation**: https://docs.aegirproject.org
- **Issue Queue**: https://github.com/aegir-project/aegir

Support
-------

For support, please visit the Aegir community:
- IRC: #aegir on Libera.Chat
- GitHub: https://github.com/aegir-project

License
-------

This project is licensed under GPL-2.0-or-later.
