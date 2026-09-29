#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$script_directory/../lib/task_utils.sh"

ci_task_require_no_arguments "$@"
ci_task_enter_repository "${BASH_SOURCE[0]}"

ci_task_require_command "python3" "Install the Xcode command-line tools with Python 3 support."

python3 "$CI_TASK_REPOSITORY_ROOT/ci_scripts/lib/check_string_catalog_vocabulary.py"

echo "String catalog vocabulary check passed."
