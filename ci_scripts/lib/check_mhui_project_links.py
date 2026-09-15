#!/usr/bin/env python3
"""Check actual MHUI product and Frameworks edges in the Xcode project."""

import json
import subprocess
import sys
from pathlib import Path


def check_project(project_path):
    converted = subprocess.run(
        ["plutil", "-convert", "json", "-o", "-", str(project_path)],
        check=True,
        capture_output=True,
        text=True,
    )
    objects = json.loads(converted.stdout)["objects"]
    errors = []

    def object_for(identifier, expected_type):
        value = objects.get(identifier, {})
        if value.get("isa") != expected_type:
            errors.append(f"Invalid {expected_type} reference: {identifier}")
            return {}
        return value

    def product_name(identifier):
        product = object_for(identifier, "XCSwiftPackageProductDependency")
        name = product.get("productName", "")
        if name == "MHUI":
            package = object_for(
                product.get("package"), "XCRemoteSwiftPackageReference"
            )
            if package.get("repositoryURL", "").rstrip("/") not in {
                "https://github.com/muhiro12/MHUI",
                "https://github.com/muhiro12/MHUI.git",
            }:
                errors.append("MHUI must resolve to its remote package.")
            requirement = package.get("requirement", {})
            if requirement != {
                "kind": "upToNextMajorVersion",
                "minimumVersion": "1.19.0",
            }:
                errors.append("Linked MHUI must require 1.19.0..<2.0.0.")
        return name

    for target_name in ("Cookle", "Widgets", "Watch"):
        targets = [
            value
            for value in objects.values()
            if value.get("isa") == "PBXNativeTarget"
            and value.get("name") == target_name
        ]
        if len(targets) != 1:
            errors.append(f"Expected one {target_name} native target.")
            continue
        target = targets[0]
        declared = {
            product_name(identifier)
            for identifier in target.get("packageProductDependencies", [])
        }
        framework_products = set()
        framework_files = set()
        for phase_identifier in target.get("buildPhases", []):
            phase = objects.get(phase_identifier, {})
            if phase.get("isa") != "PBXFrameworksBuildPhase":
                continue
            for file_identifier in phase.get("files", []):
                build_file = object_for(file_identifier, "PBXBuildFile")
                if "productRef" in build_file:
                    framework_products.add(product_name(build_file["productRef"]))
                elif "fileRef" in build_file:
                    reference = objects.get(build_file["fileRef"], {})
                    name = reference.get("path", reference.get("name", ""))
                    framework_files.add(Path(name).stem)

        all_links = declared | framework_products | framework_files
        if target_name == "Cookle":
            if "MHUI" not in declared:
                errors.append("Cookle must declare the MHUI package product.")
            if "MHUI" not in framework_products:
                errors.append("Cookle must link the MHUI product in Frameworks.")
            if "MHDesign" in all_links:
                errors.append("Cookle must use MHDesign through the MHUI re-export.")
        elif all_links & {"MHUI", "MHDesign"}:
            errors.append(f"{target_name} must not link MHUI or MHDesign.")

    return errors


def main():
    if len(sys.argv) != 2:
        print("Usage: check_mhui_project_links.py <project.pbxproj>", file=sys.stderr)
        return 2
    try:
        errors = check_project(Path(sys.argv[1]))
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError) as error:
        print(f"Cannot inspect MHUI project links: {error}", file=sys.stderr)
        return 1
    for error in errors:
        print(error, file=sys.stderr)
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
