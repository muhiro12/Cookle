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

package_manifest="CookleLibrary/Package.swift"
package_resolved="CookleLibrary/Package.resolved"
project_file=$(python3 "$repository_root/ci_scripts/lib/check_project_configuration.py" Cookle.xcodeproj --path-only)
readme_file="README.md"
architecture_guide="Designs/Architecture/ARCHITECTURE_GUIDE.md"
shared_service_design="Designs/Architecture/shared-service-design.md"

# Cookle follows current MHPlatform/MHUI consumer boundaries:
# - Cookle is the full-app MHPlatform adopter.
# - CookleLibrary uses MHPlatformCore and must stay off app runtime products.
# - Cookle adopts full MHUI and consumes MHDesign through its re-export.
# - Shared logic and delivery-surface adapters stay off MHUI/MHDesign.
# - ADR 0010 retains native Widgets and defers Watch until its surface is readable.

presentation_import_pattern='^\s*(?:@\w+(?:\([^)]*\))?\s+)*(?:(?:public|internal|package|private|fileprivate)\s+)?import\s+(?:(?:struct|class|enum|protocol|func|var|let|typealias)\s+)?(?:MHUI|MHDesign)(?:\.|\s|$)'

declare -a errors=()

append_error() {
  errors+=("$1")
}

resolved_pin_block() {
  local package_identity=$1

  awk -v identity="$package_identity" '
    index($0, "\"identity\" : \"" identity "\"") {
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
}

mhplatform_manifest_block=$(
  awk '
    /url: "https:\/\/github.com\/muhiro12\/MHPlatform(\.git)?"/ {
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

if [[ -z "$mhplatform_manifest_block" ]]; then
  append_error "MHPlatform remote dependency was not found in $package_manifest."
else
  if grep -Eq 'path:\s*"[^"]*MHPlatform' <<<"$mhplatform_manifest_block"; then
    append_error "MHPlatform must not use a local path dependency in $package_manifest."
  fi

  if grep -Eq 'branch:\s*"' <<<"$mhplatform_manifest_block"; then
    append_error "MHPlatform must not follow a floating branch in $package_manifest."
  fi

  if ! grep -Eq '^\s*"1\.20\.0"\s*\.\.<\s*"2\.0\.0"' <<<"$mhplatform_manifest_block"; then
    append_error "Cookle keeps MHPlatform on the 1.20.0..<2.0.0 version range in $package_manifest."
  fi
fi

mhplatform_resolved_pin_block=$(resolved_pin_block "mhplatform")

if [[ -z "$mhplatform_resolved_pin_block" ]]; then
  append_error "MHPlatform resolved pin was not found in $package_resolved."
else
  if grep -Eq '"branch"\s*:' <<<"$mhplatform_resolved_pin_block"; then
    append_error "MHPlatform resolved state must not contain branch tracking in $package_resolved."
  fi

  if ! grep -Eq '"version"\s*:\s*"1\.([2-9][0-9]|[1-9][0-9]{2,})\.[0-9]+"' <<<"$mhplatform_resolved_pin_block"; then
    append_error "MHPlatform resolved state must contain a semantic version in the 1.20.0..<2.0.0 range in $package_resolved."
  fi
fi

mhui_resolved_pin_block=$(resolved_pin_block "mhui")

if [[ -z "$mhui_resolved_pin_block" ]]; then
  append_error "MHUI resolved pin was not found in $package_resolved."
else
  if grep -Eq '"branch"\s*:' <<<"$mhui_resolved_pin_block"; then
    append_error "MHUI resolved state must not contain branch tracking in $package_resolved."
  fi

  if ! grep -Eq '"version"\s*:\s*"2\.([4-9]|[1-9][0-9]+)\.[0-9]+"' <<<"$mhui_resolved_pin_block"; then
    append_error "MHUI resolved state must contain a semantic version in the 2.4.0..<3.0.0 range in $package_resolved."
  fi
fi

if ! python3 "$repository_root/ci_scripts/lib/check_project_configuration.py" Cookle.xcodeproj; then
  append_error "Project package requirements and target linkage must follow the consumer contract."
fi

matches=$(ci_task_rg -nP "$presentation_import_pattern" \
  Cookle/Sources/App/Intents Cookle/Sources/Features/*/Intents)
if [[ -n "$matches" ]]; then
  append_error "App Intent implementations must not import MHUI or MHDesign."
fi

matches=$(ci_task_rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' CookleLibrary/Sources CookleLibrary/Tests)
if [[ -n "$matches" ]]; then
  append_error "CookleLibrary must not import the full MHPlatform umbrella."
fi

matches=$(ci_task_rg -n 'name:\s*"MHPlatform",\s*package:\s*"MHPlatform"|productName = MHPlatform;' "$package_manifest")
if [[ -n "$matches" ]]; then
  append_error "CookleLibrary must not depend on the full MHPlatform umbrella."
fi

matches=$(ci_task_rg -nP "$presentation_import_pattern" CookleLibrary/Sources CookleLibrary/Tests)
if [[ -n "$matches" ]]; then
  append_error "CookleLibrary must not import MHUI or MHDesign."
fi

matches=$(ci_task_rg -nP '^\s*(?:@preconcurrency\s+)?import\s+(?:SwiftUI|UIKit|AppKit|WatchKit)\s*$' CookleLibrary/Sources CookleLibrary/Tests)
if [[ -n "$matches" ]]; then
  append_error "CookleLibrary Sources and Tests must stay presentation-free and must not import SwiftUI, UIKit, AppKit, or WatchKit."
fi

matches=$(ci_task_rg -n 'url:\s*"https://github.com/muhiro12/MHUI"|name:\s*"MHUI"|name:\s*"MHDesign"' "$package_manifest")
if [[ -n "$matches" ]]; then
  append_error "CookleLibrary must not depend on MHUI or MHDesign."
fi

matches=$(ci_task_rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' Widgets)
if [[ -n "$matches" ]]; then
  append_error "Widgets must not import the full MHPlatform umbrella."
fi

matches=$(ci_task_rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' Watch)
if [[ -n "$matches" ]]; then
  append_error "Watch must not import the full MHPlatform umbrella."
fi

matches=$(ci_task_rg -nP "$presentation_import_pattern" Widgets Watch)
if [[ -n "$matches" ]]; then
  append_error "Widgets and Watch remain free of MHUI/MHDesign imports under ADR 0010."
fi

matches=$(ci_task_rg -n 'MHAppRuntimeCore' \
  "$package_manifest" \
  "$project_file" \
  "$readme_file" \
  "$architecture_guide" \
  "$shared_service_design" \
  Cookle \
  CookleLibrary \
  Widgets \
  Watch)
if [[ -n "$matches" ]]; then
  append_error "MHAppRuntimeCore must not remain in Cookle source or policy files after MHPlatform 1.9 adoption."
fi

if [[ ${#errors[@]} -gt 0 ]]; then
  printf 'Cookle package consumer boundary guardrail failures:\n' >&2
  for error_message in "${errors[@]}"; do
    printf ' - %s\n' "$error_message" >&2
  done
  exit 1
fi

echo "Cookle package consumer boundary guardrails passed."
