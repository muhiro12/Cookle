#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"
repository_root=$CI_TASK_REPOSITORY_ROOT

config_path="$repository_root/.periphery.yml"
shared_index_store_path="$repository_root/.build/ci/shared/DerivedData/Index.noindex/DataStore"
index_store_path=""
index_store_modified_at=0

index_store_latest_modified_at() {
  local candidate_path=$1
  local latest_modified_at

  if [[ "$(uname -s)" == "Darwin" ]]; then
    if ! latest_modified_at=$(
      find "$candidate_path" -path '*/units/*' -type f \
        -exec stat -f '%m' {} + 2>/dev/null |
        awk '
          BEGIN { latest = 0 }
          /^[0-9]+$/ && $1 > latest { latest = $1 }
          END { print latest }
        '
    ); then
      latest_modified_at=0
    fi
  else
    if ! latest_modified_at=$(
      find "$candidate_path" -path '*/units/*' -type f \
        -exec stat -c '%Y' {} + 2>/dev/null |
        awk '
          BEGIN { latest = 0 }
          /^[0-9]+$/ && $1 > latest { latest = $1 }
          END { print latest }
        '
    ); then
      latest_modified_at=0
    fi
  fi

  if [[ "$latest_modified_at" =~ ^[0-9]+$ ]] &&
    (( latest_modified_at > 0 )); then
    printf '%s\n' "$latest_modified_at"
    return 0
  fi

  if [[ "$(uname -s)" == "Darwin" ]]; then
    stat -f '%m' "$candidate_path" 2>/dev/null || printf '0\n'
  else
    stat -c '%Y' "$candidate_path" 2>/dev/null || printf '0\n'
  fi
}

consider_index_store() {
  local candidate_path=$1
  local candidate_modified_at

  if [[ ! -d "$candidate_path" ]]; then
    return 0
  fi

  candidate_modified_at=$(index_store_latest_modified_at "$candidate_path")
  if [[ ! "$candidate_modified_at" =~ ^[0-9]+$ ]]; then
    candidate_modified_at=0
  fi

  if [[ -z "$index_store_path" ]] ||
    (( candidate_modified_at > index_store_modified_at )); then
    index_store_path=$candidate_path
    index_store_modified_at=$candidate_modified_at
  fi
}

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

if [[ -n "${PERIPHERY_INDEX_STORE_PATH:-}" ]]; then
  index_store_path=$PERIPHERY_INDEX_STORE_PATH
  if [[ "$index_store_path" != /* ]]; then
    index_store_path="$repository_root/$index_store_path"
  fi
  if [[ ! -d "$index_store_path" ]]; then
    echo "Periphery index store not found: $index_store_path" >&2
    echo "PERIPHERY_INDEX_STORE_PATH must name an existing DataStore directory." >&2
    exit 1
  fi
else
  consider_index_store "$shared_index_store_path"

  if [[ -n "${HOME:-}" ]]; then
    shopt -s nullglob
    for candidate_path in \
      "$HOME"/Library/Developer/Xcode/DerivedData/Cookle-*/Index.noindex/DataStore
    do
      consider_index_store "$candidate_path"
    done
    shopt -u nullglob
  fi
fi

if [[ -z "$index_store_path" ]]; then
  echo "No Cookle Periphery index store was found." >&2
  echo "Build the Cookle scheme with the available Xcode-native integration first." >&2
  echo "The task checks repository shared and default Xcode DerivedData locations." >&2
  echo "Set PERIPHERY_INDEX_STORE_PATH for another DataStore location." >&2
  exit 1
fi

index_store_path=$(cd "$index_store_path" && pwd -P)
echo "Using Periphery index store: $index_store_path"
exec periphery scan --index-store-path "$index_store_path"
