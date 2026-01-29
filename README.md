# Aegir Hostmaster (Drupal 11)

[![Drupal 11](https://img.shields.io/badge/Drupal-11-blue.svg)](https://www.drupal.org)
[![PHP 8.3+](https://img.shields.io/badge/PHP-8.3+-777BB4.svg)](https://www.php.net)
[![License](https://img.shields.io/badge/license-GPL--2.0+-green.svg)](LICENSE)

> **Aegir** is a powerful hosting platform for managing multiple Drupal sites. This repository provides a modern Composer-based Drupal 11 installation that deploys the complete Aegir hosting system.

## 🏗️ System Architecture

Aegir consists of three integrated components:

- **[Frontend (aegir-hosting)](web/modules/contrib/aegir-hosting)** - Drupal 11 modules providing the entity layer, forms, and task management
- **[Backend (aegir-provision)](drush/Commands/contrib/aegir-provision)** - Drush 13 extension automating infrastructure operations
- **[Theme (aegir-eldir)](web/themes/contrib/aegir-eldir)** - Drupal 11 theme providing the hosting management UI

**Data Flow**: User actions on Drupal entities (sites, platforms, servers) trigger tasks that execute Provision commands via Drush, operating on immutable context data stored as YAML aliases.

📚 **[Complete Architecture Documentation](doc/HOME.md)**

## ✨ Features

- **Multi-site Management** - Host multiple Drupal sites on multiple platforms
- **Automated Deployment** - Create, clone, migrate, and backup sites through the UI
- **Server Management** - Manage Apache, MySQL, and other services across multiple servers
- **Task Queue System** - Asynchronous execution of infrastructure operations
- **Platform Tracking** - Monitor Drupal distributions and available updates
- **Client Management** - Multi-tenancy with client quotas and permissions

## 📋 Prerequisites

- **OS**: Ubuntu 24.04 LTS (recommended)
- **PHP**: 8.3 or higher with extensions:
  - `php8.3-cli`, `php8.3-fpm`
  - `php8.3-mysql`, `php8.3-gd`, `php8.3-curl`
  - `php8.3-xml`, `php8.3-mbstring`, `php8.3-zip`
- **Web Server**: Apache 2.4+ with modules:
  - `mod_rewrite`, `mod_ssl`, `mod_proxy_fcgi`, `mod_headers`
- **Database**: MySQL 8.0+ or MariaDB 10.6+
- **Tools**: Composer 2.x, Git

## 🚀 Quick Start

### 1. Clone Repository

```bash
git clone <repository-url> aegir
cd aegir
```

### 2. Run Installation Script

```bash
./scripts/install.sh
```

The script will:
- ✓ Verify system requirements
- ✓ Install all Composer dependencies
- ✓ Set up the database
- ✓ Install Drupal 11
- ✓ Enable and configure Aegir modules
- ✓ Create necessary directories and configuration files

### 3. Configure Web Server

Point your web server document root to `web/` directory.

### 4. Access Installation

```bash
./vendor/bin/drush user:login
```

## 🔧 Manual Installation

If you prefer to install manually:

### 1. Install Dependencies

```bash
composer install
```

### 2. Configure Database

Create database and update credentials in `web/sites/default/settings.php`

### 3. Install Drupal

```bash
./vendor/bin/drush site:install standard
```

### 4. Enable Aegir Modules

```bash
./vendor/bin/drush pm:enable hosting hosting_task hosting_client \
  hosting_db_server hosting_package hosting_platform hosting_site \
  hosting_web_server hosting_server hosting_clone hosting_migrate -y
```

## 🔄 Updating

To update your Aegir installation to the latest version:

```bash
./scripts/update.sh
```

The update script will:
- ⏸️ Put the site in maintenance mode
- 📦 Update all Composer dependencies
- 🗃️ Run database updates
- 🧹 Clear caches
- 📤 Export configuration
- ✅ Bring the site back online

## 📁 Project Structure

```
aegir/
├── web/                    # Drupal web root (document root)
│   ├── core/              # Drupal core
│   ├── modules/
│   │   └── contrib/
│   │       └── aegir-hosting/    # Frontend modules
│   ├── themes/
│   │   └── contrib/
│   │       └── aegir-eldir/      # Aegir theme
│   └── sites/             # Site configuration and files
├── drush/
│   └── Commands/
│       └── contrib/
│           └── aegir-provision/  # Backend Drush extension
├── vendor/                # Composer dependencies
├── doc/                   # Documentation
├── recipes/               # Drupal recipes
├── scripts/               # Installation and maintenance scripts
│   ├── install.sh        # Installation script
│   └── update.sh         # Update script
├── composer.json          # Project dependencies
└── README.md              # This file
```

## ⚙️ Configuration

### Database Credentials

Database credentials are stored in:
- `web/sites/default/settings.php` - Main Drupal configuration
- `~/.aegir.db.conf` - Backup credentials (created by scripts/install.sh)

### Environment Variables

Customize the installation by setting these environment variables before running `scripts/install.sh`:

| Variable | Default | Description |
|----------|---------|-------------|
| `AEGIR_USER` | aegir | System user |
| `AEGIR_HOME` | /var/aegir | Home directory |
| `AEGIR_DB_USER` | aegir | Database user |
| `AEGIR_DB_NAME` | aegir | Database name |
| `AEGIR_DB_HOST` | localhost | Database host |
| `AEGIR_HOSTNAME` | aegir.local | Aegir hostname |
| `ADMIN_EMAIL` | - | Admin email address |

## 📖 Documentation

### User Documentation

- **[Home & Architecture](doc/HOME.md)** - System overview and architectural design
- **[Frontend Guide](doc/Frontend.md)** - Hosting modules, entities, and forms
- **[Backend Guide](doc/Backend.md)** - Provision system, contexts, and services
- **[Theme Guide](doc/Theme.md)** - Eldir theme, templates, and styling
- **[Development TODO](doc/TODO.md)** - Roadmap and future goals

### For AI Coding Agents

> **AI Assistants**: Start with **[.github/AI-AGENT-GUIDE.md](.github/AI-AGENT-GUIDE.md)** for complete navigation guidance

- **[AI Agent Guide](.github/AI-AGENT-GUIDE.md)** - Navigation across all four repositories
- **[Architecture (AI)](.github/ARCHITECTURE.md)** - Technical architecture for AI agents
- **[AI Documentation](doc/AI-DOCUMENTATION.md)** - Overview of AI docs structure

## 🛠️ Development Workflow

### Working with Components

Each component has its own documentation:

- **Backend**: [drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md](drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
- **Frontend**: [web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md](web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
- **Theme**: [web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md](web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)

### Composer Management

- Never manually edit `web/core/`, `web/modules/contrib/`, or `vendor/`
- Add modules: `composer require drupal/module_name`
- Custom code goes in: `web/modules/custom/`, `web/themes/custom/`

### Drush Commands

Common development commands:

```bash
# Clear cache
./vendor/bin/drush cache:rebuild

# Export configuration
./vendor/bin/drush config:export

# Run database updates
./vendor/bin/drush updatedb

# Get admin login link
./vendor/bin/drush user:login
```

## 🧪 Testing

```bash
# Run PHPUnit tests
./vendor/bin/phpunit web/modules/contrib/aegir-hosting

# Run code standards checks
./vendor/bin/phpcs --standard=Drupal web/modules/custom/

# Fix coding standards
./vendor/bin/phpcbf --standard=Drupal web/modules/custom/
```

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

## 🔗 Resources

- **Aegir Project**: https://aegirproject.org
- **Community Portal**: https://community.aegirproject.org
- **Documentation**: https://docs.aegirproject.org
- **Issue Queue**: https://github.com/aegir-project/aegir

## 💬 Support

For support, please visit the Aegir community:
- **IRC**: #aegir on Libera.Chat
- **GitHub**: https://github.com/aegir-project
- **Community Forums**: https://community.aegirproject.org

## 📄 License

This project is licensed under [GPL-2.0-or-later](LICENSE).

---

**Made with ❤️ by the Aegir community**
