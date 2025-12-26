# Git Workflow for WordPress Plugin Development

## Repository Structure

```
plugin-name/
├── .git/
├── .gitignore
├── composer.json
├── composer.lock
├── phpcs.xml.dist
├── phpunit.xml.dist
├── plugin-name.php          # Main plugin file
├── README.md
├── src/                     # Source code (autoloaded)
│   ├── functions.php        # Helper functions
│   └── Plugin.php           # Main plugin class
├── tests/                   # PHPUnit tests
│   ├── bootstrap.php
│   ├── Unit/
│   └── Integration/
├── assets/                  # Frontend assets
│   ├── css/
│   ├── js/
│   └── images/
└── vendor/                  # Composer dependencies (gitignored)
```

## .gitignore Template

```gitignore
# Composer
/vendor/
composer.lock

# PHP
*.log
.phpunit.result.cache
coverage/
.phpunit.cache/

# WordPress
wp-config.php
.htaccess

# IDE
.idea/
.vscode/
*.swp
*.swo
*~

# OS
.DS_Store
Thumbs.db

# Build
/build/
/dist/
/node_modules/

# Environment
.env
.env.local
```

## Commit Message Convention

Follow conventional commits format:

```
<type>(<scope>): <subject>

<body>

<footer>
```

### Types

- `feat`: New feature
- `fix`: Bug fix
- `test`: Adding or updating tests
- `refactor`: Code change that neither fixes a bug nor adds a feature
- `docs`: Documentation changes
- `style`: Code style changes (formatting, missing semicolons, etc)
- `chore`: Maintenance tasks (dependencies, build process)

### Examples

```bash
feat(user): add email validation to registration

- Implement email format validation
- Add tests for valid/invalid emails
- Update error messages

Closes #123
```

```bash
fix(pricing): correct discount calculation

The discount was being applied before tax instead of after.

Fixes #456
```

```bash
test(hooks): add tests for filter callbacks

Add comprehensive tests for all filter hooks to ensure
they return expected values in various scenarios.
```

## TDD Commit Workflow

### Red Phase - Failing Test

```bash
# 1. Create feature branch
git checkout -b feature/email-validation

# 2. Write failing test
# Edit tests/Unit/ValidationTest.php

# 3. Run tests (should fail)
composer test

# 4. Commit the failing test
git add tests/Unit/ValidationTest.php
git commit -m "test(validation): add failing test for email validation"
```

### Green Phase - Make It Pass

```bash
# 5. Write minimal code to pass
# Edit src/functions.php

# 6. Run tests (should pass)
composer test

# 7. Fix coding standards
composer lint:fix

# 8. Commit the working code
git add src/functions.php
git commit -m "feat(validation): implement email validation function"
```

### Refactor Phase - Improve Code

```bash
# 9. Refactor if needed
# Edit src/functions.php

# 10. Run tests (should still pass)
composer test

# 11. Fix coding standards
composer lint:fix

# 12. Commit the refactoring
git add src/functions.php
git commit -m "refactor(validation): extract validation logic to separate class"
```

## Regular Commit Workflow

### 1. Check Status Before Starting

```bash
git status
git pull origin main
```

### 2. Create Feature Branch

```bash
git checkout -b feature/new-feature-name
```

### 3. Make Changes in Small Increments

```bash
# Edit files
# Run tests
composer test

# Fix standards
composer lint:fix

# Stage changes
git add src/functions.php tests/Unit/FunctionTest.php

# Commit with descriptive message
git commit -m "feat(module): add new functionality"
```

### 4. Commit After Each Test Passes

```bash
# Write test → commit
git add tests/Unit/NewTest.php
git commit -m "test(feature): add test for new behavior"

# Write code → commit
git add src/Module.php
git commit -m "feat(feature): implement new behavior"

# Refactor → commit
git add src/Module.php
git commit -m "refactor(feature): simplify implementation"
```

### 5. Push to Remote

```bash
git push origin feature/new-feature-name
```

## Branching Strategy

### Main Branches

- `main` - Production-ready code
- `develop` - Integration branch for features

### Supporting Branches

- `feature/*` - New features
- `bugfix/*` - Bug fixes
- `hotfix/*` - Urgent production fixes
- `release/*` - Release preparation

### Branch Lifecycle

```bash
# Start feature
git checkout develop
git checkout -b feature/user-authentication

# Work on feature (multiple commits)
git commit -m "test(auth): add login validation tests"
git commit -m "feat(auth): implement login validation"
git commit -m "refactor(auth): improve error handling"

# Merge to develop
git checkout develop
git merge --no-ff feature/user-authentication
git push origin develop

# Delete feature branch
git branch -d feature/user-authentication
```

## Pre-Commit Checklist

Before every commit, ensure:

1. ✅ Tests pass: `composer test`
2. ✅ Coding standards: `composer lint` (or auto-fix with `composer lint:fix`)
3. ✅ No debug code (var_dump, console.log, etc.)
4. ✅ Meaningful commit message
5. ✅ Related files staged together

## Automated Checks

### Pre-commit Hook

Create `.git/hooks/pre-commit`:

```bash
#!/bin/bash

echo "Running pre-commit checks..."

# Run tests
echo "Running tests..."
composer test
if [ $? -ne 0 ]; then
    echo "Tests failed. Commit aborted."
    exit 1
fi

# Check coding standards
echo "Checking coding standards..."
composer lint
if [ $? -ne 0 ]; then
    echo "Coding standards check failed."
    echo "Run 'composer lint:fix' to auto-fix issues."
    exit 1
fi

echo "Pre-commit checks passed!"
exit 0
```

Make it executable:

```bash
chmod +x .git/hooks/pre-commit
```

## Useful Git Commands

### View Changes

```bash
# See what changed
git diff

# See staged changes
git diff --staged

# See commit history
git log --oneline --graph --decorate
```

### Undo Changes

```bash
# Unstage file
git reset HEAD file.php

# Discard local changes
git checkout -- file.php

# Amend last commit (if not pushed)
git commit --amend

# Revert a commit
git revert <commit-hash>
```

### Stash Work

```bash
# Save work in progress
git stash

# List stashes
git stash list

# Apply stashed work
git stash pop
```

## Release Workflow

### Version Tagging

```bash
# Create release branch
git checkout -b release/1.2.0 develop

# Update version numbers in code
# Update CHANGELOG.md
# Run final tests
composer test

# Commit release prep
git commit -am "chore(release): prepare version 1.2.0"

# Merge to main
git checkout main
git merge --no-ff release/1.2.0

# Tag release
git tag -a v1.2.0 -m "Version 1.2.0"

# Merge back to develop
git checkout develop
git merge --no-ff release/1.2.0

# Push everything
git push origin main develop --tags

# Delete release branch
git branch -d release/1.2.0
```

## Emergency Hotfix

```bash
# Create hotfix from main
git checkout -b hotfix/security-patch main

# Fix the issue
# Write test
# Commit fix

# Merge to main
git checkout main
git merge --no-ff hotfix/security-patch
git tag -a v1.2.1 -m "Hotfix v1.2.1"

# Merge to develop
git checkout develop
git merge --no-ff hotfix/security-patch

# Push and cleanup
git push origin main develop --tags
git branch -d hotfix/security-patch
```

## Collaboration Best Practices

1. **Pull before push**: Always `git pull` before pushing
2. **Small, focused commits**: Each commit should do one thing
3. **Descriptive messages**: Explain why, not just what
4. **Review your diff**: Check `git diff --staged` before committing
5. **Test before committing**: Never commit broken code
6. **Fix standards automatically**: Run `composer lint:fix` regularly
