# Documentation for AI Coding Agents

**Last Updated**: March 1, 2026
**Audience**: AI assistants working with Aegir codebase

## Overview

Aegir uses a **layered architecture** with multiple Git repositories. This page provides an overview of documentation for AI coding agents.

## For AI Agents

If you are an AI assistant (Claude, GPT-4, GitHub Copilot, etc.) working in the Aegir codebase:

**Start Here**: [.github/AGENTS.md](../.github/AGENTS.md)

This guide explains:
- How the four repositories relate to each other
- Architecture overview and data flow
- Key concepts and naming conventions
- Known issues and anti-patterns

For actionable step-by-step procedures, see: [.github/SKILLS.md](../.github/SKILLS.md)

## Repository Structure

Aegir consists of one main repository and three component repositories:

### Main Repository: aegir-hostmaster

- **GitHub**: https://github.com/argopecten/aegir-hostmaster
- **Local**: `/var/aegir/aegir-2601/`
- **AI Docs**:
  - [.github/AGENTS.md](../.github/AGENTS.md) — Architecture + context for AI agents
  - [.github/SKILLS.md](../.github/SKILLS.md) — Actionable instruction sets
- **Published Docs**: [doc/](.) — This folder (HOME.md, Frontend.md, Backend.md, Theme.md, TODO.md)

### Component 1: aegir-hosting (Frontend)

- **GitHub**: https://github.com/argopecten/aegir-hosting
- **Local**: `/var/aegir/aegir-2601/web/modules/contrib/aegir-hosting/`
- **AI Docs**:
  - [.github/AGENTS.md](../web/modules/contrib/aegir-hosting/.github/AGENTS.md) — Entity system, services, architecture
  - [.github/SKILLS.md](../web/modules/contrib/aegir-hosting/.github/SKILLS.md) — Entity creation, forms, task queue, testing
- **Published Docs**: [doc/](../web/modules/contrib/aegir-hosting/doc/) (Home.md, hosting-d11.md)
- **Scope**: Drupal entities, forms, task queue, services

### Component 2: aegir-provision (Backend)

- **GitHub**: https://github.com/argopecten/aegir-provision
- **Local**: `/var/aegir/aegir-2601/vendor/argopecten/aegir-provision/`
- **AI Docs**:
  - [.github/AGENTS.md](../vendor/argopecten/aegir-provision/.github/AGENTS.md) — Command system, context, services
  - [.github/SKILLS.md](../vendor/argopecten/aegir-provision/.github/SKILLS.md) — Command creation, service implementation, Drush 13
- **Published Docs**: [doc/](../vendor/argopecten/aegir-provision/doc/) (Home.md, provision-d11.md)
- **Scope**: Drush commands, context system, Apache/MySQL services

### Component 3: aegir-eldir (Theme)

- **GitHub**: https://github.com/argopecten/aegir-eldir
- **Local**: `/var/aegir/aegir-2601/web/themes/contrib/aegir-eldir/`
- **AI Docs**:
  - [.github/AGENTS.md](../web/themes/contrib/aegir-eldir/.github/AGENTS.md) — Templates, CSS, JS, preprocess
  - [.github/SKILLS.md](../web/themes/contrib/aegir-eldir/.github/SKILLS.md) — Template creation, styling, behaviors
- **Published Docs**: [doc/](../web/themes/contrib/aegir-eldir/doc/) (Home.md, eldir-d11.md)
- **Scope**: Twig templates, CSS, JavaScript

## Documentation Types

### AI Agent Docs (`.github/` folders)

**Purpose**: Technical guidance for AI coding agents
**Format**: Comprehensive markdown with code examples, patterns, architecture

**Files**:
- `AGENTS.md` — Component architecture, context, rules, known issues
- `SKILLS.md` — Step-by-step actionable instruction sets for specific tasks
- `TODO-*.md` — AI-readable task lists

### Published Documentation (`doc/` folders)

**Purpose**: User-facing documentation for developers and site builders
**Format**: Markdown synced to GitHub
**Audience**: Human developers using Aegir

**Files**:
- `HOME.md` or `Home.md` — Main entry point
- `Frontend.md`, `Backend.md`, `Theme.md` — Component guides (main repo)
- `*-d11.md` — Drupal 11 implementations (components)
- `TODO.md` — Development roadmap (main repo)

## Quick Start for AI Agents

### Step 1: Determine Your Context

```bash
pwd                # Check current directory
git remote -v      # Check which repository you're in
```

### Step 2: Read Relevant Documentation

- **In main repo** → Read [.github/AGENTS.md](../.github/AGENTS.md) first
- **In aegir-hosting** → Read [web/modules/contrib/aegir-hosting/.github/AGENTS.md](../web/modules/contrib/aegir-hosting/.github/AGENTS.md)
- **In aegir-provision** → Read [vendor/argopecten/aegir-provision/.github/AGENTS.md](../vendor/argopecten/aegir-provision/.github/AGENTS.md)
- **In aegir-eldir** → Read [web/themes/contrib/aegir-eldir/.github/AGENTS.md](../web/themes/contrib/aegir-eldir/.github/AGENTS.md)

### Step 3: Perform Tasks

Read the component's `SKILLS.md` for step-by-step procedures for common tasks like creating entities, adding commands, writing templates, etc.
