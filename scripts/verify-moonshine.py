#!/usr/bin/env python3
import json
from pathlib import Path
import subprocess
import tempfile
import tomllib

root = Path(__file__).resolve().parents[1]
packages = tomllib.loads((root / 'home/.externally_modified/metapac/groups/cachyos.toml').read_text())['arch']['packages']
assert packages.count('moonshine-bin') == 1, 'Moonshine must be declared once in the CachyOS group'
config = root / 'home/dot_config/moonshine/config.toml.tmpl'
assert config.is_file(), 'Missing infinity Moonshine configuration'
with tempfile.TemporaryDirectory() as source:
    def render(os, hostname):
        return subprocess.check_output([
            'chezmoi', '--config', '/dev/null', '--config-format', 'toml', '--source', source,
            '--persistent-state', str(Path(source) / 'state.boltdb'),
            '--override-data', json.dumps({'chezmoi': {'os': os, 'hostname': hostname}}),
            'execute-template', '--file', str(config),
        ], text=True)

    assert render('linux', 'other') == ''
    assert render('darwin', 'infinity') == ''
    values = tomllib.loads(render('linux', 'infinity'))
    assert values['name'] == 'infinity (Moonshine)'
    assert values['application_scanner'] == []
    assert values['compositor'] == {'gpu': '0000:01:00.0', 'hdr': False}
    assert values['application'] == [{
        'title': 'Steam', 'command': ['/usr/bin/steam', 'steam://open/bigpicture'],
        'stdout': 'journal', 'stderr': 'journal',
    }]
print('PASS: Moonshine package, host isolation, NVIDIA selection and Steam configuration')
