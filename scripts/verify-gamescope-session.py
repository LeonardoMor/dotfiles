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
    dropin = root / 'home/dot_config/systemd/user/gamescope-session.service.d/10-unset-wayland.conf.tmpl'
    assert dropin.is_file(), 'Missing stale Wayland display isolation'
    rendered_dropin = render(dropin)
    assert 'UnsetEnvironment=WAYLAND_DISPLAY' in rendered_dropin
    assert 'Environment="OUTPUT_CONNECTOR=DP-5"' in rendered_dropin
    assert 'Environment="VK_DRIVER_FILES=/usr/share/vulkan/icd.d/nvidia_icd.json"' in rendered_dropin
    assert 'ExecStart=/usr/bin/prime-run /usr/lib/steamos/gamescope-session' in rendered_dropin
    assert 'unset-environment WAYLAND_DISPLAY DISPLAY XAUTHORITY HYPRLAND_INSTANCE_SIGNATURE' in rendered_dropin
    assert 'After=hyprland-session.target' in rendered_dropin
    assert 'ExecStartPre=/usr/bin/systemctl --user stop app-*.scope run-*.scope' in rendered_dropin
    assert render(dropin, 'other') == ''

    units = root / 'home/dot_config/systemd/user'
    desktop = (units / 'hyprland-session.target').read_text()
    kanata = (units / 'kanata.service').read_text()
    assert 'graphical-session-pre.target' in desktop
    assert 'kanata.service kanata-switcher.service' in desktop
    assert 'PartOf=hyprland-session.target' in kanata
    assert 'WantedBy=hyprland-session.target' in kanata
    assert 'ConditionEnvironment=XDG_CURRENT_DESKTOP=Hyprland' in kanata
    configs = {
        str(p.relative_to(units)).removesuffix('.tmpl'): render(p)
        for p in units.rglob('*.tmpl')
        if p.name.endswith(('.conf.tmpl', '.service.tmpl'))
        and not p.name.startswith('symlink_')
    }
    for name in ('graphical-session.target.d/10-clean-session.conf',
                 'gamescope-session.target.d/10-session-isolation.conf',
                 'kanata-switcher.service.d/10-hyprland-only.conf',
                 'hyprpolkitagent.service.d/10-hyprland-only.conf',
                 'app-dev.lizardbyte.app.Sunshine.service',
                 'gamescope-sunshine.service'):
        assert configs[name]
        assert render(units / (name + '.tmpl'), 'other') == ''
    cleanup = configs['graphical-session.target.d/10-clean-session.conf']
    assert 'PartOf=graphical-session-pre.target' in cleanup
    assert 'app.slice' not in cleanup
    switcher = configs['kanata-switcher.service.d/10-hyprland-only.conf']
    assert 'PartOf=hyprland-session.target' in switcher
    assert 'WantedBy=\nWantedBy=hyprland-session.target' in switcher
    assert 'ConditionEnvironment=XDG_CURRENT_DESKTOP=Hyprland' in switcher
    sunshine = configs['app-dev.lizardbyte.app.Sunshine.service']
    assert 'After=basic.target' in sunshine
    assert 'graphical-session.target' not in sunshine
    assert 'Slice=background.slice' in sunshine
    assert 'WantedBy=default.target' in sunshine
    assert 'PartOf=' not in sunshine
    for config in configs.values():
        assert 'After=\n' not in config and 'PartOf=\n' not in config, 'Dependencies cannot be reset in drop-ins'
    refresh = configs['gamescope-sunshine.service']
    assert 'After=gamescope-session.service graphical-session.target' in refresh
    assert 'Requisite=gamescope-session.service graphical-session.target' in refresh
    assert 'PartOf=gamescope-session.target' in refresh
    assert 'RemainAfterExit=yes' in refresh
    assert 'ExecStart=/usr/bin/systemctl --user restart app-dev.lizardbyte.app.Sunshine.service' in refresh
    link = units / 'default.target.wants/symlink_app-dev.lizardbyte.app.Sunshine.service.tmpl'
    assert render(link).strip() == '../app-dev.lizardbyte.app.Sunshine.service'
    assert render(link, 'other') == ''
    all_packages = tomllib.loads((root / 'home/.externally_modified/metapac/groups/all.toml').read_text())['arch']['packages']
    for item in all_packages:
        if isinstance(item, dict) and item.get('name') in ('kanata', 'kanata-switcher'):
            assert 'enable' not in ' '.join(item['hooks']['after_sync'])
    lua = (root / 'home/dot_config/hypr/hyprland.lua').read_text()
    assert 'unset-environment XDG_DESKTOP_PORTAL_DIR && dbus-update-activation-environment --systemd --all && systemctl --user start hyprland-session.target' in lua

    with tempfile.TemporaryDirectory() as unit_path:
        for name, content in {**configs, 'hyprland-session.target': desktop, 'kanata.service': kanata}.items():
            path = Path(unit_path) / name
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(content)
        (Path(unit_path) / 'default.target.wants').mkdir()
        (Path(unit_path) / 'default.target.wants/app-dev.lizardbyte.app.Sunshine.service').symlink_to(render(link).strip())
        subprocess.run(['systemd-analyze', '--user', '--man=no', '--generators=no', 'verify',
                        'default.target', 'hyprland-session.target', 'gamescope-session.target', 'kanata.service',
                        'kanata-switcher.service', 'app-dev.lizardbyte.app.Sunshine.service',
                        'gamescope-sunshine.service'], check=True,
                       env={**os.environ, 'SYSTEMD_UNIT_PATH': unit_path + ':/usr/lib/systemd/user'})

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
print('PASS: session lifecycle, native unit verification, Sunshine persistence/readiness, session exit, ScopeBuddy and Sekiro settings')
