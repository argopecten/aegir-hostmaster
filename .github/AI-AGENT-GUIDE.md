# AI Agent Navigation Guide for Aegir Hostmaster

**Last Updated**: January 29, 2026  
**Purpose**: Guide AI coding agents working in any Aegir repository  
**Audience**: AI agents (Claude, GPT-4, Copilot, etc.)

## Overview

Aegir Hostmaster uses a **layered architecture** with **distributed repositories**. This guide helps AI agents understand:
- How repositories relate to each other
- Where to find documentation for different components
- How to navigate between AI instructions and published docs
- When to reference parent or child repositories

## Repository Structure

### Main Repository: aegir-hostmaster

**GitHub**: https://github.com/argopecten/aegir-hostmaster  
**Local Path**: `/var/aegir/aegir-2601/`  
**Purpose**: Drupal project container integrating all Aegir components

**Key Locations**:
- **AI Instructions**: [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) - Overarching architecture for AI agents
- **Published Docs**: [doc/](../doc/) - User-facing documentation synced to GitHub
  - [HOME.md](../doc/HOME.md) - Architecture overview
  - [Frontend.md](../doc/Frontend.md) - Frontend component guide
  - [Backend.md](../doc/Backend.md) - Backend component guide
  - [Theme.md](../doc/Theme.md) - Theme component guide
  - [TODO.md](../doc/TODO.md) - Development roadmap
- **AI TODO**: [.github/TODO-RECIPES.md](.github/TODO-RECIPES.md) - Drupal Recipes implementation plan

**Contains**: Drupal 11 core, composer dependencies, and three Aegir components as submodules

---

### Component 1: aegir-hosting (Frontend)

**GitHub**: https://github.com/argopecten/aegir-hosting  
**Local Path**: `/var/aegir/aegir-2601/web/modules/contrib/aegir-hosting/`  
**Purpose**: Drupal 11 modules - entity layer, forms, task queue, UI

**Key Locations**:
- **Quick Reference**: [.github/AGENTS.md](../web/modules/contrib/aegir-hosting/.github/AGENTS.md) - AI agent quick start (when working in this repo)
- **AI Instructions**: [.github/AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md) - Detailed AI guidance (2000+ lines)
- **Published Docs**: [doc/](../web/modules/contrib/aegir-hosting/doc/) - User documentation
  - [Home.md](../web/modules/contrib/aegir-hosting/doc/Home.md) - Frontend architecture
  - [hosting-d11.md](../web/modules/contrib/aegir-hosting/doc/hosting-d11.md) - D11 implementation
  - [hosting-d7.md](../web/modules/contrib/aegir-hosting/doc/hosting-d7.md) - D7 reference (historical)

**Module Structure**:
- `src/` - Core hosting module (ContextRegistry, BackendInvoker, QueueDispatcher)
- `hosting_site/` - Site entity and forms
- `hosting_platform/` - Platform entity and forms
- `hosting_server/` - Server entity and services
- `hosting_task/` - Task queue system
- `hosting_client/`, `hosting_package/`, etc. - Supporting modules

---

### Component 2: aegir-provision (Backend)

**GitHub**: https://github.com/argopecten/aegir-provision  
**Local Path**: `/var/aegir/aegir-2601/drush/Commands/contrib/aegir-provision/`  
**Purpose**: Drush 13 extension - infrastructure automation (Apache, MySQL, files)

**Key Locations**:
- **Quick Reference**: [.github/AGENTS.md](../drush/Commands/contrib/aegir-provision/.github/AGENTS.md) - AI agent quick start (when working in this repo)
- **AI Instructions**: [.github/AI-INSTRUCTIONS.md](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md) - Backend automation guide (990+ lines)
- **Published Docs**: [doc/](../drush/Commands/contrib/aegir-provision/doc/) - User documentation
  - [Home.md](../drush/Commands/contrib/aegir-provision/doc/Home.md) - Backend architecture
  - [provision-d11.md](../drush/Commands/contrib/aegir-provision/doc/provision-d11.md) - D11 implementation
  - [provision-d7.md](../drush/Commands/contrib/aegir-provision/doc/provision-d7.md) - D7 reference (historical)

**Code Structure**:
- `src/Commands/` - Drush commands (provision-install, provision-verify, etc.)
- `src/Core/` - Context system, filesystem abstractions
- `src/Provision/` - ProvisionManager orchestrator
- `src/Service/` - Apache, MySQL, SSL, settings.php services

---

### Component 3: aegir-eldir (Theme)

**GitHub**: https://github.com/argopecten/aegir-eldir  
**Local Path**: `/var/aegir/aegir-2601/web/themes/contrib/aegir-eldir/`  
**Purpose**: Drupal 11 theme - responsive UI for hosting management

**KeQuick Reference**: [.github/AGENTS.md](../web/themes/contrib/aegir-eldir/.github/AGENTS.md) - AI agent quick start (when working in this repo)
- **y Locations**:
- **AI Instructions**: [.github/AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md) - Theme architecture guide (1200+ lines)
- **Published Docs**: [doc/](../web/themes/contrib/aegir-eldir/doc/) - User documentation
  - [Home.md](../web/themes/contrib/aegir-eldir/doc/Home.md) - Theme overview
  - [eldir-d11.md](../web/themes/contrib/aegir-eldir/doc/eldir-d11.md) - D11 implementation
  - [eldir-d7.md](../web/themes/contrib/aegir-eldir/doc/eldir-d7.md) - D7 reference (historical)

**Theme Structure**:
- `templates/` - Twig templates (page, node, hosting entities)
- `css/` - Modern CSS with variables, BEM methodology
- `js/` - JavaScript behaviors
- `eldir.theme` - Preprocess functions

---

## Documentation Strategy

### Two Documentation Types

Each repository maintains **two distinct documentation systems**:

#### 1. AI Instructions (`.github/` folder)
**Purpose**: Detailed technical guidance for AI coding agents  
**Audience**: AI assistants (Claude, GPT-4, GitHub Copilot)  
**Format**: Markdown with extensive code examples, architecture diagrams, implementation patterns  
**Update Policy**: Update when architecture changes or patterns evolve  

**Files**:
- Main repo: `.github/ARCHITECTURE.md` - Overarching integration architecture
- Components: `.github/AI-INSTRUCTIONS.md` - Component-specific technical details
- TODO files: `.github/TODO-*.md` - AI-readable task lists

**Content**:
- Complete API documentation
- Code structure and patterns
- Implementation examples
- Integration points
- Best practices and anti-patterns
- Testing strategies

#### 2. Published Documentation (`doc/` folder)
**Purpose**: User-facing documentation for developers and site builders  
**Audience**: Human developers using Aegir  
**Format**: Markdown synced to GitHub repository wikis/pages  
**Update Policy**: Update when user-facing features change  

**Files**:
- `doc/HOME.md` or `doc/Home.md` - Main documentation entry point
- `doc/*-d11.md` - Drupal 11 specific implementation
- `doc/*-d7.md` - Drupal 7 reference (historical)
- `doc/TODO.md` - User-facing roadmap (main repo only)

**Content**:
- Getting started guides
- API overview
- Configuration instructions
- Troubleshooting
- Examples and tutorials

---

## Navigation Rules for AI Agents

### When Working in Main Repository (`aegir-hostmaster`)

**You are here**: `/var/aegir/aegir-2601/`

**Read first**:
1. [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) - Overall system architecture
2. [doc/HOME.md](../doc/HOME.md) - User-facing overview

**For feature work**:
- **Frontend tasks** (entities, forms, UI): Reference [aegir-hosting AI instructions](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
- **Backend tasks** (Drush, services, automation): Reference [aegir-provision AI instructions](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
- **Theme tasks** (templates, CSS, JS): Reference [aegir-eldir AI instructions](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)

**When to modify components**:
- Always work in the component's own directory
- Changes to hosting modules go in `web/modules/contrib/aegir-hosting/`
- Changes to Drush commands go in `drush/Commands/contrib/aegir-provision/`
- Changes to theme go in `web/themes/contrib/aegir-eldir/`
- Components are Git submodules - commit in component directory first

**Integration work**:
- Composer dependencies: Edit `composer.json` in main repo
- Installation scripts: `scripts/install.sh`, `scripts/update.sh`
- Drupal recipes: `recipes/` directory (see [.github/TODO-RECIPES.md](.github/TODO-RECIPES.md))
- Configuration: `config/sync/` directory

---

### When Working in aegir-hosting (Frontend)

**You are here**: `/var/aegir/aegir-2601/web/modules/contrib/aegir-hosting/`

**Read first**:
1. [.github/AGENTS.md](../web/modules/contrib/aegir-hosting/.github/AGENTS.md) - **Quick reference** (start here!)
2. [.github/AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md) - Frontend architecture
3. [doc/Home.md](../web/modules/contrib/aegir-hosting/doc/Home.md) - User guide

**This is a standalone repository**:
- It has its own Git history: `git log` shows hosting commits only
- It can be developed independently: `git checkout -b feature-branch`
- It syncs to: https://github.com/argopecten/aegir-hosting

**Component scope**:
- ✅ Drupal entities (HostingSite, HostingPlatform, HostingServer)
- ✅ Forms and validation
- ✅ Task queue (HostingTask, TaskManager, QueueWorker)
- ✅ Services (ContextRegistry, BackendInvoker, QueueDispatcher)
- ✅ Drush commands starting with `hosting:*`
- ❌ Infrastructure automation (that's aegir-provision)
- ❌ UI presentation (that's aegir-eldir)

**When you need backend context**:
- Read [../../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
- Backend is invoked via `BackendInvoker` service
- Commands: `drush provision-install`, `drush provision-verify`, etc.

**When you need theme context**:
- Read [../../themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)
- Theme consumes entity render arrays
- Use custom theme hooks defined in `eldir.theme`

**Integration points**:
- Context sync: `ContextRegistry` writes to `~/.drush/sites/*.site.yml`
- Backend calls: `BackendInvoker::invoke('command', ['@alias'])`
- Render arrays: Pass to theme via entity view builders

---

### When Working in aegir-provision (Backend)

**You are here**: `/var/aegir/aegir-2601/drush/Commands/contrib/aegir-provision/`

**Read first**:
1. [.github/AGENTS.md](../drush/Commands/contrib/aegir-provision/.github/AGENTS.md) - **Quick reference** (start here!)
2. [.github/AI-INSTRUCTIONS.md](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md) - Backend architecture
3. [doc/Home.md](../drush/Commands/contrib/aegir-provision/doc/Home.md) - User guide

**This is a standalone repository**:
- It has its own Git history: `git log` shows provision commits only
- It can be developed independently: `git checkout -b feature-branch`
- It syncs to: https://github.com/argopecten/aegir-provision

**Component scope**:
- ✅ Drush commands (`provision-install`, `provision-verify`, etc.)
- ✅ Context system (Server, Platform, Site YAML aliases)
- ✅ Service layer (ApacheService, MySqlService, SslManager)
- ✅ Config generation (vhosts, settings.php, PHP-FPM pools)
- ✅ Infrastructure automation (Apache reload, MySQL grants)
- ❌ Drupal entities (that's aegir-hosting)
- ❌ Task queue and UI (that's aegir-hosting)
- ❌ Theme/presentation (that's aegir-eldir)

**When you need frontend context**:
- Read [../../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
- Frontend invokes backend via shell: `exec drush provision-install @site`
- Contexts are written by `ContextRegistry` service in hosting module
- Commands operate on YAML aliases in `~/.drush/sites/`

**Critical principles**:
- Commands must be idempotent (safe to run multiple times)
- Always validate context before operating
- Services must handle errors gracefully
- Template rendering must escape properly

**Context files location**:
- Read from: `~/.drush/sites/@alias.site.yml`
- Written by: Frontend's ContextRegistry
- Format: Drush 13 site alias YAML

---

### When Working in aegir-eldir (Theme)

**You are here**: `/var/aegir/aegir-2601/web/themes/contrib/aegir-eldir/`

**Read first*GENTS.md](../web/themes/contrib/aegir-eldir/.github/AGENTS.md) - **Quick reference** (start here!)
2. [.github/AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md) - Theme architecture
3. [.github/AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md) - Theme architecture
2. [doc/Home.md](../web/themes/contrib/aegir-eldir/doc/Home.md) - User guide

**This is a standalone repository**:
- It has its own Git history: `git log` shows eldir commits only
- It can be developed independently: `git checkout -b feature-branch`
- It syncs to: https://github.com/argopecten/aegir-eldir

**Component scope**:
- ✅ Twig templates (page, node, entity-specific)
- ✅ CSS (variables, BEM components, responsive layout)
- ✅ JavaScript (Drupal.behaviors)
- ✅ Preprocess functions (`eldir.theme`)
- ✅ Theme libraries and assets
- ❌ Entity logic (that's aegir-hosting)
- ❌ Form validation (that's aegir-hosting)
- ❌ Backend operations (that's aegir-provision)

**When you need frontend context**:
- Read [../../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
- Entities provide data via render arrays
- Custom theme hooks defined in hosting modules
- Variables passed via preprocess functions

**Design system**:
- CSS variables in `css/variables.css`
- BEM methodology: `.block__element--modifier`
- Mobile-first responsive design
- 5-tier breakpoints (mobile, tablet, desktop, wide, ultra-wide)

**Critical principle**:
- **Theme only presents data** - never contains business logic
- All data logic resides in hosting modules
- Preprocess functions only transform for display

---

## Cross-Repository Workflows

### Scenario 1: Adding a New Entity Field

**Example**: Add SSL certificate expiry date to HostingSite

1. **Start in aegir-hosting** (`web/modules/contrib/aegir-hosting/`)
   - Add field to [hosting_site/src/Entity/HostingSite.php](../web/modules/contrib/aegir-hosting/src/Entity/HostingSite.php)
   - Update [hosting_site/src/Form/HostingSiteForm.php](../web/modules/contrib/aegir-hosting/src/Form/HostingSiteForm.php)
   - Modify [src/Service/ContextRegistry.php](../web/modules/contrib/aegir-hosting/src/Service/ContextRegistry.php) to sync field to context
   - Commit in hosting repo: `git commit -m "Add SSL expiry field"`

2. **Move to aegir-provision** (`drush/Commands/contrib/aegir-provision/`)
   - Update context property in [src/Core/Context.php](../drush/Commands/contrib/aegir-provision/src/Core/Context.php)
   - Modify [src/Service/Ssl/SslManager.php](../drush/Commands/contrib/aegir-provision/src/Service/Ssl/SslManager.php) to read/update expiry
   - Commit in provision repo: `git commit -m "Support SSL expiry in context"`

3. **Move to aegir-eldir** (`web/themes/contrib/aegir-eldir/`)
   - Update preprocess in `eldir.theme` to format date
   - Add CSS for SSL expiry badge in `css/aegir.css`
   - Commit in theme repo: `git commit -m "Display SSL expiry date"`

4. **Return to main repo** (`/var/aegir/aegir-2601/`)
   - Test integration
   - Update [doc/Frontend.md](../doc/Frontend.md) to document field
   - Commit submodule updates: `git add web/modules/contrib/aegir-hosting drush/Commands/contrib/aegir-provision web/themes/contrib/aegir-eldir`
   - Commit: `git commit -m "Add SSL certificate expiry feature"`

---

### Scenario 2: Fixing a Backend Bug

**Example**: Fix Apache vhost generation escaping issue

1. **Start in aegir-provision** (`drush/Commands/contrib/aegir-provision/`)
   - This is purely a backend issue
   - Fix in [src/Service/Http/ApacheService.php](../drush/Commands/contrib/aegir-provision/src/Service/Http/ApacheService.php)
   - Add test in `tests/`
   - Commit: `git commit -m "Fix vhost escaping for special characters"`

2. **Check frontend implications** (`web/modules/contrib/aegir-hosting/`)
   - Read AI-INSTRUCTIONS.md to see if frontend validation should prevent the issue
   - If needed, add validation in [hosting_site/src/Form/HostingSiteForm.php](../web/modules/contrib/aegir-hosting/src/Form/HostingSiteForm.php)
   - Commit if changed: `git commit -m "Add domain validation for special chars"`

3. **Return to main repo** (`/var/aegir/aegir-2601/`)
   - Test the fix end-to-end
   - Update [doc/Backend.md](../doc/Backend.md) if needed
   - Commit submodule update: `git commit -m "Fix vhost generation escaping"`

---

### Scenario 3: Implementing a New Feature

**Example**: Add site backup functionality

1. **Plan in main repo** (`/var/aegir/aegir-2601/`)
   - Read [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) for architecture patterns
   - Check [doc/TODO.md](../doc/TODO.md) to see if already planned
   - Optionally add to [.github/TODO-RECIPES.md](.github/TODO-RECIPES.md) if it affects installation

2. **Implement in all three components**:
   
   **Frontend** (`web/modules/contrib/aegir-hosting/`):
   - Create `HostingBackup` entity in new `hosting_backup/` module
   - Add backup forms and views
   - Add "Backup" task type to [hosting_task/](../web/modules/contrib/aegir-hosting/hosting_task/)
   - Commit: `git commit -m "Add backup entity and task type"`
   
   **Backend** (`drush/Commands/contrib/aegir-provision/`):
   - Add `provision-backup` command in [src/Commands/ProvisionCommands.php](../drush/Commands/contrib/aegir-provision/src/Commands/ProvisionCommands.php)
   - Create `BackupService` in [src/Service/Backup/](../drush/Commands/contrib/aegir-provision/src/Service/)
   - Commit: `git commit -m "Add backup command and service"`
   
   **Theme** (`web/themes/contrib/aegir-eldir/`):
   - Create `templates/hosting-backup.html.twig`
   - Add backup icon CSS in `css/aegir.css`
   - Commit: `git commit -m "Add backup UI templates"`

3. **Document** (back in main repo):
   - Update [doc/HOME.md](../doc/HOME.md) with backup overview
   - Update [doc/Backend.md](../doc/Backend.md) with command details
   - Update [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) with integration points
   - Commit all: `git commit -m "Add backup feature documentation"`

---

## Documentation Maintenance

### When to Update AI Instructions

Update `.github/AI-INSTRUCTIONS.md` or `.github/ARCHITECTURE.md` when:
- Architecture patterns change
- New services or major classes are added
- Integration points between components change
- Code organization is refactored
- New development patterns are established
- Complex features need detailed technical docs

### When to Update Published Docs

Update `doc/*.md` files when:
- User-facing features are added
- API changes affect external usage
- Configuration options change
- Installation/setup procedures change
- Troubleshooting information is discovered
- Examples need updating

### Synchronization

Both documentation types should be kept in sync regarding:
- Overall architecture (high-level diagrams)
- Available features (what exists)
- API surface (public methods and services)

They diverge in:
- **AI docs**: Implementation details, code patterns, internal architecture
- **Published docs**: Usage examples, getting started, tutorials

---

## Quick Reference

### File Paths by Repository

| Repo | Quick Start | AI Instructions | Published Docs | Code Root |
|------|-------------|-----------------|----------------|-----------|
| **hostmaster** | *n/a* | `.github/ARCHITECTURE.md` | `doc/HOME.md` | `/var/aegir/aegir-2601/` |
| **hosting** | `.github/AGENTS.md` | `.github/AI-INSTRUCTIONS.md` | `doc/Home.md` | `web/modules/contrib/aegir-hosting/` |
| **provision** | `.github/AGENTS.md` | `.github/AI-INSTRUCTIONS.md` | `doc/Home.md` | `drush/Commands/contrib/aegir-provision/` |
| **eldir** | `.github/AGENTS.md` | `.github/AI-INSTRUCTIONS.md` | `doc/Home.md` | `web/themes/contrib/aegir-eldir/` |

**Pro Tip**: When working in a component repository, always check `.github/AGENTS.md` first for quick context and navigation links.

### Git Commands by Context

```bash
# Working in main repo
cd /var/aegir/aegir-2601
git status  # Shows main repo + submodule changes
git log     # Shows hostmaster commits only

# Working in component repo
cd /var/aegir/aegir-2601/web/modules/contrib/aegir-hosting
git status  # Shows hosting module changes only
git log     # Shows hosting commits only
git checkout -b feature-branch  # Create branch in hosting repo

# Committing across repos
cd /var/aegir/aegir-2601/web/modules/contrib/aegir-hosting
git add . && git commit -m "Feature in hosting"  # Commit in component
cd /var/aegir/aegir-2601
git add web/modules/contrib/aegir-hosting       # Stage submodule update
git commit -m "Update hosting submodule"         # Commit in main repo
```

---

## AI Agent Best Practices

### 1. Always Check Repository Context
Before making changes, determine which repository you're in:
```bash
git remote -v  # Shows GitHub URL
pwd            # Shows current directory
```

**If in a component repository**: Check `.github/AGENTS.md` first for quick orientation.

### 2. Read Component AI Instructions First
When working on a specific component, follow this reading order:
1. **Quick start**: `.github/AGENTS.md` (component repos only) - Immediate context
2. **Deep dive**: `.github/AI-INSTRUCTIONS.md` - Complete technical guide  
3. **Integration**: Parent repo [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) - Cross-component patterns

### 3. Understand Integration Points
When working across components:
1. Read main repo [.github/ARCHITECTURE.md](.github/ARCHITECTURE.md) for integration patterns
2. Follow the data flow diagrams
3. Check how components communicate (ContextRegistry, BackendInvoker, theme hooks)

### 4. Respect Component Boundaries
- ✅ Frontend: Entity logic, forms, validation, task creation
- ✅ Backend: Infrastructure operations, context management, service orchestration
- ✅ Theme: Presentation only - templates, CSS, JS
- ❌ Don't put backend logic in frontend
- ❌ Don't put entity logic in backend
- ❌ Don't put business logic in theme

### 5. Test Across Components
When implementing features:
1. Test in component repository first
2. Test integration in main repository
3. Verify end-to-end functionality
4. Update docs in both component and main repo

### 6. Documentation Hygiene
- Update AI-INSTRUCTIONS.md when patterns change
- Update published docs when user-facing features change
- Keep architecture diagrams in sync
- Link between related documentation

---

## Troubleshooting

### "I can't find the code I need to modify"

1. Check `.github/AGENTS.md` if you're in a component repository - it has quick navigation links

2. Identify which layer needs changes:
   - **UI/Forms/Entities** → aegir-hosting
   - **Drush/Services/Infrastructure** → aegir-provision
   - **Templates/CSS** → aegir-eldir

3. Read that component's AI-INSTRUCTIONS.md

4. Use semantic search in the component directory

### "Changes aren't being reflected"

1. Check if you're modifying the right repository:
   ```bash
   pwd  # Are you in the component or main repo?
   ```

2. If in a component, changes are local to that Git repo

3. Main repo needs submodule update to see component changes:
   ```bash
   cd /var/aegir/aegir-2601
   git status  # Shows "modified: web/modules/contrib/aegir-hosting"
   ```

### "Documentation seems outdated"

1. Check the "Last Updated" date at the top of the file

2. Read both AI instructions and published docs - they may have diverged

3. When in doubt, trust the code and update the docs

4. AI-INSTRUCTIONS.md is typically more current than published docs

---

## Summary

Aegir uses **layered architecture** with **distributed repositories**:

- **Main repo** (aegir-hostmaster): Container project with integration docs
- **Component repos** (aegir-hosting, aegir-provision, aegir-eldir): Standalone modules/theme

Each has **two documentation systems**:
- **AI Instructions** (`.github/*.md`): Technical details for AI agents
- **Published Docs** (`doc/*.md`): User-facing documentation

**Key principle for AI agents**: 
1. Identify which repository you're working in
2. Read that repository's AI instructions first
3. Check integration docs in main repo when working across components
4. Respect component boundaries
5. Update documentation when patterns change

---

## Document Status

✅ **Complete** - Covers all repositories and documentation types  
🔄 **Living Document** - Update as architecture evolves  
📍 **Quick Links**:
- [Main Repo ARCHITECTURE.md](.github/ARCHITECTURE.md)
- [Hosting AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
- [Provision AI-INSTRUCTIONS.md](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
- [Eldir AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)
