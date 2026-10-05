"""Complete retained searches must distinguish matches, absence and failure."""
from pathlib import Path
import os
import shutil
import subprocess
import unittest

SCRIPTS = ('check_test_posture.sh', 'check_package_consumer_boundaries.sh')
REPOSITORY = Path(__file__).resolve().parents[2]


class SearchEvidenceTests(unittest.TestCase):
    def test_actual_checks_reject_failed_search(self):
        native = shutil.which("rg")
        self.assertIsNotNone(native)
        for name in SCRIPTS:
            script = REPOSITORY / "ci_scripts/tasks" / name
            for status in (None, 1, 2):
                with self.subTest(script=name, status=status):
                    code = 'rg() { if [[ "$SEARCH_STATUS" == "native" ]]; then "$SEARCH_RG" "$@"; else return "$SEARCH_STATUS"; fi; }; export -f rg; bash "$SEARCH_SCRIPT"'
                    result = subprocess.run(["bash", "-c", code], cwd=REPOSITORY, capture_output=True, text=True,
                        env={**os.environ, "SEARCH_STATUS": "native" if status is None else str(status),
                             "SEARCH_RG": native, "SEARCH_SCRIPT": str(script)})
                    self.assertEqual(result.returncode, 2 if status == 2 else 0, result.stdout + result.stderr)
                    if status == 2:
                        self.assertIn("search incomplete", result.stderr)


if __name__ == "__main__":
    unittest.main()
