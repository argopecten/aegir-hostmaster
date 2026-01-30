# Development Roadmap and TODO

This document outlines the overarching development roadmap for Aegir Hostmaster, focusing on system-level features, integrations, and architectural improvements.

**Component-Specific TODOs**:
- **Backend (Provision)**: See [drush/Commands/contrib/aegir-provision/doc/TODO.md](../drush/Commands/contrib/aegir-provision/doc/TODO.md)
- **Frontend (Hosting)**: See [web/modules/contrib/aegir-hosting/doc/TODO.md](../web/modules/contrib/aegir-hosting/doc/TODO.md)
- **Theme (Eldir)**: See [web/themes/contrib/aegir-eldir/doc/TODO.md](../web/themes/contrib/aegir-eldir/doc/TODO.md)

**Recent Updates (January 29, 2026)**:
- ✅ Organized TODO tasks by component
- ✅ Implemented automatic task creation on entity save
- ✅ Implemented task retry logic with exponential backoff
- ✅ Implemented task cancellation with process killing
- ✅ Implemented streaming output for real-time logs
- ✅ Created task queue management UI with auto-refresh
- ✅ Implemented parallel task execution (when pcntl available)

## Table of Contents

- [High Priority](#high-priority)
- [Medium Priority](#medium-priority)
- [Future Enhancements](#future-enhancements)
- [Architecture Improvements](#architecture-improvements)
- [Contributing](#contributing)

## High Priority

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
- [x] Organize component-specific TODOs (completed)
- [ ] Add API documentation (PHPDoc)
- [ ] Create video tutorials
- [ ] Write migration guides
- [ ] Add troubleshooting guides

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

### Task Management Enhancements
**Status**: Not Started  
**Priority**: Medium  
**Complexity**: High

Improve task queue management with advanced features.

**Overview**:
- Task Priority System
- Task Dependencies
- Parallel Task Execution
- **Queue Management UI** (high priority, see Frontend TODO)
- **Multiple Queue Types** (backups, statistics, SSL renewals)
- **Backup Scheduling** (recurring automated backups)

**Current State**: D11 uses standard Drupal Queue API with single task queue. Tasks process via `drush cron` (runs every 5 minutes). QueueWorker processes up to 60 seconds per cron run, handling 5 tasks.

**D7 Comparison**: D7 had custom queue dispatcher with multiple queues and admin UI at `/admin/hosting/queues`. D11 is simpler and more standards-compliant but lacks some flexibility.

**Detailed Plans**: See [Frontend TODO](../web/modules/contrib/aegir-hosting/doc/TODO.md) for queue management and scheduling tasks.

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
- [x] Organize component-specific TODOs (completed)
- [ ] Add API documentation (PHPDoc)
- [ ] Create video tutorials
- [ ] Write migration guides
- [ ] Add troubleshooting guides

---

## Contributing

Want to help with any of these tasks? Here's how to get started:

1. **Choose a Task**: Pick an item from the TODO list above or from component-specific TODOs:
   - [Backend (Provision) TODO](../drush/Commands/contrib/aegir-provision/doc/TODO.md)
   - [Frontend (Hosting) TODO](../web/modules/contrib/aegir-hosting/doc/TODO.md)
   - [Theme (Eldir) TODO](../web/themes/contrib/aegir-eldir/doc/TODO.md)
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

**Last Updated**: January 29, 2026

**Questions?** Open an issue on GitHub or join our community chat.
