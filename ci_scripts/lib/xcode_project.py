"""Read the project formats supported by Cookle's reversible JSON migration."""

import json
from pathlib import Path
import subprocess


def project_file(path):
    path = Path(path)
    names = {"project.pbxproj", "project.xcproj"}
    directory = path.parent if path.name in names else path
    if not directory.is_dir():
        raise ValueError(f"Missing Xcode project configuration: {path}")
    candidates = [directory / name for name in sorted(names)]
    found = [candidate for candidate in candidates if candidate.exists() or candidate.is_symlink()]
    if len(found) != 1:
        raise ValueError(f"Expected exactly one project configuration in {directory}.")
    selected = found[0]
    if directory.is_symlink() or selected.is_symlink() or not selected.is_file():
        raise ValueError("The Xcode project configuration must be a regular file in a non-symlink project bundle.")
    if path.name in names and path != selected:
        raise ValueError(f"Missing Xcode project configuration: {path}")
    return selected


def read_project(path):
    path = project_file(path)
    result = subprocess.run(["plutil", "-convert", "json", "-o", "-", str(path)],
                            check=True, capture_output=True, text=True)
    document = json.loads(result.stdout)
    if not isinstance(document, dict):
        raise ValueError("The Xcode project must be an object.")
    if path.suffix == ".pbxproj":
        if not isinstance(document.get("objects"), dict) or not isinstance(document.get("rootObject"), str):
            raise ValueError("project.pbxproj must contain the legacy objects model.")
    elif ("objects" in document or not isinstance(document.get("packages"), list) or
          not isinstance(document.get("targets"), list)):
        raise ValueError("project.xcproj must contain the JSON packages and targets model.")
    return document


def package_name(package):
    location = package.get("repository", package.get("path", ""))
    return package.get("name", Path(location.rstrip("/")).stem)


def summarize_project(document):
    """Retain package identities and actual Frameworks edges, not text matches."""
    if "objects" not in document:
        packages = document["packages"]
        targets = []

        def package_for(name):
            matches = [package for package in packages if package_name(package) == name]
            if len(matches) != 1:
                raise ValueError(f"Invalid package reference: {name}")
            return matches[0]

        def framework_files(files, target_name):
            found = set()
            for file in files:
                for membership in file.get("target-membership", []):
                    phase = membership.get("build-phase", "") if isinstance(membership, dict) else membership
                    if phase in {target_name, f"{target_name}/frameworks"}:
                        found.add(Path(file.get("path", "")).stem)
                found.update(framework_files(file.get("children", []), target_name))
            return found

        for target in document["targets"]:
            members = []
            frameworks = []
            for member in target.get("package-product-members", []):
                package = package_for(member["package"]) if "package" in member else None
                product = {"name": member["product-name"], "package": package}
                members.append(product)
                phase = member.get("build-phase", {})
                phase = phase.get("build-phase") if isinstance(phase, dict) else phase
                if phase == "frameworks" and "frameworks" in target.get("build-phases", []):
                    frameworks.append(product)
            targets.append({"name": target["name"], "type": target["product-type"],
                            "members": members, "frameworks": frameworks,
                            "files": (framework_files(document.get("files", []), target["name"])
                                      if "frameworks" in target.get("build-phases", []) else set())})
        return packages, targets

    objects = document["objects"]

    def object_for(identifier, expected_type):
        value = objects[identifier]
        if value.get("isa") != expected_type:
            raise ValueError(f"Invalid {expected_type} reference: {identifier}")
        return value

    def package_for(identifier):
        value = objects[identifier]
        if value["isa"] == "XCRemoteSwiftPackageReference":
            requirement = value["requirement"]
            version = ({"up-to-next-major-version": requirement["minimumVersion"]}
                       if requirement["kind"] == "upToNextMajorVersion" else requirement)
            return {"kind": "remote", "repository": value["repositoryURL"], "version": version}
        if value["isa"] == "XCLocalSwiftPackageReference":
            return {"kind": "local", "path": value["relativePath"]}
        raise ValueError(f"Invalid package reference: {identifier}")

    def product_for(identifier):
        product = object_for(identifier, "XCSwiftPackageProductDependency")
        if "package" in product and product["package"] not in package_references:
            raise ValueError(f"Unattached package owner for product: {identifier}")
        package = package_for(product["package"]) if "package" in product else None
        return {"name": product["productName"], "package": package}

    root = object_for(document["rootObject"], "PBXProject")
    package_references = root.get("packageReferences", [])
    packages = [package_for(identifier) for identifier in package_references]
    targets = []
    for identifier in root["targets"]:
        target = object_for(identifier, "PBXNativeTarget")
        members = [product_for(item) for item in target.get("packageProductDependencies", [])]
        frameworks = []
        files = set()
        for phase_id in target.get("buildPhases", []):
            phase = objects[phase_id]
            if phase["isa"] != "PBXFrameworksBuildPhase":
                continue
            for file_id in phase.get("files", []):
                build_file = object_for(file_id, "PBXBuildFile")
                if "productRef" in build_file:
                    frameworks.append(product_for(build_file["productRef"]))
                elif "fileRef" in build_file:
                    reference = object_for(build_file["fileRef"], "PBXFileReference")
                    files.add(Path(reference.get("path", reference.get("name", ""))).stem)
        targets.append({"name": target["name"], "type": target["productType"],
                        "members": members, "frameworks": frameworks, "files": files})
    return packages, targets
