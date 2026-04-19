#!/usr/bin/env bash
# Build iOS release / IPA for TestFlight or App Store with Gemini keys baked in.
#
# `String.fromEnvironment` is fixed at compile time. Xcode Archive uses the same
# DART_DEFINES as the last `flutter build`; run this before uploading, or keys
# can be missing in release.
#
# Usage:
#   bash fondue/scripts/build_release_ios.sh
#   bash fondue/scripts/build_release_ios.sh ios
#   bash fondue/scripts/build_release_ios.sh ipa
#
# Key source (first match):
#   1. fondue/.env via --dart-define-from-file
#   2. CI: GOOGLE_GEMINI_KEY or GOOGLE_GENERATIVE_AI_API_KEY in the environment
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
FONDUE_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
cd "$FONDUE_ROOT"

MODE=ipa
if [[ "${1:-}" == "ipa" || "${1:-}" == "ios" ]]; then
  MODE="$1"
  shift
fi

extra_args=()
if [[ -f .env ]]; then
  extra_args+=(--dart-define-from-file=.env)
elif [[ -n "${GOOGLE_GEMINI_KEY:-}" ]]; then
  extra_args+=(--dart-define="GOOGLE_GEMINI_KEY=${GOOGLE_GEMINI_KEY}")
elif [[ -n "${GOOGLE_GENERATIVE_AI_API_KEY:-}" ]]; then
  extra_args+=(--dart-define="GOOGLE_GENERATIVE_AI_API_KEY=${GOOGLE_GENERATIVE_AI_API_KEY}")
elif [[ -n "${GEMINI_API_KEY:-}" ]]; then
  extra_args+=(--dart-define="GEMINI_API_KEY=${GEMINI_API_KEY}")
else
  echo "No Gemini key: add fondue/.env or set GOOGLE_GEMINI_KEY / GOOGLE_GENERATIVE_AI_API_KEY." >&2
  exit 1
fi

case "$MODE" in
  ipa)
    exec flutter build ipa --release "${extra_args[@]}" "$@"
    ;;
  ios)
    exec flutter build ios --release --no-codesign "${extra_args[@]}" "$@"
    ;;
  *)
    echo "Usage: $0 [ipa|ios] [extra flutter args...]" >&2
    echo "  ipa  — build release .ipa for TestFlight / App Store (default)" >&2
    echo "  ios  — build ios release; then open Xcode and Archive if you prefer" >&2
    exit 1
    ;;
esac
