---
name: wordpress-php-dev
description: WordPress PHP plugin development using Test-Driven Development (TDD) and functional programming principles. Use this skill when developing, testing, or maintaining WordPress plugins with focus on PSR-12 compliance, Composer integration, automated testing with PHPUnit, coding standards enforcement with phpcs/phpcbf, and git version control. Triggers include requests to create WordPress plugins, write WordPress PHP code, set up testing infrastructure, implement TDD workflows, or apply functional programming patterns in WordPress.
---

# WordPress PHP Development with TDD and Functional Programming

## Overview

This skill provides comprehensive guidance for developing WordPress plugins following professional development practices:

1. **Test-Driven Development (TDD)** - Write failing tests first, then implement code
2. **Functional Programming** - Pure functions, immutability, function composition
3. **PSR-12 Compliance** - Modern PHP coding standards
4. **Composer Integration** - Dependency management and autoloading
5. **Automated Testing** - PHPUnit with Brain Monkey for WordPress mocking
6. **Coding Standards** - WordPress Coding Standards with phpcs/phpcbf
7. **Git Workflow** - Regular commits following TDD cycle

## When to Use This Skill

- Creating new WordPress plugins
- Writing WordPress PHP code
- Setting up plugin testing infrastructure
- Implementing TDD workflows
- Applying functional programming patterns
- Enforcing coding standards
- Managing plugin development with Git

## Quick Start

### Initialize New Plugin

Use the initialization script to create a complete plugin structure:

```bash
python3 scripts/init_plugin.py my-plugin-name --path ~/projects
cd ~/projects/my-plugin-name
composer install
```

This creates a plugin with:
- Complete directory structure
- Configured testing (PHPUnit + Brain Monkey)
- Coding standards (phpcs/phpcbf)
- Composer autoloading
- Git-ready setup
- Example tests

### Initial Development Workflow

1. **Write a failing test** (Red phase)
2. **Write minimal code to pass** (Green phase)
3. **Refactor while keeping tests green** (Refactor phase)
4. **Run coding standards auto-fix**: `composer lint:fix`
5. **Commit changes**: `git commit -m "feat(module): add functionality"`

## Core Development Workflow

### TDD Cycle

```bash
# 1. Write failing test
# Edit tests/Unit/FeatureTest.php
composer test  # Should fail (RED)

# 2. Commit failing test
git add tests/Unit/FeatureTest.php
git commit -m "test(feature): add test for new behavior"

# 3. Write minimal code to pass
# Edit src/Module.php
composer test  # Should pass (GREEN)

# 4. Auto-fix coding standards
composer lint:fix

# 5. Commit working code
git add src/Module.php
git commit -m "feat(feature): implement new behavior"

# 6. Refactor if needed
# Edit src/Module.php
composer test  # Should still pass
composer lint:fix

# 7. Commit refactoring
git add src/Module.php
git commit -m "refactor(feature): improve implementation"
```

### Available Composer Commands

```bash
composer test              # Run all tests
composer test:coverage     # Generate coverage report
composer lint              # Check coding standards
composer lint:fix          # Auto-fix coding standards
composer lint:errors       # Show only errors, skip warnings
```

## Plugin Structure

```
plugin-name/
├── plugin-name.php          # Main plugin file
├── composer.json            # Dependencies and scripts
├── phpcs.xml.dist           # Coding standards config
├── phpunit.xml.dist         # Testing configuration
├── .gitignore               # Git ignore rules
├── README.md                # Documentation
├── src/                     # Source code (PSR-4 autoloaded)
│   ├── Plugin.php           # Main plugin class
│   └── functions.php        # Pure helper functions
├── tests/                   # PHPUnit tests
│   ├── bootstrap.php        # Test setup
│   ├── Unit/                # Unit tests (pure functions)
│   └── Integration/         # Integration tests (WordPress hooks)
└── assets/                  # Frontend assets
    ├── css/
    ├── js/
    └── images/
```

## Detailed Guidance

### TDD Patterns

**Read the TDD patterns reference for comprehensive examples:**

```bash
view references/tdd_patterns.md
```

Key patterns covered:
- AAA pattern (Arrange-Act-Assert)
- Testing pure functions
- Mocking WordPress functions with Brain Monkey
- Testing hooks and filters
- Data providers
- Red-Green-Refactor cycle

### Functional Programming Patterns

**Read the functional programming reference for detailed patterns:**

```bash
view references/functional_patterns.md
```

Key concepts covered:
- Pure vs impure functions
- Immutability patterns
- Function composition
- Higher-order functions
- WordPress-specific functional patterns
- Error handling with Option types

### Git Workflow

**Read the git workflow reference for complete workflow:**

```bash
view references/git_workflow.md
```

Key practices:
- Commit after each phase of TDD cycle
- Conventional commit messages
- Branch strategy (feature/bugfix/hotfix)
- Pre-commit hooks for testing and linting

## Code Organization Principles

### Separate Pure from Impure Code

**Pure Functions** (Easy to test, in `src/functions.php`):

```php
// Pure - deterministic transformation
function sanitize_username( string $username ): string {
    return strtolower( trim( $username ) );
}

// Pure - data validation
function is_valid_email( string $email ): bool {
    return (bool) filter_var( $email, FILTER_VALIDATE_EMAIL );
}
```

**Impure Functions** (Isolate in classes/hooks):

```php
// Impure - database access
function get_user_preferences( int $user_id ): array {
    return get_user_meta( $user_id, 'preferences', true );
}

// Impure - output
function render_template( string $template, array $data ): void {
    extract( $data );
    include $template;
}
```

### Testing Strategy

1. **Unit Tests** - Test pure functions (no WordPress mocking needed)
2. **Integration Tests** - Test WordPress integration (use Brain Monkey)
3. **Functional Tests** - Test complete workflows

Example unit test for pure function:

```php
public function test_sanitize_username_lowercase(): void {
    $result = sanitize_username( 'JohnDoe' );
    $this->assertEquals( 'johndoe', $result );
}
```

Example integration test with Brain Monkey:

```php
use Brain\Monkey\Functions;

public function test_saves_user_preference(): void {
    Functions\expect( 'update_user_meta' )
        ->once()
        ->with( 123, 'theme', 'dark' )
        ->andReturn( true );
    
    $result = save_user_preference( 123, 'theme', 'dark' );
    
    $this->assertTrue( $result );
}
```

## Coding Standards

### PSR-12 with WordPress Standards

The plugin enforces:

- WordPress Security rules
- WordPress Internationalization
- WordPress Core/Extra/Docs standards
- PSR-12 (where not conflicting with WordPress)

### Text Domain and Prefix

Update in `phpcs.xml.dist`:

```xml
<rule ref="WordPress.WP.I18n">
    <properties>
        <property name="text_domain" type="array">
            <element value="your-plugin-slug"/>
        </property>
    </properties>
</rule>

<rule ref="WordPress.NamingConventions.PrefixAllGlobals">
    <properties>
        <property name="prefixes" type="array">
            <element value="your_plugin_prefix"/>
        </property>
    </properties>
</rule>
```

### Auto-Fix Standards

Always run before committing:

```bash
composer lint:fix
```

This automatically fixes:
- Indentation
- Spacing
- Line endings
- Import order
- Many other formatting issues

## Asset Templates

### Starting a New Plugin

Copy and customize these templates:

- **composer.json**: `assets/composer.json.dist`
- **phpcs.xml**: `assets/phpcs.xml.dist`
- **phpunit.xml**: `assets/phpunit.xml.dist`
- **bootstrap.php**: `assets/bootstrap.php.dist`

Or use the initialization script:

```bash
python3 scripts/init_plugin.py my-plugin --path /path/to/directory
```

## Best Practices Summary

### Development

1. ✅ **Always start with a test** - Red → Green → Refactor
2. ✅ **Write pure functions** - Easier to test and reason about
3. ✅ **Separate concerns** - Pure logic separate from WordPress integration
4. ✅ **Use type hints** - Leverage PHP 8.1+ strict types
5. ✅ **Document code** - PHPDoc for all public functions/methods

### Testing

1. ✅ **Test one thing** - Each test verifies one specific behavior
2. ✅ **Descriptive names** - `test_returns_error_when_email_invalid()`
3. ✅ **Independent tests** - No shared state between tests
4. ✅ **Fast tests** - Unit tests should run in milliseconds
5. ✅ **Mock WordPress** - Use Brain Monkey for WordPress functions

### Git

1. ✅ **Commit frequently** - After each TDD phase
2. ✅ **Meaningful messages** - Follow conventional commits format
3. ✅ **Feature branches** - Never commit directly to main
4. ✅ **Test before push** - Ensure all tests pass
5. ✅ **Fix standards** - Run `composer lint:fix` before committing

### Code Quality

1. ✅ **Run tests**: `composer test`
2. ✅ **Fix standards**: `composer lint:fix`
3. ✅ **Check coverage**: `composer test:coverage`
4. ✅ **Review diff**: `git diff --staged`
5. ✅ **Commit clean code**: No debug statements

## Common Patterns

### Plugin Initialization

```php
// Main plugin file
add_action( 'plugins_loaded', function() {
    Plugin::get_instance()->init();
} );

// Plugin class
class Plugin {
    private static ?Plugin $instance = null;
    
    public static function get_instance(): Plugin {
        if ( null === self::$instance ) {
            self::$instance = new self();
        }
        return self::$instance;
    }
    
    public function init(): void {
        $this->register_hooks();
    }
    
    private function register_hooks(): void {
        add_action( 'init', [ $this, 'on_init' ] );
        add_filter( 'the_content', [ $this, 'filter_content' ] );
    }
}
```

### Pure Function for Filters

```php
// Pure function - easy to test
function apply_custom_discount( float $price, float $rate ): float {
    return $price * ( 1 - $rate );
}

// WordPress filter using pure function
add_filter( 'product_price', function( $price ) {
    return apply_custom_discount( $price, 0.1 );
} );

// Test is simple
public function test_applies_discount(): void {
    $result = apply_custom_discount( 100.0, 0.1 );
    $this->assertEquals( 90.0, $result );
}
```

### Data Transformation Pipeline

```php
// Compose transformations
function process_user_input( string $input ): string {
    return pipe(
        fn( $s ) => trim( $s ),
        fn( $s ) => strtolower( $s ),
        fn( $s ) => sanitize_text_field( $s )
    )( $input );
}

// Helper for function composition
function pipe( ...$functions ) {
    return fn( $value ) => array_reduce(
        $functions,
        fn( $carry, $fn ) => $fn( $carry ),
        $value
    );
}
```

## Troubleshooting

### Tests Not Running

```bash
# Ensure dependencies installed
composer install

# Clear cache
rm -rf .phpunit.cache

# Run with verbose output
vendor/bin/phpunit --verbose
```

### Coding Standards Failures

```bash
# Auto-fix most issues
composer lint:fix

# Check what can't be auto-fixed
composer lint:errors

# View detailed error
composer lint
```

### Brain Monkey Errors

Ensure proper setup/teardown in tests:

```php
protected function setUp(): void {
    parent::setUp();
    \Brain\Monkey\setUp();
}

protected function tearDown(): void {
    \Brain\Monkey\tearDown();
    parent::tearDown();
}
```

## Additional Resources

- **TDD Patterns**: `references/tdd_patterns.md` - Comprehensive testing patterns
- **Functional Programming**: `references/functional_patterns.md` - FP in WordPress context
- **Git Workflow**: `references/git_workflow.md` - Complete version control workflow
- **WordPress Coding Standards**: https://developer.wordpress.org/coding-standards/
- **PHPUnit Documentation**: https://phpunit.de/documentation.html
- **Brain Monkey**: https://brain-wp.github.io/BrainMonkey/
