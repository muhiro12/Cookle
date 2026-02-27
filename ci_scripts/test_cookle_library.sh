#!/usr/bin/env bash
set -euo pipefail

argument_count=$#
if [[ $argument_count -ne 0 ]]; then
  echo "This script does not accept arguments." >&2
  exit 2
fi

script_directory=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
repository_root=$(cd "$script_directory/.." && pwd)
cd "$repository_root"

if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  echo "This script must run inside a git repository." >&2
  exit 1
fi

build_layout_script="$script_directory/lib/build_layout.sh"
if [[ ! -f "$build_layout_script" ]]; then
  echo "Missing build layout helper: $build_layout_script" >&2
  exit 1
fi

# shellcheck source=ci_scripts/lib/build_layout.sh
source "$build_layout_script"
initialize_build_layout "$repository_root"

project_path="Cookle.xcodeproj"
derived_data_path="$BUILD_WORK_DERIVED_DATA_PATH"
results_directory="$BUILD_WORK_RESULTS_DIRECTORY"
local_home_directory="$BUILD_WORK_HOME_DIRECTORY"
cache_directory="$BUILD_CACHE_DIRECTORY"
temporary_directory="$BUILD_WORK_TEMP_DIRECTORY"
clang_module_cache_directory="$BUILD_CACHE_CLANG_MODULE_DIRECTORY"
package_cache_directory="$BUILD_CACHE_PACKAGE_DIRECTORY"
cloned_source_packages_directory="$BUILD_CACHE_SOURCE_PACKAGES_DIRECTORY"
swiftpm_cache_directory="$BUILD_CACHE_SWIFTPM_CACHE_DIRECTORY"
swiftpm_config_directory="$BUILD_CACHE_SWIFTPM_CONFIG_DIRECTORY"

resolve_simulator_identifier() {
  local booted_simulator_identifier
  booted_simulator_identifier=$(xcrun simctl list devices | awk -F'[()]' '/Booted/ {print $2; exit}' || true)
  if [[ -n "$booted_simulator_identifier" ]]; then
    echo "$booted_simulator_identifier"
    return 0
  fi

  local candidate_simulator_identifier
  candidate_simulator_identifier=$(xcrun simctl list devices | awk -F'[()]' '/iPhone/ && /(Shutdown|Booted)/ {print $2; exit}' || true)
  if [[ -n "$candidate_simulator_identifier" ]]; then
    xcrun simctl boot "$candidate_simulator_identifier" >/dev/null 2>&1 || true
    echo "$candidate_simulator_identifier"
    return 0
  fi

  echo ""
}

resolved_simulator_identifier=$(resolve_simulator_identifier)
destination=()
if [[ -n "$resolved_simulator_identifier" ]]; then
  destination=( -destination "id=$resolved_simulator_identifier" )
else
  destination=( -destination "platform=iOS Simulator,OS=latest" )
fi

timestamp=$(date +%s)
result_bundle_path="$results_directory/TestResults_CookleLibrary_${timestamp}.xcresult"
log_file_path="$BUILD_LOGS_DIRECTORY/test_cookle_library_${timestamp}.log"

print_run_summary() {
  local exit_code="$1"
  if [[ $exit_code -eq 0 ]]; then
    echo "Finished CookleLibrary tests."
  else
    echo "CookleLibrary tests failed." >&2
  fi

  echo "Result bundle: $result_bundle_path"
  echo "Log file: $log_file_path"
  echo "Re-run command: bash ci_scripts/test_cookle_library.sh"
}

trap 'print_run_summary "$?"' EXIT

{
  HOME="$local_home_directory" \
  TMPDIR="$temporary_directory" \
  XDG_CACHE_HOME="$cache_directory" \
  CLANG_MODULE_CACHE_PATH="$clang_module_cache_directory" \
  SWIFTPM_CACHE_PATH="$swiftpm_cache_directory" \
  SWIFTPM_CONFIG_PATH="$swiftpm_config_directory" \
  PLL_SOURCE_PACKAGES_PATH="$cloned_source_packages_directory" \
  xcodebuild \
    -project "$project_path" \
    -scheme "CookleLibrary" \
    "${destination[@]}" \
    -derivedDataPath "$derived_data_path" \
    -resultBundlePath "$result_bundle_path" \
    -clonedSourcePackagesDirPath "$cloned_source_packages_directory" \
    -packageCachePath "$package_cache_directory" \
    "CLANG_MODULE_CACHE_PATH=$clang_module_cache_directory" \
    test
} 2>&1 | tee "$log_file_path"
