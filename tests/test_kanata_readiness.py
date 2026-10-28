import importlib.machinery
import importlib.util
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import threading
import time
import unittest

ROOT = Path(__file__).resolve().parents[1]
HELPER = ROOT / 'home/exact_bin/executable_kanata-wait-ready'


class ReadinessTests(unittest.TestCase):
    def test_waits_for_every_connected_configured_keyboard(self):
        self.assertTrue(HELPER.exists(), 'Missing Kanata readiness check')
        loader = importlib.machinery.SourceFileLoader('kanata_ready', str(HELPER))
        spec = importlib.util.spec_from_loader(loader.name, loader)
        assert spec is not None
        module = importlib.util.module_from_spec(spec)
        loader.exec_module(module)
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory)
            first, second, absent = [root / name for name in ('first', 'second', 'absent')]
            first.touch()
            second.touch()
            config = root / 'kanata.kbd'
            config.write_text(f'(defcfg linux-dev ("{first}" "{second}" "{absent}"))')
            with first.open():
                with self.assertRaisesRegex(TimeoutError, 'keyboards'):
                    module.wait_ready(os.getpid(), config, timeout=0)
                with second.open():
                    module.wait_ready(os.getpid(), config, timeout=0)

    def test_cli_waits_for_delayed_keyboard_registration(self):
        with tempfile.TemporaryDirectory() as directory:
            device = Path(directory) / 'keyboard'
            device.touch()
            config = Path(directory) / 'kanata.kbd'
            config.write_text(f'(defcfg linux-dev ("{device}"))')
            release = threading.Event()

            def register():
                time.sleep(0.3)
                with device.open():
                    release.wait(5)

            thread = threading.Thread(target=register)
            thread.start()
            try:
                start = time.monotonic()
                result = subprocess.run([sys.executable, str(HELPER), str(os.getpid()), str(config)],
                                        capture_output=True, text=True, timeout=3)
                self.assertEqual(result.returncode, 0, result.stderr)
                self.assertGreaterEqual(time.monotonic() - start, 0.25)
            finally:
                release.set()
                thread.join()

    def test_cli_fails_closed_for_missing_devices_config_or_process(self):
        with tempfile.TemporaryDirectory() as directory:
            config = Path(directory) / 'kanata.kbd'
            device = Path(directory) / 'keyboard'
            for contents, pid in (
                ('(defcfg)', os.getpid()),
                (f'(defcfg linux-dev ("{device}"))', os.getpid()),
                (f'(defcfg linux-dev ("{config}"))', 999999999),
            ):
                with self.subTest(contents=contents, pid=pid):
                    config.write_text(contents)
                    result = subprocess.run([sys.executable, str(HELPER), str(pid), str(config)],
                                            capture_output=True, text=True, timeout=3)
                    self.assertNotEqual(result.returncode, 0)
                    self.assertIn('Kanata readiness failed', result.stderr)

    def test_service_dependencies_wait_for_readiness_and_coordinate_restart(self):
        kanata = ROOT / 'home/dot_config/systemd/user/kanata.service.tmpl'
        neru = ROOT / 'home/dot_config/systemd/user/neru.service.d/20-kanata.conf.tmpl'
        self.assertTrue(kanata.exists(), 'Missing Kanata readiness drop-in')
        self.assertTrue(neru.exists(), 'Missing Neru ordering drop-in')
        self.assertIn('ExecStartPost=/usr/bin/python3 %h/bin/kanata-wait-ready $MAINPID %h/.config/kanata/kanata.kbd', kanata.read_text())
        for setting in ('Requires=kanata.service', 'After=kanata.service', 'PartOf=kanata.service'):
            self.assertIn(setting, neru.read_text())


if __name__ == '__main__':
    unittest.main()
