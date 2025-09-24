#!/usr/bin/env bash
set -euo pipefail

# Unified xcodebuild test/build runner for a given scheme (Cookle).

SCHEME="${1:-}"
if [[ -z "$SCHEME" ]]; then
  echo "Usage: ci_scripts/xcodebuild_test_scheme.sh <SchemeName> [xcpretty]" >&2
  exit 1
fi

# Optional second arg: 'xcpretty' to pipe logs when available
USE_XCPRETTY="${2:-}"

# Optional action override via env (default: test). If not provided,
# the script tries `test` and auto-falls back to `build` if needed.
ACTION="${ACTION:-}"

PROJECT_PATH="Cookle.xcodeproj"
DERIVED_DATA_PATH="${DERIVED_DATA_PATH:-build/DerivedData}"
RESULTS_DIR="${RESULTS_DIR:-build}"

mkdir -p "$DERIVED_DATA_PATH" "$RESULTS_DIR"

STAMP=$(date +%s)
RESULT_BUNDLE_PATH="$RESULTS_DIR/TestResults_${SCHEME}_${STAMP}.xcresult"

resolve_udid() {
  if [[ -n "${UDID:-}" ]]; then
    echo "$UDID"
    return 0
  fi
  local booted
  booted=$(xcrun simctl list devices | awk -F'[()]' '/Booted/ {print $2; exit}' || true)
  if [[ -n "$booted" ]]; then
    echo "$booted"
    return 0
  fi
  local any
  any=$(xcrun simctl list devices | awk -F'[()]' '/iPhone/ && /(Shutdown|Booted)/ {print $2; exit}' || true)
  if [[ -n "$any" ]]; then
    xcrun simctl boot "$any" >/dev/null 2>&1 || true
    echo "$any"
    return 0
  fi
  echo ""
}

UDID_RESOLVED=$(resolve_udid)

if [[ -n "$UDID_RESOLVED" ]]; then
  DESTINATION=( -destination "id=$UDID_RESOLVED" )
else
  DESTINATION=( -destination "platform=iOS Simulator,OS=latest" )
fi

run_action() {
  local action="$1"
  local -a cmd=(
    xcodebuild
    -project "$PROJECT_PATH"
    -scheme "$SCHEME"
    "${DESTINATION[@]}"
    -derivedDataPath "$DERIVED_DATA_PATH"
    -resultBundlePath "$RESULT_BUNDLE_PATH"
    "$action"
  )
  if [[ "$USE_XCPRETTY" == "xcpretty" ]] && command -v xcpretty >/dev/null 2>&1; then
    set -o pipefail
    "${cmd[@]}" | xcpretty
  else
    "${cmd[@]}"
  fi
}

set -e
if [[ -n "$ACTION" ]]; then
  set -x
  run_action "$ACTION"
else
  set +e
  set -x
  run_action test
  status=$?
  set +x
  if [[ $status -ne 0 ]]; then
    if [[ $status -eq 66 ]] || \
       ( tail -n 25 "$RESULT_BUNDLE_PATH"/Info.plist 2>/dev/null | grep -qi "not currently configured for the test action" ); then
      echo "⚠️  Scheme '$SCHEME' has no test action; falling back to build."
      STAMP2=$(date +%s)
      RESULT_BUNDLE_PATH="$RESULTS_DIR/TestResults_${SCHEME}_${STAMP2}_build.xcresult"
      set -x
      run_action build
      status=$?
      set +x
    fi
  fi
  if [[ $status -ne 0 ]]; then
    echo "❌ xcodebuild failed with status $status" >&2
    exit $status
  fi
fi

echo "\n✅ Finished. Result bundle: $RESULT_BUNDLE_PATH"

