#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"
repository_root=$CI_TASK_REPOSITORY_ROOT

config_path="$repository_root/.periphery.yml"
index_store_path="$repository_root/.build/ci/shared/DerivedData/Index.noindex/DataStore"

if [[ ! -f "$config_path" ]]; then
  echo "Missing Periphery configuration: $config_path" >&2
  exit 1
fi

if ! command -v periphery >/dev/null 2>&1; then
  echo "Missing command: periphery" >&2
  echo "Install Periphery manually before running this task." >&2
  echo "Example: brew install periphery" >&2
  exit 1
fi

if [[ ! -d "$index_store_path" ]]; then
  echo "Periphery index store not found: $index_store_path" >&2
  echo "Run 'bash ci_scripts/tasks/build_app.sh' first to refresh the index store." >&2
  exit 1
fi

exec periphery scan
