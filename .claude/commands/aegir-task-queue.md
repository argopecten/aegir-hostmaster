# Aegir Task Queue Integration

Add a new background operation to the Aegir task queue system. This covers both the frontend (aegir-hosting) form and the backend (aegir-provision) Drush command.

## Architecture Reminder

ALL operations must flow: **Form → Entity → TaskManager → Queue → BackendInvoker → provision:command**

NEVER call provision commands directly from forms or services.

## Steps

### 1. Define the Task Type

The task type string must match the `provision:*` command name (e.g., `verify`, `backup`, `rename`).

### 2. Create the Frontend Form (aegir-hosting)

Path: `web/modules/contrib/aegir-hosting/{module}/src/Form/Site{Operation}Form.php`

```php
<?php

declare(strict_types=1);

namespace Drupal\hosting_site\Form;

use Drupal\Core\StringTranslation\TranslatableMarkup;
use Drupal\hosting_task\Form\HostingTaskConfirmFormBase;

final class Site{Operation}Form extends HostingTaskConfirmFormBase
{
    public function getFormId(): string
    {
        return 'hosting_site_{operation}_form';
    }

    public function getQuestion(): TranslatableMarkup
    {
        return new TranslatableMarkup('Are you sure you want to {operation} %site?', [
            '%site' => $this->getEntity()->label(),
        ]);
    }

    public function getDescription(): TranslatableMarkup
    {
        return new TranslatableMarkup('This will {operation description}.');
    }

    protected function getTaskType(): string
    {
        return '{operation}';
    }
}
```

The base form handles: task creation, queue dispatch, success message, redirect.

### 3. Add Route

In `hosting_site/hosting_site.routing.yml`:
```yaml
hosting_site.task.{operation}:
  path: '/hosting/sites/{hosting_site}/{operation}'
  defaults:
    _form: '\Drupal\hosting_site\Form\Site{Operation}Form'
    _title: '{Operation} Site'
  requirements:
    _permission: 'administer sites'
    hosting_site: \d+
```

> **Conventions**: Route name uses `{module}.task.{operation}` pattern. Path uses `/hosting/sites/` prefix. Entity param requires `\d+` validation.

### 4. Add Task Availability (if conditional)

In `TaskAvailabilityResolver`:
```php
// Example: operation only available for enabled sites
if ($taskType === '{operation}' && $entity->get('status')->value !== 'enabled') {
    return FALSE;
}
```

### 5. Create the Backend Command (aegir-provision)

If no matching `provision:{operation}` command exists, create it:
Path: `vendor/argopecten/aegir-provision/src/Drush/Commands/Provision{Operation}Commands.php`

(See `/aegir-create-drush-command` skill for the full template.)

### 6. Verify the Flow

```bash
# 1. Clear cache
drush cr

# 2. Trigger operation via UI or directly:
drush php:eval "\Drupal::service('hosting.task_manager')->createTask(\Drupal::entityTypeManager()->getStorage('hosting_site')->load(1), '{operation}');"

# 3. Run queue
drush queue:run hosting_task_queue

# 4. Check task logs
drush sql:query "SELECT * FROM hosting_task_log ORDER BY id DESC LIMIT 20"
```

## Task States

| State | Meaning |
|-------|---------|
| `queued` | Created, waiting for cron |
| `processing` | Currently executing |
| `success` | Completed successfully |
| `error` | Failed |
| `warning` | Completed with warnings |

Implement the task queue integration described by the user. Read existing task forms (e.g., `SiteVerifyForm.php`) for reference.
