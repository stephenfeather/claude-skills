# Functional Programming Patterns for WordPress

## Core Principles

Functional programming emphasizes:
1. **Pure functions** - Same input always produces same output, no side effects
2. **Immutability** - Data is not modified after creation
3. **Function composition** - Combine simple functions into complex operations
4. **First-class functions** - Functions as values, arguments, return values

These principles make code more testable, predictable, and maintainable.

## Pure Functions vs Impure Functions

### Pure Functions (Prefer These)

```php
// Pure - deterministic, no side effects
function calculate_discounted_price( float $price, float $discount ): float {
    return $price * ( 1 - $discount );
}

// Pure - transforms data without modifying input
function sanitize_post_data( array $data ): array {
    return array_map( fn( $value ) => sanitize_text_field( $value ), $data );
}

// Pure - composable validation
function is_valid_email( string $email ): bool {
    return (bool) filter_var( $email, FILTER_VALIDATE_EMAIL );
}
```

### Impure Functions (Isolate These)

```php
// Impure - reads from database
function get_user_data( int $user_id ): array {
    global $wpdb;
    return $wpdb->get_row( 
        $wpdb->prepare( "SELECT * FROM users WHERE id = %d", $user_id ), 
        ARRAY_A 
    );
}

// Impure - modifies global state
function save_user_preference( int $user_id, string $key, $value ): void {
    update_user_meta( $user_id, $key, $value );
}

// Impure - outputs HTML
function render_template( string $template, array $data ): void {
    extract( $data );
    include $template;
}
```

### Isolate Impurity Pattern

```php
// Separate data fetching (impure) from processing (pure)

// Impure - handles I/O
function fetch_posts_from_db( array $args ): array {
    return get_posts( $args );
}

// Pure - transforms data
function format_posts_for_display( array $posts ): array {
    return array_map( function( $post ) {
        return [
            'id'      => $post->ID,
            'title'   => get_the_title( $post ),
            'excerpt' => wp_trim_words( $post->post_content, 20 ),
            'link'    => get_permalink( $post ),
        ];
    }, $posts );
}

// Compose them
function get_formatted_posts( array $args ): array {
    $posts = fetch_posts_from_db( $args );    // Impure
    return format_posts_for_display( $posts ); // Pure
}
```

## Immutability Patterns

### Avoid Mutation

```php
// Bad - Mutates input array
function add_metadata_bad( array &$data, string $key, $value ): array {
    $data[ $key ] = $value; // Modifies original
    return $data;
}

// Good - Returns new array
function add_metadata( array $data, string $key, $value ): array {
    return array_merge( $data, [ $key => $value ] );
}

// Or using spread operator (PHP 7.4+)
function add_metadata( array $data, string $key, $value ): array {
    return [ ...$data, $key => $value ];
}
```

### Transform, Don't Modify

```php
// Transform arrays without mutation
function increment_prices( array $products ): array {
    return array_map( function( $product ) {
        return [ ...$product, 'price' => $product['price'] * 1.1 ];
    }, $products );
}

// Filter without mutation
function get_active_users( array $users ): array {
    return array_filter( $users, fn( $user ) => $user['status'] === 'active' );
}

// Reduce without mutation
function calculate_total( array $items ): float {
    return array_reduce( 
        $items, 
        fn( $total, $item ) => $total + $item['price'], 
        0.0 
    );
}
```

## Function Composition

### Pipe Pattern

```php
// Compose functions left-to-right
function pipe( ...$functions ) {
    return function( $value ) use ( $functions ) {
        return array_reduce(
            $functions,
            fn( $carry, $fn ) => $fn( $carry ),
            $value
        );
    };
}

// Usage
$process_username = pipe(
    fn( $s ) => trim( $s ),
    fn( $s ) => strtolower( $s ),
    fn( $s ) => sanitize_user( $s )
);

$clean_username = $process_username( '  JohnDoe  ' ); // 'johndoe'
```

### Compose Pattern

```php
// Compose functions right-to-left
function compose( ...$functions ) {
    return function( $value ) use ( $functions ) {
        return array_reduce(
            array_reverse( $functions ),
            fn( $carry, $fn ) => $fn( $carry ),
            $value
        );
    };
}

// Build complex validators from simple ones
$validate_email = compose(
    fn( $s ) => filter_var( $s, FILTER_VALIDATE_EMAIL ) !== false,
    fn( $s ) => strlen( $s ) > 0,
    fn( $s ) => trim( $s )
);
```

### Partial Application

```php
// Create specialized functions from general ones
function partial( callable $fn, ...$args ) {
    return function( ...$remaining ) use ( $fn, $args ) {
        return $fn( ...array_merge( $args, $remaining ) );
    };
}

// General function
function greet( string $greeting, string $name ): string {
    return "$greeting, $name!";
}

// Create specialized versions
$say_hello = partial( greet, 'Hello' );
$say_goodbye = partial( greet, 'Goodbye' );

echo $say_hello( 'John' );    // "Hello, John!"
echo $say_goodbye( 'Jane' );  // "Goodbye, Jane!"
```

## Higher-Order Functions

### Functions that Return Functions

```php
// Factory function
function create_validator( string $rule ): callable {
    return match( $rule ) {
        'email'    => fn( $v ) => filter_var( $v, FILTER_VALIDATE_EMAIL ) !== false,
        'url'      => fn( $v ) => filter_var( $v, FILTER_VALIDATE_URL ) !== false,
        'required' => fn( $v ) => ! empty( $v ),
        'numeric'  => fn( $v ) => is_numeric( $v ),
        default    => fn( $v ) => true,
    };
}

// Usage
$validate_email = create_validator( 'email' );
$is_valid = $validate_email( 'test@example.com' ); // true
```

### Decorator Pattern

```php
// Wrap functions with additional behavior
function with_logging( callable $fn, string $name ): callable {
    return function( ...$args ) use ( $fn, $name ) {
        error_log( "Calling $name with args: " . json_encode( $args ) );
        $result = $fn( ...$args );
        error_log( "Result: " . json_encode( $result ) );
        return $result;
    };
}

// Wrap function with caching
function with_cache( callable $fn, int $ttl = 3600 ): callable {
    return function( ...$args ) use ( $fn, $ttl ) {
        $cache_key = 'fn_' . md5( serialize( $args ) );
        
        $cached = get_transient( $cache_key );
        if ( $cached !== false ) {
            return $cached;
        }
        
        $result = $fn( ...$args );
        set_transient( $cache_key, $result, $ttl );
        return $result;
    };
}

// Combine decorators
$expensive_operation = function( $data ) {
    // Complex calculation
    return process_data( $data );
};

$cached_logged_operation = with_logging( 
    with_cache( $expensive_operation, 3600 ),
    'expensive_operation'
);
```

## WordPress-Specific Functional Patterns

### Hook Handlers as Pure Functions

```php
// Pure function for filter
function apply_discount_filter( float $price, float $discount_rate ): float {
    return $price * ( 1 - $discount_rate );
}

// Register the filter
add_filter( 'product_price', function( $price ) {
    return apply_discount_filter( $price, 0.1 );
} );
```

### Functional Query Building

```php
// Build WP_Query args functionally
function base_query(): array {
    return [
        'post_type'   => 'post',
        'post_status' => 'publish',
    ];
}

function with_pagination( array $args, int $page, int $per_page ): array {
    return array_merge( $args, [
        'paged'          => $page,
        'posts_per_page' => $per_page,
    ] );
}

function with_taxonomy( array $args, string $taxonomy, array $terms ): array {
    $tax_query = $args['tax_query'] ?? [];
    $tax_query[] = [
        'taxonomy' => $taxonomy,
        'terms'    => $terms,
        'field'    => 'slug',
    ];
    
    return array_merge( $args, [ 'tax_query' => $tax_query ] );
}

// Compose query
$query_args = pipe(
    base_query(),
    fn( $args ) => with_pagination( $args, 1, 10 ),
    fn( $args ) => with_taxonomy( $args, 'category', [ 'news' ] )
);
```

### Functional REST API Responses

```php
// Transform post data for API
function transform_post_for_api( WP_Post $post ): array {
    return [
        'id'         => $post->ID,
        'title'      => get_the_title( $post ),
        'content'    => apply_filters( 'the_content', $post->post_content ),
        'author'     => transform_author_for_api( get_user_by( 'id', $post->post_author ) ),
        'categories' => transform_terms_for_api( get_the_terms( $post, 'category' ) ),
    ];
}

function transform_author_for_api( WP_User $user ): array {
    return [
        'id'   => $user->ID,
        'name' => $user->display_name,
        'url'  => get_author_posts_url( $user->ID ),
    ];
}

function transform_terms_for_api( $terms ): array {
    if ( ! $terms || is_wp_error( $terms ) ) {
        return [];
    }
    
    return array_map( fn( $term ) => [
        'id'   => $term->term_id,
        'name' => $term->name,
        'slug' => $term->slug,
    ], $terms );
}
```

## Error Handling with Maybe/Option Pattern

```php
// Option type for handling nullable values
class Option {
    private function __construct( private $value, private bool $has_value ) {}
    
    public static function some( $value ): self {
        return new self( $value, true );
    }
    
    public static function none(): self {
        return new self( null, false );
    }
    
    public function map( callable $fn ): self {
        return $this->has_value ? self::some( $fn( $this->value ) ) : $this;
    }
    
    public function flat_map( callable $fn ): self {
        return $this->has_value ? $fn( $this->value ) : $this;
    }
    
    public function get_or_else( $default ) {
        return $this->has_value ? $this->value : $default;
    }
}

// Usage
function find_user_by_email( string $email ): Option {
    $user = get_user_by( 'email', $email );
    return $user ? Option::some( $user ) : Option::none();
}

$user_name = find_user_by_email( 'john@example.com' )
    ->map( fn( $user ) => $user->display_name )
    ->get_or_else( 'Guest' );
```

## Testing Benefits

Functional code is easier to test:

```php
// Pure functions are trivial to test
public function test_calculate_discount(): void {
    $this->assertEquals( 90.0, calculate_discounted_price( 100.0, 0.1 ) );
    $this->assertEquals( 80.0, calculate_discounted_price( 100.0, 0.2 ) );
}

// No mocking needed for pure transformations
public function test_format_posts(): void {
    $input = [
        (object) [ 'ID' => 1, 'post_title' => 'Test', 'post_content' => 'Content' ],
    ];
    
    $result = format_posts_for_display( $input );
    
    $this->assertCount( 1, $result );
    $this->assertEquals( 1, $result[0]['id'] );
}
```

## Key Takeaways

1. **Separate pure from impure** - Isolate side effects to boundaries
2. **Prefer immutability** - Transform data, don't modify
3. **Compose small functions** - Build complex behavior from simple pieces
4. **Use higher-order functions** - Functions that work with functions
5. **Make dependencies explicit** - Pass what you need as arguments
6. **Test pure functions easily** - No mocks needed for deterministic code
