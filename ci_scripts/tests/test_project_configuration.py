"""Project guards must preserve the same boundaries across format conversion."""

import copy
import json
from pathlib import Path
import plistlib
import subprocess
import sys
import tempfile
import unittest

LIBRARY = Path(__file__).resolve().parents[1] / "lib"
sys.path.insert(0, str(LIBRARY))
from check_project_configuration import check_project
from xcode_project import project_file


def fixture(legacy):
    repositories = (("MHPlatform", "1.16.0"), ("MHUI", "2.4.0"), ("SwiftLintPlugins", "0.65.1"))
    if not legacy:
        packages = [{"kind": "remote", "repository": f"https://github.com/{'SimplyDanny' if name == 'SwiftLintPlugins' else 'muhiro12'}/{name}",
                     "version": {"up-to-next-major-version": version}} for name, version in repositories]
        members = [{"package": name, "product-name": name, "build-phase": {"build-phase": "frameworks"}}
                   for name in ("MHPlatform", "MHUI")]
        return {"packages": packages, "files": [], "targets": [
            {"name": name, "product-type": "application", "package-product-members": members if name == "Cookle" else []}
            for name in ("Cookle", "Widgets", "Watch")]}
    objects = {"root": {"isa": "PBXProject", "packageReferences": [name for name, _ in repositories],
                        "targets": ["Cookle", "Widgets", "Watch"]}}
    for name, version in repositories:
        objects[name] = {"isa": "XCRemoteSwiftPackageReference",
                         "repositoryURL": f"https://github.com/{'SimplyDanny' if name == 'SwiftLintPlugins' else 'muhiro12'}/{name}",
                         "requirement": {"kind": "upToNextMajorVersion", "minimumVersion": version}}
    for name in ("Cookle", "Widgets", "Watch"):
        objects[name] = {"isa": "PBXNativeTarget", "name": name, "productType": "com.apple.product-type.application",
                         "packageProductDependencies": [], "buildPhases": [name + "Frameworks"]}
        objects[name + "Frameworks"] = {"isa": "PBXFrameworksBuildPhase", "files": []}
    for name in ("MHPlatform", "MHUI"):
        objects[name + "Product"] = {"isa": "XCSwiftPackageProductDependency", "productName": name, "package": name}
        objects[name + "BuildFile"] = {"isa": "PBXBuildFile", "productRef": name + "Product"}
        objects["Cookle"]["packageProductDependencies"].append(name + "Product")
        objects["CookleFrameworks"]["files"].append(name + "BuildFile")
    return {"rootObject": "root", "objects": objects}


class ProjectConfigurationTests(unittest.TestCase):
    def inspect(self, document, legacy, check="packages"):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / ("project.pbxproj" if legacy else "project.xcproj")
            if legacy:
                path.write_bytes(plistlib.dumps(document))
            else:
                # Exercise Xcode's JSON5 syntax, including comments and trailing commas.
                path.write_text(json.dumps(document, indent=2)[:-1] + ',\n}\n// Xcode project\n')
            return check_project(path, check)

    def test_equivalent_project_accepts_all_guards(self):
        for legacy in (False, True):
            for check in ("packages", "swiftlint", "test-posture"):
                with self.subTest(legacy=legacy, check=check):
                    self.assertEqual(self.inspect(fixture(legacy), legacy, check), [])

    def test_declared_product_without_framework_link_is_rejected(self):
        for legacy in (False, True):
            document = fixture(legacy)
            if legacy:
                document["objects"]["CookleFrameworks"]["files"].remove("MHUIBuildFile")
            else:
                document["targets"][0]["package-product-members"][1].pop("build-phase")
            with self.subTest(legacy=legacy):
                self.assertTrue(self.inspect(document, legacy))

    def test_equivalent_git_repository_urls_are_accepted(self):
        for legacy in (False, True):
            document = fixture(legacy)
            if legacy:
                for name in ("MHPlatform", "MHUI", "SwiftLintPlugins"):
                    document["objects"][name]["repositoryURL"] += ".git/"
            else:
                for package in document["packages"]:
                    package["repository"] += ".git/"
            for check in ("packages", "swiftlint"):
                with self.subTest(legacy=legacy, check=check):
                    self.assertEqual(self.inspect(document, legacy, check), [])

    def test_wrong_repository_branch_and_local_dependency_are_rejected(self):
        for legacy in (False, True):
            for mutation in ("repository", "branch", "local"):
                document = fixture(legacy)
                package = document["objects"]["MHUI"] if legacy else document["packages"][1]
                if mutation == "repository":
                    package["repositoryURL" if legacy else "repository"] = "https://github.com/other/MHUI"
                elif mutation == "branch":
                    package["requirement" if legacy else "version"] = {"kind": "branch", "branch": "main"}
                else:
                    package.clear()
                    package.update({"isa": "XCLocalSwiftPackageReference", "relativePath": "../MHUI"} if legacy else
                                   {"kind": "local", "path": "../MHUI"})
                with self.subTest(legacy=legacy, mutation=mutation):
                    self.assertTrue(self.inspect(document, legacy))

    def test_companion_framework_link_is_rejected(self):
        for legacy in (False, True):
            document = fixture(legacy)
            if legacy:
                document["objects"]["WidgetsFrameworks"]["files"].append("MHUIBuildFile")
            else:
                document["targets"][1]["package-product-members"] = copy.deepcopy(document["targets"][0]["package-product-members"])
            with self.subTest(legacy=legacy):
                self.assertTrue(self.inspect(document, legacy))

    def test_unit_test_target_is_rejected_in_each_format(self):
        for legacy in (False, True):
            document = fixture(legacy)
            if legacy:
                document["objects"]["Widgets"]["productType"] = "com.apple.product-type.bundle.unit-test"
            else:
                document["targets"][1]["product-type"] = "bundle.unit-test"
            with self.subTest(legacy=legacy):
                self.assertTrue(self.inspect(document, legacy, "test-posture"))

    def test_missing_swiftlint_is_rejected(self):
        for legacy in (False, True):
            document = fixture(legacy)
            if legacy:
                document["objects"]["root"]["packageReferences"].remove("SwiftLintPlugins")
            else:
                document["packages"].pop()
            with self.subTest(legacy=legacy):
                self.assertTrue(self.inspect(document, legacy, "swiftlint"))

    def test_missing_and_ambiguous_configuration_are_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory)
            with self.assertRaises(ValueError):
                project_file(path)
            for name in ("project.pbxproj", "project.xcproj"):
                (path / name).write_text("{}")
            with self.assertRaises(ValueError):
                project_file(path)

    def test_invalid_json_and_invalid_reference_fail_without_success(self):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "project.xcproj"
            invalid_reference = {"packages": [], "targets": [
                    {"name": "Cookle", "product-type": "application", "package-product-members": [
                        {"product-name": "MHUI", "package": "missing"}]}]}
            for text in ('{"targets":', json.dumps(invalid_reference)):
                path.write_text(text)
                result = subprocess.run([sys.executable, str(LIBRARY / "check_project_configuration.py"), str(path)],
                                        capture_output=True, text=True)
                self.assertEqual(result.returncode, 1)
                self.assertIn("Cannot inspect Xcode project configuration", result.stderr)


if __name__ == "__main__":
    unittest.main()
