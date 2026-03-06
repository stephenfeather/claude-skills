---
name: codex
description: Interface with the Codex agent for operations requiring the Codex model.
allowed-tools: [Bash]
---

# Codex Agent

Interact with the Codex agent. This skill wraps input in strict JSON enforcement prompts and handles retries.

## Activation

Triggers: "ask codex", "codex help", "consult codex"

## Features

- **Strict JSON Output**: The agent is prompted to return ONLY valid JSON.
- **Retry Logic**: Automatically retries with stricter prompts if the first response is not valid JSON.
- **Schema Validation**: Supports passing a JSON schema to validate the output against (if supported by the underlying implementation).

## Usage

### Simple Prompt

```bash
# Usage: .claude/skills/codex/codex-agent.sh "Your prompt here"
.claude/skills/codex/codex-agent.sh "Summarize the history of AI."
```

### JSON Request (Advanced)

You can pass a JSON object with `prompt`, `context`, and `schema`.

```json
{
  "prompt": "Generate a user profile",
  "schema": {
    "type": "object",
    "properties": {
      "username": {"type": "string"},
      "age": {"type": "integer"}
    }
  }
}
```

```bash
.claude/skills/codex/codex-agent.sh '{"prompt": "...", "schema": {...}}'
```

### Response Format

Success:
```json
{
  "key": "value",
  ...
}
```

Error:
```json
{
  "ok": false,
  "error": {
    "code": "error_code",
    "message": "Description"
  }
}
```
