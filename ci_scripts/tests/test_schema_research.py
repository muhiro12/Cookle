"""Synthetic research matching tests; these fixtures are not product QA."""
from pathlib import Path
import copy
import importlib.util
import json
import os
import subprocess
import tempfile
import unittest

HELPER = Path(__file__).resolve().parents[1] / 'lib/schema_research.py'
MODULE_SPEC = importlib.util.spec_from_file_location('schema_research', HELPER)
research = importlib.util.module_from_spec(MODULE_SPEC)
MODULE_SPEC.loader.exec_module(research)


class ResearchMatchingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.repo = Path(self.temporary.name).resolve()
        self.git('init', '-q')
        self.git('config', 'user.name', 'Synthetic fixture')
        self.git('config', 'user.email', 'fixture@example.invalid')
        self.source_path = 'CookleLibrary/Tests/SchemaResearch/FutureSchemaResearchTests.swift'
        self.cases = {'CookleSchemaResearchTests/FutureSchemaResearchTests/read_shared_records()':
                      'Known Recipe remains readable in a synthetic future store.',
                      'CookleSchemaResearchTests/FutureSchemaResearchTests/observe_future_data_loss()':
                      'Passing observes future-only data loss; it does not prove safety.'}
        spec = {'scheme': 'CookleLibrary', 'target': 'CookleSchemaResearchTests', 'test_plan': 'CookleSchemaResearch',
                'cases': self.cases,
                'normal_plan_path': 'CookleLibrary/Tests/CookleLibrary.xctestplan',
                'plan_path': 'CookleLibrary/Tests/CookleSchemaResearch.xctestplan',
                'inputs': ['CookleLibrary/Sources/Persistence/', self.source_path,
                           'ci_scripts/push_verification.json']}
        self.contract = {'checks': {'tests': {'test_plan': 'CookleLibrary', 'targets': ['CookleLibraryTests']}},
                         'schema_research': spec}
        self.write('ci_scripts/push_verification.json', json.dumps(self.contract))
        self.write(self.source_path, '// Synthetic source; not an executed Swift test.\n')
        self.write('CookleLibrary/Sources/Persistence/Model.swift', '// Synthetic stored contract.\n')
        self.write('README.md', 'Synthetic fixture.\n')
        for is_research, path in ((False, spec['normal_plan_path']), (True, spec['plan_path'])):
            name = spec['target'] if is_research else 'CookleLibraryTests'
            plan = {'version': 2, 'defaultOptions': {}, 'configurations': [{'options': {}}],
                    'testTargets': [{'target': {'containerPath': 'container:', 'identifier': name, 'name': name}}]}
            self.write(path, json.dumps(plan))
        self.commit('Synthetic initial scope')
        self.head = self.git('rev-parse', 'HEAD')
        self.store = self.repo / '.git/push-verification'
        self.directory = self.store / 'research'
        self.directory.mkdir(parents=True)
        source = {'head': self.head, 'tree': self.git('rev-parse', 'HEAD^{tree}'), 'clean': True}
        self.environment = {'xcodebuild': 'Synthetic Xcode', 'swift': 'Synthetic Swift'}
        self.url = 'test://synthetic/' + next(iter(self.cases))
        self.raw = 'Research started\nCoreData: warning: synthetic history truncation\nResearch passed\n'
        warning = {'line': 2, 'text': self.raw.splitlines()[1]}
        self.execution = {'schema_version': 1, 'source': {'before': source, 'after': copy.deepcopy(source),
                            'stable_clean_snapshot': True}, 'environment': self.environment,
                          'verification': {'ran': True, 'exit_code': 0, 'status': 'passed',
                            'argv': ['xcrun', 'xcodebuild', '-scheme', 'CookleLibrary', '-testPlan',
                                     'CookleSchemaResearch', 'test']},
                          'diagnostics': {'complete_captured_output': True, 'error_count': 0, 'errors': [],
                                          'warning_count': 1, 'warnings': [warning]},
                          'evidence_errors': [], 'tests': {'executed': 2},
                          'artifacts': [{'path': 'output.log', 'sha256': research.digest(self.raw.encode())}]}
        self.build = {'status': 'succeeded', 'errorCount': 0, 'warningCount': 0, 'analyzerWarningCount': 0,
                      'errors': [], 'warnings': [], 'analyzerWarnings': []}
        self.summary = {'result': 'Passed', 'passedTests': 2, 'totalTestCount': 2, 'failedTests': 0,
                        'skippedTests': 0, 'expectedFailures': 0, 'testFailures': [], 'runtimeWarnings': [],
                        'devicesAndConfigurations': [{'device': {'platform': 'iOS Simulator',
                            'architecture': 'arm64', 'osVersion': 'Synthetic OS', 'osBuildNumber': 'Synthetic Build'}}]}
        self.tree = {'testNodes': [{'nodeType': 'Test Case', 'nodeIdentifier': case.split('/', 1)[1],
                                  'nodeIdentifierURL': 'test://synthetic/' + case, 'result': 'Passed'}
                                 for case in self.cases]}
        self.tree['testNodes'].append({'nodeType': 'Unit test bundle', 'name': 'CookleSchemaResearchTests',
                                      'result': 'Passed'})
        self.review = {'source_head': self.head, 'diagnostics': [{'kind': 'warning', 'line': 2,
                        'text_sha256': research.digest(warning['text'].encode()), 'test_id': self.url,
                        'artifact': 'output.log', 'source_path': self.source_path,
                        'source_sha256': research.digest((self.repo / self.source_path).read_bytes()),
                        'reason': 'Synthetic demonstration of explicit research review, not QA warning suppression.',
                        'progress_span': {'start_line': 1, 'pass_line': 3}}]}
        self.normal = {'environment': self.environment, 'native': {'tests': copy.deepcopy(self.summary)},
                       'native_tree': {'testNodes': [{'nodeType': 'Test Case',
                           'nodeIdentifier': 'ReleasedSchemaTests/keep_released_data()', 'result': 'Passed'}]}}
        self.save()

    def tearDown(self):
        self.temporary.cleanup()

    def git(self, *args):
        return subprocess.check_output(['git', '-C', str(self.repo), *args], text=True,
                                       env={**os.environ, 'GIT_OPTIONAL_LOCKS': '0'}).strip()

    def write(self, name, text):
        path = self.repo / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(text)

    def commit(self, message):
        self.git('add', '.')
        self.git('commit', '-qm', message)

    def save(self):
        exports = {'execution.json': self.execution, 'native-build.json': self.build,
                   'native-tests.json': self.summary, 'native-test-tree.json': self.tree,
                   'diagnostic-review.json': self.review}
        (self.directory / 'output.log').write_text(self.raw)
        for name, value in exports.items():
            (self.directory / name).write_text(json.dumps(value))
        self.observed = {'schema_version': 1, 'producer': 'cookle-schema-research', 'status': 'observed',
                         'safety_proof': False, 'source_head': self.head,
                         'inputs_sha256': research.input_digest(self.repo, self.head, self.contract['schema_research']),
                         'environment': self.environment, 'sdk_build': 'Synthetic SDK',
                         'runtime': [list(row) for row in research.runtime_identity(self.summary)],
                         'assertion_meaning': self.cases, 'diagnostics': self.execution['diagnostics'],
                         'artifacts': [{'path': name, 'sha256': research.digest((self.directory / name).read_bytes())}
                                       for name in [*exports, 'output.log']]}
        self.save_observed()

    def save_observed(self):
        (self.directory / 'result.json').write_text(json.dumps(self.observed))

    def check(self, head=None, sdk='Synthetic SDK'):
        return research.check_observation(self.repo, head or self.head, self.store,
                                          'research/result.json', self.normal, sdk)

    def test_matching_observation_retains_warning_and_meaning(self):
        result = self.check()
        self.assertEqual(result['warnings'], 1)
        self.assertFalse(result['safety_proof'])
        self.assertEqual(self.execution['diagnostics']['warning_count'], 1)

    def test_no_observation_and_empty_update(self):
        self.assertEqual(research.match(self.repo, 'fixture://private', ''), [])
        destination = self.store / 'destinations' / research.digest(b'fixture://private')
        destination.mkdir(parents=True)
        (destination / 'receipt.json').write_text('{}')
        with self.assertRaisesRegex(research.Incomplete, 'no matching observation'):
            research.match(self.repo, 'fixture://private', f'{self.head} {self.head} refs/heads/main {self.head}\n')

    def test_storage_and_fixture_changes_require_new_research(self):
        for path in ('CookleLibrary/Sources/Persistence/Model.swift', self.source_path,
                     'CookleLibrary/Sources/Persistence/model ü.swift'):
            with self.subTest(path=path):
                self.write(path, '// Changed synthetic persistence input.\n')
                self.commit('Change research input')
                with self.assertRaisesRegex(research.Incomplete, 'inputs changed'):
                    self.check(self.git('rev-parse', 'HEAD'))
                self.git('reset', '--hard', self.head)

    def test_unrelated_app_and_prose_changes_reuse_observation(self):
        self.write('README.md', 'Changed prose.\n')
        self.write('Cookle/UI/View.swift', '// Synthetic view-only change.\n')
        self.commit('Unrelated app and prose')
        result = self.check(self.git('rev-parse', 'HEAD'))
        self.assertEqual(result['source_head'], self.head)
        self.assertNotEqual(result['target_head'], self.head)

    def test_sdk_xcode_swift_and_runtime_changes_require_research(self):
        with self.assertRaisesRegex(research.Incomplete, 'SDK changed'):
            self.check(sdk='Changed SDK')
        for key in ('xcodebuild', 'swift'):
            with self.subTest(key=key):
                original = self.normal['environment']
                self.normal['environment'] = {**original, key: 'Changed toolchain'}
                with self.assertRaisesRegex(research.Incomplete, 'SDK changed'):
                    self.check()
                self.normal['environment'] = original
        self.normal['native']['tests']['devicesAndConfigurations'][0]['device']['osBuildNumber'] = 'Changed Runtime'
        with self.assertRaisesRegex(research.Incomplete, 'runtime changed'):
            self.check()

    def test_plan_cannot_exclude_extra_tests_or_overlap(self):
        path = self.contract['schema_research']['normal_plan_path']
        plan = json.loads((self.repo / path).read_text())
        plan['testTargets'][0]['skippedTests'] = ['ReleasedSchemaTests']
        self.write(path, json.dumps(plan))
        self.commit('Invalid additional exclusion')
        with self.assertRaisesRegex(research.Incomplete, 'omit, overlap'):
            self.check(self.git('rev-parse', 'HEAD'))

    def test_missing_or_changed_assertion_cannot_pass(self):
        for change in ('missing', 'failed', 'skipped', 'subset'):
            with self.subTest(change=change):
                original = copy.deepcopy((self.tree, self.summary, self.execution))
                if change == 'missing':
                    self.tree['testNodes'].pop(0)
                elif change == 'failed':
                    self.tree['testNodes'][0]['result'] = 'Failed'
                elif change == 'skipped':
                    self.summary['skippedTests'] = 1
                else:
                    self.execution['verification']['argv'].append('-only-testing:CookleLibraryTests')
                self.save()
                with self.assertRaises(research.Incomplete):
                    self.check()
                self.tree, self.summary, self.execution = original
                self.save()

    def test_missing_diagnostic_review_and_wrong_source_reject(self):
        for change in ('missing', 'wrong_source', 'wrong_line', 'missing_context'):
            with self.subTest(change=change):
                original = copy.deepcopy(self.review)
                if change == 'missing':
                    self.review['diagnostics'] = []
                elif change == 'wrong_source':
                    self.review['diagnostics'][0]['source_sha256'] = '0' * 64
                elif change == 'wrong_line':
                    self.review['diagnostics'][0]['line'] = 1
                else:
                    self.review['diagnostics'][0]['progress_span'] = {}
                self.save()
                with self.assertRaises(research.Incomplete):
                    self.check()
                self.review = original
                self.save()

    def test_raw_mutation_and_warning_zero_relabel_reject(self):
        (self.directory / 'output.log').write_text('Hidden warning.\n')
        with self.assertRaisesRegex(research.Incomplete, 'artifacts changed'):
            self.check()
        self.save()
        self.observed['diagnostics'] = {**self.observed['diagnostics'], 'warning_count': 0, 'warnings': []}
        self.save_observed()
        with self.assertRaisesRegex(research.Incomplete, 'counts or assertion meaning'):
            self.check()

    def test_research_in_normal_scope_rejects(self):
        self.normal['native_tree'] = self.tree
        with self.assertRaisesRegex(research.Incomplete, 'included in normal QA'):
            self.check()

    def test_warning_cannot_be_claimed_as_safety_or_qa(self):
        for key, value in (('safety_proof', True), ('status', 'passed'), ('producer', 'ci-verify-xcode-result-review')):
            with self.subTest(key=key):
                original = self.observed[key]
                self.observed[key] = value
                self.save_observed()
                with self.assertRaisesRegex(research.Incomplete, 'separate research observation'):
                    self.check()
                self.observed[key] = original
                self.save_observed()


if __name__ == '__main__':
    unittest.main()
