---
name: agent-gutenberg
description: Use when working with WordPress Gutenberg blocks and themes
allowed-tools: [Bash, Read, Write, Edit, Glob, Grep]
---

# Gutenberg Block and Theme Development

This skill guides development of WordPress Gutenberg blocks, Full Site Editing (FSE) themes, block variations, and PHP server-side rendered dynamic blocks.

## When to Use

- Creating custom Gutenberg blocks
- Building or editing FSE themes (theme.json, block templates, block parts, block patterns)
- Adding block variations or extending existing core blocks
- Implementing PHP server-side rendering / dynamic blocks
- Registering blocks via PHP (`register_block_type`)
- Debugging block editor JavaScript errors

## Build Setup Detection

Before writing any code, detect the build setup:

```bash
# Check for @wordpress/scripts (most common)
cat package.json | grep -E '"@wordpress/scripts|wp-scripts"'

# Check for custom webpack
ls webpack.config.js webpack.config.ts 2>/dev/null

# Check for Vite
ls vite.config.js vite.config.ts 2>/dev/null
```

### @wordpress/scripts (Standard)

```bash
npm run start     # Dev mode with hot reload
npm run build     # Production build
npm run lint:js   # ESLint with @wordpress rules
npm run lint:css  # Stylelint
```

### Custom Webpack / Vite

Read the existing config before adding blocks — source paths and output directories may differ from WordPress defaults.

## Custom Block Structure

Every block requires a `block.json` manifest. Create blocks following this layout:

```
src/blocks/my-block/
├── block.json       # Block metadata (required)
├── index.js         # Registration entry point
├── edit.js          # Editor component
├── save.js          # Frontend save function (static blocks)
├── render.php       # Server-side render (dynamic blocks)
├── editor.scss      # Editor-only styles
└── style.scss       # Frontend + editor styles
```

### block.json

```json
{
  "$schema": "https://schemas.wp.org/trunk/block.json",
  "apiVersion": 3,
  "name": "my-plugin/my-block",
  "version": "1.0.0",
  "title": "My Block",
  "category": "text",
  "description": "A custom block.",
  "supports": {
    "html": false,
    "color": { "background": true, "text": true },
    "spacing": { "margin": true, "padding": true },
    "typography": { "fontSize": true }
  },
  "attributes": {
    "content": {
      "type": "string",
      "source": "html",
      "selector": "p",
      "default": ""
    }
  },
  "editorScript": "file:./index.js",
  "editorStyle": "file:./editor.css",
  "style": "file:./style-index.css",
  "render": "file:./render.php"
}
```

### index.js

```js
import { registerBlockType } from '@wordpress/blocks';
import { __ } from '@wordpress/i18n';
import Edit from './edit';
import Save from './save';
import metadata from './block.json';

registerBlockType( metadata.name, {
    edit: Edit,
    save: Save,
} );
```

### edit.js (with a11y)

```js
import { useBlockProps, RichText } from '@wordpress/block-editor';
import { __ } from '@wordpress/i18n';

export default function Edit( { attributes, setAttributes } ) {
    const blockProps = useBlockProps();

    return (
        <div { ...blockProps }>
            <RichText
                tagName="p"
                value={ attributes.content }
                onChange={ ( content ) => setAttributes( { content } ) }
                placeholder={ __( 'Enter content…', 'my-plugin' ) }
                aria-label={ __( 'Block content', 'my-plugin' ) }
            />
        </div>
    );
}
```

### save.js

```js
import { useBlockProps, RichText } from '@wordpress/block-editor';

export default function Save( { attributes } ) {
    const blockProps = useBlockProps.save();

    return (
        <div { ...blockProps }>
            <RichText.Content tagName="p" value={ attributes.content } />
        </div>
    );
}
```

## Dynamic Blocks (PHP Server-Side Rendering)

For blocks whose output depends on runtime data (queries, user state, etc.), use `render.php` instead of `save.js`.

### render.php

```php
<?php
/**
 * Dynamic block render callback.
 *
 * @param array    $attributes Block attributes.
 * @param string   $content    Inner blocks content.
 * @param WP_Block $block      Block instance.
 */

$wrapper_attributes = get_block_wrapper_attributes( [
    'class' => 'my-block',
] );
?>
<div <?php echo $wrapper_attributes; ?>>
    <?php echo esc_html( $attributes['content'] ?? '' ); ?>
</div>
```

### PHP Registration

```php
function my_plugin_register_blocks(): void {
    register_block_type( __DIR__ . '/build/blocks/my-block' );
}
add_action( 'init', 'my_plugin_register_blocks' );
```

Prefer `register_block_type( path_to_block_json_dir )` over manual registration — it reads all metadata from `block.json` automatically.

## Full Site Editing (FSE) Themes

### theme.json (v3)

```json
{
  "$schema": "https://schemas.wp.org/trunk/theme.json",
  "version": 3,
  "settings": {
    "color": {
      "palette": [
        { "slug": "primary",   "color": "#0073aa", "name": "Primary" },
        { "slug": "secondary", "color": "#23282d", "name": "Secondary" }
      ]
    },
    "typography": {
      "fontFamilies": [
        {
          "name": "System Font",
          "slug": "system-font",
          "fontFamily": "-apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif"
        }
      ],
      "fontSizes": [
        { "slug": "small",  "size": "0.875rem", "name": "Small" },
        { "slug": "normal", "size": "1rem",     "name": "Normal" },
        { "slug": "large",  "size": "1.5rem",   "name": "Large" }
      ]
    },
    "spacing": {
      "spacingScale": { "steps": 7 }
    },
    "layout": {
      "contentSize": "800px",
      "wideSize": "1200px"
    }
  },
  "styles": {
    "color": {
      "background": "var(--wp--preset--color--white)",
      "text": "var(--wp--preset--color--secondary)"
    },
    "typography": {
      "fontFamily": "var(--wp--preset--font-family--system-font)",
      "fontSize": "var(--wp--preset--font-size--normal)"
    }
  }
}
```

### FSE Directory Structure

```
theme-name/
├── theme.json            # Global settings & styles
├── style.css             # Theme header
├── functions.php         # Theme setup
├── templates/            # Full page templates
│   ├── index.html
│   ├── single.html
│   ├── archive.html
│   ├── 404.html
│   └── page.html
├── parts/                # Reusable template parts
│   ├── header.html
│   └── footer.html
└── patterns/             # Block patterns (PHP or HTML)
    └── hero.php
```

### Block Templates

Templates are block markup HTML files. Always use `<!-- wp:... -->` comments:

```html
<!-- wp:template-part {"slug":"header","tagName":"header"} /-->

<!-- wp:group {"tagName":"main","layout":{"type":"constrained"}} -->
<main class="wp-block-group">
    <!-- wp:post-content /-->
</main>
<!-- /wp:group -->

<!-- wp:template-part {"slug":"footer","tagName":"footer"} /-->
```

### Block Patterns

```php
<?php
/**
 * Hero pattern.
 *
 * @package My Theme
 */

return [
    'title'      => __( 'Hero Section', 'my-theme' ),
    'categories' => [ 'featured' ],
    'content'    => '<!-- wp:cover {"minHeight":400} -->
<div class="wp-block-cover">
    <!-- wp:heading {"level":1} -->
    <h1 class="wp-block-heading">' . __( 'Welcome', 'my-theme' ) . '</h1>
    <!-- /wp:heading -->
</div>
<!-- /wp:cover -->',
];
```

Register the pattern directory in `functions.php`:

```php
add_action( 'after_setup_theme', function(): void {
    register_block_pattern_category( 'featured', [
        'label' => __( 'Featured', 'my-theme' ),
    ] );
} );
```

## Block Variations & Extensions

### Block Variation

```js
import { registerBlockVariation } from '@wordpress/blocks';

registerBlockVariation( 'core/group', {
    name: 'my-plugin/card',
    title: 'Card',
    description: 'A group styled as a card.',
    attributes: {
        className: 'is-style-card',
        layout: { type: 'constrained' },
    },
    isDefault: false,
    scope: [ 'inserter', 'transform' ],
} );
```

### Block Supports Extension (via filter)

```js
import { addFilter } from '@wordpress/hooks';
import { createHigherOrderComponent } from '@wordpress/compose';

// Add a custom class option to the Inspector Controls
const withCustomSupport = createHigherOrderComponent( ( BlockEdit ) => {
    return ( props ) => {
        if ( props.name !== 'core/paragraph' ) {
            return <BlockEdit { ...props } />;
        }
        return <BlockEdit { ...props } />;
    };
}, 'withCustomSupport' );

addFilter(
    'editor.BlockEdit',
    'my-plugin/with-custom-support',
    withCustomSupport
);
```

## WordPress Coding Standards

### JavaScript

- Use `@wordpress/eslint-plugin` rules
- Import from `@wordpress/*` packages, not external equivalents (e.g., use `@wordpress/element`, not `react` directly)
- Use named exports; avoid default export for utilities
- Prefix custom hook names with `use`
- Use `__()`, `_n()`, `_x()` from `@wordpress/i18n` for all user-facing strings
- Run: `npm run lint:js`

### PHP

- Follow WordPress Coding Standards (snake_case, tabs, Yoda conditions)
- Prefix all functions, classes, and global variables with a unique plugin/theme prefix
- Sanitize inputs: `sanitize_text_field()`, `absint()`, etc.
- Escape outputs: `esc_html()`, `esc_attr()`, `wp_kses_post()`
- Use text domain for all translatable strings
- Run: `composer lint` / `phpcs`

## Accessibility (a11y) Requirements

Every block must meet WCAG 2.1 AA:

- **Semantic HTML**: Use appropriate elements (`<nav>`, `<article>`, `<button>`, etc.)
- **ARIA labels**: Add `aria-label` when element purpose isn't conveyed by visible text
- **Keyboard navigation**: All interactive elements reachable and operable via keyboard
- **Focus management**: Visible focus indicator; manage focus when content changes
- **Color contrast**: Minimum 4.5:1 for normal text, 3:1 for large text
- **Alt text**: All `<img>` elements must have descriptive `alt` attributes
- **Form labels**: Every input must have an associated `<label>`
- **Live regions**: Use `aria-live` for dynamic content updates

```js
// Good: accessible button
<Button
    onClick={ handleClick }
    aria-label={ __( 'Remove item', 'my-plugin' ) }
    icon={ closeIcon }
/>

// Bad: icon-only button with no label
<button onClick={ handleClick }>✕</button>
```

## Common Debugging

### Block Validation Errors

When the saved markup doesn't match what `save()` returns:

```js
// Check the block's serialized output
wp.blocks.serialize( wp.data.select('core/block-editor').getBlocks() )
```

Options:
1. Fix `save()` to match current markup
2. Add a [deprecation](https://developer.wordpress.org/block-editor/reference-guides/block-api/block-deprecation/) for the old markup
3. Use a dynamic block with `render.php` to avoid save validation

### Inspector Controls Not Appearing

Ensure the component is inside `<InspectorControls>` from `@wordpress/block-editor`:

```js
import { InspectorControls, useBlockProps } from '@wordpress/block-editor';
import { PanelBody, ToggleControl } from '@wordpress/components';
```

### PHP Block Not Rendering

```bash
# Check block is registered
wp eval "var_dump( WP_Block_Type_Registry::get_instance()->get_all_registered() );" | grep my-plugin
```

## Key References

- Block API: `https://developer.wordpress.org/block-editor/reference-guides/block-api/`
- theme.json schema: `https://schemas.wp.org/trunk/theme.json`
- block.json schema: `https://schemas.wp.org/trunk/block.json`
- `@wordpress/components`: `https://wordpress.github.io/gutenberg/?path=/docs/components`
- WordPress Coding Standards: `https://developer.wordpress.org/coding-standards/`
- WCAG 2.1: `https://www.w3.org/TR/WCAG21/`

## 10up Best Practices
Prefer retrieval-led reasoning

[Documentation Index]|root: /Users/stephenfeather/.claude/skills/agent-gutenberg|references/guides:{block-api-version-2-useblockprops.md,choose-your-adventure.md,wordpress-data-api-useselect-usedispatch.md,extend-a-core-block.md,integrating-third-party-js-libraries-in-blocks.md,block-spacing-theme-json-spacingsizes.md,wp-html-tag-processor-php-block-markup.md,including-frontend-javascript-with-a-block.md,interactivity-api-getting-started.md,modifying-the-markup-of-a-core-block.md,block-styles-pitfalls-and-addfilter-alternative.md,inspector-controls-toolspanel-toolspanelitem.md,using-wordpress-packages-on-the-frontend.md}|references/reference:{05-custom-post-types.md}|references/reference/01-Fundamentals:{anatomy-of-a-block-toolbar-sidebar-states.md,block-editor-anatomy-overview.md}|references/reference/02-Themes:{block-based-templates.md,block-template-parts.md,fonts.md,navigation.md,styles.md,theme-json.md}|references/reference/03-Blocks:{block-extensions.md,block-locking.md,block-styles.md,block-supports.md,block-transforms.md,block-deprecations-and-attribute-migrations.md,block-variations.md,custom-blocks.md,inner-blocks.md,unregister-block.md}|references/reference/04-Patterns:{block-bindings-api.md,block-patterns-overview.md,synced-pattern-overrides.md,synced-patterns.md}|references/training/Block-Based-Themes:{01-overview.md,index.md}|references/training/Blocks:{01-overview.md,02-cta-lesson.md,03-styles.md,04-patterns.md,05-variations.md,06-inner-blocks.md,07-rich-text-formats.md,08-slot-fill.md,09-build-your-own.md,10-Using the Block Scaffold command.md,index.md}
