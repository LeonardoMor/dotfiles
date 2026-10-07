#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'home/exact_bin/executable_wake-infinity.tmpl'
with tempfile.TemporaryDirectory() as source:
    def render(platform):
        return subprocess.check_output([
            'chezmoi', '--config', '/dev/null', '--config-format', 'toml', '--source', source,
            '--override-data', json.dumps({'chezmoi': {'os': platform}}),
            'execute-template', '--file', str(path),
        ], text=True)

    assert render('linux') == ''
    assert render('windows') == ''
    script = render('darwin')

subprocess.run(['bash', '-n'], input=script, text=True, check=True)
command = 'XDG_RUNTIME_DIR="/run/user/$(id -u)" WAYLAND_DISPLAY=wayland-1 wtype -k Shift_L'
stubs = f'''ssh() {{
    [[ $# == 2 && $1 == infinity && $2 == '{command}' ]] || return 99
    return "${{SSH_STATUS:-0}}"
}}
sleep() {{ [[ $# == 1 && $1 == 1 ]]; }}
'''
expected = ''.join(f'\rYou have {s:2d} seconds to connect' for s in range(15, 0, -1)) + '\n'
for status in (0, 23):
    result = subprocess.run(['bash', '-c', stubs + script], capture_output=True,
                            env={**os.environ, 'SSH_STATUS': str(status)})
    assert result.returncode == status, result
    assert result.stdout == (expected.encode() if status == 0 else b''), result
print('PASS: Mac-only rendering, Bash syntax, SSH command, countdown, and failed-wake handling')
