#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile

path = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1] / 'home/exact_bin/executable_connect-infinity.tmpl'
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
    printf 'wake\\n'
    return "${{SSH_STATUS:-0}}"
}}
moonlight() {{
    [[ $# == 3 && $1 == stream && $2 == 192.168.100.7 && $3 == Desktop ]] || return 99
    printf 'stream\\n'
    return "${{MOONLIGHT_STATUS:-0}}"
}}
'''
for ssh_status, moonlight_status in ((0, 0), (23, 0), (0, 42)):
    result = subprocess.run(['bash', '-c', stubs + script], capture_output=True,
                            env={**os.environ, 'SSH_STATUS': str(ssh_status),
                                 'MOONLIGHT_STATUS': str(moonlight_status)})
    assert result.returncode == (ssh_status or moonlight_status), result
    assert result.stdout == (b'wake\n' if ssh_status else b'wake\nstream\n'), result
print('PASS: Mac-only rendering, Bash syntax, wake-before-stream ordering, arguments, and failure handling')
