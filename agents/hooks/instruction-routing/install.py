#!/usr/bin/env python3
"""Install only instruction-routing runtime and its two native hook handlers."""
import argparse
import json
from pathlib import Path
import shlex
import shutil
import stat
import sys

from route_instructions import atomic_json

FILES = ('route_instructions.py', 'classifier-prompt.txt', 'route-schema.json', 'install.py', 'test_routing.py')


def owned(command, destination):
    try:
        words = shlex.split(command)
    except ValueError:
        return False
    return str(destination / 'route_instructions.py') in words


def install(home):
    destination = home / 'dotfiles/agents/hooks/instruction-routing'
    destination.mkdir(parents=True, exist_ok=True)
    for name in FILES:
        source, target = Path(__file__).resolve().parent / name, destination / name
        if source.resolve() == target.resolve():
            continue
        if target.exists() and source.read_bytes() == target.read_bytes():
            continue
        if target.exists():
            backup = target.with_name(target.name + '.instruction-routing-backup')
            if not backup.exists():
                shutil.copy2(target, backup)
        shutil.copy2(source, target)
    for client, relative in (('codex', '.codex/hooks.json'), ('claude', '.claude/settings.json')):
        path = home / relative
        settings = json.loads(path.read_text(encoding='utf-8')) if path.exists() else {}
        before = json.dumps(settings, sort_keys=True)
        hooks = settings.setdefault('hooks', {})
        for event, mode in (('UserPromptSubmit', 'prompt'), ('SessionStart', 'session')):
            groups = []
            for group in hooks.get(event, []):
                remaining = [handler for handler in group['hooks'] if not owned(handler.get('command', ''), destination)]
                if remaining:
                    groups.append(dict(group, hooks=remaining))
            handler = {'type': 'command', 'command': 'python3 ' + shlex.quote(str(destination / 'route_instructions.py')) + f' {client} {mode}', 'timeout': 120}
            if client == 'codex':
                handler['additionalContextLimit'] = 0
            group = {'hooks': [handler]}
            groups.append(group)
            hooks[event] = groups
        if before == json.dumps(settings, sort_keys=True):
            continue
        path.parent.mkdir(parents=True, exist_ok=True)
        mode = stat.S_IMODE(path.stat().st_mode) if path.exists() else 0o600
        if path.exists():
            backup = path.with_name(path.name + '.instruction-routing-backup')
            if not backup.exists():
                shutil.copy2(path, backup)
        atomic_json(path, settings)
        path.chmod(mode)
    return destination


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--home', type=Path, default=Path.home())
    args = parser.parse_args()
    print(install(args.home.expanduser().resolve()))
