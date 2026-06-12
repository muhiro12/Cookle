#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"
repository_root=$CI_TASK_REPOSITORY_ROOT

surface_sources=(
  "$repository_root/Cookle/Sources"
  "$repository_root/Widgets/Sources"
  "$repository_root/Watch/Sources"
)

service_pattern='(RecipeService|RecipeFormService|DiaryService|TagService|PhotoService|DataResetService)'

service_matches=$(
  rg \
    --line-number \
    "\\b${service_pattern}\\b" \
    "${surface_sources[@]}" \
    -g '*.swift' || true
)

if [[ -n "$service_matches" ]]; then
  echo "Operations boundary check failed." >&2
  echo "Delivery surfaces must call public *Operations facades instead of service collaborators:" >&2
  echo "$service_matches" >&2
  exit 1
fi

echo "Operations boundary check passed."
