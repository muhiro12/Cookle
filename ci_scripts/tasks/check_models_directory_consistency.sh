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

source "$script_directory/../lib/task_utils.sh"

ci_task_require_command "rg" "Install ripgrep so repository rule checks can scan source files."

set +e
matches=$(
  rg --line-number \
    --glob 'Cookle/Sources/**/Models/*.swift' \
    --glob 'Widgets/Sources/**/Models/*.swift' \
    --glob 'Watch/Sources/**/Models/*.swift' \
    '@ViewBuilder|: View\b|: LabelStyle\b' \
    Cookle/Sources Widgets/Sources Watch/Sources
)
ripgrep_status=$?
set -e

# ripgrep exits 1 when nothing matches, which is the passing case here.
# Anything above that is a real failure and must not be reported as a pass.
if (( ripgrep_status > 1 )); then
  echo "Models directory consistency check could not run: ripgrep exited $ripgrep_status." >&2
  exit 1
fi

if [[ -n "$matches" ]]; then
  echo "Models directory consistency check failed." >&2
  echo "Move View-related code out of */Sources/**/Models/." >&2
  echo "$matches" >&2
  exit 1
fi

echo "Models directory consistency check passed."
