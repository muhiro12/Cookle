#!/usr/bin/env python3
"""Retain and match Cookle's conditional schema observations separately from QA."""
from __future__ import annotations

import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import subprocess


class Incomplete(ValueError):
    pass


def require(condition, message):
    if not condition:
        raise Incomplete(message)


def digest(data):
    return hashlib.sha256(data).hexdigest()


def git(repo, *args):
    environment = {key: value for key, value in os.environ.items() if not key.startswith('GIT_')}
    environment.update(GIT_NO_REPLACE_OBJECTS='1', GIT_NO_LAZY_FETCH='1', GIT_TERMINAL_PROMPT='0')
    return subprocess.check_output(['git', '-C', str(repo), *args], env=environment)


def object_file(path):
    require(path.is_file() and not path.is_symlink(), 'A regular research evidence file is required.')
    value = json.loads(path.read_text())
    require(isinstance(value, dict), 'Research evidence must be a JSON object.')
    return value


def private_file(root, name):
    path = Path(name)
    require(not path.is_absolute() and '..' not in path.parts, 'Research evidence must stay in its store.')
    result = root / path
    require(all(not part.is_symlink() for part in (result, *result.parents))
            and result.resolve().is_relative_to(root.resolve()) and result.is_file(),
            'Research evidence is missing, outside its store, or symlinked.')
    return result


def contract_at(repo, head):
    return json.loads(git(repo, 'show', head + ':ci_scripts/push_verification.json'))


def input_digest(repo, head, spec):
    paths = spec['inputs']
    require(isinstance(paths, list) and paths and len(set(paths)) == len(paths)
            and all(isinstance(p, str) and p and not Path(p).is_absolute() and '..' not in Path(p).parts
                    for p in paths), 'Invalid schema research input scope.')
    entries, matched = [], set()
    for line in git(repo, 'ls-tree', '-r', '-z', head).decode().split('\0'):
        if not line:
            continue
        metadata, path = line.split('\t', 1)
        selectors = [p for p in paths if path == p or p.endswith('/') and path.startswith(p)]
        if selectors:
            require(metadata.split()[0] in {'100644', '100755'}, 'Research inputs must be regular tracked files.')
            matched.update(selectors)
            entries.append([path, metadata])
    require(matched == set(paths), 'A declared schema research input is missing.')
    return digest(json.dumps(entries, separators=(',', ':')).encode())


def validate_partition(repo, head, contract):
    spec = contract['schema_research']
    normal = contract['checks']['tests']
    require(normal['test_plan'] != spec['test_plan'] and len(normal['targets']) == 1
            and normal['targets'][0] != spec['target'],
            'Normal and research scopes must be distinct complete test targets.')
    for research, path in ((False, spec['normal_plan_path']), (True, spec['plan_path'])):
        plan = json.loads(git(repo, 'show', head + ':' + path))
        require(Path(path).stem == (spec['test_plan'] if research else normal['test_plan'])
                and plan.get('version') == 2 and plan.get('defaultOptions') == {}
                and len(plan.get('configurations', [])) == 1
                and plan['configurations'][0].get('options') == {},
                'Unexpected native plan configuration changes the research partition.')
        name = spec['target'] if research else normal['targets'][0]
        target = {'containerPath': 'container:', 'identifier': name, 'name': name}
        expected = {'target': target}
        require(plan.get('testTargets') == [expected], 'The plans omit, overlap, or add excluded tests.')
    require(spec['cases'] and all(case.startswith(spec['target'] + '/') and meaning
                                 for case, meaning in spec['cases'].items()),
            'Declared research assertions lack their native target or meaning.')


def nodes(tree):
    for node in tree:
        yield node
        yield from nodes(node.get('children', []))


def runtime_identity(summary):
    identities = set()
    for entry in summary.get('devicesAndConfigurations', []):
        device = entry['device']
        identity = tuple(device.get(key) for key in ('platform', 'architecture', 'osVersion', 'osBuildNumber'))
        require(all(identity), 'Native runtime build identity is missing.')
        identities.add(identity)
    require(identities, 'Native runtime inventory is missing.')
    return sorted(identities)


def sdk_build():
    value = subprocess.check_output(['xcrun', '--sdk', 'iphonesimulator', '--show-sdk-build-version'],
                                    text=True, timeout=30).strip()
    require(value, 'The current Simulator SDK build is unavailable.')
    return value


def assess(repo, execution, build, summary, tree, review, raw, contract):
    spec = contract['schema_research']
    source = execution.get('source', {})
    head = source.get('before', {}).get('head', '')
    require(isinstance(head, str) and re.fullmatch(r'[0-9a-f]{40}|[0-9a-f]{64}', head),
            'The research source must be an immutable commit ID.')
    require(source.get('stable_clean_snapshot') is True and source.get('before') == source.get('after')
            and source['before'].get('clean') is True
            and source['before'].get('tree') == git(repo, 'rev-parse', head + '^{tree}').decode().strip(),
            'Research must use a stable clean committed source.')
    verification = execution.get('verification', {})
    require(execution.get('schema_version') == 1 and verification.get('ran') is True
            and verification.get('exit_code') == 0 and not execution.get('evidence_errors'),
            'The research command failed or captured evidence is incomplete.')
    argv = verification['argv']
    require(argv.count('-scheme') == 1 and argv[argv.index('-scheme') + 1] == spec['scheme']
            and argv.count('-testPlan') == 1 and argv[argv.index('-testPlan') + 1] == spec['test_plan']
            and argv.count('test') == 1
            and not any(word.startswith(('-only-testing', '-skip-testing', '-only-test-configuration',
                                         '-skip-test-configuration')) for word in argv),
            'The complete declared research plan was not executed.')
    require(build.get('status') == 'succeeded'
            and all(build.get(k) == 0 for k in ('errorCount', 'warningCount', 'analyzerWarningCount'))
            and all(build.get(k) == [] for k in ('errors', 'warnings', 'analyzerWarnings')),
            'Native build issues remain in research.')
    cases = {node.get('nodeIdentifier'): node for node in nodes(tree.get('testNodes', []))
             if node.get('nodeType') == 'Test Case'}
    bundles = {node.get('name'): node.get('result') for node in nodes(tree.get('testNodes', []))
               if node.get('nodeType') in {'Unit test bundle', 'UI test bundle'}}
    expected = {case.removeprefix(spec['target'] + '/'): meaning for case, meaning in spec['cases'].items()}
    require(bundles == {spec['target']: 'Passed'} and set(cases) == set(expected)
            and all(node.get('result') == 'Passed' for node in cases.values())
            and summary.get('result') == 'Passed' and summary.get('passedTests') == len(expected)
            and summary.get('totalTestCount') == len(expected)
            and execution.get('tests', {}).get('executed') == len(expected)
            and all(summary.get(k) == 0 for k in ('failedTests', 'skippedTests', 'expectedFailures'))
            and summary.get('testFailures') == [] and summary.get('runtimeWarnings') == [],
            'Research assertions are missing, skipped, failed, or unexpectedly changed.')
    require(not any(token in output for output in raw.values()
                    for token in ('BUG IN CLIENT', 'AddressSanitizer:', 'ThreadSanitizer:')),
            'Research has an unexpected runtime lifecycle fault.')
    diagnostics = execution.get('diagnostics', {})
    require(diagnostics.get('complete_captured_output') is True, 'Research raw diagnostic capture is incomplete.')
    require(review.get('source_head') == head, 'Research diagnostic review belongs to another source.')
    entries = review.get('diagnostics', [])
    seen = set()
    passed = {node['nodeIdentifierURL'] for node in cases.values()}
    for kind in ('error', 'warning'):
        candidates = diagnostics.get(kind + 's', [])
        require(diagnostics.get(kind + '_count') == len(candidates), 'Research diagnostic counts are inconsistent.')
        for candidate in candidates:
            matches = [e for e in entries if e.get('kind') == kind and e.get('line') == candidate.get('line')
                       and e.get('text_sha256') == digest(candidate.get('text', '').encode())]
            require(len(matches) == 1, 'Every research diagnostic needs one exact contextual review.')
            entry = matches[0]
            key = (kind, entry['line'], entry['text_sha256'])
            require(key not in seen and entry.get('test_id') in passed and entry.get('reason'),
                    'Duplicated research diagnostic or missing passed assertion context.')
            seen.add(key)
            lines = raw.get(entry.get('artifact'), '').splitlines()
            require(0 < entry['line'] <= len(lines)
                    and digest(lines[entry['line'] - 1].encode()) == entry['text_sha256'],
                    'Research diagnostic differs from retained raw output.')
            path = Path(entry.get('source_path', ''))
            require(not path.is_absolute() and '..' not in path.parts and 'Tests' in path.parts
                    and path.suffix == '.swift'
                    and digest(git(repo, 'show', head + ':' + str(path))) == entry.get('source_sha256'),
                    'Research diagnostic test source changed or is missing.')
            span = entry.get('progress_span', {})
            require(0 < span.get('start_line', 0) <= entry['line'] <= span.get('pass_line', 0) <= len(lines),
                    'Research diagnostic lacks its complete start/pass context.')
    require(len(entries) == len(seen), 'Research review includes unrelated or duplicate diagnostics.')
    return head


def record(repo, captured, review_path, output):
    repo = repo.resolve()
    execution = object_file(captured / 'result.json')
    source_head = execution['source']['before']['head']
    contract = contract_at(repo, source_head)
    validate_partition(repo, source_head, contract)
    require(not output.exists() and output.parent.is_dir(), 'Use a new research output directory.')
    output.mkdir(mode=0o700)
    raw = {}
    for artifact in execution['artifacts']:
        name = artifact['path']
        require(Path(name).name == name, 'Captured artifacts must be local files.')
        path = private_file(captured, name)
        require(digest(path.read_bytes()) == artifact['sha256'], 'Captured raw output changed.')
        shutil.copyfile(path, output / name)
        raw[name] = path.read_text(errors='replace')
    shutil.copyfile(captured / 'result.json', output / 'execution.json')
    shutil.copyfile(review_path, output / 'diagnostic-review.json')
    argv = execution['verification']['argv']
    require(argv.count('-resultBundlePath') == 1, 'The producing native result bundle is missing.')
    bundle = argv[argv.index('-resultBundlePath') + 1]
    values = []
    for name, kind in (('native-build.json', ['build-results']),
                       ('native-tests.json', ['test-results', 'summary']),
                       ('native-test-tree.json', ['test-results', 'tests'])):
        result = subprocess.check_output(['xcrun', 'xcresulttool', 'get', *kind, '--path', bundle,
                                          '--format', 'json'], timeout=120)
        (output / name).write_bytes(result)
        values.append(json.loads(result))
    head = assess(repo, execution, *values, object_file(review_path), raw, contract)
    current_xcode = subprocess.check_output(['xcrun', 'xcodebuild', '-version'], text=True, timeout=30).strip()
    require(execution['environment'].get('xcodebuild') == current_xcode,
            'Record research with the producing Xcode, before changing its SDK.')
    result = {'schema_version': 1, 'producer': 'cookle-schema-research', 'status': 'observed',
              'safety_proof': False, 'source_head': head,
              'inputs_sha256': input_digest(repo, head, contract['schema_research']),
              'environment': execution['environment'], 'sdk_build': sdk_build(),
              'runtime': runtime_identity(values[1]), 'assertion_meaning': contract['schema_research']['cases'],
              'diagnostics': execution['diagnostics'],
              'artifacts': [{'path': path.name, 'sha256': digest(path.read_bytes())}
                            for path in sorted(output.iterdir())]}
    for path in output.iterdir():
        path.chmod(0o600)
    destination = output / 'result.json'
    destination.write_text(json.dumps(result, indent=2) + '\n')
    destination.chmod(0o600)
    return result


def check_observation(repo, target, store, reference, normal, current_sdk):
    contract = contract_at(repo, target)
    validate_partition(repo, target, contract)
    path = private_file(store, reference)
    observed = object_file(path)
    require(observed.get('schema_version') == 1 and observed.get('producer') == 'cookle-schema-research'
            and observed.get('status') == 'observed' and observed.get('safety_proof') is False,
            'A separate research observation is required; normal QA cannot replace it.')
    head = observed['source_head']
    require(subprocess.run(['git', '-C', str(repo), 'merge-base', '--is-ancestor', head, target],
                           capture_output=True).returncode == 0,
            'Research source is not part of the proposed history.')
    for artifact in observed.get('artifacts', []):
        file = private_file(path.parent, artifact['path'])
        require(digest(file.read_bytes()) == artifact['sha256'], 'Research raw/native/review artifacts changed.')
    names = {a['path'] for a in observed.get('artifacts', [])}
    require({'execution.json', 'native-build.json', 'native-tests.json', 'native-test-tree.json',
             'diagnostic-review.json', 'output.log'} <= names, 'Research artifacts are incomplete.')
    execution = object_file(path.parent / 'execution.json')
    build = object_file(path.parent / 'native-build.json')
    summary = object_file(path.parent / 'native-tests.json')
    tree = object_file(path.parent / 'native-test-tree.json')
    raw = {}
    for artifact in execution['artifacts']:
        file = private_file(path.parent, artifact['path'])
        require(digest(file.read_bytes()) == artifact['sha256'], 'Original research capture changed.')
        raw[artifact['path']] = file.read_text(errors='replace')
    require(assess(repo, execution, build, summary, tree, object_file(path.parent / 'diagnostic-review.json'),
                   raw, contract_at(repo, head)) == head, 'Research source binding changed.')
    require(observed.get('inputs_sha256') == input_digest(repo, head, contract['schema_research'])
            == input_digest(repo, target, contract['schema_research']),
            'Schema/storage/fixture inputs changed; run schema research again.')
    require(observed.get('diagnostics') == execution['diagnostics']
            and observed.get('assertion_meaning') == contract['schema_research']['cases'],
            'Research counts or assertion meaning were changed.')
    require(all(observed.get('environment', {}).get(k) == normal['environment'].get(k)
                == execution['environment'].get(k) for k in ('xcodebuild', 'swift'))
            and observed.get('sdk_build') == current_sdk,
            'Xcode/Swift/SDK changed; run schema research again.')
    require(observed.get('runtime') == [list(row) for row in runtime_identity(summary)]
            == [list(row) for row in runtime_identity(normal['native']['tests'])],
            'Simulator runtime changed; run schema research again.')
    research_ids = {case.split('/', 1)[1] for case in contract['schema_research']['cases']}
    normal_cases = {node['nodeIdentifier'] for node in nodes(normal['native_tree']['testNodes'])
                    if node.get('nodeType') == 'Test Case'}
    require(not normal_cases & research_ids, 'Research assertions were included in normal QA.')
    return {'source_head': head, 'target_head': target, 'status': 'observed', 'safety_proof': False,
            'warnings': observed['diagnostics']['warning_count'], 'errors': observed['diagnostics']['error_count']}


def match(repo, remote_location, lines):
    if not lines.strip():
        return []
    common = Path(git(repo, 'rev-parse', '--path-format=absolute', '--git-common-dir').decode().strip())
    store = common / 'push-verification'
    require(store.is_dir() and not store.is_symlink(), 'Schema research receipt store is missing.')
    receipt = object_file(private_file(store, 'destinations/' + digest(remote_location.encode()) + '/receipt.json'))
    results = []
    for line in lines.splitlines():
        parts = line.split()
        require(len(parts) == 4, 'Invalid publication tuple for research matching.')
        target = parts[1]
        reference = receipt.get('schema_research', {}).get(target)
        require(reference, 'Schema research required: no matching observation; run the research plan first.')
        normal_reference = receipt['quality'][target]['checks']['tests']['evidence']
        normal = object_file(private_file(store, normal_reference))
        tree_path = Path(normal_reference).parent / 'native-test-tree.json'
        normal['native_tree'] = object_file(private_file(store, str(tree_path)))
        results.append(check_observation(repo, target, store, reference, normal, sdk_build()))
    print('Schema research observations matched; passing characterizes behavior, not data-loss safety.')
    return results


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('command', choices=['record'])
    parser.add_argument('--repo', type=Path, default=Path(__file__).resolve().parents[2])
    parser.add_argument('--captured', type=Path, required=True)
    parser.add_argument('--review', type=Path, required=True)
    parser.add_argument('--output', type=Path, required=True)
    args = parser.parse_args()
    try:
        result = record(args.repo, args.captured, args.review, args.output)
        print(json.dumps({key: result[key] for key in ('status', 'source_head', 'safety_proof')}))
        return 0
    except (OSError, ValueError, KeyError, TypeError, subprocess.SubprocessError) as error:
        print('Schema research incomplete: ' + str(error))
        return 2


if __name__ == '__main__':
    raise SystemExit(main())
