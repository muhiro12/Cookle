#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"

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
if rg -q '"requiredVersion"\s*:' "$configuration_file"; then
  echo "Legacy requiredVersion must not be remotely configurable." >&2
  exit 1
fi

force_update_count=$(
  rg --count-matches '"forceUpdate"\s*:' "$configuration_file" || true
)
if [[ "$force_update_count" != "1" ]]; then
  echo "Remote update configuration must contain exactly one forceUpdate key." >&2
  exit 1
fi

xcrun swift "$validator" "$configuration_file"

echo "Remote update configuration guardrails passed."
