# Create Aegir Hosting Entity

Create a new Drupal 11 content entity for aegir-hosting. This skill covers the full entity creation process following project patterns.

## User Input Needed

Ask the user for:
1. Entity name (e.g., `HostingDomain`)
2. Entity machine name (e.g., `hosting_domain` — always prefixed with `hosting_`)
3. Which sub-module should own it (or create a new one)
4. Required fields beyond `id`, `uuid`, `title`, `status`

## Steps

### 1. Create Entity Class

Path: `web/modules/contrib/aegir-hosting/{module}/src/Entity/{EntityName}.php`

```php
<?php

declare(strict_types=1);

namespace Drupal\{module}\Entity;

use Drupal\Core\Entity\Attribute\ContentEntityType;
use Drupal\Core\Entity\ContentEntityBase;
use Drupal\Core\Entity\EntityTypeInterface;
use Drupal\Core\Entity\Routing\AdminHtmlRouteProvider;
use Drupal\Core\Field\BaseFieldDefinition;
use Drupal\Core\StringTranslation\TranslatableMarkup;

#[ContentEntityType(
    id: '{entity_id}',
    label: new TranslatableMarkup('{Entity Label}'),
    label_collection: new TranslatableMarkup('{Entity Labels}'),
    label_singular: new TranslatableMarkup('{entity label}'),
    label_plural: new TranslatableMarkup('{entity labels}'),
    label_count: ['singular' => '@count {entity label}', 'plural' => '@count {entity labels}'],
    base_table: '{entity_id}',
    admin_permission: 'administer hosting',
    entity_keys: [
        'id' => 'id',
        'label' => 'title',
        'uuid' => 'uuid',
        'status' => 'status',
    ],
    handlers: [
        'form' => [
            'default' => \Drupal\{module}\Form\{EntityName}Form::class,
            'delete' => \Drupal\Core\Entity\ContentEntityDeleteForm::class,
        ],
        'list_builder' => \Drupal\{module}\Entity\{EntityName}ListBuilder::class,
        'view_builder' => \Drupal\{module}\Entity\{EntityName}ViewBuilder::class,
        'access' => \Drupal\Core\Entity\EntityAccessControlHandler::class,
        'route_provider' => [
            'html' => AdminHtmlRouteProvider::class,
        ],
    ],
    links: [
        'canonical' => '/hosting/{entity_type_plural}/{entity_id}',
        'add-form' => '/hosting/{entity_type_plural}/add',
        'edit-form' => '/hosting/{entity_type_plural}/{entity_id}/edit',
        'delete-form' => '/hosting/{entity_type_plural}/{entity_id}/delete',
        'collection' => '/admin/hosting/{entity_type_plural}',
    ],
)]
final class {EntityName} extends ContentEntityBase
{
    public static function baseFieldDefinitions(EntityTypeInterface $entity_type): array
    {
        $fields = parent::baseFieldDefinitions($entity_type);

        $fields['title'] = BaseFieldDefinition::create('string')
            ->setLabel(new TranslatableMarkup('Title'))
            ->setRequired(TRUE)
            ->setSetting('max_length', 255)
            ->setDisplayOptions('view', ['label' => 'hidden', 'type' => 'string'])
            ->setDisplayOptions('form', ['type' => 'string_textfield'])
            ->setDisplayConfigurable('form', TRUE)
            ->setDisplayConfigurable('view', TRUE);

        $fields['status'] = BaseFieldDefinition::create('boolean')
            ->setLabel(new TranslatableMarkup('Status'))
            ->setDefaultValue(TRUE)
            ->setDisplayOptions('form', ['type' => 'boolean_checkbox'])
            ->setDisplayConfigurable('form', TRUE);

        return $fields;
    }
}
```

> **Note**: `{entity_id}` = the full machine name, e.g. `hosting_domain`. The route link placeholder `{entity_id}` in `links` must also be the entity machine name so Drupal resolves it automatically via `AdminHtmlRouteProvider`.

### 2. Create ListBuilder

Path: `{module}/src/Entity/{EntityName}ListBuilder.php`

```php
<?php

declare(strict_types=1);

namespace Drupal\{module}\Entity;

use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Entity\EntityListBuilder;
use Drupal\Core\StringTranslation\TranslatableMarkup;

final class {EntityName}ListBuilder extends EntityListBuilder
{
    public function buildHeader(): array
    {
        $header['title'] = new TranslatableMarkup('Title');
        $header['status'] = new TranslatableMarkup('Status');
        return $header + parent::buildHeader();
    }

    public function buildRow(EntityInterface $entity): array
    {
        $row['title'] = $entity->label();
        $row['status'] = $entity->get('status')->value
            ? new TranslatableMarkup('Active')
            : new TranslatableMarkup('Inactive');
        return $row + parent::buildRow($entity);
    }
}
```

### 3. Create ViewBuilder

Path: `{module}/src/Entity/{EntityName}ViewBuilder.php`

```php
<?php

declare(strict_types=1);

namespace Drupal\{module}\Entity;

use Drupal\Core\Entity\EntityInterface;
use Drupal\Core\Entity\EntityViewBuilder;

final class {EntityName}ViewBuilder extends EntityViewBuilder
{
    public function view(EntityInterface $entity, string $view_mode = 'full', ?string $langcode = NULL): array
    {
        $build = parent::view($entity, $view_mode, $langcode);
        // Add custom render arrays here.
        return $build;
    }
}
```

### 4. Create Permissions File

Path: `{module}/{module}.permissions.yml`

```yaml
administer hosting {entity_type_plural}:
  title: 'Administer {Entity Labels}'
  description: 'Create, edit and delete {entity labels}.'
  restrict access: true

view hosting {entity_type_plural}:
  title: 'View {Entity Labels}'
```

### 5. Add Routing

With `AdminHtmlRouteProvider` in handlers, routes for `canonical`, `add-form`, `edit-form`, `delete-form`, and `collection` are **auto-generated** from the entity `links`. You only need to add custom routes (e.g., task operations):

In `{module}/{module}.routing.yml`:
```yaml
# Custom routes only — CRUD routes are auto-generated by AdminHtmlRouteProvider.
{module}.{entity_id}.{custom_operation}:
  path: '/hosting/{entity_type_plural}/{entity_id}/{custom_operation}'
  defaults:
    _form: '\Drupal\{module}\Form\{EntityName}{CustomOperation}Form'
    _title: '{Custom Operation}'
  requirements:
    _permission: 'administer hosting'
    {entity_id}: \d+
```

> **Important**: Always add `{entity_id}: \d+` to route requirements to validate the entity ID is numeric.

### 6. Add Entity Lifecycle Hooks

In `{module}/{module}.module` (using Drupal 11 `#[Hook]` attributes, NOT procedural hooks):

```php
<?php

declare(strict_types=1);

use Drupal\Core\Hook\Attribute\Hook;

/**
 * @file
 * Hosting {EntityName} module.
 */
```

In `{module}/src/Hook/{EntityName}Hooks.php`:

```php
<?php

declare(strict_types=1);

namespace Drupal\{module}\Hook;

use Drupal\Core\Hook\Attribute\Hook;
use Drupal\{module}\Entity\{EntityName};

final class {EntityName}Hooks
{
    #[Hook('entity_insert')]
    public function entityInsert({EntityName} $entity): void
    {
        // React to entity creation.
    }

    #[Hook('{entity_id}_update')]
    public function {entityId}Update({EntityName} $entity): void
    {
        // React to entity update.
    }
}
```

> **Drupal 11 rule**: Use `#[Hook]` attributes in dedicated Hook classes under `src/Hook/`, NOT procedural `hook_entity_insert()` functions.

### 7. Install

Since this project uses no update hooks, reinstall the module:

```bash
drush pm:uninstall {module} -y && drush en {module} -y
drush cr
```

## Anti-patterns to Avoid

- ❌ Do NOT use config entities for infrastructure data — always content entities
- ❌ Do NOT skip `admin_permission` on the entity type
- ❌ Do NOT omit the `route_provider` handler — without it, `links` in the attribute do nothing
- ❌ Do NOT use `_permission: 'access content'` for admin entities — use a specific permission
- ❌ Do NOT use annotation-style docblocks for entity type — use PHP 8 `#[ContentEntityType]`
- ❌ Do NOT use procedural `hook_*()` functions — use `#[Hook]` attributes in `src/Hook/` classes
- ❌ Do NOT call `drush entity:updates` — this command does not exist in Drush 13; reinstall the module instead
- ❌ Do NOT add `status` to `entity_keys` as a string — use `boolean` field type for enabled/disabled

Read existing entities (e.g., `hosting_site/src/Entity/HostingSite.php`) before implementing.
