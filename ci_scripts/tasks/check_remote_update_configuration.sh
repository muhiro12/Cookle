#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"

ci_task_require_command "grep" "The configuration check requires the standard grep command."

configuration_file=".config.json"
validator="ci_scripts/tools/RemoteUpdateConfigurationValidator.swift"

if [[ ! -f "$configuration_file" ]]; then
  echo "Remote update configuration is missing: $configuration_file" >&2
  exit 1
fi

if [[ ! -f "$validator" ]]; then
  echo "Remote update configuration validator is missing: $validator" >&2
  exit 1
fi

# Cookle 3.8 requires requiredVersion during decoding. Omitting it makes that
# release fail open instead of leaving an unbounded remote lock available.
set +e
LC_ALL=C grep -Eq '"requiredVersion"[[:space:]]*:' "$configuration_file"
search_status=$?
set -e
if (( search_status > 1 )); then
  echo "Remote update configuration check could not read $configuration_file: grep exited $search_status." >&2
  exit 2
fi
if (( search_status == 0 )); then
  echo "Legacy requiredVersion must not be remotely configurable." >&2
  exit 1
fi

set +e
force_update_matches=$(LC_ALL=C grep -Eo '"forceUpdate"[[:space:]]*:' "$configuration_file")
search_status=$?
set -e
if (( search_status > 1 )); then
  echo "Remote update configuration check could not read $configuration_file: grep exited $search_status." >&2
  exit 2
fi
force_update_count=0
while IFS= read -r match; do
  if [[ -n "$match" ]]; then
    ((force_update_count += 1))
  fi
done <<<"$force_update_matches"
if [[ "$force_update_count" != "1" ]]; then
  echo "Remote update configuration must contain exactly one forceUpdate key." >&2
  exit 1
fi

module_cache_directory="${CI_SHARED_DIR:-$CI_TASK_REPOSITORY_ROOT/.build/ci/shared}/ModuleCache"
mkdir -p "$module_cache_directory"
xcrun swift -module-cache-path "$module_cache_directory" "$validator" "$configuration_file"

echo "Remote update configuration guardrails passed."
