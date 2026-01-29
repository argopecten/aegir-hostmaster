#!/bin/bash

# Aegir Installation Script
# This script installs the Aegir hosting system using Drupal 11 and Composer
#
# Requirements:
#   - Ubuntu 24.04 LTS
#   - MySQL 8.0+
#   - PHP 8.3+
#   - Apache 2.4+
#
# IMPORTANT: This script must be run as root or with sudo
#
# Usage: sudo ./install.sh [OPTIONS]
# Options:
#   --dry-run          Show what would be done without executing
#   --skip-db          Skip database setup (use existing DB)
#   --db-pass PASS     MySQL database password (skip root password prompt)
#   --force            Force reinstall (removes existing installation)
#   --config FILE      Load configuration from file
#   -h, --help         Show this help message

set -euo pipefail
IFS=$'\n\t'

# ============================================================================
# Configuration and Constants
# ============================================================================

# Script metadata
readonly SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
readonly SCRIPT_VERSION="1.0.1"

# Color output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[1;33m'
readonly BLUE='\033[0;34m'
readonly NC='\033[0m'

# Default configuration
AEGIR_USER="${AEGIR_USER:-aegir}"
AEGIR_HOME="${AEGIR_HOME:-/var/aegir}"
AEGIR_DB_USER="${AEGIR_DB_USER:-aegir}"
AEGIR_DB_NAME="${AEGIR_DB_NAME:-aegir}"
AEGIR_DB_HOST="${AEGIR_DB_HOST:-localhost}"
AEGIR_DB_PORT="${AEGIR_DB_PORT:-3306}"
AEGIR_HOSTNAME="${AEGIR_HOSTNAME:-aegir.local}"
ADMIN_EMAIL="${ADMIN_EMAIL:-admin@${AEGIR_HOSTNAME}}"

# Site directory (default or hostname-specific for multi-site)
if [ "${AEGIR_HOSTNAME}" = "aegir.local" ]; then
    SITE_DIR="default"
else
    SITE_DIR="${AEGIR_HOSTNAME}"
fi

# Required PHP version
readonly REQUIRED_PHP_VERSION="8.3.0"

# Installation flags
DRY_RUN=false
SKIP_DB=false
FORCE_INSTALL=false
CONFIG_FILE=""
DB_PASS_PROVIDED=""
WEBSERVER="apache"  # Options: apache, skip

# Track original user who invoked sudo
ORIGINAL_USER="${SUDO_USER:-}"
if [ -z "$ORIGINAL_USER" ]; then
    ORIGINAL_USER="$AEGIR_USER"
fi

# Required commands
readonly REQUIRED_COMMANDS=("php" "composer" "mysql" "openssl")

# Aegir core modules to enable (order matters - dependencies must be installed first)
# Dependency tree:
#   hosting (base)
#   ├── hosting_task
#   └── hosting_server
#       ├── hosting_web_server
#       ├── hosting_db_server
#       └── hosting_platform
#           ├── hosting_client (PlatformAccess references Platform)
#           ├── hosting_package (PackageInstance references Platform)
#           └── hosting_site (references Platform, Package, Client, Server)
readonly AEGIR_CORE_MODULES=(
    "hosting"
    "hosting_task"
    "hosting_server"
    "hosting_web_server"
    "hosting_db_server"
    "hosting_platform"
    "hosting_client"        # Must come AFTER hosting_platform (PlatformAccess references Platform)
    "hosting_package"       # Must come AFTER hosting_platform (PackageInstance references Platform)
    "hosting_site"          # Must come last (references most other modules)
)

# ============================================================================
# Utility Functions
# ============================================================================

# Print colored output
print_header() {
    echo -e "${GREEN}========================================${NC}"
    echo -e "${GREEN}  $1${NC}"
    echo -e "${GREEN}========================================${NC}"
}

print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ Error: $1${NC}" >&2
}

print_warning() {
    echo -e "${YELLOW}⚠ Warning: $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_step() {
    echo
    echo -e "${YELLOW}▶ $1${NC}"
}

# Exit with error message
die() {
    print_error "$1"
    exit 1
}

# Check if running in dry-run mode
execute_or_simulate() {
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would execute: $*"
        return 0
    else
        "$@"
    fi
}

# Run command as aegir user
run_as_aegir() {
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would run as ${AEGIR_USER}: $*"
        return 0
    fi
    
    if ! id "${AEGIR_USER}" &>/dev/null; then
        die "User ${AEGIR_USER} does not exist. Create user first."
    fi
    
    su - "${AEGIR_USER}" -c "cd ${PROJECT_ROOT} && $*"
}

# Check if user exists
user_exists() {
    id "$1" &>/dev/null
}

# Create aegir user if needed
ensure_aegir_user() {
    if user_exists "${AEGIR_USER}"; then
        print_success "User ${AEGIR_USER} already exists"
        return 0
    fi
    
    print_step "Creating aegir user..."
    
    if [ "$DRY_RUN" = false ]; then
        # Create user with home directory
        useradd -r -m -d "${AEGIR_HOME}" -s /bin/bash "${AEGIR_USER}" \
            || die "Failed to create user ${AEGIR_USER}"
        
        print_success "User ${AEGIR_USER} created"
    else
        print_info "[DRY RUN] Would create user ${AEGIR_USER}"
    fi
}

# ============================================================================
# Validation Functions
# ============================================================================

# Validate email address
validate_email() {
    local email="$1"
    if [[ ! "$email" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
        return 1
    fi
    return 0
}

# Validate hostname
validate_hostname() {
    local hostname="$1"
    if [[ ! "$hostname" =~ ^[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?(\.[a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?)*$ ]]; then
        return 1
    fi
    return 0
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check PHP version
check_php_version() {
    local current_version
    current_version=$(php -r 'echo PHP_VERSION;')
    
    if php -r "exit(version_compare(PHP_VERSION, '${REQUIRED_PHP_VERSION}', '>=') ? 0 : 1);"; then
        print_success "PHP version: ${current_version} (>= ${REQUIRED_PHP_VERSION})"
        return 0
    else
        print_error "PHP version ${current_version} does not meet requirement (>= ${REQUIRED_PHP_VERSION})"
        return 1
    fi
}

# ============================================================================
# System Checks
# ============================================================================

check_prerequisites() {
    print_step "Checking prerequisites..."
    
    # Check if running as root
    if [[ $EUID -ne 0 ]]; then 
        die "This script must be run as root or with sudo. Try: sudo $0"
    fi
    
    # Verify project root
    if [ ! -f "${PROJECT_ROOT}/composer.json" ]; then
        die "composer.json not found. Please run this script from the Aegir project root."
    fi
    
    cd "${PROJECT_ROOT}" || die "Cannot change to project root directory"
    
    # Ensure aegir user exists
    ensure_aegir_user
    
    # Check required commands
    local missing_commands=()
    for cmd in "${REQUIRED_COMMANDS[@]}"; do
        if ! command_exists "$cmd"; then
            missing_commands+=("$cmd")
        fi
    done
    
    if [ ${#missing_commands[@]} -gt 0 ]; then
        die "Missing required commands: ${missing_commands[*]}"
    fi
    
    print_success "All required commands found"
    
    # Check PHP version
    check_php_version || exit 1
    
    # Check for existing installation
    if [ -f "web/sites/${SITE_DIR}/settings.php" ] && [ "$FORCE_INSTALL" = false ]; then
        print_warning "Existing installation detected at web/sites/${SITE_DIR}/settings.php"
        read -p "Do you want to continue and overwrite? (yes/no): " -r
        if [[ ! $REPLY =~ ^[Yy]es$ ]]; then
            die "Installation cancelled by user"
        fi
    fi
    
    # Validate configuration
    if ! validate_email "$ADMIN_EMAIL"; then
        die "Invalid admin email address: $ADMIN_EMAIL"
    fi
    
    if ! validate_hostname "$AEGIR_HOSTNAME"; then
        die "Invalid hostname: $AEGIR_HOSTNAME"
    fi
    
    print_success "Prerequisites check completed"
}

# ============================================================================
# Database Functions
# ============================================================================

# Generate secure random password
generate_password() {
    openssl rand -base64 32 | tr -d "=+/" | cut -c1-32
}

# Create database and user
setup_database() {
    if [ "$SKIP_DB" = true ]; then
        print_warning "Skipping database setup as requested"
        load_database_credentials
        test_database_connection || die "Database connection test failed"
        return 0
    fi
    
    print_step "Setting up database..."
    
    # Generate secure password for Aegir DB user if not provided
    if [ -z "${DB_PASS_PROVIDED}" ]; then
        AEGIR_DB_PASS=$(generate_password)
    else
        AEGIR_DB_PASS="${DB_PASS_PROVIDED}"
    fi
    
    # Try to create database without password first (Unix socket auth)
    print_info "Attempting to create database..."
    
    if [ "$DRY_RUN" = false ]; then
        # Try MySQL without password (Unix socket authentication)
        if mysql -u root <<EOF 2>/dev/null
CREATE DATABASE IF NOT EXISTS \`${AEGIR_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}';
CREATE USER '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}' IDENTIFIED BY '${AEGIR_DB_PASS}';
GRANT ALL PRIVILEGES ON \`${AEGIR_DB_NAME}\`.* TO '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}';
FLUSH PRIVILEGES;
EOF
        then
            print_success "Database created using Unix socket authentication"
            save_database_credentials
            test_database_connection || die "Database connection test failed"
            return 0
        fi
        
        # If that fails, prompt for password
        print_info "Unix socket authentication failed, prompting for password..."
        local mysql_root_password
        read -rsp "Enter MySQL root password (or press Enter to skip DB creation): " mysql_root_password
        echo
        
        if [ -z "$mysql_root_password" ]; then
            print_warning "Skipping database creation. Ensure database exists and credentials are configured."
            load_database_credentials
            test_database_connection || die "Database connection test failed"
            return 0
        fi
        
        # Create temporary MySQL defaults file for secure password passing
        local mysql_config_file
        mysql_config_file=$(mktemp)
        trap "rm -f ${mysql_config_file}" EXIT
        
        cat > "${mysql_config_file}" <<EOF
[client]
user=root
password=${mysql_root_password}
host=${AEGIR_DB_HOST}
port=${AEGIR_DB_PORT}
EOF
        chmod 600 "${mysql_config_file}"
        
        if ! mysql --defaults-file="${mysql_config_file}" <<EOF
CREATE DATABASE IF NOT EXISTS \`${AEGIR_DB_NAME}\` CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
DROP USER IF EXISTS '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}';
CREATE USER '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}' IDENTIFIED BY '${AEGIR_DB_PASS}';
GRANT ALL PRIVILEGES ON \`${AEGIR_DB_NAME}\`.* TO '${AEGIR_DB_USER}'@'${AEGIR_DB_HOST}';
FLUSH PRIVILEGES;
EOF
        then
            rm -f "${mysql_config_file}"
            die "Failed to create database. Check MySQL credentials and permissions."
        fi
        
        rm -f "${mysql_config_file}"
        print_success "Database created successfully"
        save_database_credentials
        test_database_connection || die "Database connection test failed"
    else
        print_info "[DRY RUN] Would create database ${AEGIR_DB_NAME} and user ${AEGIR_DB_USER}"
    fi
}

# Save database credentials securely
save_database_credentials() {
    local cred_file="${AEGIR_HOME}/.aegir.db.conf"
    
    cat > "${cred_file}" <<EOF
# Aegir Database Credentials
# Generated on $(date)
# DO NOT commit this file to version control

AEGIR_DB_HOST='${AEGIR_DB_HOST}'
AEGIR_DB_PORT='${AEGIR_DB_PORT}'
AEGIR_DB_NAME='${AEGIR_DB_NAME}'
AEGIR_DB_USER='${AEGIR_DB_USER}'
AEGIR_DB_PASS='${AEGIR_DB_PASS}'
EOF
    
    chmod 600 "${cred_file}"
    chown "${AEGIR_USER}:${AEGIR_USER}" "${cred_file}"
    print_success "Database credentials saved to: ${cred_file}"
}

# Load existing database credentials
load_database_credentials() {
    local cred_file="${AEGIR_HOME}/.aegir.db.conf"
    
    if [ -f "${cred_file}" ]; then
        # shellcheck source=/dev/null
        source "${cred_file}"
        print_success "Loaded database credentials from ${cred_file}"
    else
        die "No database credentials found. Create ${cred_file} or run with database setup."
    fi
}

# Test database connection
test_database_connection() {
    print_info "Testing database connection as ${AEGIR_DB_USER}..."
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would test database connection"
        return 0
    fi
    
    if mysql -h"${AEGIR_DB_HOST}" -P"${AEGIR_DB_PORT}" -u"${AEGIR_DB_USER}" -p"${AEGIR_DB_PASS}" "${AEGIR_DB_NAME}" -e "SELECT 1;" &>/dev/null; then
        print_success "Database connection successful"
        return 0
    else
        print_error "Failed to connect to database with provided credentials"
        print_info "Host: ${AEGIR_DB_HOST}:${AEGIR_DB_PORT}"
        print_info "Database: ${AEGIR_DB_NAME}"
        print_info "User: ${AEGIR_DB_USER}"
        return 1
    fi
}

# ============================================================================
# Composer Functions
# ============================================================================

install_dependencies() {
    print_step "Installing Composer dependencies as ${AEGIR_USER}..."
    print_info "This may take several minutes..."
    
    # Ensure project directory is owned by aegir user
    if [ "$DRY_RUN" = false ]; then
        chown -R "${AEGIR_USER}:${AEGIR_USER}" "${PROJECT_ROOT}"
    fi
    
    run_as_aegir "composer install --no-interaction --prefer-dist --optimize-autoloader --no-progress" \
        || die "Failed to install Composer dependencies"
    
    print_success "Composer dependencies installed"
    
    # Scaffold Drupal files (generates .htaccess for clean URLs)
    print_info "Scaffolding Drupal files (.htaccess, robots.txt, etc.)..."
    run_as_aegir "composer drupal:scaffold" \
        || print_warning "Failed to scaffold Drupal files (non-fatal)"
    
    if [ -f "${PROJECT_ROOT}/web/.htaccess" ]; then
        print_success "Drupal .htaccess file generated successfully"
    else
        print_warning "Warning: .htaccess file not found - clean URLs may not work"
    fi
}

# ============================================================================
# Drupal Setup Functions
# ============================================================================

create_settings_file() {
    print_step "Creating Drupal settings file..."
    
    local settings_dir="web/sites/${SITE_DIR}"
    local settings_file="${settings_dir}/settings.php"
    
    # Create directory if needed
    if [ ! -d "${settings_dir}" ]; then
        execute_or_simulate mkdir -p "${settings_dir}"
    fi
    
    # Ensure directory is owned by aegir user
    if [ "$DRY_RUN" = false ]; then
        chown -R "${AEGIR_USER}:${AEGIR_USER}" "${settings_dir}"
    fi
    
    # Backup existing settings if present
    if [ -f "${settings_file}" ] && [ "$DRY_RUN" = false ]; then
        local backup_file="${settings_file}.backup.$(date +%Y%m%d_%H%M%S)"
        cp "${settings_file}" "${backup_file}"
        print_info "Backed up existing settings to ${backup_file}"
    fi
    
    if [ "$DRY_RUN" = false ]; then
        # Start with default settings
        if [ -f "${settings_dir}/default.settings.php" ]; then
            cp "${settings_dir}/default.settings.php" "${settings_file}"
        else
            touch "${settings_file}"
        fi
        
        # Generate secure hash salt
        local hash_salt
        hash_salt=$(openssl rand -base64 75 | tr -d "\n")
        
        # Append Aegir-specific configuration
        cat >> "${settings_file}" <<EOF

// ============================================================================
// Aegir Configuration
// Generated on $(date)
// ============================================================================

// Database configuration
\$databases['default']['default'] = [
  'database' => '${AEGIR_DB_NAME}',
  'username' => '${AEGIR_DB_USER}',
  'password' => '${AEGIR_DB_PASS}',
  'host' => '${AEGIR_DB_HOST}',
  'port' => '${AEGIR_DB_PORT}',
  'driver' => 'mysql',
  'prefix' => '',
  'collation' => 'utf8mb4_general_ci',
  'charset' => 'utf8mb4',
];

// Security settings
\$settings['hash_salt'] = '${hash_salt}';

// File paths
\$settings['config_sync_directory'] = '../config/sync';
\$settings['file_private_path'] = 'sites/${SITE_DIR}/files/private';

// Trusted host patterns
\$settings['trusted_host_patterns'] = [
  '^${AEGIR_HOSTNAME}\$',
  '^localhost\$',
];

// Aegir-specific settings
\$settings['aegir']['mode'] = 'hosted';
\$settings['aegir']['hostname'] = '${AEGIR_HOSTNAME}';

// Development settings (comment out in production)
// \$config['system.logging']['error_level'] = 'verbose';
// \$config['system.performance']['css']['preprocess'] = FALSE;
// \$config['system.performance']['js']['preprocess'] = FALSE;

EOF
        
        chmod 644 "${settings_file}"
        chown "${AEGIR_USER}:${AEGIR_USER}" "${settings_file}"
        print_success "Settings file created at ${settings_file}"
    else
        print_info "[DRY RUN] Would create settings file at ${settings_file}"
    fi
}

create_directories() {
    print_step "Creating required directories..."
    
    local directories=(
        "web/sites/${SITE_DIR}/files"
        "web/sites/${SITE_DIR}/files/private"
        "web/sites/${SITE_DIR}/files/tmp"
        "config/sync"
    )
    
    for dir in "${directories[@]}"; do
        if [ "$DRY_RUN" = false ]; then
            mkdir -p "${dir}"
            chmod 775 "${dir}"
            chown -R "${AEGIR_USER}:${AEGIR_USER}" "${dir}"
        else
            print_info "[DRY RUN] Would create directory: ${dir}"
        fi
    done
    
    print_success "Directories created"
}

fix_file_permissions() {
    print_step "Fixing file permissions..."
    
    if [ "$DRY_RUN" = false ]; then
        # Add aegir user to www-data group so both can manage files
        if ! groups "${AEGIR_USER}" | grep -q "\bwww-data\b"; then
            usermod -a -G www-data "${AEGIR_USER}"
            print_info "Added ${AEGIR_USER} to www-data group"
        fi
        
        # Set proper ownership and permissions for files directory
        local files_dir="web/sites/${SITE_DIR}/files"
        if [ -d "${files_dir}" ]; then
            chown -R "${AEGIR_USER}:www-data" "${files_dir}"
            chmod -R 775 "${files_dir}"
            find "${files_dir}" -type f -exec chmod 664 {} \;
            print_success "File permissions fixed: ${files_dir}"
        fi
    else
        print_info "[DRY RUN] Would fix file permissions"
    fi
}

install_drupal() {
    print_step "Installing Drupal as ${AEGIR_USER}..."
    
    local db_url="mysql://${AEGIR_DB_USER}:${AEGIR_DB_PASS}@${AEGIR_DB_HOST}:${AEGIR_DB_PORT}/${AEGIR_DB_NAME}"
    
    # Create sites.php for multi-site setup if needed
    if [ "${SITE_DIR}" != "default" ] && [ "$DRY_RUN" = false ]; then
        local sites_php="web/sites/sites.php"
        if [ ! -f "${sites_php}" ]; then
            cat > "${sites_php}" <<EOF
<?php
// Multi-site configuration
\$sites['${AEGIR_HOSTNAME}'] = '${SITE_DIR}';
EOF
            chown "${AEGIR_USER}:${AEGIR_USER}" "${sites_php}"
            print_info "Created sites.php for multi-site configuration"
        fi
    fi
    
    # Set proper ownership on settings.php before install
    if [ -f "web/sites/${SITE_DIR}/settings.php" ]; then
        chown "${AEGIR_USER}:${AEGIR_USER}" "web/sites/${SITE_DIR}/settings.php"
    fi
    
    if [ "$DRY_RUN" = false ]; then
        print_info "This may take 5-10 minutes..."
        
        # Build drush command with optional sites-subdir parameter
        local drush_cmd="cd '${PROJECT_ROOT}' && ./vendor/bin/drush site:install standard --root=${PROJECT_ROOT}/web --uri=${AEGIR_HOSTNAME} --db-url='${db_url}' --site-name='Aegir Hosting System' --site-mail='${ADMIN_EMAIL}' --account-name=admin --account-mail='${ADMIN_EMAIL}'"
        if [ "${SITE_DIR}" != "default" ]; then
            drush_cmd="${drush_cmd} --sites-subdir='${SITE_DIR}'"
        fi
        drush_cmd="${drush_cmd} --yes 2>&1"
        
        # Use timeout to prevent indefinite hangs (15 minutes max)
        if ! timeout 900 su - "${AEGIR_USER}" -c "${drush_cmd}"; then
            local exit_code=$?
            if [ $exit_code -eq 124 ]; then
                die "Drupal installation timed out after 15 minutes"
            else
                die "Failed to install Drupal (exit code: $exit_code)"
            fi
        fi
    else
        print_info "[DRY RUN] Would run as ${AEGIR_USER}: ./vendor/bin/drush site:install standard"
    fi
    
    print_success "Drupal installed successfully"
}

enable_aegir_modules() {
    print_step "Enabling Aegir modules as ${AEGIR_USER}..."
    
    if [ "$DRY_RUN" = false ]; then
        # Install modules one by one to identify failures
        local failed_modules=()
        local successful_modules=()
        
        for module in "${AEGIR_CORE_MODULES[@]}"; do
            print_info "Installing module: ${module}..."
            if su - "${AEGIR_USER}" -c "cd ${PROJECT_ROOT}/web && ../vendor/bin/drush pm:enable ${module} --uri=${AEGIR_HOSTNAME} -y" 2>&1; then
                successful_modules+=("${module}")
                print_success "Module ${module} enabled"
            else
                failed_modules+=("${module}")
                print_error "Module ${module} failed to install"
            fi
        done
        
        # Report results
        if [ ${#successful_modules[@]} -gt 0 ]; then
            print_success "Successfully enabled ${#successful_modules[@]} module(s): ${successful_modules[*]}"
        fi
        
        if [ ${#failed_modules[@]} -gt 0 ]; then
            print_warning "Failed to enable ${#failed_modules[@]} module(s): ${failed_modules[*]}"
            print_warning "You can try to enable these modules manually after installation"
        fi
    else
        local modules_string="${AEGIR_CORE_MODULES[*]}"
        print_info "[DRY RUN] Would run as ${AEGIR_USER}: ./vendor/bin/drush pm:enable ${modules_string} -y"
    fi
    
    print_success "Aegir module installation completed"
}

clear_cache() {
    print_step "Clearing cache as ${AEGIR_USER}..."
    
    if ! su - "${AEGIR_USER}" -c "cd ${PROJECT_ROOT}/web && ../vendor/bin/drush cr --uri=${AEGIR_HOSTNAME}"; then
        die "Failed to clear cache"
    fi
    
    print_success "Cache cleared"
}

# ============================================================================
# Webserver Configuration Functions
# ============================================================================

# Configure Apache virtual host
configure_apache() {
    print_step "Configuring Apache webserver..."
    
    local sites_available="/etc/apache2/sites-available"
    local sites_enabled="/etc/apache2/sites-enabled"
    local vhost_file="${sites_available}/${AEGIR_HOSTNAME}.conf"
    
    if [ "$DRY_RUN" = true ]; then
        print_info "[DRY RUN] Would create Apache vhost at ${vhost_file}"
        return 0
    fi
    
    # Create virtual host configuration
    cat > "${vhost_file}" <<EOF
<VirtualHost *:80>
    ServerName ${AEGIR_HOSTNAME}
    ServerAdmin ${ADMIN_EMAIL}
    
    DocumentRoot ${PROJECT_ROOT}/web
    
    <Directory ${PROJECT_ROOT}/web>
        Options -Indexes +FollowSymLinks
        AllowOverride All
        Require all granted
        
        # Enable Drupal clean URLs
        <IfModule mod_rewrite.c>
            RewriteEngine On
        </IfModule>
    </Directory>
    
    # Logging
    ErrorLog \${APACHE_LOG_DIR}/${AEGIR_HOSTNAME}-error.log
    CustomLog \${APACHE_LOG_DIR}/${AEGIR_HOSTNAME}-access.log combined
    
    # Security headers
    <IfModule mod_headers.c>
        Header set X-Content-Type-Options "nosniff"
        Header set X-Frame-Options "SAMEORIGIN"
        Header set X-XSS-Protection "1; mode=block"
    </IfModule>
</VirtualHost>
EOF
    
    print_success "Apache vhost created: ${vhost_file}"
    
    # Enable required Apache modules
    print_info "Enabling required Apache modules..."
    a2enmod rewrite &>/dev/null || true
    a2enmod headers &>/dev/null || true
    
    # Enable the site
    print_info "Enabling site ${AEGIR_HOSTNAME}..."
    a2ensite "${AEGIR_HOSTNAME}" &>/dev/null
    
    # Test configuration
    if apachectl -t &>/dev/null; then
        print_success "Apache configuration valid"
    else
        print_warning "Apache configuration test failed. Check manually with: apachectl -t"
    fi
    
    # Reload Apache
    print_info "Reloading Apache..."
    if systemctl is-active --quiet apache2; then
        systemctl reload apache2
        print_success "Apache reloaded"
    else
        print_warning "Apache is not running. Start with: systemctl start apache2"
    fi
    
    print_success "Apache configuration completed"
}

# Main webserver configuration function
configure_webserver() {
    if [ "${WEBSERVER}" = "skip" ]; then
        print_warning "Skipping webserver configuration as requested"
        return 0
    fi
    
    configure_apache
}

# ============================================================================
# Main Installation Process
# ============================================================================

run_installation() {
    print_header "Aegir Hosting System Installation v${SCRIPT_VERSION}"
    echo
    
    check_prerequisites
    setup_database
    install_dependencies
    create_directories
    install_drupal
    fix_file_permissions
    enable_aegir_modules
    clear_cache
    configure_webserver
    
    print_installation_summary
}

print_installation_summary() {
    echo
    print_header "Installation Complete!"
    echo
    print_success "Aegir has been successfully installed."
    echo
    echo -e "${YELLOW}Configuration Summary:${NC}"
    echo "  • Project Root:    ${PROJECT_ROOT}"
    echo "  • Web Root:        ${PROJECT_ROOT}/web"
    echo "  • Site Directory:  sites/${SITE_DIR}"
    echo "  • Hostname:        ${AEGIR_HOSTNAME}"
    echo "  • Admin Email:     ${ADMIN_EMAIL}"
    echo "  • Database:        ${AEGIR_DB_NAME}"
    echo "  • Database Host:   ${AEGIR_DB_HOST}:${AEGIR_DB_PORT}"
    echo "  • Webserver:       Apache"
    
    echo
    echo -e "${YELLOW}Access Your Site:${NC}"
    echo "  • URL: http://${AEGIR_HOSTNAME}"
    echo "  • Get admin login link:"
    echo "     cd ${PROJECT_ROOT}/web && ../vendor/bin/drush user:login --uri=${AEGIR_HOSTNAME}"
    echo
    
    echo -e "${YELLOW}Important:${NC}"
    echo "  • Database credentials: ${AEGIR_HOME}/.aegir.db.conf"
    echo "  • Keep credentials secure and never commit to version control"
    echo "  • Review settings.php for production deployment"
    echo "  • Apache vhost: /etc/apache2/sites-available/${AEGIR_HOSTNAME}.conf"
    
    echo
}

# ============================================================================
# Help and Usage
# ============================================================================

show_help() {
    cat <<EOF
Aegir Installation Script v${SCRIPT_VERSION}

Requirements:
    - Ubuntu 24.04 LTS
    - MySQL 8.0+
    - PHP 8.3+
    - Apache 2.4+

IMPORTANT: This script must be run as root or with sudo

Usage: sudo $0 [OPTIONS]

Options:
    --dry-run          Show what would be done without executing
    --skip-db          Skip database setup (use existing DB)
    --db-pass PASS     Provide database password (avoid interactive prompt)
    --webserver TYPE   Configure webserver (apache|skip, default: apache)
    --force            Force reinstall (removes existing installation)
    --config FILE      Load configuration from file
    -h, --help         Show this help message

Environment Variables:
    AEGIR_USER         Aegir system user (default: aegir)
    AEGIR_HOME         Aegir home directory (default: /var/aegir)
    AEGIR_DB_USER      Database user (default: aegir)
    AEGIR_DB_NAME      Database name (default: aegir)
    AEGIR_DB_HOST      Database host (default: localhost)
    AEGIR_DB_PORT      Database port (default: 3306)
    AEGIR_HOSTNAME     Aegir hostname (default: aegir.local)
    ADMIN_EMAIL        Admin email (default: admin@HOSTNAME)

Examples:
    # Standard installation (creates aegir user, DB, and installs)
    sudo ./install.sh

    # With MySQL root authentication via Unix socket (no password needed)
    sudo ./install.sh

    # Provide database password directly
    sudo ./install.sh --db-pass 'secure_password'

    # Skip database setup and use existing DB
    sudo ./install.sh --skip-db

    # Dry run to see what would be done
    sudo ./install.sh --dry-run

    # Custom hostname (IMPORTANT: sudo strips environment variables by default)
    # Method 1: Use sudo -E to preserve environment
    export AEGIR_HOSTNAME=hosting.example.com
    sudo -E ./install.sh
    
    # Method 2: Set variable within sudo context
    sudo bash -c "AEGIR_HOSTNAME=hosting.example.com ./install.sh"
    
    # This will NOT work (variable is stripped by sudo):
    # sudo AEGIR_HOSTNAME=hosting.example.com ./install.sh

    # Force reinstall
    sudo ./install.sh --force

Multi-site Setup:
    When AEGIR_HOSTNAME is set to a custom hostname (not 'aegir.local'),
    the site will be installed in sites/<AEGIR_HOSTNAME>/ instead of
    sites/default/. This enables multi-site configuration.
    
    Example: AEGIR_HOSTNAME=site1.example.com → sites/site1.example.com/

Database Setup:
    The script will attempt to create the database using:
    1. MySQL Unix socket authentication (no password needed if running as root)
    2. If that fails, it will prompt for MySQL root password
    3. Use --db-pass to provide the Aegir DB password directly
    4. Use --skip-db to skip creation entirely

EOF
}

# ============================================================================
# Argument Parsing
# ============================================================================

parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case "$1" in
            --dry-run)
                DRY_RUN=true
                shift
                ;;
            --skip-db)
                SKIP_DB=true
                shift
                ;;
            --db-pass)
                DB_PASS_PROVIDED="$2"
                shift 2
                ;;
            --webserver)
                WEBSERVER="$2"
                if [[ ! "$WEBSERVER" =~ ^(apache|skip)$ ]]; then
                    die "Invalid webserver option: $WEBSERVER. Use: apache or skip"
                fi
                shift 2
                ;;
            --force)
                FORCE_INSTALL=true
                shift
                ;;
            --config)
                CONFIG_FILE="$2"
                if [ ! -f "$CONFIG_FILE" ]; then
                    die "Config file not found: $CONFIG_FILE"
                fi
                # shellcheck source=/dev/null
                source "$CONFIG_FILE"
                shift 2
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                die "Unknown option: $1. Use --help for usage information."
                ;;
        esac
    done
}

# ============================================================================
# Main Entry Point
# ============================================================================

main() {
    parse_arguments "$@"
    
    if [ "$DRY_RUN" = true ]; then
        print_warning "Running in DRY RUN mode - no changes will be made"
        echo
    fi
    
    run_installation
    
    exit 0
}

# Run main function with all arguments
main "$@"
