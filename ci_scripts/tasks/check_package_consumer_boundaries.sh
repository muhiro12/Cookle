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
shared_service_design="Designs/Architecture/shared-service-design.md"

# Cookle follows current MHPlatform/MHUI consumer boundaries:
# - Cookle is the full-app MHPlatform adopter.
# - CookleLibrary uses MHPlatformCore and must stay off app runtime products.
# - Cookle uses the full MHUI styled surface for app-owned presentation.
# - Shared logic and delivery-surface adapters stay off MHUI/MHDesign.

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

remote_package_block() {
  local package_name=$1

  awk -v package_name="$package_name" '
    index($0, "XCRemoteSwiftPackageReference \"" package_name "\" */ = {") {
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
}

target_block() {
  local target_name=$1

  awk -v target_name="$target_name" '
    index($0, "name = " target_name ";") {
      in_block = 1
    }
    in_block {
      print
    }
    in_block && /^\t\t};$/ {
      exit
    }
  ' "$project_file"
}

check_project_package_reference() {
  local package_name=$1
  local block=$2

  if [[ -z "$block" ]]; then
    append_error "$package_name remote package reference was not found in $project_file."
    return 0
  fi

  if grep -Eq 'kind = branch;|branch = ' <<<"$block"; then
    append_error "$package_name must not follow a floating branch in $project_file."
  fi

  if ! grep -Eq 'kind = upToNextMajorVersion;' <<<"$block"; then
    append_error "Cookle keeps $package_name on an upToNextMajorVersion requirement in $project_file."
  fi

  if ! grep -Eq 'minimumVersion = 1\.0\.0;' <<<"$block"; then
    append_error "Cookle keeps $package_name on minimumVersion 1.0.0 in $project_file."
  fi
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

  if ! grep -Eq '^\s*"1\.0\.0"\s*\.\.<\s*"2\.0\.0"' <<<"$mhplatform_manifest_block"; then
    append_error "Cookle keeps MHPlatform on the 1.0.0..<2.0.0 version range in $package_manifest."
  fi
fi

mhplatform_resolved_pin_block=$(resolved_pin_block "mhplatform")

if [[ -z "$mhplatform_resolved_pin_block" ]]; then
  append_error "MHPlatform resolved pin was not found in $package_resolved."
else
  if grep -Eq '"branch"\s*:' <<<"$mhplatform_resolved_pin_block"; then
    append_error "MHPlatform resolved state must not contain branch tracking in $package_resolved."
  fi

  if ! grep -Eq '"version"\s*:\s*"1\.([9]|[1-9][0-9]+)\.[0-9]+"' <<<"$mhplatform_resolved_pin_block"; then
    append_error "MHPlatform resolved state must contain a semantic version in the 1.9.0..<2.0.0 range in $package_resolved."
  fi
fi

mhui_resolved_pin_block=$(resolved_pin_block "mhui")

if [[ -z "$mhui_resolved_pin_block" ]]; then
  append_error "MHUI resolved pin was not found in $package_resolved."
else
  if grep -Eq '"branch"\s*:' <<<"$mhui_resolved_pin_block"; then
    append_error "MHUI resolved state must not contain branch tracking in $package_resolved."
  fi

  if ! grep -Eq '"version"\s*:\s*"1\.([5-9]|[1-9][0-9]+)\.[0-9]+"' <<<"$mhui_resolved_pin_block"; then
    append_error "MHUI resolved state must contain a semantic version in the 1.5.0..<2.0.0 range in $package_resolved."
  fi
fi

mhplatform_remote_package_block=$(remote_package_block "MHPlatform")
mhui_remote_package_block=$(remote_package_block "MHUI")

check_project_package_reference "MHPlatform" "$mhplatform_remote_package_block"
check_project_package_reference "MHUI" "$mhui_remote_package_block"

if rg -n 'XCLocalSwiftPackageReference "MHPlatform"|relativePath = .*MHPlatform' "$project_file" >/dev/null; then
  append_error "MHPlatform must not be referenced as a local Xcode package in $project_file."
fi

if rg -n 'XCLocalSwiftPackageReference "MHUI"|relativePath = .*MHUI' "$project_file" >/dev/null; then
  append_error "MHUI must not be referenced as a local Xcode package in $project_file."
fi

cookle_target_block=$(target_block "Cookle")
widgets_target_block=$(target_block "Widgets")
watch_target_block=$(target_block "Watch")

if ! grep -Eq '/\* MHPlatform \*/' <<<"$cookle_target_block"; then
  append_error "Cookle must keep the MHPlatform umbrella linked in $project_file."
fi

if ! grep -Eq '/\* MHUI \*/' <<<"$cookle_target_block"; then
  append_error "Cookle must keep the full MHUI styled product linked in $project_file."
fi

if grep -Eq '/\* MHDesign \*/|productName = MHDesign;' <<<"$cookle_target_block"; then
  append_error "Cookle uses the full MHUI styled product and must not link only MHDesign."
fi

if rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' CookleLibrary/Sources CookleLibrary/Tests >/dev/null; then
  append_error "CookleLibrary must not import the full MHPlatform umbrella."
fi

if rg -n 'name:\s*"MHPlatform",\s*package:\s*"MHPlatform"|productName = MHPlatform;' "$package_manifest" >/dev/null; then
  append_error "CookleLibrary must not depend on the full MHPlatform umbrella."
fi

if rg -nP '^\s*(?:@preconcurrency\s+)?import\s+(?:MHUI|MHDesign)\s*$' CookleLibrary/Sources CookleLibrary/Tests >/dev/null; then
  append_error "CookleLibrary must not import MHUI or MHDesign."
fi

if rg -n 'url:\s*"https://github.com/muhiro12/MHUI"|name:\s*"MHUI"|name:\s*"MHDesign"' "$package_manifest" >/dev/null; then
  append_error "CookleLibrary must not depend on MHUI or MHDesign."
fi

if grep -Eq '/\* MHPlatform \*/|productName = MHPlatform;' <<<"$widgets_target_block"; then
  append_error "Widgets must not depend on the full MHPlatform umbrella."
fi

if grep -Eq '/\* MHPlatform \*/|productName = MHPlatform;' <<<"$watch_target_block"; then
  append_error "Watch must not depend on the full MHPlatform umbrella."
fi

if grep -Eq '/\* MHUI \*/|/\* MHDesign \*/|productName = MHUI;|productName = MHDesign;' <<<"$widgets_target_block"; then
  append_error "Widgets must use CookleLibrary first and must not link MHUI or MHDesign by default."
fi

if grep -Eq '/\* MHUI \*/|/\* MHDesign \*/|productName = MHUI;|productName = MHDesign;' <<<"$watch_target_block"; then
  append_error "Watch must use CookleLibrary first and must not link MHUI or MHDesign by default."
fi

if rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' Widgets >/dev/null; then
  append_error "Widgets must not import the full MHPlatform umbrella."
fi

if rg -nP '^\s*(?:@preconcurrency\s+)?import\s+MHPlatform\s*$' Watch >/dev/null; then
  append_error "Watch must not import the full MHPlatform umbrella."
fi

if rg -nP '^\s*(?:@preconcurrency\s+)?import\s+(?:MHUI|MHDesign)\s*$' Widgets Watch >/dev/null; then
  append_error "Widgets and Watch must not import MHUI or MHDesign by default."
fi

if rg -n 'MHAppRuntimeCore' \
  "$package_manifest" \
  "$project_file" \
  "$readme_file" \
  "$architecture_guide" \
  "$shared_service_design" \
  Cookle \
  CookleLibrary \
  Widgets \
  Watch >/dev/null; then
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
