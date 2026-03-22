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

package_manifest="CookleLibrary/Package.swift"
package_resolved="CookleLibrary/Package.resolved"
project_file="Cookle.xcodeproj/project.pbxproj"

declare -a errors=()

append_error() {
  errors+=("$1")
}

manifest_block=$(
  awk '
    /url: "https:\/\/github.com\/muhiro12\/MHPlatform\.git"/ {
      in_block = 1
    }
    in_block {
      print
    }
    in_block && /\)/ {
      exit
    }
  ' "$package_manifest"
)

if [[ -z "$manifest_block" ]]; then
  append_error "MHPlatform remote dependency was not found in $package_manifest."
else
  if grep -Eq 'path:\s*"[^"]*MHPlatform' <<<"$manifest_block"; then
    append_error "MHPlatform must not use a local path dependency in $package_manifest."
  fi

  if grep -Eq 'branch:\s*"' <<<"$manifest_block"; then
    append_error "MHPlatform must not follow a floating branch in $package_manifest."
  fi

  if ! grep -Eq '^\s*(revision|exact):\s*"' <<<"$manifest_block"; then
    append_error "MHPlatform must be pinned with revision or exact in $package_manifest."
  fi
fi

if grep -Eq '"branch"\s*:' "$package_resolved"; then
  append_error "MHPlatform resolved state must not contain branch tracking in $package_resolved."
fi

remote_package_block=$(
  awk '
    /XCRemoteSwiftPackageReference "MHPlatform" \*\/ = \{/ {
      in_block = 1
    }
    in_block {
      print
      open_braces += gsub(/\{/, "{")
      close_braces += gsub(/\};/, "};")
    }
    in_block && open_braces > 0 && open_braces == close_braces {
      exit
    }
  ' "$project_file"
)

if [[ -z "$remote_package_block" ]]; then
  append_error "MHPlatform remote package reference was not found in $project_file."
else
  if grep -Eq 'kind = branch;|branch = ' <<<"$remote_package_block"; then
    append_error "MHPlatform must not follow a floating branch in $project_file."
  fi

  if ! grep -Eq 'kind = (revision|exactVersion);' <<<"$remote_package_block"; then
    append_error "MHPlatform must be pinned to revision or exactVersion in $project_file."
  fi
fi

if rg -n 'XCLocalSwiftPackageReference "MHPlatform"|relativePath = .*MHPlatform' "$project_file" >/dev/null; then
  append_error "MHPlatform must not be referenced as a local Xcode package in $project_file."
fi

if rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' CookleLibrary/Sources CookleLibrary/Tests >/dev/null; then
  append_error "CookleLibrary must not import the full MHPlatform umbrella."
fi

if rg -n 'name:\s*"MHPlatform",\s*package:\s*"MHPlatform"|productName = MHPlatform;' "$package_manifest" >/dev/null; then
  append_error "CookleLibrary must not depend on the full MHPlatform umbrella."
fi

widgets_target_block=$(
  awk '
    /\/\* Widgets \*\/ = \{/ {
      in_block = 1
    }
    in_block {
      print
    }
    in_block && /^\t\t};$/ {
      exit
    }
  ' "$project_file"
)

if grep -Eq 'MHPlatform /\* MHPlatform \*/|productName = MHPlatform;' <<<"$widgets_target_block"; then
  append_error "Widgets must not depend on the full MHPlatform umbrella."
fi

tests_target_block=$(
  awk '
    /\/\* CookleTests \*\/ = \{/ {
      in_block = 1
    }
    in_block {
      print
    }
    in_block && /^\t\t};$/ {
      exit
    }
  ' "$project_file"
)

if grep -Eq 'MHPlatform /\* MHPlatform \*/|productName = MHPlatform;' <<<"$tests_target_block"; then
  append_error "CookleTests must not depend on the full MHPlatform umbrella."
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  printf 'MHPlatform adoption guardrail failures:\n' >&2
  for error_message in "${errors[@]}"; do
    printf ' - %s\n' "$error_message" >&2
  done
  exit 1
fi

echo "MHPlatform adoption guardrails passed."
