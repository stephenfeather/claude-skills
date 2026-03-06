---
name: qwen
description: Interface with the Qwen Code CLI agent for operations requiring the Qwen model.
allowed-tools: [Bash]
---

# Qwen Agent

Interact with the Qwen agent. This skill wraps input in strict JSON enforcement prompts and handles retries.

## Activation

Triggers: "ask qwen", "qwen help", "consult qwen"

## Features

- **Strict JSON Output**: The agent is prompted to return ONLY valid JSON.
- **Retry Logic**: Automatically retries with stricter prompts if the first response is not valid JSON.
- **Schema Support**: Supports passing a JSON schema to constrain/shape the output (best-effort; enforced by instruction).

## Usage

### Simple Prompt

```bash
# Usage: .claude/skills/qwen/qwen-agent.sh "Your prompt here"
.claude/skills/qwen/qwen-agent.sh "Summarize the history of AI."
```

### JSON Request (Advanced)

You can pass a JSON object with `prompt`, `context`, and `schema`.

```json
{
  "prompt": "Generate a user profile",
  "context": "Target audience: internal admin tools",
  "schema": {
    "type": "object",
    "properties": {
      "username": {"type": "string"},
      "age": {"type": "integer"}
    },
    "required": ["username", "age"],
    "additionalProperties": false
  }
}
```

```bash
.claude/skills/qwen/qwen-agent.sh '{"prompt":"...","context":"...","schema":{...}}'
```

### Response Format

Success (JSON only):
```json
{
  "key": "value"
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

## Environment Variables

- `QWEN_CMD` (default: `qwen`)
- `QWEN_ARGS` (default: empty)
- `QWEN_TIMEOUT` (default: `60`)
- `QWEN_APPROVAL_MODE` (default: `plan`)
