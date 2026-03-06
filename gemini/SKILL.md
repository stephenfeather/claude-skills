---
name: gemini
description: Interface with the Gemini agent for operations requiring the Gemini model.
allowed-tools: [Bash]
---

# Gemini Agent

Interact with the Gemini agent. This skill wraps input in strict JSON enforcement prompts and handles retries.

## Routing

**Image generation?** Use the `gemini-image-generator` skill instead. This skill is for text/reasoning tasks only.

## Activation

Triggers: "ask gemini", "gemini help", "consult gemini"

## Features

- **Strict JSON Output**: The agent is prompted to return ONLY valid JSON.
- **Retry Logic**: Automatically retries with stricter prompts if the first response is not valid JSON.
- **Schema Validation**: Supports passing a JSON schema to validate the output against (if supported by the underlying implementation).

## Usage

### Simple Prompt

```bash
# Usage: .claude/skills/gemini/gemini-agent.sh "Your prompt here"
.claude/skills/gemini/gemini-agent.sh "Summarize the history of AI."
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
.claude/skills/gemini/gemini-agent.sh '{"prompt": "...", "schema": {...}}'
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
