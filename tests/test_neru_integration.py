import os
from pathlib import Path
import re
import signal
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
RUNGAME = ROOT / 'home/exact_bin/executable_rungame.tmpl'
NERU_INSTALLER = ROOT / 'home/.chezmoiscripts/linux/run_once_after_03neru-startup.sh.tmpl'


def shell_body(path):
    text = path.read_text()
    return text[text.index('#!/usr/bin/env bash'):].split('{{', 1)[0]


class RungameNeruTests(unittest.TestCase):
    def run_game(self, **settings):
        with tempfile.TemporaryDirectory(prefix='dotfiles-neru-') as directory:
            home = Path(directory)
            (home / 'bin').mkdir()
            utils = (ROOT / 'home/.chezmoitemplates/utils').read_text().split('{{', 1)[0]
            (home / 'bin/utils.sh').write_text(utils)
            log = home / 'calls.log'
            env = os.environ.copy()
            env.pop('HYPRLAND_INSTANCE_SIGNATURE', None)
            env.update({
                'HOME': str(home),
                'CALL_LOG': str(log),
                'NERU_STATE': 'active',
                'SHOW_STATUS': '0',
                'STOP_STATUS': '0',
                'STOP_SIGNAL': '',
                'START_STATUS': '0',
                'GAME_STATUS': '0',
                'GAME_SIGNAL': '',
            })
            env.update(settings)
            stubs = r'''
systemctl() {
    printf 'systemctl %s\n' "$*" >> "$CALL_LOG"
    case "$*" in
        '--user show --property=ActiveState --value neru.service')
            printf '%s\n' "$NERU_STATE"
            return "$SHOW_STATUS"
            ;;
        '--user stop neru.service')
            [[ -z $STOP_SIGNAL ]] || kill -s "$STOP_SIGNAL" "$$"
            return "$STOP_STATUS"
            ;;
        '--user start neru.service') return "$START_STATUS" ;;
        *) return 99 ;;
    esac
}
game-performance() {
    printf 'game\n' >> "$CALL_LOG"
    [[ -z $GAME_SIGNAL ]] || kill -s "$GAME_SIGNAL" "$$"
    return "$GAME_STATUS"
}
'''
            body = shell_body(RUNGAME)
            if settings.get('HYPRLAND_INSTANCE_SIGNATURE'):
                body = body.replace('\ntrap post EXIT', '\nquery-dnd() { return 1; }\n\ntrap post EXIT', 1)
            result = subprocess.run(
                ['bash', '-s', '--', 'test-game'],
                input=stubs + body,
                text=True,
                capture_output=True,
                env=env,
                preexec_fn=lambda: signal.signal(signal.SIGINT, signal.SIG_DFL),
                timeout=10,
            )
            calls = log.read_text().splitlines() if log.exists() else []
            return result, calls

    def test_stops_neru_before_game_and_resumes_afterward(self):
        result, calls = self.run_game()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls, [
            'systemctl --user show --property=ActiveState --value neru.service',
            'systemctl --user stop neru.service',
            'game',
            'systemctl --user start neru.service',
        ])

    def test_leaves_previously_inactive_neru_stopped(self):
        result, calls = self.run_game(NERU_STATE='inactive')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[-1], 'game')
        self.assertIn('systemctl --user stop neru.service', calls)
        self.assertNotIn('systemctl --user start neru.service', calls)

    def test_does_not_launch_game_when_state_query_fails(self):
        result, calls = self.run_game(SHOW_STATUS='1')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(len(calls), 1)
        self.assertIn('Unable to read Neru service state', result.stderr)

    def test_does_not_launch_game_when_neru_cannot_stop(self):
        result, calls = self.run_game(STOP_STATUS='1')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(calls, [
            'systemctl --user show --property=ActiveState --value neru.service',
            'systemctl --user stop neru.service',
            'systemctl --user start neru.service',
        ])
        self.assertNotIn('game', calls)
        self.assertIn('Unable to stop Neru', result.stderr)

    def test_stop_failure_does_not_start_previously_inactive_neru(self):
        result, calls = self.run_game(NERU_STATE='inactive', STOP_STATUS='1')
        self.assertEqual(result.returncode, 1)
        self.assertEqual(calls, [
            'systemctl --user show --property=ActiveState --value neru.service',
            'systemctl --user stop neru.service',
        ])
        self.assertNotIn('game', calls)
        self.assertNotIn('systemctl --user start neru.service', calls)

    def test_resumes_neru_after_sigint_during_stop(self):
        result, calls = self.run_game(STOP_SIGNAL='INT')
        self.assertEqual(result.returncode, 130, result.stderr)
        self.assertEqual(calls, [
            'systemctl --user show --property=ActiveState --value neru.service',
            'systemctl --user stop neru.service',
            'systemctl --user start neru.service',
        ])
        self.assertNotIn('game', calls)

    def test_resumes_neru_after_sigterm_during_stop(self):
        result, calls = self.run_game(STOP_SIGNAL='TERM')
        self.assertEqual(result.returncode, 143, result.stderr)
        self.assertEqual(calls, [
            'systemctl --user show --property=ActiveState --value neru.service',
            'systemctl --user stop neru.service',
            'systemctl --user start neru.service',
        ])
        self.assertNotIn('game', calls)

    def test_resumes_neru_when_game_fails(self):
        result, calls = self.run_game(GAME_STATUS='7')
        self.assertEqual(result.returncode, 7)
        self.assertEqual(calls[-1], 'systemctl --user start neru.service')

    def test_resumes_neru_after_sigterm(self):
        result, calls = self.run_game(GAME_SIGNAL='TERM')
        self.assertEqual(result.returncode, 143)
        self.assertEqual(calls[-1], 'systemctl --user start neru.service')

    def test_dnd_failure_does_not_prevent_neru_restore(self):
        result, calls = self.run_game(HYPRLAND_INSTANCE_SIGNATURE='test-instance')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn('Unable to read do-not-disturb state', result.stderr)
        self.assertEqual(calls[-1], 'systemctl --user start neru.service')

    def test_resume_failure_preserves_game_status(self):
        result, calls = self.run_game(START_STATUS='1', GAME_STATUS='7')
        self.assertEqual(result.returncode, 7)
        self.assertEqual(calls[-1], 'systemctl --user start neru.service')
        self.assertIn('Unable to resume Neru', result.stderr)


class NeruInstallerTests(unittest.TestCase):
    def test_run_once_after_script_installs_neru_service(self):
        self.assertTrue(NERU_INSTALLER.exists(), 'Missing Neru run_once_after installer')
        result = subprocess.run(
            ['bash', '-s'],
            input='neru() { printf "%s\\n" "$*"; }\n' + shell_body(NERU_INSTALLER),
            text=True,
            capture_output=True,
            timeout=10,
        )
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), 'services install')

    def test_install_failure_is_reported_to_chezmoi(self):
        result = subprocess.run(
            ['bash', '-s'],
            input='neru() { return 7; }\n' + shell_body(NERU_INSTALLER),
            text=True,
            capture_output=True,
            timeout=10,
        )
        self.assertNotEqual(result.returncode, 0)


class NeruHyprlandBindingsTests(unittest.TestCase):
    def test_super_chords_match_mac_neru_actions(self):
        template = (ROOT / 'home/dot_config/neru/config.toml.tmpl').read_text()
        hotkeys = template.split('\n[hotkeys]\n', 1)[1].split('\n[hints]\n', 1)[0]
        config = tomllib.loads('[hotkeys]\n' + hotkeys)
        expected = {
            'SUPER + ALT + SHIFT + ' + chord.rsplit('+', 1)[1].lower(): 'neru ' + command
            for chord, command in config['hotkeys'].items()
        }
        binds = (ROOT / 'home/dot_config/hypr/exact_custom/binds.lua').read_text()
        actual = dict(re.findall(
            r"hl\.bind\('([^']+)', hl\.dsp\.exec_cmd\('(neru [^']+)'\)",
            binds,
        ))
        self.assertEqual(actual, expected)


if __name__ == '__main__':
    unittest.main()
