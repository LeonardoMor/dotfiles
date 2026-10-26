#!/usr/bin/env python3
"""Exercise automatic Gamescope mode selection without starting a compositor."""
import io
import json
import os
from pathlib import Path
import runpy
import subprocess
import sys
import tempfile
from unittest.mock import patch

root = Path(__file__).resolve().parents[1]
wrapper = root / 'home/dot_local/libexec/gamescope-session/executable_gamescope.tmpl'
with tempfile.TemporaryDirectory() as directory:
    def render(host):
        return subprocess.check_output([
            'chezmoi', '--config', '/dev/null', '--config-format', 'toml', '--source', directory,
            '--override-data', json.dumps({'chezmoi': {'hostname': host}}),
            'execute-template', '--file', str(wrapper),
        ], text=True)

    assert render('other') == ''
    script = render('infinity')
    assert script.startswith('#!/usr/bin/env python3'), 'Missing automatic monitor/mode selector'
    path = Path(directory) / 'gamescope.py'
    path.write_text(script)
    module = runpy.run_path(str(path))
    select_mode = module['select_mode']
    fixture = '''Connectors:
10 1 connected eDP-1 300x200 1 1
  #0 3840x2160 240.00 3840 3841 3842 4000 2160 2161 2162 2200 100000 flags: phsync; type: preferred
20 2 disconnected HDMI-A-1 0x0 0 2
30 3 connected DP-5 590x330 4 3, 4
  #0 2560x1440 59.95 2560 2608 2640 2720 1440 1443 1448 1481 241500 flags: phsync; type: preferred
  #1 2560x1440 279.96 2560 2608 2640 2720 1440 1443 1448 1653 1258750 flags: phsync; type:
  #2 1920x1080 360.00 1920 1968 2000 2080 1080 1083 1088 1240 722000 flags: phsync; type:
  #3 7680x4320 60.00 7680 7700 7800 8000 4320 4330 4340 4400 100000 flags: interlace; type:
'''
    assert select_mode(fixture) == ('DP-5', 2560, 1440, 280)
    other_monitor = fixture.replace('DP-5', 'HDMI-A-2').replace('279.96', '164.99')
    assert select_mode(other_monitor) == ('HDMI-A-2', 2560, 1440, 165)
    assert select_mode(fixture.split('20 2 disconnected')[0]) == ('eDP-1', 3840, 2160, 240)
    for bad in ('', '30 3 connected DP-5 590x330 1 3\n  #0 malformed',
                fixture.replace('2560 2608', '0 2608')):
        try:
            select_mode(bad)
        except ValueError:
            pass
        else:
            raise AssertionError('Malformed or empty mode list was accepted')
    # Only mock process boundaries: parsing and argument construction are real.
    for args in (['--generate-drm-mode', 'fixed', '-O', 'old-port'],
                 ['-f', '--', 'game with spaces'], []):
        prefix = str(Path.home() / '.local/libexec/gamescope-session') + ':'
        with patch.object(sys, 'argv', ['gamescope', *args]), \
             patch.dict(os.environ, {'PATH': prefix + '/usr/bin'}), \
             patch('subprocess.run', return_value=subprocess.CompletedProcess([], 0, fixture, '')) as query, \
             patch('os.execv') as execute, patch('sys.stderr', new_callable=io.StringIO):
            assert module['main']() is None
            expected = list(args)
            if args[:1] == ['--generate-drm-mode']:
                expected += ['--adaptive-sync', '-O', 'DP-5',
                             '-W', '2560', '-H', '1440', '-r', '280']
                query.assert_called_once()
            else:
                query.assert_not_called()
            execute.assert_called_once_with('/usr/bin/gamescope', ['/usr/bin/gamescope', *expected])
            assert os.environ['PATH'] == '/usr/bin'
    for error in (FileNotFoundError('modetest'), subprocess.TimeoutExpired('modetest', 12),
                  subprocess.CalledProcessError(1, 'modetest')):
        with patch.object(sys, 'argv', ['gamescope', '--generate-drm-mode']), \
             patch('subprocess.run', side_effect=error), patch('os.execv') as execute, \
             patch('sys.stderr', new_callable=io.StringIO) as stderr:
            assert module['main']() == 1
            execute.assert_not_called()
            assert 'display selection failed' in stderr.getvalue()
    print('PASS: automatic external/native mode selection, alternate monitor, fallback, input errors, argv/PATH preservation and query failures')
