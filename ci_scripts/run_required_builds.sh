#!/usr/bin/env bash
set -euo pipefail

argument_count=$#
if [[ $argument_count -ne 0 ]]; then
  echo "This script does not accept arguments." >&2
  exit 2
fi

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repository_root=$(cd "$script_directory/.." && pwd)
cd "$repository_root"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must run inside a git repository." >&2
  exit 1
fi

changed_files=$(
  {
    git diff --name-only --cached
    git diff --name-only
    git ls-files --others --exclude-standard
  } | sed '/^$/d' | sort -u
)

if [[ -z "$changed_files" ]]; then
  echo "No local changes detected."
  exit 0
fi

needs_cookle_build=false
needs_cookle_library_tests=false

if grep -Eq '^Cookle/|^Cookle\.xcodeproj/|^Widgets/' <<<"$changed_files"; then
  needs_cookle_build=true
fi

if grep -Eq '^CookleLibrary/' <<<"$changed_files"; then
  needs_cookle_library_tests=true
fi

if ! $needs_cookle_build && ! $needs_cookle_library_tests; then
  echo "No changes under Cookle/, CookleLibrary/, Widgets/, or Cookle.xcodeproj/."
  exit 0
fi

if $needs_cookle_build; then
  bash ci_scripts/check_models_directory_consistency.sh
  echo "Running Cookle build."
  bash ci_scripts/build_cookle.sh
fi

if $needs_cookle_library_tests; then
  echo "Running CookleLibrary tests."
  bash ci_scripts/test_cookle_library.sh
fi
