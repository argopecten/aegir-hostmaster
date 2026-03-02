# Create Aegir Provision Drush Command

Create a new `provision:*` Drush command in aegir-provision.

## User Input Needed

Ask the user for:
1. Command name (e.g., `rename` for `provision:rename`)
2. What the command should do
3. What context type(s) it operates on (server/platform/site)
4. Whether it needs events (validate/before/after/rollback)

## Steps

### 1. Create Command Class

Path: `vendor/argopecten/aegir-provision/src/Drush/Commands/Provision{Name}Commands.php`

```php
<?php

declare(strict_types=1);

namespace Aegir\Provision\Drush\Commands;

use Drush\Attributes as CLI;
use Drush\Boot\DrupalBootLevels;
use Drush\Commands\DrushCommands;

final class Provision{Name}Commands extends DrushCommands
{
    use ProvisionAutowireTrait;

    #[CLI\Command(name: 'provision:{name}')]
    #[CLI\Argument(name: 'context', description: 'Context name (e.g. @site.example.com)')]
    #[CLI\Option(name: 'option-name', description: 'Description')]
    #[CLI\Usage(name: 'provision:{name} @site.example.com', description: 'Usage description')]
    #[CLI\Bootstrap(level: DrupalBootLevels::NONE)]
    public function {name}(string $context): void
    {
        $pm = $this->getProvisionManager();
        $ctx = $pm->contextRepository()->load($context);

        // Implementation — delegate to a Manager
        // $pm->{name}Manager()->{name}($ctx);
    }
}
```

### 2. Add Event Constants (if needed)

In `src/Event/ProvisionEvents.php`:
```php
public const {NAME}_VALIDATE = 'provision.{name}.validate';
public const {NAME}_BEFORE   = 'provision.{name}.before';
public const {NAME}_AFTER    = 'provision.{name}.after';
public const {NAME}_ROLLBACK = 'provision.{name}.rollback';
```

### 3. Create Event Class (if needed)

Path: `src/Event/{Name}Event.php`:
```php
<?php

declare(strict_types=1);

namespace Aegir\Provision\Event;

final class {Name}Event extends ProvisionEvent {}
```

### 4. Create Manager (if needed)

Path: `src/Manager/{Name}Manager.php`:
```php
<?php

declare(strict_types=1);

namespace Aegir\Provision\Manager;

use Aegir\Provision\Core\Context;
use Aegir\Provision\Core\ContextRepository;
use Aegir\Provision\Core\Filesystem;

final class {Name}Manager
{
    public function __construct(
        private readonly ContextRepository $contextRepository,
        private readonly Filesystem $filesystem,
    ) {}

    public function {name}(Context $context): void
    {
        // Implementation with event lifecycle:
        // try {
        //     dispatch VALIDATE, BEFORE
        //     execute
        //     dispatch AFTER
        // } catch { dispatch ROLLBACK; throw; }
    }
}
```

Add to `ProvisionManager.php`:
```php
public function {name}Manager(): {Name}Manager
{
    return $this->{name}Manager ??= new {Name}Manager(
        $this->contextRepository(),
        $this->filesystem(),
    );
}
```

### 5. No Registration Needed

Drush 13 auto-discovers command classes from `src/Drush/Commands/` via PSR-4. **No `drush.services.yml` needed** — that pattern is deprecated and removed.

### 6. Output in Drush 13 (inside command methods)

`$this->io()` was **removed in Drush 13**. Use:

```php
// Structured logging — respects --verbose / --debug flags
$this->logger()->success('Completed successfully.');
$this->logger()->info('Processing context: {ctx}', ['ctx' => $context]);
$this->logger()->warning('Falling back to defaults.');
$this->logger()->error('Fatal: could not connect.');

// Raw console output — always printed regardless of verbosity
$this->output()->writeln(sprintf('<info>Starting %s...</info>', $context));
```

### 7. Test

```bash
drush provision:{name} @context_name          # Normal run
drush provision:{name} @context_name -v       # Verbose (shows info messages)
drush provision:{name} @context_name --debug  # Debug (shows debug messages)

# List all available provision commands
drush list --filter=provision
```

## Rules

- Command name: `provision:{name}` with **colon** — never `provision-{name}`
- Class: `Provision{Name}Commands` extends `DrushCommands` + `ProvisionAutowireTrait`
- Always declare `#[CLI\Bootstrap(level: DrupalBootLevels::NONE)]` — no Drupal bootstrap
- Always import `use Drush\Boot\DrupalBootLevels;` — never use inline FQCN
- NEVER instantiate `ProvisionEvent` directly (abstract) — create a concrete subclass
- NEVER use `\Drupal::` — this package is standalone, no Drupal bootstrap
- NEVER use `$this->io()` — removed in Drush 13; use `$this->logger()` / `$this->output()`
- NEVER add `drush.services.yml` — use `ProvisionServiceRegistry::register()` instead
- All classes `final`

Read existing commands (e.g., `ProvisionVerifyCommands.php`) before implementing to ensure consistency.
