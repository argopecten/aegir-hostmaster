# Create Aegir Theme Template or Component

Create a new Twig template or reusable component in aegir-eldir.

## User Input Needed

Ask the user whether they need:
1. An entity display template (for a hosting entity type)
2. A reusable component (badge, card, chip, panel)
3. A page template suggestion (for specific routes)

---

## Option A: Entity Display Template

### 1. Create Template

Path: `web/themes/contrib/aegir-eldir/templates/hosting-{entity_type}.html.twig`

```twig
{#
/**
 * @file
 * Template for hosting {entity_type} entities.
 *
 * Available variables:
 * - content: Entity render array.
 * - attributes: HTML attributes for the wrapper.
 * - label: Entity label.
 * - status_badge: Status badge render array.
 */
#}
<article{{ attributes.addClass('hosting-{entity_type}') }}>

  <header class="hosting-{entity_type}__header">
    <h2 class="hosting-{entity_type}__title">{{ label }}</h2>
    {% if status_badge %}
      {{ status_badge }}
    {% endif %}
  </header>

  <div class="hosting-{entity_type}__content">
    {{ content }}
  </div>

</article>
```

### 2. Add Preprocess Function

In `web/themes/contrib/aegir-eldir/eldir.theme`:
```php
function eldir_preprocess_hosting_{entity_type}(array &$variables): void {
    $entity = $variables['elements']['#hosting_{entity_type}'];

    $variables['label'] = $entity->label();
    $variables['status'] = $entity->get('status')->value ?? 'unknown';

    $variables['status_badge'] = [
        '#theme' => 'hosting_status_badge',
        '#status' => $variables['status'],
        '#label' => ucfirst($variables['status']),
    ];

    eldir_add_entity_metadata_attributes($variables);
}
```

### 3. Add CSS in `css/aegir.css`

```css
.hosting-{entity_type} {
    display: grid;
    gap: var(--aegir-spacing-md);
}

.hosting-{entity_type}__header {
    display: flex;
    align-items: center;
    gap: var(--aegir-spacing-sm);
}

.hosting-{entity_type}__title {
    font-size: var(--aegir-font-size-lg);
    font-weight: var(--aegir-font-weight-bold);
}
```

---

## Option B: Reusable Component Theme Hook

### 1. Register hook in `eldir_theme()` in `eldir.theme`

```php
'{component_name}' => [
    'variables' => [
        'var1' => NULL,
        'var2' => NULL,
        'attributes' => [],
    ],
    'template' => 'components/{component-name}',
],
```

### 2. Create Template

Path: `templates/components/{component-name}.html.twig`

```twig
<div{{ attributes.addClass('{component-name}') }}>
  <span class="{component-name}__label">{{ var1 }}</span>
  {% if var2 %}
    <span class="{component-name}__secondary">{{ var2 }}</span>
  {% endif %}
</div>
```

### 3. Add CSS in `css/components.css`

```css
.{component-name} {
    display: inline-flex;
    align-items: center;
    gap: var(--aegir-spacing-xs);
}
```

---

## After Changes

```bash
drush cr
```

## Rules

- Template filenames: underscores → hyphens (`hosting_server` → `hosting-server.html.twig`)
- CSS: BEM naming, CSS custom properties only — no hardcoded values
- Preprocess: formatting only — no business logic, no entity saves, no DB queries
- Base theme is `false` — Eldir is standalone

Read existing templates (e.g., `hosting-server.html.twig`) before implementing to match style.
