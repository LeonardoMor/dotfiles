#!/usr/bin/env python3
import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import tomllib

root = Path(sys.argv[1]) if len(sys.argv) > 1 else Path(__file__).resolve().parents[1]
packages = tomllib.loads((root / 'home/.externally_modified/metapac/groups/cachyos.toml').read_text())['arch']['packages']
entries = [p for p in packages if isinstance(p, dict) and p.get('name') == 'gamescope-session-cachyos']
assert len(entries) == 1
assert entries[0]['hooks']['after_sync'] == ['systemctl', '--user', 'daemon-reload']
helper = root / 'home/exact_bin/executable_steamos-session-select.tmpl'
assert helper.is_file(), 'Missing greetd-compatible session exit helper'
with tempfile.TemporaryDirectory() as source:
    def render(path, hostname='infinity'):
        return subprocess.check_output([
            'chezmoi', '--config', '/dev/null', '--config-format', 'toml', '--source', source,
            '--override-data', json.dumps({'chezmoi': {'os': 'linux', 'hostname': hostname}}),
            'execute-template', '--file', str(path),
        ], text=True)

    assert render(helper, 'other') == ''
    script = render(helper)
    subprocess.run(['bash', '-n'], input=script, text=True, check=True)
    for mode in ('plasma', 'desktop'):
        for status in (0, 23):
            stub = 'systemctl() { printf "%s\\n" "$*"; return "$STATUS"; }\n'
            result = subprocess.run(['bash', '-c', stub + script, 'check', mode],
                                    capture_output=True, text=True,
                                    env={**os.environ, 'STATUS': str(status)})
            assert result.returncode == status, result
            assert result.stdout == '--user --no-block stop gamescope-session.target\n', result
    mask = root / 'home/dot_config/systemd/user/symlink_cachyos-gamescope-autologin.service.tmpl'
    assert mask.is_file(), 'Missing mask for the unsupported autologin helper'
    assert render(mask).strip() == '/dev/null'
    assert render(mask, 'other') == ''

with tempfile.TemporaryDirectory() as config_home:
    config = Path(config_home) / 'scopebuddy'
    (config / 'AppID').mkdir(parents=True)
    for name in ('gamemode.conf', 'noscope.conf', 'common.conf', 'AppID/814380.conf'):
        path = root / 'home/dot_config/scopebuddy' / name
        assert path.is_file(), f'Missing ScopeBuddy config: {name}'
        (config / name).write_text(path.read_text())
    (config / 'scb.conf').write_text((config / 'noscope.conf').read_text())
    probe = Path(config_home) / 'probe.py'
    probe.write_text('import json, os\nprint(json.dumps({k: os.environ.get(k) for k in '
                     '("PROTON_ENABLE_WAYLAND", "SDL_GAMECONTROLLER_IGNORE_DEVICES", '
                     '"PROTON_DXVK_LOWLATENCY")}))\n')
    for desktop in ('gamescope', 'Hyprland'):
        result = subprocess.run(['scopebuddy', '--', sys.executable, str(probe)],
                                capture_output=True, text=True, env={**os.environ,
                                'XDG_CONFIG_HOME': config_home, 'XDG_CURRENT_DESKTOP': desktop,
                                'SCB_APPID': '814380', 'SCB_NOSCOPE': '0',
                                'GAMESCOPE_BIN': '/usr/bin/false', 'PROTON_ENABLE_WAYLAND': '1'})
        assert result.returncode == 0, result
        values = json.loads(result.stdout.splitlines()[-1])
        assert values['PROTON_DXVK_LOWLATENCY'] == '1', values
        assert values['SDL_GAMECONTROLLER_IGNORE_DEVICES'] == '0x3434/0x0630', values
        assert values['PROTON_ENABLE_WAYLAND'] == (None if desktop == 'gamescope' else '1'), values
print('PASS: session exit, autologin mask, ScopeBuddy bypass, shared config and Sekiro controller/display settings')
