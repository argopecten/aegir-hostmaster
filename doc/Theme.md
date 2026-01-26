# Theme Component - Aegir Eldir

The **Theme** component provides the visual interface for Aegir. Eldir is a custom Drupal 11 theme designed specifically for hosting management, providing a clean and efficient interface for administrators.

## Table of Contents

- [Overview](#overview)
- [Theme Architecture](#theme-architecture)
- [Template System](#template-system)
- [CSS Architecture](#css-architecture)
- [JavaScript Integration](#javascript-integration)
- [Responsive Design](#responsive-design)
- [Single Directory Components](#single-directory-components)
- [Development Guidelines](#development-guidelines)

## Overview

**Location**: `web/themes/contrib/aegir-eldir/`

**Purpose**: Provides the user interface theme optimized for Aegir hosting management.

**Key Responsibilities**:
- Visual presentation of hosting entities
- Task log display and formatting
- Server status visualization
- Responsive layout for mobile and desktop
- Accessibility compliance

**Key Principle**: The theme handles **only presentation** - all data logic resides in hosting modules.

## Theme Architecture

### Directory Structure

```
aegir-eldir/
├── css/
│   ├── base.css              # Reset, typography, base elements
│   ├── layout.css            # Grid, regions, page structure
│   ├── components.css        # Buttons, forms, tables, messages
│   └── aegir.css             # Aegir-specific styling
├── js/
│   └── aegir-tasks.js        # Task queue updates, log filtering
├── templates/
│   ├── page.html.twig        # Page layout
│   ├── node--hosting-site.html.twig
│   ├── node--hosting-platform.html.twig
│   ├── node--hosting-server.html.twig
│   └── hosting-task-log.html.twig
├── components/               # Single Directory Components (SDC)
│   └── info-table/
│       ├── info-table.component.yml
│       ├── info-table.twig
│       └── info-table.css
├── eldir.theme               # Preprocess hooks, theme logic
├── eldir.info.yml            # Theme metadata, regions, libraries
├── eldir.libraries.yml       # CSS/JS library definitions
├── eldir.breakpoints.yml     # Responsive breakpoints
├── logo.svg                  # Aegir logo
└── screenshot.png            # Theme preview
```

### Theme Configuration

**File**: `eldir.info.yml`

```yaml
name: 'Aegir Eldir'
type: theme
description: 'Official theme for Aegir Hostmaster D11'
package: Aegir
core_version_requirement: ^11
base theme: false

regions:
  header: Header
  navigation: Navigation
  breadcrumb: Breadcrumb
  highlighted: Highlighted
  help: Help
  content: Content
  sidebar_first: 'Left sidebar'
  sidebar_second: 'Right sidebar'
  footer: Footer

libraries:
  - eldir/global

libraries-override:
  core/drupal.ajax: eldir/aegir-tasks

settings:
  use_svg_logo: true
  wide_layout: false
  main_menu_name: main
  secondary_menu_name: account
```

### Library Definitions

**File**: `eldir.libraries.yml`

```yaml
global:
  version: 1.x
  css:
    base:
      css/base.css: {}
    layout:
      css/layout.css: {}
    component:
      css/components.css: {}
    theme:
      css/aegir.css: {}

aegir-tasks:
  version: 1.x
  js:
    js/aegir-tasks.js: {}
  dependencies:
    - core/drupal
    - core/jquery
    - core/drupal.ajax
```

## Template System

### Page Template

**File**: `templates/page.html.twig`

```twig
<div class="layout-container">
  <header role="banner">
    {{ page.header }}
    
    <div class="site-branding">
      {% if logo %}
        <a href="{{ front_page }}" class="site-logo">
          <img src="{{ logo }}" alt="{{ site_name }}" />
        </a>
      {% endif %}
      <div class="site-name">
        <a href="{{ front_page }}">{{ site_name }}</a>
      </div>
    </div>
  </header>

  {% if page.navigation %}
    <nav id="navigation" role="navigation">
      {{ page.navigation }}
    </nav>
  {% endif %}

  {% if page.breadcrumb %}
    <div class="breadcrumb-wrapper">
      {{ page.breadcrumb }}
    </div>
  {% endif %}

  <main role="main">
    <a id="main-content" tabindex="-1"></a>

    {% if page.highlighted %}
      <div class="highlighted">
        {{ page.highlighted }}
      </div>
    {% endif %}

    <div class="layout-content">
      {% if page.sidebar_first %}
        <aside class="layout-sidebar-first" role="complementary">
          {{ page.sidebar_first }}
        </aside>
      {% endif %}

      <div class="layout-main">
        {{ page.content }}
      </div>

      {% if page.sidebar_second %}
        <aside class="layout-sidebar-second" role="complementary">
          {{ page.sidebar_second }}
        </aside>
      {% endif %}
    </div>
  </main>

  {% if page.footer %}
    <footer role="contentinfo">
      {{ page.footer }}
    </footer>
  {% endif %}
</div>
```

### Entity Templates

#### Site Node Template

**File**: `templates/node--hosting-site.html.twig`

```twig
<article class="node node--hosting-site {{ attributes.class }}" role="article">
  <header class="node__header">
    <h1 class="node__title">
      <span class="hosting-icon hosting-icon--site"></span>
      {{ label }}
    </h1>
    
    <div class="hosting-status hosting-status--{{ content.field_hosting_status }}">
      {{ content.field_hosting_status }}
    </div>
  </header>

  <div class="node__content">
    <div class="hosting-info-grid">
      <div class="info-section">
        <h2>Site Information</h2>
        <dl class="info-list">
          <dt>Domain</dt>
          <dd>{{ content.field_hosting_domain }}</dd>
          
          <dt>Platform</dt>
          <dd>{{ content.field_hosting_platform }}</dd>
          
          <dt>Database Server</dt>
          <dd>{{ content.field_hosting_db_server }}</dd>
          
          <dt>Install Profile</dt>
          <dd>{{ content.field_hosting_install_profile }}</dd>
        </dl>
      </div>

      <div class="info-section">
        <h2>Recent Tasks</h2>
        {{ content.recent_tasks }}
      </div>
    </div>
    
    {% if content.task_log %}
      <div class="hosting-task-log">
        {{ content.task_log }}
      </div>
    {% endif %}
  </div>
</article>
```

#### Task Log Template

**File**: `templates/hosting-task-log.html.twig`

```twig
<div class="hosting-task-log {{ attributes.class }}">
  <div class="task-log-header">
    <h3>{{ task_type }} Task</h3>
    <span class="task-status task-status--{{ status }}">
      {{ status }}
    </span>
  </div>
  
  <div class="task-log-meta">
    <span class="task-time">{{ created|date('Y-m-d H:i:s') }}</span>
    <span class="task-duration">{{ duration }}</span>
  </div>
  
  <div class="task-log-content">
    <div class="log-controls">
      <button class="btn-filter" data-filter="error">Errors Only</button>
      <button class="btn-filter" data-filter="warning">Warnings</button>
      <button class="btn-filter active" data-filter="all">All</button>
    </div>
    
    <pre class="log-output">{{ log_output }}</pre>
  </div>
</div>
```

## CSS Architecture

### Base Styles

**File**: `css/base.css`

```css
/* Reset and Base Elements */
* {
  box-sizing: border-box;
}

body {
  font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, sans-serif;
  font-size: 16px;
  line-height: 1.6;
  color: #333;
  background: #f5f5f5;
  margin: 0;
  padding: 0;
}

a {
  color: #0073aa;
  text-decoration: none;
}

a:hover {
  color: #005177;
  text-decoration: underline;
}

h1, h2, h3, h4, h5, h6 {
  margin: 0 0 1rem;
  font-weight: 600;
  line-height: 1.2;
}

code, pre {
  font-family: "Monaco", "Menlo", "Courier New", monospace;
  font-size: 0.9em;
}
```

### Layout Styles

**File**: `css/layout.css`

```css
/* Page Layout */
.layout-container {
  min-height: 100vh;
  display: flex;
  flex-direction: column;
}

header[role="banner"] {
  background: #23282d;
  color: #fff;
  padding: 1rem 2rem;
  display: flex;
  justify-content: space-between;
  align-items: center;
}

.site-branding {
  display: flex;
  align-items: center;
  gap: 1rem;
}

.site-logo img {
  height: 40px;
  width: auto;
}

main[role="main"] {
  flex: 1;
  padding: 2rem;
  max-width: 1400px;
  width: 100%;
  margin: 0 auto;
}

.layout-content {
  display: grid;
  grid-template-columns: 250px 1fr 250px;
  gap: 2rem;
}

.layout-content.no-sidebars {
  grid-template-columns: 1fr;
}

footer[role="contentinfo"] {
  background: #23282d;
  color: #fff;
  padding: 1rem 2rem;
  text-align: center;
}
```

### Component Styles

**File**: `css/components.css`

```css
/* Navigation */
#navigation {
  background: #32373c;
  padding: 0;
}

#main-menu {
  list-style: none;
  margin: 0;
  padding: 0;
  display: flex;
}

#main-menu li {
  margin: 0;
}

#main-menu a {
  display: block;
  padding: 0.75rem 1.5rem;
  color: #fff;
  text-decoration: none;
}

#main-menu a:hover,
#main-menu a.is-active {
  background: #0073aa;
}

/* Buttons */
.button,
.btn,
input[type="submit"] {
  display: inline-block;
  padding: 0.5rem 1rem;
  background: #0073aa;
  color: #fff;
  border: none;
  border-radius: 4px;
  cursor: pointer;
  text-decoration: none;
  font-size: 0.9rem;
}

.button:hover,
.btn:hover {
  background: #005177;
}

.button--danger {
  background: #dc3232;
}

.button--danger:hover {
  background: #a00;
}

/* Tables */
table {
  width: 100%;
  border-collapse: collapse;
  background: #fff;
  box-shadow: 0 1px 3px rgba(0,0,0,0.1);
}

thead th {
  background: #f7f7f7;
  border-bottom: 2px solid #ddd;
  padding: 0.75rem;
  text-align: left;
  font-weight: 600;
}

tbody td {
  padding: 0.75rem;
  border-bottom: 1px solid #eee;
}

tbody tr:hover {
  background: #f9f9f9;
}

/* Messages */
.messages {
  padding: 1rem;
  margin: 1rem 0;
  border-left: 4px solid;
  border-radius: 4px;
}

.messages.error {
  background: #fef6f6;
  border-color: #dc3232;
  color: #a00;
}

.messages.warning {
  background: #fffbf0;
  border-color: #ffb900;
  color: #876100;
}

.messages.status {
  background: #f0f9f6;
  border-color: #46b450;
  color: #0a5f20;
}
```

### Aegir-Specific Styles

**File**: `css/aegir.css`

```css
/* Hosting Entity Styles */
.ntype-site,
.ntype-platform,
.ntype-server {
  background: #fff;
  padding: 2rem;
  border-radius: 8px;
  box-shadow: 0 2px 4px rgba(0,0,0,0.1);
}

.hosting-icon {
  display: inline-block;
  width: 24px;
  height: 24px;
  background-size: contain;
  vertical-align: middle;
  margin-right: 0.5rem;
}

.hosting-icon--site {
  background-image: url('../images/site-icon.svg');
}

.hosting-icon--platform {
  background-image: url('../images/platform-icon.svg');
}

.hosting-icon--server {
  background-image: url('../images/server-icon.svg');
}

/* Status Indicators */
.hosting-status {
  display: inline-block;
  padding: 0.25rem 0.75rem;
  border-radius: 12px;
  font-size: 0.85rem;
  font-weight: 600;
  text-transform: uppercase;
}

.hosting-status--enabled {
  background: #d4edda;
  color: #155724;
}

.hosting-status--disabled {
  background: #f8d7da;
  color: #721c24;
}

.hosting-status--deleted {
  background: #d1d1d1;
  color: #666;
}

/* Task Log Display */
.hosting-task-log {
  background: #1e1e1e;
  color: #d4d4d4;
  padding: 1rem;
  border-radius: 4px;
  margin: 1rem 0;
}

.log-output {
  font-family: "Monaco", "Menlo", monospace;
  font-size: 0.85rem;
  line-height: 1.4;
  white-space: pre-wrap;
  word-wrap: break-word;
  margin: 0;
}

.log-output .log-error {
  color: #f48771;
}

.log-output .log-warning {
  color: #dcdcaa;
}

.log-output .log-success {
  color: #4ec9b0;
}

/* Info Grid */
.hosting-info-grid {
  display: grid;
  grid-template-columns: repeat(auto-fit, minmax(300px, 1fr));
  gap: 2rem;
  margin: 2rem 0;
}

.info-section {
  background: #f9f9f9;
  padding: 1.5rem;
  border-radius: 4px;
}

.info-list {
  margin: 0;
}

.info-list dt {
  font-weight: 600;
  color: #666;
  margin-top: 0.75rem;
}

.info-list dd {
  margin: 0.25rem 0 0 0;
  padding-left: 1rem;
}
```

## JavaScript Integration

### Task Updates

**File**: `js/aegir-tasks.js`

```javascript
(function ($, Drupal, drupalSettings) {
  'use strict';

  /**
   * Live task log updates.
   */
  Drupal.behaviors.aegirTaskUpdates = {
    attach: function (context, settings) {
      $('.hosting-task-log', context).once('aegir-task-update').each(function () {
        var $log = $(this);
        var taskId = $log.data('task-id');
        
        // Poll for updates every 5 seconds
        var pollInterval = setInterval(function () {
          $.ajax({
            url: '/aegir/task/' + taskId + '/log',
            success: function (data) {
              if (data.status === 'completed' || data.status === 'error') {
                clearInterval(pollInterval);
              }
              
              // Update log output
              $log.find('.log-output').html(data.log);
              
              // Update status
              $log.find('.task-status')
                .removeClass()
                .addClass('task-status task-status--' + data.status)
                .text(data.status);
            }
          });
        }, 5000);
      });
    }
  };

  /**
   * Log filtering.
   */
  Drupal.behaviors.aegirLogFilters = {
    attach: function (context, settings) {
      $('.log-controls .btn-filter', context).once('log-filter').on('click', function (e) {
        e.preventDefault();
        
        var $btn = $(this);
        var filter = $btn.data('filter');
        var $output = $btn.closest('.task-log-content').find('.log-output');
        
        // Update active button
        $btn.siblings().removeClass('active');
        $btn.addClass('active');
        
        // Apply filter
        $output.removeClass('filter-error filter-warning').addClass('filter-' + filter);
      });
    }
  };

})(jQuery, Drupal, drupalSettings);
```

## Responsive Design

### Breakpoints

**File**: `eldir.breakpoints.yml`

```yaml
eldir.mobile:
  label: Mobile
  mediaQuery: '(max-width: 767px)'
  weight: 0
  multipliers:
    - 1x

eldir.tablet:
  label: Tablet
  mediaQuery: '(min-width: 768px) and (max-width: 1023px)'
  weight: 1
  multipliers:
    - 1x

eldir.desktop:
  label: Desktop
  mediaQuery: '(min-width: 1024px)'
  weight: 2
  multipliers:
    - 1x
```

### Responsive CSS

```css
/* Mobile First Approach */
@media (max-width: 767px) {
  .layout-content {
    grid-template-columns: 1fr;
  }
  
  .layout-sidebar-first,
  .layout-sidebar-second {
    display: none;
  }
  
  #main-menu {
    flex-direction: column;
  }
  
  .hosting-info-grid {
    grid-template-columns: 1fr;
  }
}

@media (min-width: 768px) and (max-width: 1023px) {
  .layout-content {
    grid-template-columns: 200px 1fr;
  }
  
  .layout-sidebar-second {
    display: none;
  }
}
```

## Single Directory Components

### Component Structure

**Directory**: `components/info-table/`

**Component Definition** (`info-table.component.yml`):
```yaml
'$schema': https://git.drupalcode.org/project/drupal/-/raw/11.x/core/modules/sdc/src/ComponentSchema.json
name: Info Table
description: 'Displays structured property listings for Aegir entities'
props:
  type: object
  properties:
    title:
      type: string
      title: Table Title
    items:
      type: array
      title: Table Items
      items:
        type: object
        properties:
          title:
            type: string
          value:
            type: string
    collapsible:
      type: boolean
      title: Is Collapsible
      default: false
```

**Template** (`info-table.twig`):
```twig
<div class="info-table {{ collapsible ? 'info-table--collapsible' : '' }}">
  {% if title %}
    <h3 class="info-table__title">{{ title }}</h3>
  {% endif %}
  
  <dl class="info-table__list">
    {% for item in items %}
      <div class="info-table__item">
        <dt class="info-table__label">{{ item.title }}</dt>
        <dd class="info-table__value">{{ item.value }}</dd>
      </div>
    {% endfor %}
  </dl>
</div>
```

**Usage in Module**:
```php
$build['info'] = [
  '#type' => 'component',
  '#component' => 'eldir:info-table',
  '#props' => [
    'title' => 'Site Information',
    'items' => [
      ['title' => 'Domain', 'value' => 'example.com'],
      ['title' => 'Platform', 'value' => 'Drupal 11'],
      ['title' => 'Status', 'value' => 'Enabled'],
    ],
    'collapsible' => TRUE,
  ],
];
```

## Development Guidelines

### Theme Development

**DO**:
- ✓ Use preprocess functions for data preparation
- ✓ Use render arrays from modules
- ✓ Follow Twig best practices
- ✓ Use CSS classes for module integration
- ✓ Support dark mode (future)

**DON'T**:
- ✗ Implement business logic in theme
- ✗ Query entities directly
- ✗ Modify entity data
- ✗ Use inline styles
- ✗ Hardcode URLs or paths

### Preprocess Functions

**File**: `eldir.theme`

```php
/**
 * Implements hook_preprocess_node().
 */
function eldir_preprocess_node(&$variables) {
  $node = $variables['node'];
  
  // Add entity type class
  $variables['attributes']['class'][] = 'ntype-' . $node->bundle();
  
  // Add status class for hosting entities
  if ($node->hasField('field_hosting_status')) {
    $status = $node->get('field_hosting_status')->value;
    $variables['attributes']['class'][] = 'hosting-status--' . $status;
  }
}

/**
 * Implements hook_preprocess_page().
 */
function eldir_preprocess_page(&$variables) {
  // Add current route to body class
  $route = \Drupal::routeMatch()->getRouteName();
  $variables['attributes']['class'][] = 'route-' . str_replace('.', '-', $route);
}
```

### CSS Organization

**Order of Specificity**:
1. Base (elements, reset)
2. Layout (grid, regions)
3. Components (buttons, forms, tables)
4. Theme-specific (Aegir entities)
5. Utilities (helpers, overrides)

### Accessibility

**WCAG 2.1 AA Compliance**:
- ✓ Color contrast ratio ≥ 4.5:1
- ✓ Keyboard navigation support
- ✓ ARIA labels on interactive elements
- ✓ Focus indicators
- ✓ Screen reader friendly markup

## Next Steps

- **[Frontend Documentation](Frontend.md)** - Learn about hosting modules
- **[Backend Documentation](Backend.md)** - Understand the provision system
- **[Architecture Overview](HOME.md)** - Return to main documentation

---

**Questions?** Check the [theme AI instructions](../web/themes/contrib/aegir-eldir/.github/AI-INSTRUCTIONS.md) for detailed technical guidance.
