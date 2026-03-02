#!/bin/bash
set -e

# Aegir Update Script
# This script updates the Aegir hosting system, runs database updates, and clears caches

# Color output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Aegir Hosting System Update${NC}"
echo -e "${GREEN}========================================${NC}"
echo

# Verify we're in the right directory
if [ ! -f "composer.json" ]; then
    echo -e "${RED}Error: composer.json not found${NC}"
    echo -e "${YELLOW}Please run this script from the Aegir project root${NC}"
    exit 1
fi

# Check if Drupal is installed
if [ ! -f "web/sites/default/settings.php" ]; then
    echo -e "${RED}Error: Drupal does not appear to be installed${NC}"
    echo -e "${YELLOW}Please run ./scripts/install.sh first${NC}"
    exit 1
fi

# Backup option
echo -e "${YELLOW}Before updating, consider backing up your database and files.${NC}"
read -p "Do you want to create a database backup now? (y/N) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    BACKUP_DIR="backups/$(date +%Y%m%d_%H%M%S)"
    mkdir -p "$BACKUP_DIR"
    
    echo -e "${YELLOW}Creating database backup...${NC}"
    ./vendor/bin/drush sql:dump --gzip --result-file="${BACKUP_DIR}/database.sql"
    echo -e "${GREEN}✓ Database backed up to: ${BACKUP_DIR}/database.sql.gz${NC}"
fi

# Put site in maintenance mode
echo
echo -e "${YELLOW}Enabling maintenance mode...${NC}"
./vendor/bin/drush state:set system.maintenance_mode 1 --input-format=integer
./vendor/bin/drush cache:rebuild
echo -e "${GREEN}✓ Site in maintenance mode${NC}"

# Update Composer dependencies
echo
echo -e "${YELLOW}Updating Composer dependencies...${NC}"
echo -e "${YELLOW}This may take several minutes...${NC}"

composer update --no-interaction --prefer-dist --optimize-autoloader

echo -e "${GREEN}✓ Composer dependencies updated${NC}"

# Run database updates
echo
echo -e "${YELLOW}Running database updates...${NC}"

./vendor/bin/drush updatedb --yes

echo -e "${GREEN}✓ Database updates completed${NC}"

# Clear all caches
echo
echo -e "${YELLOW}Clearing caches...${NC}"

./vendor/bin/drush cache:rebuild

echo -e "${GREEN}✓ Caches cleared${NC}"

# Export configuration (if changes exist)
echo
echo -e "${YELLOW}Exporting configuration...${NC}"

if ./vendor/bin/drush config:export --yes 2>/dev/null; then
    echo -e "${GREEN}✓ Configuration exported${NC}"
else
    echo -e "${YELLOW}! Configuration export skipped (no changes or not configured)${NC}"
fi

# Run cron
echo
echo -e "${YELLOW}Running cron...${NC}"

./vendor/bin/drush cron

echo -e "${GREEN}✓ Cron completed${NC}"

# Disable maintenance mode
echo
echo -e "${YELLOW}Disabling maintenance mode...${NC}"
./vendor/bin/drush state:set system.maintenance_mode 0 --input-format=integer
./vendor/bin/drush cache:rebuild
echo -e "${GREEN}✓ Site back online${NC}"

# Check for security updates
echo
echo -e "${YELLOW}Checking for security updates...${NC}"

if ./vendor/bin/drush pm:security 2>/dev/null; then
    echo -e "${GREEN}✓ No security updates needed${NC}"
else
    echo -e "${YELLOW}! Security updates may be available - review the output above${NC}"
fi

# Show status report
echo
echo -e "${YELLOW}Site status:${NC}"
./vendor/bin/drush status

echo
echo -e "${GREEN}========================================${NC}"
echo -e "${GREEN}  Update Complete!${NC}"
echo -e "${GREEN}========================================${NC}"
echo
echo -e "${GREEN}Aegir has been successfully updated.${NC}"
echo
echo -e "${YELLOW}Recommended next steps:${NC}"
echo -e "1. Test critical functionality on your site"
echo -e "2. Review any warnings or errors above"
echo -e "3. Check hosting tasks: ./vendor/bin/drush hosting:tasks"
echo -e "4. Access admin interface: ./vendor/bin/drush user:login"
echo
