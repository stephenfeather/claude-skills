# Claude Skills Repository

This repository contains custom skills for Claude Code, Anthropic's official CLI tool. Skills extend Claude Code's capabilities by providing specialized domain knowledge and workflows for specific development tasks.

## About Claude Skills

Skills are reusable prompt templates that give Claude Code deep expertise in specific domains. When you invoke a skill, Claude receives comprehensive context about best practices, patterns, and workflows for that domain, enabling more effective and consistent assistance.

## Available Skills

### wordpress-php-dev

WordPress PHP plugin development using Test-Driven Development (TDD) and functional programming principles.

**Purpose:** Provides comprehensive guidance for developing professional WordPress plugins with modern PHP practices, including PSR-12 compliance, Composer integration, automated testing with PHPUnit, coding standards enforcement, and git version control.

**Use when:**
- Creating new WordPress plugins
- Writing WordPress PHP code with TDD workflows
- Setting up plugin testing infrastructure
- Implementing functional programming patterns in WordPress
- Enforcing coding standards with phpcs/phpcbf
- Managing plugin development with Git

**Key features:**
- Test-Driven Development (TDD) workflows
- Functional programming patterns for WordPress
- PSR-12 compliant code structure
- PHPUnit testing with Brain Monkey for WordPress mocking
- Automated coding standards enforcement
- Complete plugin scaffolding and initialization
- Git workflow integration with conventional commits

## Using Skills

To use a skill in Claude Code, invoke it by name when relevant to your task, or Claude will automatically suggest using it when appropriate based on your request.

For more information about creating and using skills, refer to the [Claude Code documentation](https://github.com/anthropics/claude-code).
