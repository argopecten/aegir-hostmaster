#!/bin/bash
set -e

# Aegir Installation Script
# This script installs the Aegir hosting system using Drupal 11 and Composer

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Aegir Hosting System Installation${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# Configuration variables - customize these for your environment
AEGIR_USER="${AEGIR_USER:-aegir}"
AEGIR_HOME="${AEGIR_HOME:-/var/aegir}"
AEGIR_DB_USER="${AEGIR_DB_USER:-aegir}"
AEGIR_DB_NAME="${AEGIR_DB_NAME:-aegir}"
AEGIR_DB_HOST="${AEGIR_DB_HOST:-localhost}"
AEGIR_HOSTNAME="${AEGIR_HOSTNAME:-aegir.local}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${AEGIR_HOSTNAME}}"

# Check if running as root
if [[ $EUID -eq 0 ]]; then 
   echo -e "${RED}Error: This script should not be run as root${NC}" 
   echo -e "${YELLOW}Please run as the aegir user or with appropriate permissions${NC}"
   exit 1
fi

# Verify we're in the right directory
if [ ! -f "composer.json" ]; then
    echo -e "${RED}Error: composer.json not found${NC}"
    echo -e "${YELLOW}Please run this script from the Aegir project root${NC}"
    exit 1
fi

# Check prerequisites
echo -e "${YELLOW}Checking prerequisites...${NC}"

command -v php >/dev/null 2>&1 || { echo -e "${RED}Error: PHP is not installed${NC}"; exit 1; }
command -v composer >/dev/null 2>&1 || { echo -e "${RED}Error: Composer is not installed${NC}"; exit 1; }
command -v mysql >/dev/null 2>&1 || { echo -e "${RED}Error: MySQL client is not installed${NC}"; exit 1; }

PHP_VERSION=$(php -r 'echo PHP_VERSION;')
echo -e "${GREEN}✓ PHP version: ${PHP_VERSION}${NC}"
echo -e "${GREEN}✓ Composer found${NC}"

# Check PHP version requirement
if php -r 'exit(version_compare(PHP_VERSION, "8.3.0", ">=") ? 0 : 1);'; then
    echo -e "${GREEN}✓ PHP version meets requirements (>= 8.3)${NC}"
else
    echo -e "${RED}Error: PHP 8.3 or higher is required${NC}"
    exit 1
fi

# Database setup
echo
echo -e "${YELLOW}Setting up database...${NC}"
read -sp "Enter MySQL root password (or press Enter to skip DB creation): " MYSQL_ROOT_PASSWORD
echo

if [ ! -z "$MYSQL_ROOT_PASSWORD" ]; then
    # Generate random password for Aegir DB user
    AEGIR_DB_PASS=$(openssl rand -base64 32 | tr -d "=+/" | cut -c1-25)
    
    mysql -u root -p"${MYSQL_ROOT_PASSWORD}" <<EOF
CREATE DATABASE IF NOT EXISTS ${AEGIR_DB_NAME} CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER IF NOT EXISTS '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}' IDENTIFIED BY '${AEGIR_DB_PASS}';
GRANT ALL PRIVILEGES ON ${AEGIR_DB_NAME}.* TO '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}';
FLUSH PRIVILEGES;
EOF
    
    echo -e "${GREEN}✓ Database created${NC}"
    echo -e "${YELLOW}Database credentials saved to: ${AEGIR_HOME}/.aegir.db.conf${NC}"
    
    # Save DB credentials
    cat > "${AEGIR_HOME}/.aegir.db.conf" <<EOF
# Aegir Database Credentials
# Generated on $(date)
AEGIR_DB_HOST=${AEGIR_DB_HOST}
AEGIR_DB_NAME=${AEGIR_DB_NAME}
AEGIR_DB_USER=${AEGIR_DB_USER}
AEGIR_DB_PASS=${AEGIR_DB_PASS}
EOF
    chmod 600 "${AEGIR_HOME}/.aegir.db.conf"
else
    echo -e "${YELLOW}Skipping database creation. Ensure database exists and credentials are configured.${NC}"
    # Try to load existing credentials
    if [ -f "${AEGIR_HOME}/.aegir.db.conf" ]; then
        source "${AEGIR_HOME}/.aegir.db.conf"
    else
        echo -e "${RED}Error: No database credentials found${NC}"
        echo -e "${YELLOW}Please create ${AEGIR_HOME}/.aegir.db.conf with DB credentials${NC}"
        exit 1
    fi
fi

# Install Composer dependencies
echo
echo -e "${YELLOW}Installing Composer dependencies...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"

composer install --no-interaction --prefer-dist --optimize-autoloader

echo -e "${GREEN}✓ Composer dependencies installed${NC}"

# Create web/sites/default/settings.php
echo
echo -e "${YELLOW}Creating Drupal settings file...${NC}"

if [ ! -d "web/sites/default" ]; then
    mkdir -p web/sites/default
fi

# Create settings.php from default
if [ -f "web/sites/default/default.settings.php" ]; then
    cp web/sites/default/default.settings.php web/sites/default/settings.php
fi

# Append database settings
cat >> web/sites/default/settings.php <<EOF

// Aegir database configuration
\$databases['default']['default'] = array (
  'database' => '${AEGIR_DB_NAME}',
  'username' => '${AEGIR_DB_USER}',
  'password' => '${AEGIR_DB_PASS}',
  'host' => '${AEGIR_DB_HOST}',
  'port' => '3306',
  'driver' => 'mysql',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
);

\$settings['hash_salt'] = '$(openssl rand -base64 75 | tr -d "\n")';
\$settings['config_sync_directory'] = '../config/sync';
\$settings['file_private_path'] = 'sites/default/files/private';

// Aegir specific settings
\$settings['aegir']['mode'] = 'hosted';
EOF

chmod 644 web/sites/default/settings.php
echo -e "${GREEN}✓ Settings file created${NC}"

# Create necessary directories
echo
echo -e "${YELLOW}Creating directories...${NC}"
mkdir -p web/sites/default/files
mkdir -p web/sites/default/files/private
mkdir -p config/sync
chmod 755 web/sites/default/files
chmod 755 web/sites/default/files/private

echo -e "${GREEN}✓ Directories created${NC}"

# Install Drupal
echo
echo -e "${YELLOW}Installing Drupal...${NC}"

./vendor/bin/drush site:install standard \
  --db-url="mysql://${AEGIR_DB_USER}:${AEGIR_DB_PASS}@${AEGIR_DB_HOST}/${AEGIR_DB_NAME}" \
  --site-name="Aegir Hosting System" \
  --site-mail="${ADMIN_EMAIL}" \
  --account-name=admin \
  --account-mail="${ADMIN_EMAIL}" \
  --yes

echo -e "${GREEN}✓ Drupal installed${NC}"

# Enable Aegir modules
echo
echo -e "${YELLOW}Enabling Aegir modules...${NC}"

./vendor/bin/drush pm:enable hosting hosting_task hosting_client hosting_db_server \
  hosting_package hosting_platform hosting_site hosting_web_server hosting_server \
  hosting_clone hosting_migrate admin_toolbar admin_toolbar_tools -y

echo -e "${GREEN}✓ Aegir modules enabled${NC}"

# Clear cache
echo
echo -e "${YELLOW}Clearing cache...${NC}"
./vendor/bin/drush cache:rebuild

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Installation Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${GREEN}Aegir has been successfully installed.${NC}"
echo
echo -e "${YELLOW}Next steps:${NC}"
echo -e "1. Configure your web server to point to: $(pwd)/web"
echo -e "2. Access Aegir at: http://${AEGIR_HOSTNAME}"
echo -e "3. Get admin login link: ./vendor/bin/drush user:login"
echo
echo -e "${YELLOW}Database credentials are stored in: ${AEGIR_HOME}/.aegir.db.conf${NC}"
echo
