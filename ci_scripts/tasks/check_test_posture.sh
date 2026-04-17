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

declare -a errors=()

append_error() {
  errors+=("$1")
}

project_file="Cookle.xcodeproj/project.pbxproj"
tests_directory="CookleTests"
legacy_test_script="ci_scripts/tasks/test_app.sh"

if [[ -d "$tests_directory" ]]; then
  append_error "Repository-owned app test directory must not exist at $tests_directory."
fi

if [[ -e "$legacy_test_script" ]]; then
  append_error "Legacy app test entrypoint must not exist at $legacy_test_script."
fi

if rg -n 'CookleTests|com\.apple\.product-type\.bundle\.unit-test|CookleTests\.xctest' "$project_file" >/dev/null; then
  append_error "Cookle.xcodeproj must not define a CookleTests unit test target."
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  printf 'Cookle test posture guardrail failures:\n' >&2
  for error_message in "${errors[@]}"; do
    printf ' - %s\n' "$error_message" >&2
  done
  exit 1
fi

echo "Cookle test posture guardrails passed."
