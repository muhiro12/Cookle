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

if [[ -n "${CI_RUN_COMMANDS_FILE:-}" ]]; then
  source "$repository_root/ci_scripts/lib/ci_run_artifacts.sh"
  ci_run_capture_command "$CI_RUN_COMMANDS_FILE" pre-commit run --all-files
fi

if ! command -v pre-commit >/dev/null 2>&1; then
  echo "pre-commit is not installed. Install it and retry." >&2
  echo "Install with: pipx install pre-commit or brew install pre-commit" >&2
  exit 1
fi

echo "Running pre-commit checks..."
pre-commit run --all-files
