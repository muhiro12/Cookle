#!/usr/bin/env python3
"""Resolve the installed shared verifier without copying its implementation."""
from pathlib import Path
import os
import runpy
import subprocess
import sys


def main():
    root = Path(__file__).resolve().parents[2]
    skill = Path(os.environ.get("CI_VERIFICATION_SKILL", str(Path.home() / ".agents/skills/ci-verify-and-summarize")))
    helpers = {"push": "check_push_verification.py", "swiftlint": "swiftlint_evidence.py"}
    try:
        helper = skill / "scripts" / helpers[sys.argv[1]]
        if not helper.is_file():
            raise ValueError("Shared verifier is missing; resolve CI_VERIFICATION_SKILL to the installed ci-verify-and-summarize skill.")
        module = runpy.run_path(str(helper))
        if module.get("CHECKER_API_VERSION") != 1:
            raise ValueError("Unsupported shared verifier version; review compatibility before enabling it.")
        os.chdir(root)
        return module["main"](["ci_scripts/push_verification.json", *sys.argv[2:]])
    except (OSError, ValueError, KeyError, TypeError, IndexError, subprocess.SubprocessError) as error:
        print("Verification incomplete: " + str(error), file=sys.stderr)
        return 2


if __name__ == "__main__":
    raise SystemExit(main())
