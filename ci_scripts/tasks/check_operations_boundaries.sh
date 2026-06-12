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

internal_collaborator_pattern='(RecipeService|RecipeFormService|RecipeTopReturnTargetService|DailyRecipeSuggestionService|RecipeBlurbService|RecipeImageConceptService|DiaryService|DiaryTopSuggestionService|TagService|PhotoService|DataResetService|CookleDataArchiveService|DetachedObjectCleanupService)'

collaborator_matches=$(
  rg \
    --line-number \
    "\\b${internal_collaborator_pattern}\\b" \
    "${surface_sources[@]}" \
    -g '*.swift' || true
)

if [[ -n "$collaborator_matches" ]]; then
  echo "Operations boundary check failed." >&2
  echo "Delivery surfaces must call public *Operations facades instead of internal library collaborators:" >&2
  echo "$collaborator_matches" >&2
  exit 1
fi

echo "Operations boundary check passed."
