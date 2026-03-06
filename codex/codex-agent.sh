#!/usr/bin/env bash
set -euo pipefail

# codex-agent.sh
# Wrapper around the Codex CLI that enforces JSON-only output and retries once
# if the first response is not valid JSON.
#
# Usage examples:
#   ./codex-agent.sh "Summarize this text..."
#   echo "Summarize this..." | ./codex-agent.sh
#   ./codex-agent.sh '{"prompt":"...","context":"...","schema":{...}}'
#
# Environment:
#   CODEX_CMD      (default: codex)
#   CODEX_ARGS     (default: empty)  # appended after `codex exec`
#   CODEX_TIMEOUT  (default: 60)

CODEX_CMD="${CODEX_CMD:-codex}"
CODEX_ARGS="${CODEX_ARGS:-}"
CODEX_TIMEOUT="${CODEX_TIMEOUT:-60}"

# 1. Dependency Checks
if ! command -v jq >/dev/null 2>&1; then
  echo '{"ok":false,"error":{"code":"missing_dependency","message":"jq is required"}}'
  exit 2
fi

# 2. Input Handling (Arg 1 or Stdin)
if [ -n "${1:-}" ]; then
  INPUT_RAW="$1"
else
  INPUT_RAW="$(cat)"
fi

if [ -z "${INPUT_RAW// }" ]; then
  echo '{"ok":false,"error":{"code":"no_input","message":"No input provided"}}'
  exit 1
fi

# 3. Parse Input (JSON vs Text)
IS_JSON_INPUT="false"
if printf '%s' "$INPUT_RAW" | jq -e . >/dev/null 2>&1; then
  IS_JSON_INPUT="true"
fi

PROMPT=""
SCHEMA_JSON=""
CONTEXT=""

if [ "$IS_JSON_INPUT" = "true" ]; then
  PROMPT="$(printf '%s' "$INPUT_RAW" | jq -r 'if type=="object" and (.prompt? | type=="string") then .prompt else "" end')"
  SCHEMA_JSON="$(printf '%s' "$INPUT_RAW" | jq -c 'if type=="object" and (.schema? != null) then .schema else empty end' || true)"
  CONTEXT="$(printf '%s' "$INPUT_RAW" | jq -r 'if type=="object" and (.context? | type=="string") then .context else "" end')"
else
  PROMPT="$INPUT_RAW"
fi

if [ -z "${PROMPT// }" ] && [ "$IS_JSON_INPUT" = "true" ]; then
  echo '{"ok":false,"error":{"code":"no_prompt","message":"No prompt field found in JSON input"}}'
  exit 1
fi

# 4. Construct Wrapper
WRAPPER_HEADER=$(cat <<'EOF2'
You are a JSON-only response engine.

Rules:
- Output ONLY valid JSON (no markdown, no code fences, no commentary).
- Do not include trailing commas.
- Do not include any keys not requested by the schema (if provided).
- If you cannot comply, output exactly:
  {"error":{"code":"cannot_comply","message":"<short reason>"}}

EOF2
)

WRAPPER_SCHEMA=""
if [ -n "$SCHEMA_JSON" ]; then
  WRAPPER_SCHEMA=$(jq -nc --arg schema "$SCHEMA_JSON" '"You MUST conform to this JSON Schema (draft-agnostic). Return an instance that validates:\n" + $schema + "\n\n"')
  WRAPPER_SCHEMA="$(printf '%s' "$WRAPPER_SCHEMA" | jq -r .)"
fi

WRAPPER_CONTEXT=""
if [ -n "${CONTEXT// }" ]; then
  WRAPPER_CONTEXT=$(cat <<EOF2
Context (may be empty):
$CONTEXT

EOF2
)
fi

FINAL_PROMPT="$WRAPPER_HEADER$WRAPPER_SCHEMA$WRAPPER_CONTEXT""User request:
$PROMPT
"

# 5. Execution Logic
run_codex () {
  local prompt="$1"

  if command -v "${CODEX_CMD}" >/dev/null 2>&1; then
    # Try to find a timeout command
    local TIMEOUT_BIN=""
    if command -v timeout >/dev/null 2>&1; then
      TIMEOUT_BIN="timeout"
    elif command -v gtimeout >/dev/null 2>&1; then
      TIMEOUT_BIN="gtimeout"
    fi

    # Ensure --skip-git-repo-check is always set (required in your codex skill guide)
    local ARGS="${CODEX_ARGS}"
    if [[ ! "$ARGS" =~ --skip-git-repo-check ]]; then
      ARGS="--skip-git-repo-check $ARGS"
    fi

    # Prefer piping prompt to stdin; suppress stderr by default to avoid "thinking" noise.
    if [ -n "$TIMEOUT_BIN" ]; then
      # shellcheck disable=SC2086
      printf '%s' "$prompt" | "$TIMEOUT_BIN" "${CODEX_TIMEOUT}" "${CODEX_CMD}" exec ${ARGS} 2>/dev/null
    else
      # shellcheck disable=SC2086
      printf '%s' "$prompt" | "${CODEX_CMD}" exec ${ARGS} 2>/dev/null
    fi
  else
    # Mock fallback if codex command is missing
    cat <<EOF2
{
  "mock_response": true,
  "status": "success",
  "message": "Codex CLI not found, returning mock response.",
  "response": "{\"status\": \"mocked\", \"message\": \"this is a mock response because codex was not found\"}"
}
EOF2
  fi
}

extract_json () {
  python3 -c "
import sys, json, re

def find_json(text):
    if not text: return None, None
    for m in re.finditer(r'[\\{\\[]', text):
        start = m.start()
        for end in range(len(text)-1, start, -1):
            if (text[start] == '{' and text[end] == '}') or (text[start] == '[' and text[end] == ']'):
                chunk = text[start:end+1]
                try:
                    return json.loads(chunk), chunk
                except: continue
    return None, None

s = sys.stdin.read()

# 1. Try finding a wrapper object first
cli_data, cli_raw = find_json(s)
if cli_data:
    res_text = ''
    if isinstance(cli_data, dict):
        for k in ['response', 'text', 'content', 'candidates']:
            if k in cli_data:
                if k == 'candidates' and isinstance(cli_data[k], list) and cli_data[k]:
                    c = cli_data[k][0]
                    if isinstance(c, dict) and 'content' in c and isinstance(c['content'], dict) and 'parts' in c['content']:
                        res_text = ''.join([p.get('text', '') for p in c['content'].get('parts', []) if isinstance(p, dict)])
                    elif isinstance(c, dict) and 'text' in c:
                        res_text = c.get('text', '')
                    break
                else:
                    res_text = str(cli_data[k])
                    break
        else:
            res_text = cli_raw
    else:
        res_text = cli_raw

    # 2. Find model JSON inside the wrapper
    m_data, m_raw = find_json(res_text)
    if m_data is not None:
        print(m_raw.strip())
        sys.exit(0)
    elif res_text:
        print(res_text.strip())
        sys.exit(0)

# 3. Last-ditch: find any JSON in the full output
v, r = find_json(s)
if v is not None:
    print(r.strip())
    sys.exit(0)

sys.exit(1)
"
}

attempt_once () {
  local prompt="$1"
  local raw out_json

  raw="$(run_codex "$prompt" 2>&1 || true)"
  out_json="$(printf '%s' "$raw" | extract_json || true)"

  if [ -n "$out_json" ] && printf '%s' "$out_json" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$out_json"
    return 0
  fi

  jq -nc --arg raw "$raw" '{ok:false,error:{code:"invalid_json_from_codex",message:"Codex output was not valid JSON",raw:$raw}}'
  return 1
}

# 6. Retry Logic
OUT="$(attempt_once "$FINAL_PROMPT" || true)"
if printf '%s' "$OUT" | jq -e '.ok == false and .error.code == "invalid_json_from_codex"' >/dev/null 2>&1; then
  FINAL_PROMPT_2="$WRAPPER_HEADER$WRAPPER_SCHEMA$WRAPPER_CONTEXT""User request:
$PROMPT

REMINDER: Output ONLY JSON. No other characters before or after.
"

  OUT2="$(attempt_once "$FINAL_PROMPT_2" || true)"
  if printf '%s' "$OUT2" | jq -e '.ok == false' >/dev/null 2>&1; then
    FIRST_RAW="$(printf '%s' "$OUT" | jq -r '.error.raw // ""' 2>/dev/null || true)"
    jq -nc --arg first_raw "$FIRST_RAW" --arg second "$OUT2" '
      (try ( $second | fromjson ) catch {"ok":false,"error":{"code":"unknown","message":"failed"}}) as $e
      | $e
      | .error.first_attempt_raw = $first_raw
    '
    exit 1
  fi

  printf '%s' "$OUT2"
  exit 0
fi

printf '%s' "$OUT"
exit 0
