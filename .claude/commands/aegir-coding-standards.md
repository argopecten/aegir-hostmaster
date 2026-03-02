# Aegir Coding Standards

Reference for all coding standards in the Aegir Hostmaster project.

## PHP (All Components)

- `declare(strict_types=1);` on its own line immediately after `<?php` in every file
- Blank line between `<?php`, `declare()`, and `namespace` — follow PSR-12
- All new classes `final` unless they are base classes designed for extension
- Value objects: `final readonly class` with constructor promotion
- PHP 8.3+ features: typed properties, named arguments, enums, `match`, `readonly`
- All method parameters and return types must be explicitly typed (no `mixed` unless unavoidable)
- `#[Hook]` attributes over procedural `hook_*()` functions — Drupal 11 standard

### `#[Hook]` Attribute Pattern (Drupal 11)

```php
// ❌ Old procedural hook (Drupal 7/8/9 style) — do NOT use
function hosting_site_entity_insert(EntityInterface $entity): void { }

// ✅ Drupal 11 — Hook class in src/Hook/{Module}Hooks.php
namespace Drupal\hosting_site\Hook;

use Drupal\Core\Hook\Attribute\Hook;
use Drupal\Core\Entity\EntityInterface;

final class HostingSiteHooks
{
    #[Hook('entity_insert')]
    public function entityInsert(EntityInterface $entity): void { }

    #[Hook('hosting_site_presave')]
    public function hostingSitePresave(EntityInterface $entity): void { }
}
```

Hook classes are auto-discovered — no registration needed. The `.module` file can be empty.

## aegir-hosting (Frontend — Drupal Module)

- Drupal 11 APIs only — no deprecated D9/D10 APIs
- Entity PHP 8 attributes (`#[ContentEntityType(...)]`) — NOT docblock annotations
- All entities need `admin_permission` declared in the attribute
- All entities need `route_provider` handler (`AdminHtmlRouteProvider`) for auto-routing
- All entities need `{module}.permissions.yml` defining access permissions
- Entity route params must include `\d+` validation in routing requirements
- Task operation routes use `{module}.task.{operation}` naming and `/hosting/{type_plural}/{param}/{operation}` paths
- Services via DI — inject in constructors, declare in `*.services.yml`
- Services needing translation: use `StringTranslationTrait` or inject `TranslationInterface`
- Never `\Drupal::service()` inside service/entity classes — only in procedural `.module` code
- Manager services encapsulate business logic — forms only delegate
- Task forms extend `HostingTaskConfirmFormBase`
- Entity machine names: `hosting_{name}` prefix always
- Service IDs: `{module}.{snake_case}` format (e.g., `hosting_site.backup_manager`)
- Form IDs: `hosting_{module}_{operation}_form`
- No update hooks — reinstall the module for schema changes

### Service Definition (Drupal 11)

```yaml
# {module}/{module}.services.yml
services:
  hosting_site.site_manager:
    class: Drupal\hosting_site\Service\SiteManager
    arguments:
      - '@entity_type.manager'
      - '@string_translation'
    # autowire: true  # supported in Drupal 11 — can replace explicit arguments
```

### `use` Statement Ordering (PSR-12)

```php
use Drupal\Core\Entity\Attribute\ContentEntityType;   # Core first
use Drupal\Core\Entity\ContentEntityBase;
use Drupal\Core\Entity\EntityTypeInterface;
use Drupal\Core\Field\BaseFieldDefinition;
use Drupal\Core\StringTranslation\TranslatableMarkup;
use Drupal\hosting_site\Service\SiteManager;          # Then contrib/custom
```

## aegir-provision (Backend — Drush Package, Drush 13.7+)

- No Drupal APIs — standalone, no `\Drupal::` calls, no entity API
- PSR-4 namespace: `Aegir\Provision\`
- Command names: `provision:{name}` colon syntax (NOT `provision-{name}`)
- All command classes: extend `DrushCommands` + use `ProvisionAutowireTrait`
- Always declare `#[CLI\Bootstrap(level: DrupalBootLevels::NONE)]` on every command method
- Always `use Drush\Boot\DrupalBootLevels;` — never inline `\Drush\Boot\DrupalBootLevels::NONE`
- NEVER instantiate abstract `ProvisionEvent` — create concrete event subclasses
- NEVER add `drush.services.yml` — removed in Drush 13; use `ProvisionServiceRegistry::register()`
- NEVER use `$this->io()` — **removed in Drush 13**; use `$this->logger()` or `$this->output()`
- Throw typed exceptions — `drush_set_error()` removed in Drush 10
- Idempotent commands — safe to run repeatedly
- Every operation fires VALIDATE → BEFORE → execute → AFTER events (ROLLBACK on exception)

### Drush 13 Output API (inside command classes)

```php
$this->logger()->success('Completed.');      // always visible
$this->logger()->info('Processing...');      // visible with -v / --verbose
$this->logger()->debug('YAML: {data}');      // visible with --debug / -vvv
$this->output()->writeln('Raw output');      // raw, always printed

$this->io()->success('...');                 // ❌ REMOVED in Drush 13
```

### Drush 13 `use` Import Ordering (provision commands)

```php
use Drush\Attributes as CLI;
use Drush\Boot\DrupalBootLevels;   // always import — never use inline FQCN
use Drush\Commands\DrushCommands;
```

## aegir-eldir (Theme)

- No PHP classes — all PHP in `eldir.theme` only (themes don't have `src/`)
- No `declare(strict_types=1)` in `.theme` files (they are not standard PHP files)
- BEM methodology: `.block__element--modifier` for all new classes
- CSS custom properties for ALL design tokens — no hardcoded values
- Mobile-first responsive design (`min-width:` media queries only)
- `once()` in ALL JS behaviors — required for AJAX/BigPipe compatibility
- ES6+ JavaScript, `Drupal.behaviors.*` pattern, no jQuery dependency
- `data-*` attributes for JS hooks (not CSS classes)
- WCAG AA compliance — semantic HTML, ARIA labels, keyboard nav, color contrast ≥ 4.5:1
- Twig: use `{{ attributes }}` object, document available variables at file top with `@file`
- Render theme hooks as render arrays from PHP preprocess — Drupal has no `theme()` Twig function

## CSS File Placement

| Content | File |
|---------|------|
| New CSS custom properties | `variables.css` |
| HTML element resets | `base.css` |
| Page/grid layout | `layout.css` |
| Reusable component styles | `components.css` |
| Hosting entity/page styles | `aegir.css` |
| Media query overrides | `responsive.css` |

## Naming Summary

| What | Convention | Example |
|------|-----------|---------|
| Drupal entities | `hosting_{name}` | `hosting_site` |
| Services | `{module}.{snake_case}` | `hosting.context_registry` |
| Drush commands | `provision:{operation}` | `provision:verify` |
| Task routes | `{module}.task.{operation}` | `hosting_site.task.verify` |
| Route paths | `/hosting/{type_plural}/{param}/{operation}` | `/hosting/sites/{hosting_site}/verify` |
| CSS classes | `.hosting-{block}__element--modifier` | `.hosting-server__header--active` |
| Templates | `hosting-{type}.html.twig` | `hosting-site.html.twig` |
| Hook classes | `src/Hook/{Module}Hooks.php` | `src/Hook/HostingSiteHooks.php` |

## What to Check Before Every Commit

1. `declare(strict_types=1);` present in every new PHP file
2. All new classes are `final`
3. All type hints present on parameters and return types
4. No procedural `hook_*()` functions — use `#[Hook]` classes
5. No `\Drupal::service()` inside classes — use constructor DI
6. No hardcoded colors/spacing in CSS — use `var(--aegir-*)`
7. Entity param `\d+` in routing requirements
8. Permissions defined in `{module}.permissions.yml`

Display the relevant coding standards for the component the user is working on.
