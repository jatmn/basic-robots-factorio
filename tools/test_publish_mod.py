#!/usr/bin/env python3
"""Exercise Mod Portal publishing decisions on a real built ZIP, with the portal simulated."""
import hashlib
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import textwrap
import unittest
from unittest.mock import patch

import publish_mod
from test_package import PackageSourceTests
import validate_package

UPLOAD = {'upload_url': 'https://uploads.example.test/upload'}


class PortalPublishTests(unittest.TestCase):
    git = PackageSourceTests.git
    tool = PackageSourceTests.tool

    def setUp(self):
        PackageSourceTests.setUp(self)
        built = self.tool('package.py')
        self.assertEqual(built.returncode, 0, built.stderr)
        self.archive = self.output / 'basic-robots-f2_1.2.9.zip'
        root = patch.object(validate_package, 'ROOT', self.root)
        root.start()
        self.addCleanup(root.stop)

    def portal(self, version='1.2.9', sha1=None):
        return {'releases': [
            {'version': '0.3.0', 'file_name': 'basic-robots-f2_0.3.0.zip', 'sha1': 'old'},
            {'version': version, 'file_name': f'basic-robots-f2_{version}.zip',
             'sha1': sha1 or hashlib.sha1(self.archive.read_bytes()).hexdigest()},
        ]}

    def publish(self, tag='v1.2.9', token='fixture-key'):
        publish_mod.publish(self.output, tag, token)

    def test_upload_uses_key_only_to_initialize_then_verifies_bytes(self):
        with patch.object(publish_mod, 'listing', side_effect=[{'releases': []}, self.portal()]) as listing, \
                patch.object(publish_mod, 'request_json', side_effect=[UPLOAD, {'success': True}]) as request:
            self.publish()
        init, upload = request.call_args_list
        self.assertEqual(init.args, (publish_mod.PORTAL + '/api/v2/mods/releases/init_upload',
                                     {'mod': 'basic-robots-f2'}))
        self.assertEqual(init.kwargs, {'token': 'fixture-key'})
        self.assertEqual(upload.args, (UPLOAD['upload_url'], {}))
        self.assertEqual(upload.kwargs, {'archive': self.archive})
        self.assertEqual(listing.call_count, 2)

    def test_retry_requires_identical_bytes_and_refuses_older_versions(self):
        with patch.object(publish_mod, 'request_json') as request:
            with patch.object(publish_mod, 'listing', return_value=self.portal()):
                self.publish()
            with patch.object(publish_mod, 'listing', return_value=self.portal(sha1='different')), \
                    self.assertRaisesRegex(ValueError, 'different package bytes'):
                self.publish()
            with patch.object(publish_mod, 'listing', return_value=self.portal(version='1.3.0')), \
                    self.assertRaisesRegex(ValueError, 'newer version'):
                self.publish()
            # An identical package on the portal does not excuse a newer version beside it.
            both = self.portal()
            both['releases'].append({'version': '1.3.0', 'file_name': 'basic-robots-f2_1.3.0.zip', 'sha1': 'new'})
            with patch.object(publish_mod, 'listing', return_value=both), \
                    self.assertRaisesRegex(ValueError, 'newer version'):
                self.publish()
            request.assert_not_called()

    def test_invalid_inputs_and_portal_failures_stop(self):
        with patch.object(publish_mod, 'listing') as listing, patch.object(publish_mod, 'request_json') as request:
            with self.assertRaisesRegex(ValueError, 'must match info.json'):
                self.publish(tag='v1.2.8')
            with self.assertRaisesRegex(ValueError, 'FACTORIO_API_KEY'):
                self.publish(token='')
            listing.assert_not_called()
            listing.return_value = None
            with self.assertRaisesRegex(ValueError, 'listing does not exist'):
                self.publish()
            request.assert_not_called()
        (self.output / 'SHA256SUMS').write_text('0' * 64 + '  ' + self.archive.name + '\n')
        with self.assertRaisesRegex(ValueError, 'SHA256SUMS'):
            self.publish()
        self.tool('package.py')
        for reply in ({'error': 'Unknown'}, {'upload_url': 'http://uploads.example.test/upload'},
                      {'upload_url': 'https://user:pass@uploads.example.test/upload'}):
            with self.subTest(reply=reply), patch.object(publish_mod, 'listing', return_value={'releases': []}), \
                    patch.object(publish_mod, 'request_json', return_value=reply) as request, \
                    self.assertRaisesRegex(ValueError, 'valid HTTPS upload destination'):
                self.publish()
            self.assertEqual(request.call_count, 1)
        with patch.object(publish_mod, 'listing', return_value={'releases': []}), \
                patch.object(publish_mod, 'request_json', side_effect=[UPLOAD, {'success': False}]), \
                self.assertRaisesRegex(ValueError, 'rejected'):
            self.publish()

    def test_listing_reads_past_the_cdn_cache(self):
        with patch.object(publish_mod, 'request_json', return_value={'releases': []}) as request:
            publish_mod.listing('basic-robots-f2')
            publish_mod.listing('basic-robots-f2')
        first, second = (call.args[0] for call in request.call_args_list)
        self.assertTrue(first.startswith(publish_mod.PORTAL + '/api/mods/basic-robots-f2?fresh='))
        self.assertNotEqual(first, second)


class PortalWorkflowTests(unittest.TestCase):
    guard = 'Require the unchanged draft before writing to the Mod Portal'
    name = 'Publish the same package to the Mod Portal when connected'
    page = 'Bring the Mod Portal page in line with portal/ when connected'

    def setUp(self):
        self.workflow = (Path(__file__).resolve().parents[1] / '.github/workflows/release-please.yml').read_text()
        self.names = [line.split('- name: ', 1)[1] for line in self.workflow.splitlines()
                      if line.startswith('      - name: ')]

    def step(self, name):
        return self.workflow.split('      - name: ' + name + '\n', 1)[1].split('\n      - ', 1)[0]

    def test_portal_steps_precede_github_publication_with_only_their_key(self):
        self.assertEqual(self.names[self.names.index('Build and validate the release') + 1:][:4],
                         [self.guard, self.name, self.page, 'Attach the installable mod and publish'])
        guard = self.step(self.guard)
        self.assertIn("if: steps.draft.outputs.sha != ''", guard)
        self.assertIn('RELEASE_SHA: ${{ steps.draft.outputs.sha }}', guard)
        self.assertNotIn('FACTORIO_API_KEY', guard)
        for name in (self.name, self.page):
            env = self.step(name).split('        run:', 1)[0]
            self.assertIn("if: steps.draft.outputs.sha != ''", env)
            self.assertIn('FACTORIO_API_KEY: ${{ secrets.FACTORIO_API_KEY }}', env)
            self.assertNotIn('GH_TOKEN', env)
            self.assertNotIn('RELEASE_PLEASE_TOKEN', env)

    def run_step(self, name, key, workspace, exit_code=0):
        script = textwrap.dedent(self.step(name).split('        run: |\n', 1)[1])
        summary = workspace / 'summary'
        summary.write_text('')
        return subprocess.run(
            ['bash', '-e', '-o', 'pipefail', '-c', script], capture_output=True, text=True,
            env={**os.environ, 'PATH': str(workspace) + os.pathsep + os.environ['PATH'],
                 'FACTORIO_API_KEY': key, 'TAG': 'v1.2.9', 'GITHUB_STEP_SUMMARY': str(summary),
                 'PY_LOG': str(workspace / 'python-args'), 'PY_EXIT': str(exit_code)},
        )

    def test_guard_step_stops_on_a_changed_draft_or_moved_tag(self):
        # The shared guard's full state matrix runs through the Attach step in
        # test_prepare_release.py; this checks the pre-portal step runs that same guard.
        sha = 'a' * 40
        draft = {'isDraft': True, 'tagName': 'v1.2.9', 'targetCommitish': sha}
        moved = [{'ref': 'refs/tags/v1.2.9'}]
        cases = ((draft, [], sha, 0), (draft, [{'ref': 'refs/tags/v1.2.90'}], sha, 0), (draft, moved, sha, 0),
                 (draft, moved, 'b' * 40, 1), ({**draft, 'isDraft': False}, [], sha, 1),
                 ({**draft, 'targetCommitish': 'b' * 40}, [], sha, 1))
        root = Path(__file__).resolve().parents[1]
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            (workspace / 'gh').write_text(f'#!{sys.executable}\n' + textwrap.dedent('''\
                import os, sys
                args = sys.argv[1:]
                replies = {
                    ('release', 'view', 'v1.2.9', '--json', 'isDraft,targetCommitish,tagName'): 'DRAFT',
                    ('api', 'repos/fixture/fixture/git/matching-refs/tags/v1.2.9'): 'REFS',
                    ('api', 'repos/fixture/fixture/commits/refs/tags/v1.2.9', '--jq', '.sha'): 'TAG_SHA',
                }
                if tuple(args) not in replies:
                    sys.exit('Unexpected gh request: ' + repr(args))
                print(os.environ[replies[tuple(args)]])
                '''))
            (workspace / 'gh').chmod(0o755)
            script = self.step(self.guard).split('        run: ', 1)[1].strip()
            for state, refs, tag_sha, expected in cases:
                with self.subTest(state=state, refs=refs, tag_sha=tag_sha):
                    result = subprocess.run(
                        ['bash', '-e', '-c', script], cwd=root, capture_output=True, text=True,
                        env={**os.environ, 'PATH': str(workspace) + os.pathsep + os.environ['PATH'],
                             'TAG': 'v1.2.9', 'RELEASE_SHA': sha, 'GH_REPO': 'fixture/fixture',
                             'RUNNER_TEMP': directory, 'DRAFT': json.dumps(state),
                             'REFS': json.dumps(refs), 'TAG_SHA': tag_sha},
                    )
                    self.assertEqual(result.returncode, expected, result.stderr)

    def test_missing_key_skips_and_present_key_runs_portal_tools(self):
        with tempfile.TemporaryDirectory() as directory:
            workspace = Path(directory)
            log = workspace / 'python-args'
            fake = workspace / 'python3'
            fake.write_text('#!/bin/sh\nprintf "%s\\n" "$*" > "$PY_LOG"\nexit "$PY_EXIT"\n')
            fake.chmod(0o755)
            for name, tool in ((self.name, 'publish_mod.py'), (self.page, 'portal_page.py')):
                for key, exit_code in (('', 0), ('fixture-key', 0), ('fixture-key', 3)):
                    with self.subTest(step=name, key=bool(key), exit_code=exit_code):
                        log.unlink(missing_ok=True)
                        result = self.run_step(name, key, workspace, exit_code)
                        self.assertEqual(result.returncode, exit_code if key else 0, result.stderr)
                        summary = (workspace / 'summary').read_text()
                        if key:
                            self.assertEqual(log.read_text(), f'tools/{tool} --tag v1.2.9\n')
                            self.assertEqual(summary, '')
                        else:
                            self.assertFalse(log.exists())
                            self.assertEqual('not connected' in summary, tool == 'publish_mod.py')


if __name__ == '__main__':
    unittest.main(defaultTest=['PortalPublishTests', 'PortalWorkflowTests'])
