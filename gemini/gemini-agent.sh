#!/usr/bin/env bash
set -euo pipefail

# gemini-agent.sh
# Adapted from user provided claude_to_gemini.sh
#
# Usage examples:
#   ./gemini-agent.sh "Summarize this text..."
#   echo "Summarize this..." | ./gemini-agent.sh
#
# Environment:
#   GEMINI_CMD   (default: gemini)
#   GEMINI_ARGS  (default: empty)
#   GEMINI_TIMEOUT (default: 60)

GEMINI_CMD="${GEMINI_CMD:-gemini}"
GEMINI_ARGS="${GEMINI_ARGS:-}"
GEMINI_TIMEOUT="${GEMINI_TIMEOUT:-60}"

# 1. Dependency Checks
if ! command -v jq >/dev/null 2>&1; then
  echo '{"ok":false,"error":{"code":"missing_dependency","message":"jq is required"}}'
  exit 2
fi

# 2. Input Handling (Arg 1 or Stdin)
if [ -n "${1:-}" ]; then
  INPUT_RAW="$1"
else
  # Read from stdin if no arg provided
  # If stdin is empty (interactive usage without pipe), this might hang, 
  # but typical agent usage provides args.
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
    # Fallback if the JSON didn't have a 'prompt' field but was just a raw JSON object meant as a prompt?
    # For now, assume structure. If empty prompt from struct, error.
    echo '{"ok":false,"error":{"code":"no_prompt","message":"No prompt field found in JSON input"}}'
    exit 1
fi

# 4. Construct Wrapper
WRAPPER_HEADER=$(cat <<'EOF'
You are a JSON-only response engine.

Rules:
- Output ONLY valid JSON (no markdown, no code fences, no commentary).
- Do not include trailing commas.
- Do not include any keys not requested by the schema (if provided).
- If you cannot comply, output exactly:
  {"error":{"code":"cannot_comply","message":"<short reason>"}}

EOF
)

WRAPPER_SCHEMA=""
if [ -n "$SCHEMA_JSON" ]; then
  WRAPPER_SCHEMA=$(jq -nc --arg schema "$SCHEMA_JSON" '"You MUST conform to this JSON Schema (draft-agnostic). Return an instance that validates:\n" + $schema + "\n\n"')
  WRAPPER_SCHEMA="$(printf '%s' "$WRAPPER_SCHEMA" | jq -r .)"
fi

WRAPPER_CONTEXT=""
if [ -n "${CONTEXT// }" ]; then
  WRAPPER_CONTEXT=$(cat <<EOF
Context (may be empty):
$CONTEXT

EOF
)
fi

FINAL_PROMPT="$WRAPPER_HEADER$WRAPPER_SCHEMA$WRAPPER_CONTEXT""User request:
$PROMPT
"

# 5. Execution Logic
run_gemini () {
  local prompt="$1"
  
  if command -v "${GEMINI_CMD}" >/dev/null 2>&1; then
     # Try to find a timeout command
     local TIMEOUT_BIN=""
     if command -v timeout >/dev/null 2>&1; then
       TIMEOUT_BIN="timeout"
     elif command -v gtimeout >/dev/null 2>&1; then
       TIMEOUT_BIN="gtimeout"
     fi

     # Ensure --output-format json is used if not already in GEMINI_ARGS
     local ARGS="${GEMINI_ARGS}"
     if [[ ! "$ARGS" =~ "--output-format" ]]; then
       ARGS="$ARGS --output-format json"
     fi

     if [ -n "$TIMEOUT_BIN" ]; then
       "$TIMEOUT_BIN" "${GEMINI_TIMEOUT}" "${GEMINI_CMD}" ${ARGS} <<<"$prompt"
     else
       # Fallback: run without timeout
       "${GEMINI_CMD}" ${ARGS} <<<"$prompt"
     fi
  else
     # Mock Fallback if gemini command is missing
     cat <<EOF
{
  "mock_response": true,
  "status": "success",
  "message": "Gemini CLI not found, returning mock response.",
  "response": "{\"status\": \"mocked\", \"message\": \"this is a mock response because gemini was not found\"}"
}
EOF
  fi
}

extract_json () {
  python3 -c "
import sys, json, re

def find_json(text):
    if not text: return None, None
    for m in re.finditer(r'[\{\[]', text):
        start = m.start()
        for end in range(len(text)-1, start, -1):
            if (text[start] == '{' and text[end] == '}') or (text[start] == '[' and text[end] == ']'):
                chunk = text[start:end+1]
                try:
                    return json.loads(chunk), chunk
                except: continue
    return None, None

s = sys.stdin.read()
# 1. Try finding CLI wrapper
cli_data, cli_raw = find_json(s)
if cli_data:
    res_text = ''
    if isinstance(cli_data, dict):
        for k in ['response', 'text', 'content', 'candidates']:
            if k in cli_data:
                if k == 'candidates' and isinstance(cli_data[k], list) and cli_data[k]:
                    c = cli_data[k][0]
                    if 'content' in c and 'parts' in c['content']:
                        res_text = ''.join([p.get('text', '') for p in c['content']['parts']])
                    elif 'text' in c: res_text = c['text']
                    break
                else:
                    res_text = str(cli_data[k])
                    break
        else: res_text = cli_raw
    else: res_text = cli_raw
    
    # 2. Find model JSON in response
    m_data, m_raw = find_json(res_text)
    if m_data is not None:
        print(m_raw.strip())
        sys.exit(0)
    elif res_text:
        print(res_text.strip())
        sys.exit(0)

# 3. Last ditch
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
  raw="$(run_gemini "$prompt" 2>&1 || true)"
  out_json="$(printf '%s' "$raw" | extract_json || true)"

  if [ -n "$out_json" ] && printf '%s' "$out_json" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$out_json"
    return 0
  fi

  jq -nc --arg raw "$raw" '{ok:false,error:{code:"invalid_json_from_gemini",message:"Gemini output was not valid JSON",raw:$raw}}'
  return 1
}

# 6. Retry Logic
OUT="$(attempt_once "$FINAL_PROMPT" || true)"
if printf '%s' "$OUT" | jq -e '.ok == false and .error.code == "invalid_json_from_gemini"' >/dev/null 2>&1; then
  # Attempt 2: Stricter
  FINAL_PROMPT_2="$WRAPPER_HEADER$WRAPPER_SCHEMA$WRAPPER_CONTEXT""User request:
$PROMPT

REMINDER: Output ONLY JSON. No other characters before or after.
"
  OUT2="$(attempt_once "$FINAL_PROMPT_2" || true)"
  if printf '%s' "$OUT2" | jq -e '.ok == false' >/dev/null 2>&1; then
     # Return error from 2nd attempt, with raw from 1st
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
