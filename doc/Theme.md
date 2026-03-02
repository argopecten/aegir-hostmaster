# Theme Component — Aegir Eldir

Eldir is the companion Drupal 11 theme for Aegir Hostmaster. It extends **stable9** (Drupal core's backward-compatible base theme) and provides a hosting-management-optimized interface with custom templates, preprocess functions, and Drupal behaviors.

## Table of Contents

- [Overview](#overview)
- [Theme Configuration](#theme-configuration)
- [Directory Structure](#directory-structure)
- [Template System](#template-system)
- [CSS Architecture](#css-architecture)
- [JavaScript](#javascript)
- [Preprocess Functions](#preprocess-functions)
- [Responsive Design](#responsive-design)
- [Development Guidelines](#development-guidelines)

## Overview

**Location**: `web/themes/contrib/aegir-eldir/`
**Machine name**: `eldir`
**Base theme**: `false` (standalone)
**Core requirement**: `^11`

### At a Glance

| Metric | Count |
|---|---|
| Templates | 99 (20 custom + 79 from stable9) |
| CSS files | 6 (~3,889 lines) |
| JS files | 1 (313 lines, 9 behaviors) |
| Preprocess functions | 19 |
| Breakpoints | 5 (0/768/1024/1280/1600px) |
| Regions | 8 |

**Key Principle**: The theme handles **only presentation** — all data logic resides in hosting modules.

**No SDC (Single Directory Components)** are used. Templates use traditional `hook_theme()` registration via `eldir.theme`. SDC adoption is planned (see [eldir doc/TODO.md](../web/themes/contrib/aegir-eldir/doc/TODO.md)). There is no `src/` directory — Eldir has no PHP classes.

## Theme Configuration

### eldir.info.yml

```yaml
name: Eldir
type: theme
description: Companion theme for the Aegir hosting system.
core_version_requirement: ^11
base theme: false
libraries:
  - eldir/global-styling
regions:
  navigation: Navigation
  header: Header
  help: Help
  content: Content
  content_bottom: Content bottom
  sidebar_first: Sidebar top
  sidebar_second: Sidebar bottom
  footer: Footer
```

### eldir.libraries.yml

Single library `global-styling`, attached globally:

```yaml
global-styling:
  css:
    base:
      css/variables.css: { weight: -100 }
      css/base.css: {}
    layout:
      css/layout.css: {}
    component:
      css/components.css: {}
    theme:
      css/aegir.css: {}
      css/responsive.css: {}
  js:
    js/eldir.js: {}
  dependencies:
    - core/drupal
    - core/once
```

Dependencies: `core/drupal` (Drupal JS API) and `core/once` (one-time processing).

### eldir.breakpoints.yml

| Breakpoint | Media Query | Weight |
|---|---|---|
| `eldir.mobile` | `(min-width: 0px)` | 0 |
| `eldir.tablet` | `(min-width: 768px)` | 1 |
| `eldir.desktop` | `(min-width: 1024px)` | 2 |
| `eldir.wide` | `(min-width: 1280px)` | 3 |
| `eldir.ultrawide` | `(min-width: 1600px)` | 4 |

All breakpoints define `1x` and `2x` multipliers.

## Directory Structure

```
aegir-eldir/
├── eldir.info.yml              # Theme metadata, regions
├── eldir.libraries.yml         # CSS/JS library definitions
├── eldir.breakpoints.yml       # Responsive breakpoints
├── eldir.theme                 # 19 preprocess functions (588 lines)
├── logo.svg                    # Aegir logo
├── screenshot.png              # Theme preview
├── css/
│   ├── variables.css           # CSS custom properties (284 lines)
│   ├── base.css                # Reset, typography, base elements (266 lines)
│   ├── layout.css              # Grid, regions, page structure (329 lines)
│   ├── components.css          # Buttons, forms, tables, messages (997 lines)
│   ├── aegir.css               # Aegir-specific hosting styles (1,671 lines)
│   └── responsive.css          # Media queries (342 lines)
├── js/
│   └── eldir.js                # 9 Drupal behaviors (313 lines)
├── templates/
│   ├── html.html.twig          # HTML wrapper
│   ├── page.html.twig          # Default page layout
│   ├── page--hosting.html.twig # Hosting pages (sidebar layout)
│   ├── page--user--login.html.twig
│   ├── page--user--password.html.twig
│   ├── page--user--register.html.twig
│   ├── node.html.twig          # Default node template
│   ├── block.html.twig         # Block template
│   ├── region.html.twig        # Region wrapper
│   ├── menu--main.html.twig    # Main navigation menu
│   ├── menu--secondary.html.twig # Secondary/account menu
│   ├── hosting-site.html.twig  # Site entity display
│   ├── hosting-server.html.twig # Server entity display
│   ├── hosting-task.html.twig  # Task entity display
│   ├── hosting-queues-table.html.twig # Queue overview table
│   ├── hosting-service-status-cell.html.twig # Service status in tables
│   └── components/
│       ├── hosting-entity-chip.html.twig   # Compact entity reference
│       ├── hosting-panel.html.twig         # Content panel wrapper
│       ├── hosting-status-badge.html.twig  # Status indicator badge
│       └── hosting-task-card.html.twig     # Task card in queue view
└── doc/
    ├── Home.md
    ├── eldir-d11.md
    └── TODO.md
```

## Template System

### Page Templates

| Template | Usage |
|---|---|
| `page.html.twig` | Default page layout |
| `page--hosting.html.twig` | Hosting entity pages — includes sidebar navigation |
| `page--user--login.html.twig` | Login page (centered, minimal) |
| `page--user--password.html.twig` | Password reset page |
| `page--user--register.html.twig` | Registration page |

### Entity Templates

| Template | Renders |
|---|---|
| `hosting-site.html.twig` | Site entity view — domain, platform, status, tasks |
| `hosting-server.html.twig` | Server entity view — services, status cells |
| `hosting-task.html.twig` | Task entity view — type, status, log output |
| `hosting-queues-table.html.twig` | Queue overview — pending tasks per queue |
| `hosting-service-status-cell.html.twig` | Service status in server table |

These are registered via `hook_theme()` in `eldir.theme`, not via entity view builders. The hosting modules provide render arrays; the theme provides the templates.

### Component Templates

Reusable UI fragments in `templates/components/`:

| Template | Purpose |
|---|---|
| `hosting-entity-chip.html.twig` | Compact entity reference (icon + label + status) |
| `hosting-panel.html.twig` | Titled content panel with optional actions |
| `hosting-status-badge.html.twig` | Color-coded status indicator |
| `hosting-task-card.html.twig` | Task summary card for queue views |

These are render-array-based components, not SDC. Called from preprocess functions and entity view builders.

## CSS Architecture

### Layer Structure

CSS follows Drupal's SMACSS-inspired library weight system:

| Layer | File | Weight | Purpose | Lines |
|---|---|---|---|---|
| Base | `variables.css` | -100 | CSS custom properties (colors, spacing, fonts) | 284 |
| Base | `base.css` | default | Reset, typography, base HTML elements | 266 |
| Layout | `layout.css` | layout | Grid, regions, page structure | 329 |
| Component | `components.css` | component | Buttons, forms, tables, messages, navigation | 997 |
| Theme | `aegir.css` | theme | Aegir-specific hosting entity styles | 1,671 |
| Theme | `responsive.css` | theme | Media queries for all breakpoints | 342 |

### CSS Custom Properties

`variables.css` defines design tokens — colors, spacing, typography, and component-specific values. All other CSS files reference these variables for consistency.

### Key CSS Classes

| Pattern | Purpose |
|---|---|
| `.hosting-site`, `.hosting-server`, `.hosting-task` | Entity type containers |
| `.hosting-status--enabled`, `.hosting-status--disabled` | Status indicators |
| `.hosting-panel` | Content panel |
| `.hosting-entity-chip` | Compact entity reference |
| `.hosting-status-badge` | Status badge |
| `.hosting-task-card` | Task card |

## JavaScript

### eldir.js

Single file with 9 `Drupal.behaviors`:

| Behavior | Purpose |
|---|---|
| `eldirSmoothScroll` | Smooth scrolling for anchor links |
| `eldirResponsiveTables` | Responsive table wrapping |
| `eldirMobileNav` | Mobile navigation toggle |
| `eldirFormEnhancement` | Form UX improvements |
| `eldirAutoExpandTextarea` | Auto-expanding textareas |
| `eldirLiveTaskStatus` | Live task status polling/updates |
| `eldirCollapsible` | Collapsible sections |
| `eldirActiveTrail` | Active menu trail highlighting |
| `eldirCopyCode` | Copy-to-clipboard for code blocks |

All behaviors use `core/once` for idempotent attachment and follow the `Drupal.behaviors.{name} = { attach: function(context, settings) {} }` pattern.

## Preprocess Functions

`eldir.theme` (588 lines) contains 19 preprocess functions:

### Core Preprocess

| Function | Purpose |
|---|---|
| `eldir_preprocess_html()` | Body classes, page-level attributes |
| `eldir_preprocess_page()` | Page variables, sidebar logic, branding |
| `eldir_preprocess_node()` | Node type classes, view mode handling |

### Entity Preprocess

| Function | Purpose |
|---|---|
| `eldir_preprocess_entity__hosting_server()` | Server entity variables |
| `eldir_preprocess_entity__hosting_site()` | Site entity variables |
| `eldir_preprocess_entity__hosting_client()` | Client entity variables |
| `eldir_preprocess_entity__hosting_task()` | Task entity variables |
| `eldir_preprocess_hosting_site()` | Site template variables |
| `eldir_preprocess_hosting_platform()` | Platform template variables |
| `eldir_preprocess_hosting_server()` | Server template variables |

### UI Element Preprocess

| Function | Purpose |
|---|---|
| `eldir_preprocess_menu__main()` | Main menu customization |
| `eldir_preprocess_menu_local_tasks()` | Local tasks (tabs) |
| `eldir_preprocess_table()` | Table enhancements |
| `eldir_preprocess_form()` | Form wrapper classes |
| `eldir_preprocess_form_element()` | Form element styling |

### Component Preprocess

| Function | Purpose |
|---|---|
| `eldir_preprocess_hosting_status_badge()` | Badge color/label from status |
| `eldir_preprocess_hosting_panel()` | Panel title/content/actions |
| `eldir_preprocess_hosting_task_card()` | Task card data extraction |
| `eldir_preprocess_hosting_entity_chip()` | Entity chip label/icon/link |

## Responsive Design

Mobile-first approach using the 5 breakpoints defined in `eldir.breakpoints.yml`.

### Key Responsive Patterns

- **Navigation**: collapses to hamburger menu below tablet (768px)
- **Layout**: single column on mobile, sidebar layout on desktop (1024px+)
- **Tables**: horizontal scroll wrapper on small screens
- **Forms**: full-width inputs on mobile, inline labels on desktop

All responsive styles are in `responsive.css`, using `@media` queries matching the breakpoint values.

## Development Guidelines

### Key Rules

- No PHP classes — all logic is in `eldir.theme` preprocess functions
- No SDC yet — templates use traditional `hook_theme()` registration
- Base theme is `false` (standalone, D11 pattern) — 79 stable9 templates are copied into the theme for full markup ownership
- All JavaScript uses `Drupal.behaviors` with `core/once`
- CSS custom properties in `variables.css` — use them instead of hardcoded values
- Hosting-specific templates are entity-based, not node-type-based
- SVG icon sprite path is resolved via `hosting.icon_provider` service — modules must never hardcode the theme name

### Adding a New Template

1. Create `.html.twig` file in `templates/` (or `templates/components/`)
2. Register via `hook_theme()` in `eldir.theme`
3. Add preprocess function `eldir_preprocess_{template_name}()`
4. Ensure the hosting module provides the render array

### Styling Convention

- Use existing CSS custom properties from `variables.css`
- Follow SMACSS layers: base → layout → component → theme
- Prefix all Aegir classes with `hosting-`
- Responsive styles go in `responsive.css`

---

**Related**: [HOME.md](HOME.md) · [Frontend.md](Frontend.md) · [Backend.md](Backend.md) · [eldir-d11.md](../web/themes/contrib/aegir-eldir/doc/eldir-d11.md)
