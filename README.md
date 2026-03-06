# Claude Skills Repository

Custom skills for [Claude Code](https://github.com/anthropics/claude-code), Anthropic's official CLI tool. Skills extend Claude Code's capabilities by providing specialized domain knowledge and workflows for specific development tasks.

## Available Skills

### agent-gutenberg

WordPress Gutenberg block and Full Site Editing (FSE) theme development.

**Triggers:** `Gutenberg`, `custom block`, `FSE theme`, `theme.json`, `block.json`, `block pattern`, `render.php`

**Key features:**
- Custom block scaffolding (block.json, edit.js, save.js, render.php)
- FSE theme structure with theme.json v3, templates, parts, and patterns
- Block variations and block supports extension via filters
- Build setup detection (wp-scripts, Webpack, Vite)
- WCAG 2.1 AA accessibility requirements
- Indexed reference library of 10up best-practice guides

### codex

Wraps the Codex CLI in strict JSON enforcement with automatic retry logic.

**Triggers:** `ask codex`, `codex help`, `consult codex`

**Key features:**
- Strict JSON-only output enforcement via prompt wrapping
- Automatic retry with progressively stricter prompts on invalid JSON
- Optional JSON schema validation for structured output

### gemini

Wraps the Gemini CLI for text and reasoning tasks with strict JSON enforcement and retry logic.

**Triggers:** `ask gemini`, `gemini help`, `consult gemini`

**Key features:**
- Strict JSON-only output enforcement via prompt wrapping
- Automatic retry with progressively stricter prompts on invalid JSON
- Routes image generation tasks to the `gemini-image-generator` skill

### insights

Extracts non-obvious insights, tensions, and actionable takeaways from documents and webpages.

**Triggers:** `what am I missing`, `analyze this`, `key insights`, `critique this`, `break this down`

**Key features:**
- Identifies 3-5 non-obvious insights not explicitly stated by the author
- Surfaces internal tensions, contradictions, and unanswered questions
- Extracts actionable "so what" for time-strapped readers
- Context-aware analysis for research papers, business plans, meeting notes, and news articles

### interview-me

Conducts a deep, iterative interview to extract detailed requirements from the user and writes them to a spec file.

**Triggers:** Before building something complex from a rough spec; when a spec.md exists but lacks depth.

**Key features:**
- Reads an existing spec.md as starting context
- Asks in-depth, non-obvious questions covering technical implementation, UI/UX, and tradeoffs
- Iterative interview process until coverage is complete
- Writes finalized output spec back to file

### qwen

Wraps the Qwen Code CLI in strict JSON enforcement with retry logic and configurable environment.

**Triggers:** `ask qwen`, `qwen help`, `consult qwen`

**Key features:**
- Strict JSON-only output enforcement via prompt wrapping
- Automatic retry with progressively stricter prompts on invalid JSON
- Configurable via environment variables (`QWEN_CMD`, `QWEN_ARGS`, `QWEN_TIMEOUT`)

### wordpress-php-dev

WordPress PHP plugin development using Test-Driven Development (TDD) and functional programming principles.

**Triggers:** Creating WordPress plugins, writing WordPress PHP code, setting up testing infrastructure, implementing TDD workflows.

**Key features:**
- Full TDD cycle (Red-Green-Refactor) with Composer-driven commands
- Functional programming patterns: pure functions, immutability, function composition
- PHPUnit + Brain Monkey for unit and integration testing
- PSR-12 compliance enforced with phpcs/phpcbf
- Plugin initialization script generates complete scaffold
- Conventional commit messages and feature-branch git workflow

### writing-clearly-and-concisely

Applies Strunk's *Elements of Style* rules to any prose humans will read.

**Triggers:** Any time prose is written for a human audience: documentation, commit messages, PR descriptions, error messages, UI copy, reports.

**Key features:**
- 18 core rules spanning grammar, punctuation, and composition
- Active voice, positive form, concrete language, omit needless words
- Common misused words/expressions reference
- Token-budget aware: loads the full guide only when editing prose

## Using Skills

Invoke a skill with `/skill-name` in Claude Code, or Claude will suggest relevant skills based on your request.

For more information, see the [Claude Code documentation](https://github.com/anthropics/claude-code).
