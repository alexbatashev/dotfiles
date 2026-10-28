#!/usr/bin/env python3
"""Behavior tests through native JSON hooks with local fake client executables."""
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

import yaml

ROOT = Path(__file__).resolve().parent
MANDATORY_PRINCIPLES = ('All loaded principle instructions are mandatory, not optional guidance. '
                        'Uphold every loaded principle unconditionally throughout the task. '
                        'Do not silently skip, weaken, or replace any requirement.')
FAKE = '''#!/usr/bin/env python3
import json, os, pathlib, sys, time
args = sys.argv[1:]
request = sys.stdin.read()
with open(os.environ['FAKE_CALLS'], 'a') as f:
    f.write(json.dumps({'args':args,'request':request,'env':{k:os.environ.get(k) for k in ('AGENT_ROUTER_CHILD','PLAN_REVIEW_CHILD','CLAUDECODE')},'cwd':os.getcwd()})+'\\n')
mode = os.environ.get('FAKE_MODE', '')
if mode == 'timeout': time.sleep(5)
if mode == 'crash': sys.exit(9)
result = json.loads(os.environ['FAKE_RESULT'])
if mode == 'malformed': result = {'playbook':None}
if '--output-last-message' in args:
    pathlib.Path(args[args.index('--output-last-message')+1]).write_text(json.dumps(result))
else:
    print(json.dumps({'structured_output':result}))
'''


class RoutingTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.base = Path(self.temporary.name)
        self.agents = self.base / 'agents'
        self.agents.mkdir()
        self.bin = self.base / 'bin'
        self.bin.mkdir()
        for client in ('codex', 'claude'):
            path = self.bin / client
            path.write_text(FAKE)
            path.chmod(0o755)
        self.playbook = 'Feature steps\n1. Identify data.\n2. Verify behavior.\n'
        self.p1 = 'Principle one full text\n' + 'a' * 12000 + '\n'
        self.p2 = 'Principle two full text λ\r\n'
        for path, content in (('playbooks/feature.md', self.playbook), ('playbooks/bug-fix.md', 'Bug fix steps'), ('skills/one/SKILL.md', self.p1), ('skills/two/SKILL.md', self.p2)):
            target = self.agents / path
            target.parent.mkdir(parents=True, exist_ok=True)
            target.write_bytes(content.encode('utf-8'))
        for kind, entries in (
            ('playbooks', [{'id': value, 'name': value, 'when': 'work', 'path': f'playbooks/{value}.md'} for value in ('feature', 'bug-fix')]),
            ('principles', [{'id': 'principle-' + value, 'name': value, 'when': 'coding', 'path': f'skills/{value}/SKILL.md'} for value in ('one', 'two')])):
            instructions = (yaml.safe_load((ROOT.parents[1]/'principles.yaml').read_text())['instructions']
                            if kind == 'principles' else 'playbooks instructions')
            (self.agents / (kind + '.yaml')).write_text(yaml.safe_dump({'version':1, 'scope':'Coding only', 'instructions':instructions, kind:entries}))
        self.env = dict(os.environ, PATH=str(self.bin) + os.pathsep + os.environ['PATH'],
                        AGENT_ROUTER_ROOT=str(self.agents), AGENT_ROUTER_STATE_DIR=str(self.base/'state'),
                        CODEX_HOME=str(self.base/'codex-config'), FAKE_CALLS=str(self.base/'calls'),
                        FAKE_RESULT=json.dumps({'playbook':None, 'principles':[], 'reason':'nothing'}))
        for key in ('AGENT_ROUTER_CHILD', 'PLAN_REVIEW_CHILD'):
            self.env.pop(key, None)
        self.event = {'session_id':'one', 'cwd':str(self.base), 'prompt':'Please implement the feature'}

    def choice(self, playbook=None, principles=()):
        self.env['FAKE_RESULT'] = json.dumps({'playbook':playbook,'principles':list(principles),'reason':'semantic test result'})

    def run_hook(self, client='codex', mode='prompt', **changes):
        event = dict(self.event, **changes)
        return subprocess.run([sys.executable, str(ROOT/'route_instructions.py'), client, mode],
                              input=json.dumps(event), text=True, capture_output=True, env=self.env)

    def context(self, result):
        self.assertEqual(result.returncode, 0, result.stderr)
        return json.loads(result.stdout)['hookSpecificOutput']['additionalContext'] if result.stdout else ''

    def calls(self):
        path = self.base/'calls'
        return [json.loads(line) for line in path.read_text().splitlines()] if path.exists() else []

    def snapshots(self):
        return {str(path):path.read_bytes() for path in (self.base/'state').rglob('*.json')}

    def assert_reminder(self, context):
        self.assertIn('Obey every rule in CLAUDE.md and AGENTS.md.', context)
        self.assertIn('These rules are mandatory, not optional guidance.', context)
        self.assertIn('Do not silently skip, weaken, or replace them.', context)

    def test_session_sources_remind_both_clients_without_state_or_classifier(self):
        self.env['FAKE_MODE'] = 'crash'
        for client in ('codex', 'claude'):
            for source in ('startup', 'resume', 'fork', 'clear', 'compact'):
                with self.subTest(client=client, source=source):
                    result = self.run_hook(client=client, mode='session', source=source, prompt=None)
                    context = self.context(result)
                    self.assertEqual(json.loads(result.stdout)['hookSpecificOutput']['hookEventName'], 'SessionStart')
                    self.assert_reminder(context)
                    self.assertNotIn(self.playbook, context)
                    self.assertNotIn(self.p1, context)
                    self.assertNotIn(MANDATORY_PRINCIPLES, context)
                    self.assertEqual(self.snapshots(), {})
        self.assertEqual(self.calls(), [])

    def test_session_requires_valid_session_id(self):
        for client in ('codex', 'claude'):
            for source in ('startup', 'compact'):
                for session_id in (None, '', 7):
                    with self.subTest(client=client, source=source, session_id=session_id):
                        result = self.run_hook(client=client, mode='session', source=source, session_id=session_id)
                        self.assertEqual(result.returncode, 2)
                        self.assertEqual(json.loads(result.stdout)['decision'], 'block')
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.snapshots(), {})

    def test_delayed_first_playbook_then_fixed(self):
        self.assertEqual(self.context(self.run_hook(prompt='hello')), '')
        self.choice('feature')
        self.assertIn(self.playbook, self.context(self.run_hook()))
        self.choice('bug-fix')
        self.assertEqual(self.context(self.run_hook(prompt='Fix another issue')), '')
        self.assertEqual(next(iter(self.snapshots().values())).decode().count('feature'), 1)
        self.assertEqual(json.loads(next(iter(self.snapshots().values())))['selected_playbook'], 'feature')

    def test_nonexclusive_principles_dedup_and_new_later(self):
        self.choice('feature', ['principle-one'])
        context = self.context(self.run_hook())
        self.assertIn(self.playbook, context)
        self.assertIn(self.p1, context)
        self.assertIn(MANDATORY_PRINCIPLES, context)
        self.assertEqual(self.context(self.run_hook()), '')
        self.choice(None, ['principle-one', 'principle-two'])
        context = self.context(self.run_hook())
        self.assertNotIn(self.p1, context)
        self.assertIn(self.p2, context)
        self.assertIn(MANDATORY_PRINCIPLES, context)

    def test_simultaneous_skills_and_compaction_no_classifier_or_playbook(self):
        self.choice('feature', ['principle-one', 'principle-two'])
        for client in ('codex', 'claude'):
            self.assertIn(MANDATORY_PRINCIPLES, self.context(self.run_hook(client=client)))
        self.env['FAKE_MODE'] = 'crash'
        changed = self.p1 + 'updated after initial load'
        (self.agents/'skills/one/SKILL.md').write_text(changed)
        catalog = yaml.safe_load((self.agents/'principles.yaml').read_text())
        catalog['principles'] = []
        (self.agents/'principles.yaml').write_text(yaml.safe_dump(catalog))
        before = self.snapshots()
        for client in ('codex', 'claude'):
            context = self.context(self.run_hook(client=client, mode='session', source='compact'))
            self.assert_reminder(context)
            self.assertIn(MANDATORY_PRINCIPLES, context)
            self.assertIn(changed, context)
            self.assertIn(self.p2, context)
            self.assertNotIn(self.playbook, context)
            self.assertEqual(self.snapshots(), before)
            for source in ('startup', 'resume', 'fork', 'clear'):
                context = self.context(self.run_hook(client=client, mode='session', source=source))
                self.assert_reminder(context)
                self.assertNotIn(self.p1, context)
                self.assertNotIn(self.p2, context)
        self.assertEqual(self.snapshots(), before)
        self.assertEqual(len(self.calls()), 2)

    def test_sessions_clients_and_cwd_are_isolated(self):
        self.choice('feature', ['principle-one'])
        self.assertIn(self.p1, self.context(self.run_hook()))
        elsewhere = self.base/'elsewhere'
        elsewhere.mkdir()
        self.assertEqual(self.context(self.run_hook(cwd=str(elsewhere))), '')
        self.assertIn(self.p1, self.context(self.run_hook(session_id='two')))
        self.assertIn(self.p1, self.context(self.run_hook(client='claude')))
        self.assertEqual(len(self.snapshots()), 3)

    def test_simultaneous_same_session_prompts_inject_once(self):
        self.choice('feature', ['principle-one'])
        command = [sys.executable, str(ROOT/'route_instructions.py'), 'codex', 'prompt']
        processes = [subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                      stderr=subprocess.PIPE, text=True, env=self.env) for _ in range(2)]
        outputs = []
        for process in processes:
            stdout, stderr = process.communicate(json.dumps(self.event))
            self.assertEqual(process.returncode, 0, stderr)
            outputs.append(stdout)
        self.assertEqual(sum(self.p1 in json.loads(output)['hookSpecificOutput']['additionalContext'] for output in outputs if output), 1)
        state = json.loads(next(iter(self.snapshots().values())))
        self.assertEqual([entry['id'] for entry in state['loaded_principles']], ['principle-one'])

    def test_failures_block_without_state_advancement(self):
        self.choice('feature', ['principle-one'])
        self.context(self.run_hook())
        before = self.snapshots()
        for mode in ('malformed', 'crash', 'timeout'):
            with self.subTest(mode=mode):
                self.env['FAKE_MODE'] = mode
                self.env['AGENT_ROUTER_TIMEOUT'] = '0.05' if mode == 'timeout' else '90'
                result = self.run_hook()
                self.assertEqual(result.returncode, 2)
                self.assertEqual(json.loads(result.stdout)['decision'], 'block')
                self.assertEqual(before, self.snapshots())
        self.env.pop('FAKE_MODE')
        self.choice(None, ['unknown-skill'])
        self.assertEqual(self.run_hook().returncode, 2)
        self.assertEqual(before, self.snapshots())
        self.choice('unknown-playbook')
        self.assertEqual(self.run_hook().returncode, 2)
        self.assertEqual(before, self.snapshots())

    def test_missing_file_does_not_partially_advance_selection(self):
        (self.agents/'skills/two/SKILL.md').unlink()
        self.choice('feature', ['principle-one', 'principle-two'])
        result = self.run_hook()
        self.assertEqual(result.returncode, 2)
        self.assertEqual(self.snapshots(), {})
        self.choice(None, ['principle-one'])
        self.context(self.run_hook())
        before = self.snapshots()
        (self.agents/'skills/one/SKILL.md').unlink()
        self.assertEqual(self.run_hook(mode='session', source='compact').returncode, 2)
        self.assertEqual(before, self.snapshots())

    def test_child_flags_model_and_provider_configuration_are_preserved(self):
        config = self.base/'codex-config/config.toml'
        config.parent.mkdir()
        config.write_text('model_provider="custom"\nmodel="configured-model"\n[mcp_servers."dot.server"]\ncommand="never-run"\n[model_providers.custom]\nbase_url="https://private.invalid"\n')
        project = self.base/'.codex/config.toml'
        project.parent.mkdir()
        project.write_text('[mcp_servers.project]\ncommand="never-run"\n')
        original = config.read_bytes()
        self.env['CLAUDECODE'] = 'outer'
        self.context(self.run_hook(model='inherited-model'))
        codex = self.calls()[-1]
        args = codex['args']
        self.assertEqual(args[args.index('--model')+1], 'inherited-model')
        for flag in ('--ephemeral', '--skip-git-repo-check', '--output-schema', '--output-last-message'):
            self.assertIn(flag, args)
        self.assertIn('read-only', args)
        self.assertIn('hooks', args)
        for flag in ('features.shell_tool=false', 'features.apps=false', 'features.multi_agent=false'):
            self.assertIn(flag, args)
        override = next(arg for arg in args if arg.startswith('mcp_servers='))
        self.assertIn('"dot.server"={enabled=false}', override)
        self.assertIn('"project"={enabled=false}', override)
        self.assertNotIn('model_provider=', ' '.join(args))
        self.assertEqual(codex['cwd'], str(self.base))
        self.assertIn('project_doc_max_bytes=0', args)
        self.assertIn('web_search="disabled"', args)
        self.assertTrue(any(arg.startswith('developer_instructions=') for arg in args))
        self.assertEqual(config.read_bytes(), original)
        self.assertEqual(codex['env'], {'AGENT_ROUTER_CHILD':'1','PLAN_REVIEW_CHILD':'1','CLAUDECODE':None})
        self.context(self.run_hook(client='claude', model='opus'))
        args = self.calls()[-1]['args']
        self.assertEqual(args[args.index('--tools')+1], '')
        self.assertIn('{"mcpServers":{}}', args)
        self.assertIn('--safe-mode', args)
        self.assertEqual(self.calls()[-1]['cwd'], str(self.base))
        self.assertIn('{"disableAllHooks":true}', args)
        self.assertEqual(args[args.index('--model')+1], 'opus')
        for flag in ('--strict-mcp-config', '--no-session-persistence', '--no-chrome', '--disable-slash-commands'):
            self.assertIn(flag, args)
        self.context(self.run_hook())
        self.assertNotIn('--model', self.calls()[-1]['args'])

    def test_child_guards_do_not_read_state_or_classify(self):
        for guard in ('AGENT_ROUTER_CHILD', 'PLAN_REVIEW_CHILD'):
            self.env[guard] = '1'
            self.assertEqual(self.context(self.run_hook()), '')
            self.env.pop(guard)
        self.assertEqual(self.calls(), [])
        self.assertEqual(self.snapshots(), {})

    def test_transcript_contains_only_short_same_session_message_context(self):
        transcript = self.base/'session.jsonl'
        records = [{'type':'response_item','payload':{'type':'message','role':role,'content':[{'type':'text','text':text}]}} for role,text in [('user','old context'),('assistant','response'),('user','recent question'),('assistant','recent answer')]]
        records += [{'type':'response_item','payload':{'type':'function_call_output','output':'SECRET TOOL OUTPUT'}}, {'type':'response_item','payload':{'type':'message','role':'user','content':[{'type':'text','text':'# AGENTS.md instructions\nSECRET SETUP'}]}}]
        transcript.write_text('\n'.join(json.dumps(record) for record in records))
        self.context(self.run_hook(prompt='continue', transcript_path=str(transcript)))
        request = self.calls()[-1]['request']
        self.assertIn('recent question', request)
        self.assertIn('recent answer', request)
        self.assertNotIn('SECRET TOOL OUTPUT', request)
        self.assertNotIn('SECRET SETUP', request)

    def test_installer_preserves_other_hooks_modes_and_is_idempotent(self):
        stop = [{'hooks':[{'type':'command','command':'python3 plan_review.py codex stop','timeout':240}]}]
        unrelated = {'hooks':[{'type':'command','command':'unchanged','extra':42}, {'type':'command','command':'python3 /unrelated/instruction_context.py'}]}
        for client, relative in (('codex','.codex/hooks.json'), ('claude','.claude/settings.json')):
            path = self.base/relative
            path.parent.mkdir(exist_ok=True)
            old_session = {'matcher':'compact', 'extra':'retain-group', 'hooks':[
                {'type':'command', 'command':f'python3 {self.base}/dotfiles/agents/hooks/instruction-routing/route_instructions.py {client} session'},
                {'type':'command', 'command':'another-compact-hook'}]}
            path.write_text(json.dumps({'model':'retain', 'hooks':{'Stop':stop, 'UserPromptSubmit':[unrelated], 'SessionStart':[unrelated, old_session]}}))
            path.chmod(0o640)
        command = [sys.executable, str(ROOT/'install.py'), '--home', str(self.base)]
        first = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(first.returncode, 0, first.stderr)
        values = {}
        for relative in ('.codex/hooks.json','.claude/settings.json'):
            path = self.base/relative
            values[relative] = path.read_bytes()
            settings = json.loads(values[relative])
            self.assertEqual(settings['model'], 'retain')
            self.assertEqual(settings['hooks']['Stop'], stop)
            self.assertEqual(settings['hooks']['UserPromptSubmit'][0], unrelated)
            self.assertEqual(settings['hooks']['SessionStart'][0], unrelated)
            self.assertEqual(settings['hooks']['SessionStart'][1], {'matcher':'compact', 'extra':'retain-group', 'hooks':[
                {'type':'command', 'command':'another-compact-hook'}]})
            self.assertEqual(len(settings['hooks']['SessionStart']), 3)
            self.assertNotIn('matcher', settings['hooks']['SessionStart'][-1])
            self.assertEqual(path.stat().st_mode & 0o777, 0o640)
            handler = settings['hooks']['UserPromptSubmit'][-1]['hooks'][0]
            self.assertEqual(handler.get('additionalContextLimit'), 0 if relative.startswith('.codex') else None)
        second = subprocess.run(command, capture_output=True, text=True)
        self.assertEqual(second.returncode, 0, second.stderr)
        for relative, value in values.items():
            self.assertEqual((self.base/relative).read_bytes(), value)
            backup = self.base/(relative+'.instruction-routing-backup')
            self.assertTrue(backup.exists())
            self.assertIn('"matcher": "compact"', backup.read_text())


    def test_initial_prompt_routes_before_transcript_exists(self):
        self.choice('feature', ('principle-one',))
        for client in ('codex', 'claude'):
            with self.subTest(client=client):
                content = self.context(self.run_hook(client=client, transcript_path=str(self.base/'not-created.jsonl')))
                self.assertIn(self.playbook, content)
                self.assertIn(self.p1, content)
                payload = json.loads(self.calls()[-1]['request'].split('UNTRUSTED TASK DATA AS JSON:\n', 1)[1])
                self.assertEqual(payload['recent_messages'], [])


if __name__ == '__main__':
    unittest.main()
