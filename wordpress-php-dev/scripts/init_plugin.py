#!/usr/bin/env python3
"""
Initialize a new WordPress plugin with TDD and functional programming setup.

Usage:
    python3 init_plugin.py <plugin-name> [--path <directory>]

Example:
    python3 init_plugin.py my-awesome-plugin --path ~/projects
"""

import argparse
import os
import sys
from pathlib import Path
from datetime import datetime


def create_directory(path: Path) -> None:
    """Create directory if it doesn't exist."""
    path.mkdir(parents=True, exist_ok=True)
    print(f"✅ Created: {path}")


def write_file(path: Path, content: str) -> None:
    """Write content to file."""
    path.write_text(content)
    print(f"✅ Created: {path}")


def to_pascal_case(name: str) -> str:
    """Convert slug-name to PascalCase."""
    return ''.join(word.capitalize() for word in name.split('-'))


def to_snake_case(name: str) -> str:
    """Convert slug-name to snake_case."""
    return name.replace('-', '_')


def init_plugin(plugin_name: str, base_path: Path) -> None:
    """Initialize WordPress plugin structure."""
    
    plugin_path = base_path / plugin_name
    
    if plugin_path.exists():
        print(f"❌ Error: Directory {plugin_path} already exists")
        sys.exit(1)
    
    print(f"\n🚀 Initializing WordPress plugin: {plugin_name}")
    print(f"   Location: {plugin_path}\n")
    
    # Convert names
    class_name = to_pascal_case(plugin_name)
    function_prefix = to_snake_case(plugin_name)
    text_domain = plugin_name
    
    # Create directory structure
    create_directory(plugin_path)
    create_directory(plugin_path / "src")
    create_directory(plugin_path / "tests" / "Unit")
    create_directory(plugin_path / "tests" / "Integration")
    create_directory(plugin_path / "assets" / "css")
    create_directory(plugin_path / "assets" / "js")
    
    # Main plugin file
    main_plugin_content = f'''<?php
/**
 * Plugin Name: {plugin_name.replace('-', ' ').title()}
 * Plugin URI: https://example.com/{plugin_name}
 * Description: Plugin description
 * Version: 1.0.0
 * Requires at least: 6.0
 * Requires PHP: 8.1
 * Author: Your Name
 * Author URI: https://example.com
 * License: GPL v2 or later
 * License URI: https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain: {text_domain}
 * Domain Path: /languages
 *
 * @package {class_name}
 */

declare(strict_types=1);

namespace {class_name};

// Exit if accessed directly.
if ( ! defined( 'ABSPATH' ) ) {{
    exit;
}}

// Plugin version
define( '{function_prefix.upper()}_VERSION', '1.0.0' );
define( '{function_prefix.upper()}_FILE', __FILE__ );
define( '{function_prefix.upper()}_PATH', plugin_dir_path( __FILE__ ) );
define( '{function_prefix.upper()}_URL', plugin_dir_url( __FILE__ ) );

// Load Composer autoloader
if ( file_exists( __DIR__ . '/vendor/autoload.php' ) ) {{
    require_once __DIR__ . '/vendor/autoload.php';
}}

// Bootstrap plugin
add_action( 'plugins_loaded', function() {{
    Plugin::get_instance()->init();
}} );

// Activation hook
register_activation_hook( __FILE__, [ Plugin::class, 'activate' ] );

// Deactivation hook
register_deactivation_hook( __FILE__, [ Plugin::class, 'deactivate' ] );
'''
    write_file(plugin_path / f"{plugin_name}.php", main_plugin_content)
    
    # Plugin class
    plugin_class_content = f'''<?php
/**
 * Main Plugin Class
 *
 * @package {class_name}
 */

declare(strict_types=1);

namespace {class_name};

/**
 * Class Plugin
 */
class Plugin {{
    /**
     * Single instance of the class
     *
     * @var Plugin|null
     */
    private static ?Plugin $instance = null;

    /**
     * Private constructor to prevent direct instantiation
     */
    private function __construct() {{
        // Use get_instance() instead
    }}

    /**
     * Get single instance
     *
     * @return Plugin
     */
    public static function get_instance(): Plugin {{
        if ( null === self::$instance ) {{
            self::$instance = new self();
        }}
        return self::$instance;
    }}

    /**
     * Initialize plugin
     *
     * @return void
     */
    public function init(): void {{
        // Load textdomain
        load_plugin_textdomain(
            '{text_domain}',
            false,
            dirname( plugin_basename( {function_prefix.upper()}_FILE ) ) . '/languages'
        );

        // Register hooks
        $this->register_hooks();
    }}

    /**
     * Register WordPress hooks
     *
     * @return void
     */
    private function register_hooks(): void {{
        add_action( 'init', [ $this, 'on_init' ] );
    }}

    /**
     * Runs on WordPress init
     *
     * @return void
     */
    public function on_init(): void {{
        // Plugin initialization code
    }}

    /**
     * Activation hook callback
     *
     * @return void
     */
    public static function activate(): void {{
        // Activation code
        flush_rewrite_rules();
    }}

    /**
     * Deactivation hook callback
     *
     * @return void
     */
    public static function deactivate(): void {{
        // Deactivation code
        flush_rewrite_rules();
    }}
}}
'''
    write_file(plugin_path / "src" / "Plugin.php", plugin_class_content)
    
    # Functions file
    functions_content = f'''<?php
/**
 * Helper Functions
 *
 * Pure functions that can be easily tested.
 *
 * @package {class_name}
 */

declare(strict_types=1);

namespace {class_name};

/**
 * Example pure function
 *
 * @param string $text Text to sanitize.
 * @return string Sanitized text.
 */
function sanitize_custom_field( string $text ): string {{
    return sanitize_text_field( trim( $text ) );
}}
'''
    write_file(plugin_path / "src" / "functions.php", functions_content)
    
    # Test bootstrap
    bootstrap_content = '''<?php
/**
 * PHPUnit Bootstrap File
 */

// Load Composer autoloader
require_once dirname( __DIR__ ) . '/vendor/autoload.php';

// Set up Brain Monkey
\\Brain\\Monkey\\setUp();

// Register shutdown function
register_shutdown_function( function() {
    \\Brain\\Monkey\\tearDown();
} );

// Define WordPress constants
if ( ! defined( 'ABSPATH' ) ) {
    define( 'ABSPATH', '/tmp/wordpress/' );
}
'''
    write_file(plugin_path / "tests" / "bootstrap.php", bootstrap_content)
    
    # Example test
    test_content = f'''<?php
/**
 * Tests for helper functions
 *
 * @package {class_name}
 */

declare(strict_types=1);

namespace {class_name}\\Tests\\Unit;

use PHPUnit\\Framework\\TestCase;
use Brain\\Monkey\\Functions;

use function {class_name}\\sanitize_custom_field;

/**
 * Class FunctionsTest
 */
class FunctionsTest extends TestCase {{
    /**
     * Set up test environment
     */
    protected function setUp(): void {{
        parent::setUp();
        \\Brain\\Monkey\\setUp();
    }}

    /**
     * Tear down test environment
     */
    protected function tearDown(): void {{
        \\Brain\\Monkey\\tearDown();
        parent::tearDown();
    }}

    /**
     * Test sanitize_custom_field function
     *
     * @return void
     */
    public function test_sanitize_custom_field_trims_whitespace(): void {{
        // Mock WordPress sanitize_text_field function
        Functions\\expect( 'sanitize_text_field' )
            ->once()
            ->andReturnUsing( fn( $s ) => $s );

        $result = sanitize_custom_field( '  test  ' );

        $this->assertEquals( 'test', $result );
    }}
}}
'''
    write_file(plugin_path / "tests" / "Unit" / "FunctionsTest.php", test_content)
    
    # Composer.json
    composer_content = f'''{{
    "name": "vendor/{plugin_name}",
    "description": "WordPress plugin following TDD and functional programming",
    "type": "wordpress-plugin",
    "license": "GPL-2.0-or-later",
    "require": {{
        "php": ">=8.1",
        "composer/installers": "^2.0"
    }},
    "require-dev": {{
        "phpunit/phpunit": "^10.0",
        "squizlabs/php_codesniffer": "^3.7",
        "wp-coding-standards/wpcs": "^3.0",
        "phpcompatibility/phpcompatibility-wp": "*",
        "dealerdirect/phpcodesniffer-composer-installer": "^1.0",
        "brain/monkey": "^2.6",
        "mockery/mockery": "^1.5"
    }},
    "autoload": {{
        "psr-4": {{
            "{class_name}\\\\": "src/"
        }},
        "files": [
            "src/functions.php"
        ]
    }},
    "autoload-dev": {{
        "psr-4": {{
            "{class_name}\\\\Tests\\\\": "tests/"
        }}
    }},
    "scripts": {{
        "test": "phpunit",
        "test:coverage": "phpunit --coverage-html coverage",
        "lint": "phpcs",
        "lint:fix": "phpcbf",
        "lint:errors": "phpcs -n"
    }},
    "config": {{
        "allow-plugins": {{
            "dealerdirect/phpcodesniffer-composer-installer": true,
            "composer/installers": true
        }},
        "sort-packages": true,
        "optimize-autoloader": true
    }}
}}
'''
    write_file(plugin_path / "composer.json", composer_content)
    
    # phpcs.xml
    phpcs_content = f'''<?xml version="1.0"?>
<ruleset name="WordPress Plugin Standards">
    <description>WordPress coding standards for {plugin_name}</description>

    <file>.</file>

    <exclude-pattern>/vendor/*</exclude-pattern>
    <exclude-pattern>/node_modules/*</exclude-pattern>
    <exclude-pattern>/tests/bootstrap.php</exclude-pattern>

    <arg value="ps"/>
    <arg value="ns"/>
    <arg name="colors"/>
    <arg name="parallel" value="20"/>
    <arg name="extensions" value="php"/>

    <rule ref="WordPress.Security.EscapeOutput"/>
    <rule ref="WordPress.Security.ValidatedSanitizedInput"/>
    <rule ref="WordPress.Security.NonceVerification"/>
    <rule ref="WordPress.WP.I18n"/>
    <rule ref="WordPress.WP.DeprecatedFunctions"/>
    <rule ref="WordPress-Core"/>
    <rule ref="WordPress-Extra"/>
    <rule ref="WordPress-Docs"/>

    <rule ref="PSR12">
        <exclude name="PSR1.Methods.CamelCapsMethodName.NotCamelCaps"/>
        <exclude name="Squiz.Classes.ValidClassName.NotCamelCaps"/>
    </rule>

    <config name="minimum_supported_wp_version" value="6.0"/>
    <config name="testVersion" value="8.1-"/>

    <rule ref="WordPress.WP.I18n">
        <properties>
            <property name="text_domain" type="array">
                <element value="{text_domain}"/>
            </property>
        </properties>
    </rule>

    <rule ref="WordPress.NamingConventions.PrefixAllGlobals">
        <properties>
            <property name="prefixes" type="array">
                <element value="{function_prefix}"/>
            </property>
        </properties>
    </rule>
</ruleset>
'''
    write_file(plugin_path / "phpcs.xml.dist", phpcs_content)
    
    # phpunit.xml
    phpunit_content = '''<?xml version="1.0"?>
<phpunit
    xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
    xsi:noNamespaceSchemaLocation="https://schema.phpunit.de/10.0/phpunit.xsd"
    bootstrap="tests/bootstrap.php"
    colors="true"
    cacheDirectory=".phpunit.cache"
>
    <testsuites>
        <testsuite name="Unit Tests">
            <directory suffix="Test.php">./tests/Unit</directory>
        </testsuite>
        <testsuite name="Integration Tests">
            <directory suffix="Test.php">./tests/Integration</directory>
        </testsuite>
    </testsuites>

    <source>
        <include>
            <directory suffix=".php">./src</directory>
        </include>
    </source>
</phpunit>
'''
    write_file(plugin_path / "phpunit.xml.dist", phpunit_content)
    
    # .gitignore
    gitignore_content = '''# Composer
/vendor/
composer.lock

# PHP
*.log
.phpunit.result.cache
coverage/
.phpunit.cache/

# IDE
.idea/
.vscode/
*.swp

# OS
.DS_Store

# Build
/build/
/node_modules/

# Environment
.env
'''
    write_file(plugin_path / ".gitignore", gitignore_content)
    
    # README.md
    readme_content = f'''# {plugin_name.replace('-', ' ').title()}

WordPress plugin built with Test-Driven Development and Functional Programming principles.

## Development Setup

```bash
# Install dependencies
composer install

# Run tests
composer test

# Check coding standards
composer lint

# Auto-fix coding standards
composer lint:fix
```

## TDD Workflow

1. Write a failing test
2. Write minimal code to pass
3. Refactor while keeping tests green
4. Commit

See `references/tdd_patterns.md` for detailed patterns.

## Functional Programming

This plugin follows functional programming principles:

- Pure functions when possible
- Immutable data transformations
- Function composition
- Explicit dependencies

See `references/functional_patterns.md` for detailed patterns.
'''
    write_file(plugin_path / "README.md", readme_content)
    
    print(f"\n✅ Plugin '{plugin_name}' initialized successfully!\n")
    print("Next steps:")
    print(f"1. cd {plugin_path}")
    print("2. composer install")
    print("3. composer test")
    print("4. git init && git add . && git commit -m 'Initial commit'")
    print("\nStart developing with TDD! 🚀\n")


def main():
    """Main entry point."""
    parser = argparse.ArgumentParser(
        description='Initialize a new WordPress plugin with TDD setup'
    )
    parser.add_argument(
        'plugin_name',
        help='Plugin name (e.g., my-awesome-plugin)'
    )
    parser.add_argument(
        '--path',
        default='.',
        help='Base directory for plugin (default: current directory)'
    )
    
    args = parser.parse_args()
    
    # Validate plugin name
    if not args.plugin_name.replace('-', '').replace('_', '').isalnum():
        print("❌ Error: Plugin name must contain only letters, numbers, hyphens, and underscores")
        sys.exit(1)
    
    base_path = Path(args.path).resolve()
    
    if not base_path.exists():
        print(f"❌ Error: Directory {base_path} does not exist")
        sys.exit(1)
    
    init_plugin(args.plugin_name, base_path)


if __name__ == '__main__':
    main()
