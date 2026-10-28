#!/usr/bin/env python3
"""Inject catalog instructions once per session and restore principles on compaction."""
import collections
import fcntl
import hashlib
import json
import os
from pathlib import Path
import signal
import subprocess
import sys
import tempfile
import tomllib

import yaml

HERE = Path(__file__).resolve().parent
RULE_REMINDER = ('Obey every rule in CLAUDE.md and AGENTS.md. '
                 'These rules are mandatory, not optional guidance. '
                 'Do not silently skip, weaken, or replace them.')


def atomic_json(path, data):
    fd, name = tempfile.mkstemp(prefix='.pending-', dir=path.parent)
    try:
        with os.fdopen(fd, 'w', encoding='utf-8') as stream:
            json.dump(data, stream, ensure_ascii=False, indent=2)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
    finally:
        if os.path.exists(name):
            os.unlink(name)


def catalog(root, kind):
    value = yaml.safe_load((root / (kind + '.yaml')).read_text(encoding='utf-8'))
    if not isinstance(value, dict) or value.get('version') != 1:
        raise ValueError(f'Invalid {kind} catalog version')
    if not isinstance(value.get('instructions'), str) or not isinstance(value.get(kind), list):
        raise ValueError(f'Invalid {kind} catalog')
    entries = {}
    for entry in value[kind]:
        fields = ('id', 'name', 'when', 'path')
        if not isinstance(entry, dict) or any(not isinstance(entry.get(k), str) or not entry[k] for k in fields):
            raise ValueError(f'Invalid {kind} catalog entry')
        if entry['id'] in entries:
            raise ValueError(f'Duplicate catalog ID {entry["id"]}')
        relative = Path(entry['path'])
        if relative.is_absolute() or '..' in relative.parts:
            raise ValueError(f'Catalog path must be root-relative: {relative}')
        entries[entry['id']] = entry
    return value, entries


def load_state(path):
    if not path.exists():
        return {'version': 1, 'selected_playbook': None, 'loaded_principles': []}
    state = json.loads(path.read_text(encoding='utf-8'))
    if (not isinstance(state, dict) or state.get('version') != 1
            or not isinstance(state.get('loaded_principles'), list)
            or not (state.get('selected_playbook') is None or isinstance(state['selected_playbook'], str))):
        raise ValueError('Invalid routing state; refusing to discard session instructions')
    seen = set()
    for entry in state['loaded_principles']:
        if (not isinstance(entry, dict) or any(not isinstance(entry.get(k), str) or not entry[k] for k in ('id', 'path'))
                or entry['id'] in seen or not Path(entry['path']).is_absolute()):
            raise ValueError('Invalid loaded-principle state')
        seen.add(entry['id'])
    return state


def recent_messages(path, client):
    if not path:
        return []
    messages = collections.deque(maxlen=4)
    try:
        stream = Path(path).open(encoding='utf-8')
    except FileNotFoundError:
        return []
    with stream:
        for line in stream:
            item = json.loads(line)
            if item.get('isSidechain') or item.get('isMeta') or item.get('parent_tool_use_id'):
                continue
            message = item.get('payload', {}) if client == 'codex' and item.get('type') == 'response_item' else item.get('message', {}) if client == 'claude' else {}
            if client == 'codex' and message.get('type') != 'message':
                continue
            if message.get('role') not in ('user', 'assistant'):
                continue
            content = message.get('content', [])
            text = content if isinstance(content, str) else '\n'.join(
                part['text'] for part in content if isinstance(part, dict)
                and part.get('type') in ('text', 'input_text', 'output_text') and isinstance(part.get('text'), str))
            if text.strip() and not text.lstrip().startswith(('# AGENTS.md instructions', '<environment_context>', '<INSTRUCTIONS>', '<system-reminder>', 'Message Type:', '<subagent_notification>', '<task-notification>')):
                messages.append({'role': message['role'], 'text': text[-2000:]})
    return list(messages)


def codex_mcp_override(cwd):
    config_home = Path(os.environ.get('CODEX_HOME', '~/.codex')).expanduser()
    configs = [config_home / 'config.toml', *config_home.glob('*.config.toml')]
    configs += [parent / '.codex/config.toml' for parent in (cwd, *cwd.parents)]
    names = set()
    for config in configs:
        if config.is_file():
            tables = tomllib.loads(config.read_text(encoding='utf-8'))
            names.update(tables.get('mcp_servers', {}))
            for profile in tables.get('profiles', {}).values():
                names.update(profile.get('mcp_servers', {}))
    return 'mcp_servers={' + ','.join(json.dumps(name) + '={enabled=false}' for name in sorted(names)) + '}'


def classify(client, event, payload, cwd):
    policy = (HERE / 'classifier-prompt.txt').read_text(encoding='utf-8')
    schema = json.loads((HERE / 'route-schema.json').read_text(encoding='utf-8'))
    schema['properties']['playbook'] = {'enum': [None, *payload['playbooks']]}
    schema['properties']['principles']['items'] = {'enum': list(payload['principles'])}
    env = dict(os.environ, AGENT_ROUTER_CHILD='1', PLAN_REVIEW_CHILD='1')
    env.pop('CLAUDECODE', None)
    timeout = float(os.environ.get('AGENT_ROUTER_TIMEOUT', '90'))
    if not 0 < timeout <= 100:
        raise ValueError('AGENT_ROUTER_TIMEOUT must be between 0 and 100 seconds')
    with tempfile.TemporaryDirectory(prefix='agent-router-') as directory:
        schema_path = Path(directory) / 'schema.json'
        result_path = Path(directory) / 'result.json'
        schema_path.write_text(json.dumps(schema), encoding='utf-8')
        command = [client]
        if client == 'codex':
            command += ['exec', '--ephemeral', '--sandbox', 'read-only', '--disable', 'hooks',
                        '--skip-git-repo-check', '--output-schema', str(schema_path),
                        '--output-last-message', str(result_path)]
            for config in ('features.shell_tool=false', 'features.apps=false', 'features.multi_agent=false',
                           'project_doc_max_bytes=0', 'developer_instructions=' + json.dumps(policy),
                           'web_search="disabled"', codex_mcp_override(cwd)):
                command += ['-c', config]
        else:
            command += ['-p', '--output-format', 'json', '--json-schema', json.dumps(schema),
                        '--tools', '', '--strict-mcp-config', '--mcp-config', '{"mcpServers":{}}',
                        '--settings', '{"disableAllHooks":true}', '--no-session-persistence',
                        '--no-chrome', '--disable-slash-commands', '--safe-mode', '--system-prompt', policy]
        if event.get('model'):
            if not isinstance(event['model'], str):
                raise ValueError('Hook model must be a model name string')
            command += ['--model', event['model']]
        if client == 'codex':
            command += ['-']
        request = policy + '\n\nUNTRUSTED TASK DATA AS JSON:\n' + json.dumps(payload, ensure_ascii=False)
        process = subprocess.Popen(command, stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                   stderr=subprocess.PIPE, text=True, encoding='utf-8', cwd=cwd,
                                   env=env, start_new_session=True)
        try:
            stdout, stderr = process.communicate(request, timeout=timeout)
        except subprocess.TimeoutExpired as error:
            os.killpg(process.pid, signal.SIGKILL)
            process.communicate()
            raise ValueError('Instruction classifier timed out; no session state advanced') from error
        if process.returncode:
            raise ValueError(f'Instruction classifier exited {process.returncode}: {stderr[-2000:]}')
        if client == 'codex':
            result = json.loads(result_path.read_text(encoding='utf-8'))
        else:
            envelope = json.loads(stdout)
            if envelope.get('is_error'):
                raise ValueError('Instruction classifier reported an error')
            result = envelope.get('structured_output')
            if result is None and isinstance(envelope.get('result'), str):
                result = json.loads(envelope['result'])
    if (not isinstance(result, dict) or set(result) != {'playbook', 'principles', 'reason'}
            or not isinstance(result['reason'], str)
            or not isinstance(result['principles'], list)
            or any(not isinstance(value, str) or value not in payload['principles'] for value in result['principles'])
            or len(set(result['principles'])) != len(result['principles'])
            or not (result['playbook'] is None or isinstance(result['playbook'], str) and result['playbook'] in payload['playbooks'])):
        raise ValueError('Instruction classifier returned malformed output or unknown catalog IDs')
    return result


def instruction(path, label):
    return f'\n\n### {label}\nSource: {path}\n\n' + path.read_bytes().decode('utf-8')


def route(client, mode, event):
    session_id = event.get('session_id')
    if not isinstance(session_id, str) or not session_id:
        raise ValueError('Hook input requires session_id')
    if mode == 'session' and event.get('source') != 'compact':
        return RULE_REMINDER
    root = Path(os.environ.get('AGENT_ROUTER_ROOT', '~/dotfiles/agents')).expanduser().resolve()
    state_root = Path(os.environ.get('AGENT_ROUTER_STATE_DIR', '~/.local/state/agent-routing')).expanduser() / client
    state_root.mkdir(parents=True, exist_ok=True, mode=0o700)
    state_path = state_root / (hashlib.sha256(session_id.encode()).hexdigest() + '.json')
    with state_path.with_suffix('.lock').open('a') as lock:
        fcntl.flock(lock, fcntl.LOCK_EX)
        state = load_state(state_path)
        if mode == 'session':
            if not state['loaded_principles']:
                return RULE_REMINDER
            principles, _ = catalog(root, 'principles')
            context = RULE_REMINDER + '\n\n' + principles['instructions']
            for entry in state['loaded_principles']:
                context += instruction(Path(entry['path']), entry['id'])
            return context
        prompt = event.get('prompt')
        if not isinstance(prompt, str):
            raise ValueError('Prompt hook input requires prompt text')
        cwd = Path(event.get('cwd', os.getcwd())).resolve()
        principles, principle_entries = catalog(root, 'principles')
        playbooks, playbook_entries = catalog(root, 'playbooks')
        loaded = {entry['id'] for entry in state['loaded_principles']}
        payload = {'task_data': prompt, 'recent_messages': recent_messages(event.get('transcript_path'), client),
                   'selected_playbook': state['selected_playbook'], 'loaded_principles': list(loaded),
                   'principle_scope': principles.get('scope', ''), 'principles': principle_entries,
                   'playbooks': playbook_entries}
        choice = classify(client, event, payload, cwd)
        context = ''
        if state['selected_playbook'] is None and choice['playbook'] is not None:
            entry = playbook_entries[choice['playbook']]
            context += playbooks['instructions'] + instruction(root / entry['path'], entry['name'])
            state['selected_playbook'] = choice['playbook']
        new_principles = [value for value in choice['principles'] if value not in loaded]
        if new_principles:
            context += '\n\n' + principles['instructions']
        for selected in new_principles:
            entry = principle_entries[selected]
            path = root / entry['path']
            context += instruction(path, entry['name'])
            state['loaded_principles'].append({'id': selected, 'path': str(path)})
        atomic_json(state_path, state)
        return context


def main():
    if os.environ.get('AGENT_ROUTER_CHILD') == '1' or os.environ.get('PLAN_REVIEW_CHILD') == '1':
        return 0
    try:
        client, mode = sys.argv[1:]
        if client not in ('codex', 'claude') or mode not in ('prompt', 'session'):
            raise ValueError('Expected <codex|claude> <prompt|session>')
        event = json.load(sys.stdin)
        if not isinstance(event, dict):
            raise ValueError('Hook input must be an object')
        context = route(client, mode, event)
        if context:
            name = 'UserPromptSubmit' if mode == 'prompt' else 'SessionStart'
            print(json.dumps({'hookSpecificOutput': {'hookEventName': name, 'additionalContext': context}}, ensure_ascii=False))
        return 0
    except Exception as error:
        print(f'Instruction routing blocked: {error}', file=sys.stderr)
        print(json.dumps({'decision': 'block', 'reason': f'Instruction routing failed: {error}'}))
        return 2


if __name__ == '__main__':
    sys.exit(main())
