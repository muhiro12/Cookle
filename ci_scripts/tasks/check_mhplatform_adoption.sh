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
readme_file="README.md"
architecture_guide="Designs/Architecture/ARCHITECTURE_GUIDE.md"

# Cookle follows the MHPlatform 1.2 consumer pillars by keeping the app target
# on the default MHPlatform umbrella and the shared package on MHPlatformCore.
# This repository keeps remote range requirements at 1.0.0..<2.0.0 and checks
# in a resolved baseline at MHPlatform 1.2+.

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

  if ! grep -Eq '^\s*"1\.0\.0"\s*\.\.<\s*"2\.0\.0"' <<<"$manifest_block"; then
    append_error "Cookle keeps MHPlatform on the 1.0.0..<2.0.0 version range in $package_manifest."
  fi
fi

resolved_pin_block=$(
  awk '
    /"identity" : "mhplatform"/ {
      in_block = 1
    }
    in_block {
      print
      open_braces += gsub(/\{/, "{")
      close_braces += gsub(/\}/, "}")
    }
    in_block && open_braces > 0 && open_braces == close_braces {
      exit
    }
  ' "$package_resolved"
)

if [[ -z "$resolved_pin_block" ]]; then
  append_error "MHPlatform resolved pin was not found in $package_resolved."
else
  if grep -Eq '"branch"\s*:' <<<"$resolved_pin_block"; then
    append_error "MHPlatform resolved state must not contain branch tracking in $package_resolved."
  fi

  if ! grep -Eq '"version"\s*:\s*"1\.([2-9]|[1-9][0-9]+)\.[0-9]+"' <<<"$resolved_pin_block"; then
    append_error "MHPlatform resolved state must contain a semantic version in the 1.2.0..<2.0.0 range in $package_resolved."
  fi
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

  if ! grep -Eq 'kind = upToNextMajorVersion;' <<<"$remote_package_block"; then
    append_error "Cookle keeps MHPlatform on an upToNextMajorVersion requirement in $project_file."
  fi

  if ! grep -Eq 'minimumVersion = 1\.0\.0;' <<<"$remote_package_block"; then
    append_error "Cookle keeps MHPlatform on minimumVersion 1.0.0 in $project_file."
  fi
fi

if rg -n 'XCLocalSwiftPackageReference "MHPlatform"|relativePath = .*MHPlatform' "$project_file" >/dev/null; then
  append_error "MHPlatform must not be referenced as a local Xcode package in $project_file."
fi

cookle_target_tail=$(
  awk '
    /name = Cookle;/ {
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

if ! grep -Eq '/\* MHPlatform \*/' <<<"$cookle_target_tail"; then
  append_error "Cookle must keep the MHPlatform umbrella linked in $project_file."
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

if grep -Eq '/\* MHPlatform \*/|productName = MHPlatform;' <<<"$widgets_target_block"; then
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

if grep -Eq '/\* MHPlatform \*/|productName = MHPlatform;' <<<"$tests_target_block"; then
  append_error "CookleTests must not depend on the full MHPlatform umbrella."
fi

if rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' Widgets CookleTests >/dev/null; then
  append_error "Widgets and CookleTests must not import the full MHPlatform umbrella."
fi

if rg -n 'MHAppRuntimeCore' \
  "$package_manifest" \
  "$project_file" \
  "$readme_file" \
  "$architecture_guide" \
  Cookle \
  CookleLibrary \
  Widgets \
  CookleTests >/dev/null; then
  append_error "MHAppRuntimeCore must not remain in Cookle source or policy files after MHPlatform 1.2 adoption."
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  printf 'Cookle MHPlatform consumer-boundary guardrail failures:\n' >&2
  for error_message in "${errors[@]}"; do
    printf ' - %s\n' "$error_message" >&2
  done
  exit 1
fi

echo "Cookle MHPlatform consumer-boundary guardrails passed."
