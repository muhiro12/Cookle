#!/usr/bin/env bash

CI_TASK_REPOSITORY_ROOT=""

ci_task_require_no_arguments() {
  if [[ $# -ne 0 ]]; then
    echo "This script does not accept arguments." >&2
    exit 2
  fi
}

ci_task_resolve_repository_root() {
  local source_path=$1
  local script_directory

  script_directory=$(cd "$(dirname "$source_path")" && pwd)
  cd "$script_directory/../.." && pwd
}

ci_task_enter_repository() {
  local source_path=$1
  CI_TASK_REPOSITORY_ROOT=$(ci_task_resolve_repository_root "$source_path")
  cd "$CI_TASK_REPOSITORY_ROOT"

  if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    echo "This script must run inside a git repository." >&2
    exit 1
  fi
}

ci_task_require_command() {
  local command_name=$1
  local install_hint=$2

  if command -v "$command_name" >/dev/null 2>&1; then
    return 0
  fi

  echo "Missing required command: $command_name" >&2
  echo "$install_hint" >&2
  exit 1
}

ci_task_should_skip_environment_check() {
  [[ "${CI_SKIP_ENV_CHECK:-0}" == "1" || "${CI_SKIP_ENV_CHECK:-}" == "true" ]]
}
