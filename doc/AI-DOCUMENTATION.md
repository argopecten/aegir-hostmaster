# Documentation for AI Coding Agents

**Last Updated**: January 29, 2026  
**Audience**: AI assistants working with Aegir codebase

## Overview

Aegir uses a **layered architecture** with multiple Git repositories. This page provides an overview of documentation for AI coding agents.

## For AI Agents

If you are an AI assistant (Claude, GPT-4, GitHub Copilot, etc.) working in the Aegir codebase:

**📘 Start Here**: [.github/AI-AGENT-GUIDE.md](../.github/AI-AGENT-GUIDE.md)

This comprehensive guide explains:
- How the four repositories relate to each other
- Where to find AI instructions vs. published docs
- Navigation strategies for cross-repository work
- When to reference parent or child components
- Best practices for working across the codebase

## Repository Structure

Aegir consists of one main repository and three component repositories:

### Main Repository: aegir-hostmaster

- **GitHub**: https://github.com/argopecten/aegir-hostmaster
- **Local**: `/var/aegir/aegir-2601/`
- **AI Docs**: 
  - [.github/ARCHITECTURE.md](../.github/ARCHITECTURE.md) - Overall architecture
  - [.github/AI-AGENT-GUIDE.md](../.github/AI-AGENT-GUIDE.md) - Navigation guide
  - [.github/TODO-RECIPES.md](../.github/TODO-RECIPES.md) - Recipes implementation
- **Published Docs**: [doc/](.) - This folder (HOME.md, Frontend.md, Backend.md, Theme.md, TODO.md)

### Component 1: aegir-hosting (Frontend)

- **GitHub**: https://github.com/argopecten/aegir-hosting
- **Local**: `/var/aegir/aegir-2601/web/modules/contrib/aegir-hosting/`
- **AI Docs**: [.github/AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md) (2000+ lines)
- **Published Docs**: [doc/](../web/modules/contrib/aegir-hosting/doc/) (Home.md, hosting-d11.md)
- **Scope**: Drupal entities, forms, task queue, services

### Component 2: aegir-provision (Backend)

- **GitHub**: https://github.com/argopecten/aegir-provision
- **Local**: `/var/aegir/aegir-2601/drush/Commands/contrib/aegir-provision/`
- **AI Docs**: [.github/AI-INSTRUCTIONS.md](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md) (990+ lines)
- **Published Docs**: [doc/](../drush/Commands/contrib/aegir-provision/doc/) (Home.md, provision-d11.md)
- **Scope**: Drush commands, context system, Apache/MySQL services

### Component 3: aegir-eldir (Theme)

- **GitHub**: https://github.com/argopecten/aegir-eldir
- **Local**: `/var/aegir/aegir-2601/web/themes/contrib/aegir-eldir/`
- **AI Docs**: [.github/AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md) (1200+ lines)
- **Published Docs**: [doc/](../web/themes/contrib/aegir-eldir/doc/) (Home.md, eldir-d11.md)
- **Scope**: Twig templates, CSS, JavaScript

## Documentation Types

### AI Instructions (`.github/` folders)

**Purpose**: Detailed technical guidance for AI coding agents  
**Format**: Comprehensive markdown with code examples, patterns, architecture  
**Audience**: AI assistants (Claude, GPT-4, Copilot)

**Files**:
- `ARCHITECTURE.md` - Integration architecture (main repo only)
- `AI-INSTRUCTIONS.md` - Component-specific details (all components)
- `AI-AGENT-GUIDE.md` - Navigation guide (main repo only)
- `TODO-*.md` - AI-readable task lists

### Published Documentation (`doc/` folders)

**Purpose**: User-facing documentation for developers and site builders  
**Format**: Markdown synced to GitHub  
**Audience**: Human developers using Aegir

**Files**:
- `HOME.md` or `Home.md` - Main entry point
- `Frontend.md`, `Backend.md`, `Theme.md` - Component guides (main repo)
- `*-d11.md` - Drupal 11 implementations (components)
- `TODO.md` - Development roadmap (main repo)

## Quick Start for AI Agents

### Step 1: Determine Your Context

```bash
pwd                # Check current directory
git remote -v      # Check which repository you're in
```

### Step 2: Read Relevant Documentation

- **In main repo** → Read [.github/ARCHITECTURE.md](../.github/ARCHITECTURE.md) first
- **In aegir-hosting** → Read [.github/AI-INSTRUCTIONS.md](../web/modules/contrib/aegir-hosting/.github/AI-INSTRUCTIONS.md)
- **In aegir-provision** → Read [.github/AI-INSTRUCTIONS.md](../drush/Commands/contrib/aegir-provision/.github/AI-INSTRUCTIONS.md)
- **In aegir-eldir** → Read [.github/AI-INSTRUCTIONS.md](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md)

### Step 3: Understand Integration Points

Read [AI-AGENT-GUIDE.md](../.github/AI-AGENT-GUIDE.md) for:
- How components communicate
- Cross-repository workflows
- When to update multiple repos
- Documentation maintenance rules

## For Human Developers

If you're a human developer looking for AI documentation to understand the system better, the AI instructions can be valuable resources:

- **System Architecture**: Start with [HOME.md](HOME.md) then [.github/ARCHITECTURE.md](../.github/ARCHITECTURE.md)
- **Code Patterns**: Read component AI-INSTRUCTIONS.md files for detailed implementation patterns
- **Integration**: [AI-AGENT-GUIDE.md](../.github/AI-AGENT-GUIDE.md) explains how components interact

However, for getting started and basic usage, stick with the published docs in this folder.

## See Also

- [HOME.md](HOME.md) - Architecture overview (published)
- [Frontend.md](Frontend.md) - Frontend component guide
- [Backend.md](Backend.md) - Backend component guide
- [Theme.md](Theme.md) - Theme component guide
- [TODO.md](TODO.md) - Development roadmap

---

**Note**: This is a meta-documentation page. For actual system documentation, start with [HOME.md](HOME.md).
