# Development Roadmap and TODO

This document outlines the development roadmap for Aegir Hostmaster, including planned features, known issues, and future enhancements.

## Table of Contents

- [High Priority](#high-priority)
- [Medium Priority](#medium-priority)
- [Future Enhancements](#future-enhancements)
- [Known Issues](#known-issues)
- [Architecture Improvements](#architecture-improvements)
- [Contributing](#contributing)

## High Priority

### Backend (Provision)

#### 🔧 PHP-FPM Pool Configuration
**Status**: Not Started  
**Priority**: High  
**Complexity**: Medium

Create per-site PHP-FPM pools for better resource isolation and security.

**Tasks**:
- [ ] Add PHP-FPM service class
- [ ] Generate pool configuration per site
- [ ] Add pool reload to site operations
- [ ] Configure Unix socket paths
- [ ] Set per-pool resource limits (memory, max_children)
- [ ] Update Apache vhost to use site-specific socket

**Implementation Note**: Follow service abstraction pattern used by Apache and MySQL services.

---

#### 🔐 Let's Encrypt Integration
**Status**: Not Started  
**Priority**: High  
**Complexity**: High

Implement ACME v2 protocol for automated SSL certificate management.

**Tasks**:
- [ ] Create LetsEncryptService class
- [ ] Implement ACME v2 client
- [ ] Add DNS challenge support
- [ ] Implement automatic renewal cron job
- [ ] Add certificate storage management
- [ ] Update Apache vhost for HTTPS
- [ ] Add HTTPS redirect configuration

**Dependencies**: 
- `acme-php/core` or `php-acme/protocol`

---

#### ✅ Context Schema Validation
**Status**: Not Started  
**Priority**: High  
**Complexity**: Medium

Add JSON Schema validation for context files to catch configuration errors early.

**Tasks**:
- [ ] Create JSON Schema definitions for each context type
- [ ] Add validation service
- [ ] Validate contexts before operations
- [ ] Provide helpful error messages
- [ ] Add `provision-validate` Drush command
- [ ] Document schema in AI instructions

---

#### 🔄 Rollback/Transaction System
**Status**: Partially Implemented  
**Priority**: High  
**Complexity**: High

Improve transaction and rollback support for failed operations.

**Tasks**:
- [ ] Complete Transaction class implementation
- [ ] Add rollback hooks to all services
- [ ] Implement database transaction snapshots
- [ ] Add file system rollback (restore from temp)
- [ ] Test failure scenarios
- [ ] Document rollback behavior

---

#### 🐘 PostgreSQL Support
**Status**: Not Started  
**Priority**: High  
**Complexity**: Medium

Add PostgreSQL as an alternative database backend.

**Tasks**:
- [ ] Create PostgresqlService class
- [ ] Implement database creation/deletion
- [ ] Add user/permission management
- [ ] Update settings.php generation
- [ ] Add to server configuration options
- [ ] Test with Drupal PostgreSQL driver

---

### Frontend (Hosting)

#### 📝 Complete Entity Field Definitions
**Status**: In Progress  
**Priority**: High  
**Complexity**: Medium

All entity fields should be properly defined using Field API.

**Tasks**:
- [ ] Audit all entity field definitions
- [ ] Replace computed fields with proper field types
- [ ] Add field constraints and validation
- [ ] Document field schema
- [ ] Add update hooks for field changes

---

#### 🎛️ Manager Services for All Entities
**Status**: Partially Implemented  
**Priority**: High  
**Complexity**: Medium

Separate business logic from entity/form classes into manager services.

**Tasks**:
- [x] SiteManager service (completed)
- [x] PlatformManager service (completed)
- [x] ServerManager service (completed)
- [ ] ClientManager service
- [ ] PackageManager service
- [ ] TaskManager improvements (priority, dependencies)

---

#### 📋 Task Priority and Dependencies
**Status**: Not Started  
**Priority**: High  
**Complexity**: High

Add task scheduling with priorities and dependencies.

**Tasks**:
- [ ] Add priority field to HostingTask entity
- [ ] Add dependencies field (references other tasks)
- [ ] Update queue worker to respect priority
- [ ] Implement dependency resolution
- [ ] Add parallel task execution (where safe)
- [ ] Add task status: waiting, queued, processing, completed, failed

---

#### 👥 Client Entity and Permissions
**Status**: Basic Implementation  
**Priority**: High  
**Complexity**: High

Complete client/organization management with quota and permission system.

**Tasks**:
- [ ] Add client quotas (max sites, max storage)
- [ ] Implement quota checking in forms
- [ ] Add client-specific permissions
- [ ] Create client dashboard
- [ ] Add billing integration hooks
- [ ] Support client groups/organizations

---

#### 📦 Package Tracking and Updates
**Status**: Basic Implementation  
**Priority**: High  
**Complexity**: Medium

Track installed packages and notify about available updates.

**Tasks**:
- [ ] Scan platforms for installed modules/themes
- [ ] Check drupal.org for security advisories
- [ ] Display update status on platform pages
- [ ] Add "Update Available" notifications
- [ ] Integrate with Composer for updates
- [ ] Add one-click update task

---

### Theme (Eldir)

#### ⚡ Complete JavaScript Implementation
**Status**: Partially Implemented  
**Priority**: High  
**Complexity**: Medium

Finish all planned JavaScript functionality.

**Tasks**:
- [x] Task queue live updates (basic)
- [ ] Log filtering and search
- [ ] Log syntax highlighting
- [ ] Real-time server status
- [ ] AJAX form enhancements
- [ ] Keyboard shortcuts

---

#### 📱 Mobile Responsive Optimization
**Status**: Basic Implementation  
**Priority**: High  
**Complexity**: Medium

Improve mobile experience for hosting management.

**Tasks**:
- [ ] Test all pages on mobile devices
- [ ] Optimize task log display for mobile
- [ ] Add mobile navigation menu
- [ ] Improve form layouts on small screens
- [ ] Add touch-friendly controls
- [ ] Test on iOS and Android

---

#### 🎨 Theme Suggestions
**Status**: Not Started  
**Priority**: Medium  
**Complexity**: Low

Add theme suggestion hooks for better template customization.

**Tasks**:
- [ ] Implement `hook_theme_suggestions_HOOK_alter()`
- [ ] Add suggestions for entity types
- [ ] Add suggestions for view modes
- [ ] Document suggestion patterns

---

#### ♿ Accessibility Improvements
**Status**: Basic Implementation  
**Priority**: High  
**Complexity**: Medium

Ensure WCAG 2.1 AA compliance throughout.

**Tasks**:
- [ ] Run automated accessibility tests
- [ ] Add ARIA labels to all interactive elements
- [ ] Improve keyboard navigation
- [ ] Add skip links
- [ ] Test with screen readers (NVDA, JAWS)
- [ ] Fix color contrast issues

---

#### 🧩 Single Directory Components Migration
**Status**: Not Started  
**Priority**: Medium  
**Complexity**: High

Migrate theme hooks to Single Directory Components (SDC).

**Tasks**:
- [ ] Create info-table component (started)
- [ ] Create server-status component
- [ ] Create task-log component
- [ ] Create service-badge component
- [ ] Document component usage patterns
- [ ] Update module integrations

---

## Medium Priority

### Drupal Recipes Implementation
**Status**: Planned  
**Priority**: Medium  
**Complexity**: High

Replace install.sh with Drupal Recipes for better modularity.

**Reference**: See [TODO-RECIPES.md](../.github/TODO-RECIPES.md) for detailed implementation plan.

**Tasks**:
- [ ] Create `aegir-hostmaster` core recipe
- [ ] Create `aegir-development` recipe
- [ ] Create `aegir-production` recipe
- [ ] Create `aegir-multiserver` recipe
- [ ] Update installation documentation
- [ ] Test recipe installation flow

---

### Backup Management
**Status**: Basic Implementation  
**Priority**: Medium  
**Complexity**: Medium

Improve backup and restore functionality.

**Tasks**:
- [ ] Add backup scheduling (daily, weekly, monthly)
- [ ] Implement backup retention policies
- [ ] Add incremental backups
- [ ] Support remote backup storage (S3, FTP)
- [ ] Add backup encryption
- [ ] Create backup browser UI

---

### Migration Tools
**Status**: Not Started  
**Priority**: Medium  
**Complexity**: High

Add tools for migrating from Aegir 3.x (Drupal 7) to Aegir 4.x (Drupal 11).

**Tasks**:
- [ ] Create migration Drush commands
- [ ] Import D7 sites as entities
- [ ] Convert D7 contexts to D11 format
- [ ] Migrate client data
- [ ] Migrate task history
- [ ] Document migration process

---

### Remote Server Support
**Status**: Not Started  
**Priority**: Medium  
**Complexity**: Very High

Add support for managing sites on remote servers via SSH.

**Tasks**:
- [ ] Add SSH service layer
- [ ] Implement remote command execution
- [ ] Add SSH key management
- [ ] Support rsync for file operations
- [ ] Add remote MySQL access
- [ ] Test multi-server deployments

---

### Nginx Support
**Status**: Not Started  
**Priority**: Medium  
**Complexity**: Medium

Add Nginx as an alternative to Apache.

**Tasks**:
- [ ] Create NginxService class
- [ ] Generate Nginx site configurations
- [ ] Implement PHP-FPM integration
- [ ] Add Nginx reload/restart
- [ ] Update server configuration options
- [ ] Document Nginx setup

---

### Git Integration
**Status**: Not Started  
**Priority**: Medium  
**Complexity**: High

Add Git repository integration for platform deployments.

**Tasks**:
- [ ] Add Git service class
- [ ] Support platform deployment from Git
- [ ] Implement automatic updates from Git
- [ ] Add webhook support for CI/CD
- [ ] Support multiple branches
- [ ] Add rollback to previous commits

---

## Future Enhancements

### Multi-tenancy Improvements
- [ ] Client resource quotas
- [ ] Client-specific billing integration
- [ ] Client API access tokens
- [ ] Client usage statistics dashboard

### Monitoring and Alerts
- [ ] Site uptime monitoring
- [ ] Disk space alerts
- [ ] Performance metrics collection
- [ ] Email notifications for failures
- [ ] Slack/Discord integration

### Advanced Security
- [ ] Two-factor authentication
- [ ] Audit logging
- [ ] Security scan integration
- [ ] Automated security updates
- [ ] WAF integration

### API and Integrations
- [ ] REST API for all operations
- [ ] GraphQL API
- [ ] Webhook system
- [ ] Third-party service integrations
- [ ] CI/CD pipeline integration

### Platform Features
- [ ] Docker/container support
- [ ] Kubernetes integration
- [ ] CDN integration
- [ ] Load balancer support
- [ ] Auto-scaling capabilities

## Known Issues

### Frontend

#### Entity Query Performance
**Impact**: Medium  
**Status**: Investigating

Large installations (1000+ sites) may experience slow entity queries.

**Workaround**: Add database indexes on commonly queried fields.

**Solution**: Implement caching layer and optimize queries.

---

#### Task Queue Bottleneck
**Impact**: Medium  
**Status**: Known Issue

Sequential task processing can be slow for bulk operations.

**Workaround**: Run multiple queue workers in parallel.

**Solution**: Implement parallel task execution for independent tasks.

---

### Backend

#### Settings.php Overwrite
**Impact**: Low  
**Status**: By Design

Verify tasks regenerate settings.php, overwriting manual changes.

**Workaround**: Use `local.settings.php` for custom settings.

**Solution**: Document settings.php management in AI instructions.

---

#### Large File Migrations
**Impact**: Medium  
**Status**: Known Issue

Migrating sites with large file directories can timeout.

**Workaround**: Increase PHP execution time limits.

**Solution**: Implement chunked file operations with progress tracking.

---

### Theme

#### IE11 Compatibility
**Impact**: Low  
**Status**: Won't Fix

Theme uses modern CSS features not supported in IE11.

**Workaround**: None. IE11 is not supported.

**Solution**: Document browser requirements (modern evergreen browsers only).

---

#### Dark Mode Support
**Impact**: Low  
**Status**: Planned

Theme does not currently support system dark mode preferences.

**Workaround**: None currently.

**Solution**: Add `prefers-color-scheme` media query support.

---

## Architecture Improvements

### Service Layer Enhancement
**Priority**: Medium  
**Complexity**: High

Improve service abstraction for better testability and extensibility.

**Tasks**:
- [ ] Define service interfaces
- [ ] Add service discovery/plugin system
- [ ] Implement service decorators
- [ ] Add service events
- [ ] Improve dependency injection

---

### Testing Infrastructure
**Priority**: High  
**Complexity**: High

Expand test coverage across all components.

**Tasks**:
- [ ] Add unit tests for all manager services
- [ ] Add functional tests for all entity operations
- [ ] Add integration tests for backend commands
- [ ] Add end-to-end tests for common workflows
- [ ] Set up CI/CD for automated testing
- [ ] Achieve 80%+ code coverage

---

### Documentation
**Priority**: High  
**Complexity**: Medium

Expand and improve documentation.

**Tasks**:
- [x] Create main README.md (completed)
- [x] Create doc/HOME.md (completed)
- [x] Create doc/Frontend.md (completed)
- [x] Create doc/Backend.md (completed)
- [x] Create doc/Theme.md (completed)
- [x] Create doc/TODO.md (this file, completed)
- [ ] Add API documentation (PHPDoc)
- [ ] Create video tutorials
- [ ] Write migration guides
- [ ] Add troubleshooting guides

---

## Contributing

Want to help with any of these tasks? Here's how to get started:

1. **Choose a Task**: Pick an item from the TODO list above
2. **Check the AI Instructions**: Review the relevant component's AI instructions:
   - [Backend Instructions](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
   - [Frontend Instructions](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
   - [Theme Instructions](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)
   - [Architecture Overview](../.github/ARCHITECTURE.md)
3. **Follow Best Practices**: Adhere to the development guidelines in each component
4. **Write Tests**: Include unit/functional tests with your changes
5. **Update Documentation**: Update relevant documentation files
6. **Submit PR**: Open a pull request with your changes

### Priority Legend
- **High**: Critical for core functionality or security
- **Medium**: Important but not blocking
- **Low**: Nice to have, enhances UX

### Complexity Legend
- **Low**: A few hours of work
- **Medium**: A few days of work
- **High**: A week or more of work
- **Very High**: Multi-week project

---

**Last Updated**: January 26, 2026

**Questions?** Open an issue on GitHub or join our community chat.
