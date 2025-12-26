# Test-Driven Development Patterns for WordPress

## Core TDD Workflow

1. **Write a failing test** - Define expected behavior first
2. **Write minimal code** - Make the test pass with simplest solution
3. **Refactor** - Improve code while keeping tests green
4. **Commit** - Save working state to version control

## Test Structure Patterns

### AAA Pattern (Arrange-Act-Assert)

```php
public function test_example_behavior(): void {
    // Arrange - Set up test data and mocks
    $input = 'test';
    
    // Act - Execute the code under test
    $result = function_under_test( $input );
    
    // Assert - Verify the result
    $this->assertEquals( 'expected', $result );
}
```

### Given-When-Then Pattern

```php
public function test_user_registration(): void {
    // Given a valid email address
    $email = 'user@example.com';
    
    // When the user registers
    $user_id = register_user( $email );
    
    // Then a user should be created
    $this->assertIsInt( $user_id );
    $this->assertGreaterThan( 0, $user_id );
}
```

## Testing Functional Code

### Pure Function Testing (Easiest)

```php
/**
 * Pure function - same input always produces same output
 */
function sanitize_username( string $username ): string {
    return strtolower( trim( $username ) );
}

// Test is straightforward
public function test_sanitize_username(): void {
    $this->assertEquals( 'john', sanitize_username( '  John  ' ) );
    $this->assertEquals( 'jane', sanitize_username( 'JANE' ) );
}
```

### WordPress Hook Testing with Brain Monkey

```php
use Brain\Monkey\Functions;
use Brain\Monkey\Filters;

public function test_filter_is_applied(): void {
    // Mock WordPress apply_filters function
    Filters\expectApplied( 'my_custom_filter' )
        ->once()
        ->with( 'default_value', 123 )
        ->andReturn( 'filtered_value' );
    
    $result = my_function_that_uses_filter( 123 );
    
    $this->assertEquals( 'filtered_value', $result );
}

public function test_action_is_triggered(): void {
    // Verify do_action is called
    Functions\expect( 'do_action' )
        ->once()
        ->with( 'my_custom_action', 'data' );
    
    my_function_that_triggers_action( 'data' );
}
```

### Testing with Mock Dependencies

```php
use Mockery;

public function test_service_with_dependency(): void {
    // Create a mock database
    $mock_db = Mockery::mock( 'Database' );
    $mock_db->shouldReceive( 'get_user' )
        ->once()
        ->with( 123 )
        ->andReturn( [ 'name' => 'John' ] );
    
    // Inject mock into service
    $service = new UserService( $mock_db );
    
    $result = $service->get_user_name( 123 );
    
    $this->assertEquals( 'John', $result );
}

protected function tearDown(): void {
    Mockery::close();
    parent::tearDown();
}
```

## Test Organization

### Directory Structure

```
tests/
├── bootstrap.php
├── Unit/
│   ├── Functions/
│   │   └── SanitizationTest.php
│   ├── Services/
│   │   └── UserServiceTest.php
│   └── Validators/
│       └── EmailValidatorTest.php
└── Integration/
    ├── Hooks/
    │   └── InitHooksTest.php
    └── Database/
        └── QueryTest.php
```

### Naming Conventions

- Test files: `{ClassName}Test.php`
- Test methods: `test_{behavior}_when_{condition}()`
- Example: `test_returns_error_when_email_invalid()`

## TDD Best Practices

### 1. Test One Thing at a Time

```php
// Good - Tests one specific behavior
public function test_returns_empty_array_when_no_posts(): void {
    $result = get_recent_posts( 0 );
    $this->assertIsArray( $result );
    $this->assertEmpty( $result );
}

// Avoid - Tests multiple behaviors
public function test_posts_functionality(): void {
    // Testing too many things at once
}
```

### 2. Use Descriptive Test Names

```php
// Good - Clear what's being tested
public function test_throws_exception_when_email_is_empty(): void

// Avoid - Unclear test purpose  
public function test_email(): void
```

### 3. Keep Tests Independent

```php
// Each test should set up its own data
public function test_user_creation(): void {
    $email = 'test@example.com'; // Local to this test
    $user_id = create_user( $email );
    $this->assertIsInt( $user_id );
}
```

### 4. Use Data Providers for Similar Tests

```php
/**
 * @dataProvider email_validation_data
 */
public function test_email_validation( string $email, bool $expected ): void {
    $result = is_valid_email( $email );
    $this->assertEquals( $expected, $result );
}

public function email_validation_data(): array {
    return [
        'valid email'           => [ 'user@example.com', true ],
        'missing @'             => [ 'userexample.com', false ],
        'missing domain'        => [ 'user@', false ],
        'empty string'          => [ '', false ],
    ];
}
```

## Red-Green-Refactor Cycle

### 1. Red - Write Failing Test

```php
public function test_formats_price_with_currency(): void {
    $result = format_price( 19.99 );
    $this->assertEquals( '$19.99', $result );
}
// Test fails - format_price() doesn't exist yet
```

### 2. Green - Minimum Code to Pass

```php
function format_price( float $price ): string {
    return '$' . number_format( $price, 2 );
}
// Test passes!
```

### 3. Refactor - Improve Code

```php
function format_price( float $price, string $currency = '$' ): string {
    return $currency . number_format( $price, 2 );
}
// Still passes, now more flexible
```

### 4. Commit

```bash
git add tests/Unit/PriceTest.php src/functions.php
git commit -m "Add price formatting with currency support"
```

## Common Testing Patterns

### Testing WordPress Options

```php
use Brain\Monkey\Functions;

public function test_gets_option_with_default(): void {
    Functions\expect( 'get_option' )
        ->once()
        ->with( 'my_option', 'default' )
        ->andReturn( 'custom_value' );
    
    $result = my_get_setting();
    
    $this->assertEquals( 'custom_value', $result );
}
```

### Testing WordPress Transients

```php
public function test_caches_expensive_operation(): void {
    Functions\expect( 'get_transient' )
        ->once()
        ->with( 'my_cache_key' )
        ->andReturn( false );
    
    Functions\expect( 'set_transient' )
        ->once()
        ->with( 'my_cache_key', Mockery::type( 'array' ), 3600 );
    
    $result = get_cached_data();
    
    $this->assertIsArray( $result );
}
```

### Testing Form Validation

```php
public function test_validates_required_fields(): void {
    $data = [
        'email' => '',
        'name'  => 'John',
    ];
    
    $errors = validate_form( $data );
    
    $this->assertArrayHasKey( 'email', $errors );
    $this->assertEquals( 'Email is required', $errors['email'] );
}
```

## Continuous Testing

Run tests automatically:

```bash
# Run all tests
composer test

# Run specific test file
vendor/bin/phpunit tests/Unit/Functions/SanitizationTest.php

# Run with coverage
composer test:coverage

# Watch mode (requires phpunit-watcher)
vendor/bin/phpunit-watcher watch
```
