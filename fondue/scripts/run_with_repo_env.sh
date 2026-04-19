#!/usr/bin/env bash
# Runs `flutter run` with Gemini keys available as compile-time defines (works on device/simulator).
#
# Key resolution (first match wins):
#   1. `fondue/.env` via --dart-define-from-file (same file you already use locally)
#   2. Process environment: GOOGLE_GENERATIVE_AI_API_KEY, GEMINI_API_KEY, GOOGLE_GEMINI_KEY
#      (e.g. Infisical: `infisical run -- bash fondue/scripts/run_with_repo_env.sh`)
#   3. Repo-root `.env.local`
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
FONDUE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
ENV_FILE="$REPO_ROOT/.env.local"

if [[ -f "$FONDUE_ROOT/.env" ]]; then
  cd "$FONDUE_ROOT"
  exec flutter run --dart-define-from-file=".env" "$@"
fi

read_env_value() {
  local key="$1"
  grep -E "^${key}=" "$ENV_FILE" 2>/dev/null | tail -1 \
    | sed "s/^${key}=//" | tr -d '\r' | sed 's/^"//;s/"$//'
}

KEY="${GOOGLE_GENERATIVE_AI_API_KEY:-}"
if [[ -z "$KEY" ]]; then KEY="${GEMINI_API_KEY:-}"; fi
if [[ -z "$KEY" ]]; then KEY="${GOOGLE_GEMINI_KEY:-}"; fi

if [[ -z "$KEY" ]] && [[ -f "$ENV_FILE" ]]; then
  KEY="$(read_env_value GOOGLE_GENERATIVE_AI_API_KEY)"
  if [[ -z "$KEY" ]]; then KEY="$(read_env_value GEMINI_API_KEY)"; fi
  if [[ -z "$KEY" ]]; then KEY="$(read_env_value GOOGLE_GEMINI_KEY)"; fi
fi

if [[ -z "$KEY" ]]; then
  echo "No Gemini API key found." >&2
  echo "  Set GOOGLE_GENERATIVE_AI_API_KEY (or GEMINI_API_KEY / GOOGLE_GEMINI_KEY) in the environment, e.g.:" >&2
  echo "    infisical run -- bash fondue/scripts/run_with_repo_env.sh" >&2
  echo "  Or add the key to $ENV_FILE and run:" >&2
  echo "    bash fondue/scripts/run_with_repo_env.sh" >&2
  exit 1
fi

cd "$FONDUE_ROOT"
exec flutter run --dart-define=GOOGLE_GENERATIVE_AI_API_KEY="${KEY}" "$@"
