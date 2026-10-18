#!/usr/bin/env python3
"""Check Cookle's project-owned package and test boundaries in either format."""

import argparse
import subprocess
import sys

from xcode_project import package_name, project_file, read_project, summarize_project


def check_project(path, check):
    packages, targets = summarize_project(read_project(path))
    errors = []
    if check == "swiftlint":
        if not any(package.get("kind") == "remote" and
                   package.get("repository", "").rstrip("/").removesuffix(".git") ==
                   "https://github.com/SimplyDanny/SwiftLintPlugins" for package in packages):
            errors.append("Cookle.xcodeproj must reference the remote SwiftLintPlugins package.")
        return errors
    if check == "test-posture":
        if any(target["name"] == "CookleTests" or target["type"].endswith("unit-test") for target in targets):
            errors.append("Cookle.xcodeproj must not define a unit test target.")
        return errors

    for name, minimum in (("MHPlatform", "1.16.0"), ("MHUI", "2.4.0")):
        matches = [package for package in packages if package_name(package) == name]
        if len(matches) != 1 or not valid_package(matches[0], name, minimum):
            errors.append(f"{name} must use its remote up-to-next-major-version requirement from {minimum}.")

    for name in ("Cookle", "Widgets", "Watch"):
        matches = [target for target in targets if target["name"] == name]
        if len(matches) != 1:
            errors.append(f"Expected one {name} native target.")
            continue
        target = matches[0]
        all_links = {product["name"] for product in target["members"] + target["frameworks"]} | target["files"]
        if name == "Cookle":
            for product_name, minimum in (("MHPlatform", "1.16.0"), ("MHUI", "2.4.0")):
                for edge in ("members", "frameworks"):
                    products = [product for product in target[edge] if product["name"] == product_name]
                    if len(products) != 1 or not valid_package(products[0]["package"], product_name, minimum):
                        errors.append(f"Cookle must declare and link the remote {product_name} product in Frameworks.")
            if "MHDesign" in all_links:
                errors.append("Cookle must use MHDesign through the MHUI re-export.")
        elif all_links & {"MHPlatform", "MHUI", "MHDesign"}:
            errors.append(f"{name} must not link MHPlatform, MHUI or MHDesign.")
    return errors


def valid_package(package, name, minimum):
    return (package is not None and package.get("kind") == "remote" and
            package.get("repository", "").rstrip("/").removesuffix(".git") ==
            f"https://github.com/muhiro12/{name}" and
            package.get("version") == {"up-to-next-major-version": minimum})


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("project")
    parser.add_argument("--check", choices=("packages", "swiftlint", "test-posture"), default="packages")
    parser.add_argument("--path-only", action="store_true")
    arguments = parser.parse_args()
    try:
        if arguments.path_only:
            print(project_file(arguments.project))
            return 0
        errors = check_project(arguments.project, arguments.check)
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError, TypeError, AttributeError) as error:
        print(f"Cannot inspect Xcode project configuration: {error}", file=sys.stderr)
        return 1
    for error in errors:
        print(error, file=sys.stderr)
    return bool(errors)


if __name__ == "__main__":
    sys.exit(main())
