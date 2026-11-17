import importlib.machinery
import importlib.util
from pathlib import Path
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'home/exact_bin/executable_sunshine-start'


def load_helper():
    loader = importlib.machinery.SourceFileLoader('sunshine_start', str(HELPER))
    spec = importlib.util.spec_from_loader(loader.name, loader)
    assert spec is not None
    module = importlib.util.module_from_spec(spec)
    loader.exec_module(module)
    return module


class SunshineOutputTests(unittest.TestCase):
    def test_active_external_wins_over_internal_and_inactive_connectors(self):
        self.assertTrue(HELPER.exists(), 'Missing Sunshine startup display selector')
        helper = load_helper()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            for name, status, enabled in (
                ('card1-eDP-1', 'connected', 'enabled'),
                ('card1-DP-1', 'disconnected', 'disabled'),
                ('card1-DP-2', 'connected', 'disabled'),
                ('card1-DP-3', 'connected', 'enabled'),
            ):
                connector = root / name
                connector.mkdir()
                (connector / 'status').write_text(status + '\n')
                (connector / 'enabled').write_text(enabled + '\n')
            self.assertEqual(helper.select_output(root), 'DP-3')

    def test_internal_fallback_and_deterministic_external_selection(self):
        helper = load_helper()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            self.assertEqual(helper.select_output(root), 'eDP-1')
            for name in ('card4-eDP-1', 'card4-HDMI-A-1', 'card4-DP-3'):
                connector = root / name
                connector.mkdir()
                (connector / 'status').write_text('connected\n')
                (connector / 'enabled').write_text('enabled\n')
                if name.endswith('eDP-1'):
                    self.assertEqual(helper.select_output(root), 'eDP-1')
            self.assertEqual(helper.select_output(root), 'DP-3')
            (root / 'card4-DP-3/enabled').write_text('disabled\n')
            self.assertEqual(helper.select_output(root), 'HDMI-A-1')

    def test_disappeared_connector_is_ignored(self):
        helper = load_helper()
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            (root / 'card0-DP-1').mkdir()
            self.assertEqual(helper.select_output(root), 'eDP-1')

    def test_cli_executes_sunshine_with_override_and_forwards_arguments(self):
        from unittest.mock import patch
        helper = load_helper()
        with patch.object(helper, 'select_output', return_value='HDMI-A-1'), \
                patch.object(helper.os, 'execv') as execute, \
                patch.object(helper.sys, 'argv', ['sunshine-start', 'capture=kms']):
            helper.main()
        execute.assert_called_once_with(
            '/usr/bin/sunshine', ['sunshine', 'output_name=HDMI-A-1', 'capture=kms'])

    def test_startup_errors_fail_service(self):
        from unittest.mock import patch
        helper = load_helper()
        with patch.object(helper, 'select_output', side_effect=PermissionError('denied')):
            self.assertEqual(helper.main(), 1)
        with patch.object(helper, 'select_output', return_value='DP-3'), \
                patch.object(helper.os, 'execv', side_effect=FileNotFoundError('sunshine missing')):
            self.assertEqual(helper.main(), 1)

    def test_service_uses_selector_without_hardcoded_output(self):
        unit = ROOT / 'home/dot_config/systemd/user/app-dev.lizardbyte.app.Sunshine.service.tmpl'
        config = ROOT / 'home/dot_config/private_sunshine/private_sunshine.conf'
        self.assertIn('ExecStart=/usr/bin/python3 %h/bin/sunshine-start', unit.read_text())
        self.assertNotIn('output_name', config.read_text())
        self.assertIn('UnsetEnvironment=DISPLAY WAYLAND_DISPLAY XAUTHORITY HYPRLAND_INSTANCE_SIGNATURE',
                      unit.read_text())


if __name__ == '__main__':
    unittest.main()
