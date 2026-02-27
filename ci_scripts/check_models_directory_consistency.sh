#!/usr/bin/env bash
set -euo pipefail

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repository_root=$(cd "$script_directory/.." && pwd)
cd "$repository_root"

matches=$(
  rg --line-number \
    --glob 'Cookle/Sources/**/Models/*.swift' \
    '@ViewBuilder|: View\b|: LabelStyle\b' \
    Cookle/Sources || true
)

if [[ -n "$matches" ]]; then
  echo "Models directory consistency check failed." >&2
  echo "Move View-related code out of Cookle/Sources/**/Models/." >&2
  echo "$matches" >&2
  exit 1
fi

echo "Models directory consistency check passed."
