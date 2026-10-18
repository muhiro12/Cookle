#!/usr/bin/env bash
set -euo pipefail

argument_count=$#
if [[ $argument_count -ne 0 ]]; then
  echo "This script does not accept arguments." >&2
  exit 2
fi

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repository_root=$(cd "$script_directory/../.." && pwd)
cd "$repository_root"

source "$script_directory/../lib/task_utils.sh"

ci_task_require_command "rg" "Install ripgrep so repository rule checks can scan source files."

declare -a errors=()

append_error() {
  errors+=("$1")
}

schemes_directory="Cookle.xcodeproj/xcshareddata/xcschemes"
tests_directory="CookleTests"
legacy_test_script="ci_scripts/tasks/test_app.sh"

if [[ -d "$tests_directory" ]]; then
  append_error "Repository-owned app test directory must not exist at $tests_directory."
fi

if [[ -e "$legacy_test_script" ]]; then
  append_error "Legacy app test entrypoint must not exist at $legacy_test_script."
fi

if ! python3 "$repository_root/ci_scripts/lib/check_project_configuration.py" Cookle.xcodeproj --check test-posture; then
  append_error "Cookle.xcodeproj must not define a unit test target."
fi

if [[ -d "$schemes_directory" ]]; then
  matches=$(ci_task_rg -n 'CookleTests|CookleTests\.xctest' "$schemes_directory")
  if [[ -n "$matches" ]]; then
    append_error "Shared Xcode schemes must not reference CookleTests."
  fi
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  printf 'Cookle test posture guardrail failures:\n' >&2
  for error_message in "${errors[@]}"; do
    printf ' - %s\n' "$error_message" >&2
  done
  exit 1
fi

echo "Cookle test posture guardrails passed."
