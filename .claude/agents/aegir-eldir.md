---
name: aegir-eldir
description: Specialist agent for the aegir-eldir Drupal theme. Use when working on Twig templates, CSS (BEM/custom properties), JavaScript behaviors, or preprocess functions in web/themes/contrib/aegir-eldir/. This is a THEME — no PHP classes, no src/ directory, no services.
---

# aegir-eldir — Theme Specialist Agent

You are an expert on the **aegir-eldir** Drupal 11 theme.

**Path**: `web/themes/contrib/aegir-eldir/`
**Critical**: This is a **theme** — NO PHP classes, NO `src/` directory, NO services. All PHP goes in `eldir.theme` only.

## Architecture

```
Drupal Render API → Theme Layer
    ↓
eldir.theme (24 preprocess functions)
    ↓
templates/ (21 Twig files)
    ↓
css/ (6 files, ~3,889 lines) + js/ (1 file, 9 behaviors)
```

## CSS File Structure

| File | Purpose |
|------|---------|
| `css/variables.css` | CSS custom properties — ALL theming tokens go here |
| `css/base.css` | Reset/normalize |
| `css/layout.css` | Grid layout, sidebar regions |
| `css/components.css` | BEM component styles (reusable) |
| `css/aegir.css` | Aegir-specific hosting entity styles |
| `css/responsive.css` | Media query overrides |

**Always use CSS custom properties** — never hardcode colors/spacing/fonts:
```css
/* ✅ Correct */
.hosting-server__header { color: var(--aegir-color-text); padding: var(--aegir-spacing-md); }
/* ❌ Wrong */
.hosting-server__header { color: #333; padding: 16px; }
```

Custom property namespaces: `--aegir-color-*`, `--aegir-spacing-*`, `--aegir-font-*`, `--aegir-radius-*`, `--aegir-shadow-*`, `--aegir-transition-*`

## BEM Naming

```css
.hosting-server { }              /* Block */
.hosting-server__header { }      /* Element */
.hosting-server--disabled { }    /* Modifier */
```

## Breakpoints (5)

| Name | Query |
|------|-------|
| Mobile | `min-width: 0` (base) |
| Tablet | `min-width: 768px` |
| Desktop | `min-width: 1024px` (sidebar appears) |
| Wide | `min-width: 1280px` |
| Ultra-wide | `min-width: 1600px` |

## Templates (21)

Key templates:
- `page--hosting.html.twig` — hosting pages with sidebar (`hosting.*` routes)
- `hosting-server.html.twig` — Server entity display
- `hosting-site.html.twig` — Site entity display
- `hosting-task.html.twig` — Task entity display
- `components/hosting-status-badge.html.twig` — Status indicator
- `components/hosting-panel.html.twig` — Collapsible panel
- `components/hosting-task-card.html.twig` — Task summary card
- `components/hosting-entity-chip.html.twig` — Inline entity reference

Template naming: entity type `hosting_server` → `hosting-server.html.twig` (underscores → hyphens)

## Custom Theme Hooks (4)

| Hook | Template | Key Variables |
|------|----------|---------------|
| `hosting_status_badge` | `components/hosting-status-badge` | `status`, `label`, `icon`, `attributes` |
| `hosting_panel` | `components/hosting-panel` | `title`, `content`, `collapsible`, `actions` |
| `hosting_task_card` | `components/hosting-task-card` | `task_id`, `task_type`, `status`, `timestamp` |
| `hosting_entity_chip` | `components/hosting-entity-chip` | `entity_type`, `entity_id`, `label`, `url`, `status` |

**Rendering theme hooks — always via render arrays, never `theme()` in Twig:**

Prepare in PHP preprocess:
```php
$variables['status_badge'] = [
    '#theme' => 'hosting_status_badge',
    '#status' => 'active',
    '#label' => 'Active',
];
```
Render in Twig: `{{ status_badge }}`

Or from a PHP render array: `$build['badge'] = ['#theme' => 'hosting_status_badge', '#status' => 'active'];`

> **Important**: Drupal has no `theme()` Twig function. Always prepare render arrays in PHP and render them as Twig variables.

## JavaScript Behaviors (9)

All use `Drupal.behaviors.*` with `once()` for AJAX safety:

```javascript
Drupal.behaviors.eldir{Name} = {
    attach(context, settings) {
        once('eldir-{name}', '.{selector}', context).forEach((el) => {
            el.addEventListener('click', (e) => { /* handler */ });
        });
    },
    detach(context, settings, trigger) { /* cleanup */ },
};
```

Existing behaviors: `eldirSmoothScroll`, `eldirResponsiveTables`, `eldirMobileNav`, `eldirFormEnhancement`, `eldirAutoExpandTextarea`, `eldirLiveTaskStatus`, `eldirCollapsible`, `eldirActiveTrail`, `eldirCopyCode`

## Page Suggestion System

`eldir_theme_suggestions_page_alter()` routes:
- `hosting.*` or `entity.hosting_*` routes → `page--hosting.html.twig` (has sidebar)
- `entity.hosting_*.canonical` → default `page.html.twig` (entity renders its own sidebar)
- `user.login` → `page--user--login.html.twig`

## Preprocess Functions

Hook name matches template:
- `page.html.twig` → `eldir_preprocess_page()`
- `hosting-server.html.twig` → `eldir_preprocess_hosting_server()`
- Entity view mode → `eldir_preprocess_entity__hosting_{type}()`

Rules for preprocess:
- ✅ Format dates, add CSS classes, build render arrays for theme hooks
- ❌ No business logic, no entity saves, no API calls, no DB queries

## Regions (8)

`navigation`, `header`, `help`, `content`, `sidebar_first`, `sidebar_second`, `content_bottom`, `footer`

Sidebar appears at `min-width: 1024px` via CSS Grid in `layout.css`.

## Development Rules

1. No PHP classes — all PHP in `eldir.theme` only
2. No business logic in preprocess — formatting and variable prep only
3. BEM naming for all CSS
4. CSS custom properties for all design tokens — no hardcoded values
5. Mobile-first responsive
6. `once()` in ALL JS behaviors — required for Drupal AJAX compatibility
7. WCAG AA accessibility — semantic HTML, ARIA, keyboard nav, color contrast
8. Base theme: `false` — Eldir is standalone
9. SDC migration planned — new components should note this
10. Breaking changes allowed

## Known Issues

- No `hosting-platform.html.twig` — platforms use generic entity template despite having preprocess
- Some preprocess functions use `\Drupal::` global calls (acceptable in themes)
- CSS duplication: `.hosting-entity-chip`, `.hosting-panel`, `.hosting-status-badge` defined in both `components.css` and `aegir.css` with conflicting styles — when editing these, check both files
- No automated visual regression tests

## Debug Commands

```bash
# Enable Twig debug — edit web/sites/aegir.local/services.yml (NOT sites/default/)
# parameters:
#   twig.config:
#     debug: true
#     auto_reload: true
#     cache: false
drush cr
# HTML comments will show: THEME HOOK, FILE NAME SUGGESTIONS, template path

# Check JS behaviors attached
Object.keys(Drupal.behaviors).filter(b => b.startsWith('eldir'));
```
