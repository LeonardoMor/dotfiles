import configparser
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


ROOT = Path(__file__).resolve().parents[1]
DROPIN = ROOT / (
    r'home/dot_config/systemd/user/app-limine\x2drestore\x2dnotify@autostart.service.d/'
    '10-dms-readiness.conf.tmpl'
)


def render(platform='linux', hostname='infinity'):
    with tempfile.TemporaryDirectory(prefix='limine-render-') as source:
        return subprocess.check_output([
            'chezmoi', '--config', '/dev/null', '--config-format', 'toml', '--source', source,
            '--override-data', json.dumps({'chezmoi': {'os': platform, 'hostname': hostname}}),
            'execute-template', '--file', str(DROPIN),
        ], text=True)


class LimineRestoreNotificationTests(unittest.TestCase):
    def test_hyprland_does_not_duplicate_packaged_autostart(self):
        config = (ROOT / 'home/dot_config/hypr/hyprland.lua').read_text()
        self.assertNotIn('limine-snapper-restore', config)

    def test_notifier_waits_for_existing_dms_readiness(self):
        self.assertTrue(DROPIN.is_file(), 'Missing notifier readiness drop-in')
        config = configparser.ConfigParser()
        config.read_string(render())
        self.assertEqual(config['Unit']['After'].split(), ['dms.service'])
        self.assertEqual(config['Unit']['Requisite'].split(), ['dms.service'])
        self.assertNotIn('Requires', config['Unit'])
        self.assertNotIn('Wants', config['Unit'])
        self.assertEqual(config.sections(), ['Unit'])

    def test_other_hosts_and_platforms_are_unchanged(self):
        for platform, hostname in [('linux', 'other'), ('darwin', 'infinity'), ('windows', 'infinity')]:
            with self.subTest(platform=platform, hostname=hostname):
                self.assertEqual(render(platform, hostname), '')

    def test_systemd_accepts_rendered_dropin_with_packaged_unit(self):
        with tempfile.TemporaryDirectory(prefix='limine-units-') as directory:
            units = Path(directory)
            name = DROPIN.parent.name.removesuffix('.d')
            (units / name).write_text(
                '[Unit]\nPartOf=graphical-session.target\nAfter=graphical-session.target\n'
                '[Service]\nType=exec\nExitType=cgroup\nExecStart=/usr/bin/true\n'
            )
            (units / 'dms.service').write_text(
                '[Service]\nType=notify\nBusName=org.freedesktop.Notifications\nExecStart=/usr/bin/true\n'
            )
            dropin = units / DROPIN.parent.name / DROPIN.name.removesuffix('.tmpl')
            dropin.parent.mkdir()
            dropin.write_text(render())
            result = subprocess.run([
                'systemd-analyze', '--user', '--man=no', '--generators=no', 'verify', name,
            ], text=True, capture_output=True, env={
                **os.environ, 'SYSTEMD_UNIT_PATH': directory + ':/usr/lib/systemd/user',
            }, timeout=10)
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
