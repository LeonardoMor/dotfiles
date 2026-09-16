#!/usr/bin/env python3

import hashlib
import json
import os
from pathlib import Path
import re
import shlex
import shutil
import subprocess
import tempfile
import tomllib
import unittest


ROOT = Path(__file__).resolve().parents[1]
DECLARCH = ROOT / "home/dot_config/declarch"
BOOTSTRAP = ROOT / ".bootstrap/bootstrap.sh"
HOME_SOURCE = ROOT / "home"


def sandbox_command(temp: Path, argv: list[str], env: dict[str, str]) -> list[str]:
    bwrap = shutil.which("bwrap")
    if not bwrap:
        raise unittest.SkipTest("bwrap is required for mutation-safe fixtures")
    command = [
        bwrap,
        "--unshare-net",
        "--unshare-pid",
        "--die-with-parent",
        "--proc",
        "/proc",
        "--dev",
        "/dev",
        "--ro-bind",
        "/usr",
        "/usr",
    ]
    for runtime in ("/bin", "/lib", "/lib64"):
        if Path(runtime).exists():
            command.extend(("--ro-bind", runtime, runtime))
    command.extend(
        (
            "--dir",
            "/tmp",
            "--bind",
            str(temp),
            str(temp),
            "--dir",
            "/repo",
            "--ro-bind",
            str(ROOT),
            "/repo",
            "--chdir",
            "/repo",
            "--clearenv",
        )
    )
    for name, value in env.items():
        command.extend(("--setenv", name, value))
    command.extend(argv)
    return command


class PackageMigrationTest(unittest.TestCase):
    @staticmethod
    def module_packages(path: Path) -> dict[str, list[str]]:
        packages: dict[str, list[str]] = {}
        backend = None
        for line in path.read_text(encoding="utf-8").splitlines():
            match = re.fullmatch(r"    ([A-Za-z0-9_-]+) \{", line)
            if match:
                backend = match.group(1)
                packages[backend] = []
            elif backend and line.startswith('        "'):
                packages[backend].append(json.loads(line.strip()))
            elif backend and line == "    }":
                backend = None
        return packages

    def test_declarch_source_layout_exists(self) -> None:
        expected = {
            DECLARCH / "declarch.kdl",
            DECLARCH / "exact_modules/all.kdl",
            DECLARCH / "exact_modules/cachyos.kdl",
            DECLARCH / "exact_backends/paru.kdl",
            DECLARCH / "exact_backends/npm.kdl",
            DECLARCH / "exact_backends/pipx.kdl",
        }
        self.assertEqual([], sorted(str(path.relative_to(ROOT)) for path in expected if not path.is_file()))

    def test_migrated_package_inventory_is_exact(self) -> None:
        shared = self.module_packages(DECLARCH / "exact_modules/all.kdl")
        cachyos = self.module_packages(DECLARCH / "exact_modules/cachyos.kdl")
        inventories = {
            "arch": sorted(shared["paru"] + cachyos["paru"]),
            "npm": sorted(shared["npm"]),
            "pipx": sorted(shared["pipx"]),
        }
        expected = {
            "arch": (485, "74d9913698082a111d5a806f879ccc139579a9f5326d4745ec763bfe6acc7535"),
            "npm": (5, "bfb38b0f839cb1cf270bde4d5d3c839580ac099b8f1f6f88550d0b08e20ef305"),
            "pipx": (1, "980853a12ff2186fbc0a820c721c504b8490cb9003d706e46b71d022a57d4e3f"),
        }
        for name, values in inventories.items():
            digest = hashlib.sha256(("\n".join(values) + "\n").encode()).hexdigest()
            self.assertEqual(expected[name], (len(values), digest))
        self.assertNotIn("alacritty", inventories["arch"])
        self.assertIn("metapac", inventories["arch"])

    def test_package_apply_uses_declarch_only(self) -> None:
        install = (HOME_SOURCE / ".chezmoiscripts/run_once_after_01install-packages.sh.tmpl").read_text(
            encoding="utf-8"
        )
        self.assertIn('eq .osid "linux-cachyos"', install)
        self.assertIn("declarch --yes sync", install)
        self.assertIn("Missing Declarch module", install)
        self.assertNotIn("metapac", install.lower())

    def test_prune_policy_removes_only_declarch_tracked_orphans(self) -> None:
        root = (DECLARCH / "declarch.kdl").read_text(encoding="utf-8")
        self.assertIn('orphans "remove"', root)

    def test_rendered_package_phases_execute_with_fixture_commands(self) -> None:
        chezmoi = os.environ.get("CHEZMOI_BIN")
        if not chezmoi:
            self.skipTest("CHEZMOI_BIN is required for rendered fixture validation")

        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            home = fixture / "home"
            bin_dir = fixture / "bin"
            modules = home / ".config/declarch/modules"
            modules.mkdir(parents=True)
            bin_dir.mkdir()
            for module in ("all", "cachyos"):
                (modules / f"{module}.kdl").write_text("meta {}\n", encoding="utf-8")
            log = fixture / "commands.log"
            (home / ".profile").write_text(
                f"nvm() {{ printf 'nvm %s\\n' \"$*\" >>{log!s}; }}\n",
                encoding="utf-8",
            )
            (bin_dir / "declarch").write_text(
                "#!/usr/bin/env bash\n"
                f"printf 'declarch %s\\n' \"$*\" >>{log!s}\n"
                "[[ $* == 'info --plan' ]] && printf 'Planned install: 0\\n'\n"
                "exit 0\n",
                encoding="utf-8",
            )
            (bin_dir / "declarch").chmod(0o755)
            config = fixture / "chezmoi.toml"
            config.write_text('[data]\nosid="linux-cachyos"\n', encoding="utf-8")

            rendered = []
            for name in (
                "run_once_after_00install-backends.sh.tmpl",
                "run_once_after_01install-packages.sh.tmpl",
            ):
                result = subprocess.run(
                    [
                        chezmoi,
                        "--config",
                        str(config),
                        "--source",
                        str(HOME_SOURCE),
                        "execute-template",
                        "--file",
                        str(HOME_SOURCE / ".chezmoiscripts" / name),
                    ],
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(0, result.returncode, result.stderr)
                script = fixture / name.removesuffix(".tmpl")
                script.write_text(result.stdout, encoding="utf-8")
                rendered.append(script)

            for script in rendered:
                result = subprocess.run(
                    sandbox_command(
                        fixture,
                        ["/usr/bin/bash", str(script)],
                        {
                            "HOME": str(home),
                            "PATH": f"{bin_dir}:/usr/bin",
                            "XDG_CONFIG_HOME": str(home / ".config"),
                        },
                    ),
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(0, result.returncode, result.stderr)
            trace = log.read_text(encoding="utf-8")
            self.assertIn("nvm install --lts=iron", trace)
            self.assertIn("declarch lint --mode validate", trace)
            self.assertIn("declarch --yes sync", trace)
            self.assertIn("declarch info --plan", trace)

            missing_module = modules / "cachyos.kdl"
            missing_module.unlink()
            log.unlink()
            missing = subprocess.run(
                sandbox_command(
                    fixture,
                    ["/usr/bin/bash", str(rendered[1])],
                    {
                        "HOME": str(home),
                        "PATH": f"{bin_dir}:/usr/bin",
                        "XDG_CONFIG_HOME": str(home / ".config"),
                    },
                ),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(0, missing.returncode)
            self.assertIn("Missing Declarch module", missing.stderr)
            self.assertFalse(log.exists())
            missing_module.write_text("meta {}\n", encoding="utf-8")

            (bin_dir / "declarch").write_text(
                "#!/usr/bin/env bash\n"
                "[[ $* == 'info --plan' ]] && printf 'Planned install: 1\\n'\n"
                "exit 0\n",
                encoding="utf-8",
            )
            (bin_dir / "declarch").chmod(0o755)
            pending = subprocess.run(
                sandbox_command(
                    fixture,
                    ["/usr/bin/bash", str(rendered[1])],
                    {
                        "HOME": str(home),
                        "PATH": f"{bin_dir}:/usr/bin",
                        "XDG_CONFIG_HOME": str(home / ".config"),
                    },
                ),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertNotEqual(0, pending.returncode)
            self.assertIn("left package installations pending", pending.stderr)

    def test_pipx_backend_install_and_remove_mappings_use_fixture_binary(self) -> None:
        declarch = os.environ.get("DECLARCH_BIN")
        if not declarch:
            self.skipTest("DECLARCH_BIN is required for backend fixture validation")

        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            config = fixture / "config/declarch"
            backend_dir = config / "backends"
            module_dir = config / "modules"
            bin_dir = fixture / "bin"
            state_home = fixture / "state-home"
            home = fixture / "home"
            for path in (backend_dir, module_dir, bin_dir, state_home, home):
                path.mkdir(parents=True)
            shutil.copy2(declarch, bin_dir / "declarch")
            shutil.copy2(DECLARCH / "exact_backends/pipx.kdl", backend_dir / "pipx.kdl")
            (config / "declarch.kdl").write_text(
                'backends {\n    "backends/pipx.kdl"\n}\nimports {\n    "modules/fixture.kdl"\n}\n'
                'policy {\n    orphans "remove"\n}\n',
                encoding="utf-8",
            )
            module = module_dir / "fixture.kdl"
            module.write_text(
                'meta {\n    title "Fixture"\n}\npkg {\n    pipx {\n        "fixture-tool"\n    }\n}\n',
                encoding="utf-8",
            )
            package_state = fixture / "pipx-state"
            command_log = fixture / "pipx-commands"
            (bin_dir / "pipx").write_text(
                "#!/usr/bin/env bash\n"
                f"printf '%s\\n' \"$*\" >>{command_log!s}\n"
                "case ${1-} in\n"
                f"  list) [[ ! -f {package_state!s} ]] || cat {package_state!s}; exit 0 ;;\n"
                f"  install) shift; [[ $1 == broken-tool ]] && exit 42; printf '%s\\n' \"$@\" >>{package_state!s} ;;\n"
                f"  uninstall) shift; grep -vxF \"$1\" {package_state!s} >{package_state!s}.tmp || true; mv {package_state!s}.tmp {package_state!s} ;;\n"
                "  *) exit 99 ;;\n"
                "esac\n",
                encoding="utf-8",
            )
            (bin_dir / "pipx").chmod(0o755)

            environment = {
                "HOME": str(home),
                "PATH": f"{bin_dir}:/usr/bin",
                "XDG_CONFIG_HOME": str(fixture / "config"),
                "XDG_STATE_HOME": str(state_home),
            }
            install = subprocess.run(
                sandbox_command(
                    fixture,
                    [str(bin_dir / "declarch"), "sync", "--yes"],
                    environment,
                ),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(0, install.returncode, install.stdout + install.stderr)
            self.assertTrue(package_state.is_file(), install.stdout + install.stderr)
            self.assertEqual("fixture-tool\n", package_state.read_text(encoding="utf-8"))

            module.write_text(
                'meta {\n    title "Fixture"\n}\npkg {\n    pipx {\n        "keeper-tool"\n    }\n}\n',
                encoding="utf-8",
            )
            remove = subprocess.run(
                sandbox_command(
                    fixture,
                    [str(bin_dir / "declarch"), "sync", "prune", "--yes"],
                    environment,
                ),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(0, remove.returncode, remove.stderr)
            self.assertEqual("keeper-tool\n", package_state.read_text(encoding="utf-8"), remove.stdout + remove.stderr)
            trace = command_log.read_text(encoding="utf-8")
            self.assertIn("install fixture-tool", trace)
            self.assertIn("uninstall fixture-tool", trace)

            module.write_text(
                'meta {\n    title "Fixture"\n}\npkg {\n    pipx {\n        "broken-tool"\n    }\n}\n',
                encoding="utf-8",
            )
            failed_install = subprocess.run(
                sandbox_command(
                    fixture,
                    [str(bin_dir / "declarch"), "sync", "--yes"],
                    environment,
                ),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(0, failed_install.returncode, failed_install.stdout + failed_install.stderr)
            plan = subprocess.run(
                sandbox_command(
                    fixture,
                    [str(bin_dir / "declarch"), "info", "--plan"],
                    environment,
                ),
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(0, plan.returncode, plan.stdout + plan.stderr)
            self.assertIn("Planned install: 1", plan.stdout)

    def test_metapac_has_no_active_configuration_or_linux_wrapper(self) -> None:
        retired = {
            HOME_SOURCE / ".chezmoitemplates/metapac/config.toml",
            HOME_SOURCE / "dot_config/metapac/config.toml.tmpl",
            HOME_SOURCE / "dot_config/metapac/exact_groups/symlink_all.toml.tmpl",
            HOME_SOURCE / "dot_config/metapac/exact_groups/symlink_cachyos.toml.tmpl",
            HOME_SOURCE / ".externally_modified/metapac/groups/all.toml",
            HOME_SOURCE / ".externally_modified/metapac/groups/cachyos.toml",
        }
        self.assertEqual([], sorted(str(path.relative_to(ROOT)) for path in retired if path.exists()))
        wrapper = (HOME_SOURCE / "exact_bin/executable_chezmoi-mpm.tmpl").read_text(encoding="utf-8")
        self.assertNotIn("metapac", wrapper.lower())


class OwnershipTest(unittest.TestCase):
    def test_bash_sources_use_builtin_syntax(self) -> None:
        paths = list((HOME_SOURCE / ".chezmoiscripts").rglob("*.tmpl")) + list(
            (HOME_SOURCE / "exact_bin").rglob("*.tmpl")
        )
        offenders = [
            str(path.relative_to(ROOT))
            for path in paths
            if "source -p" in path.read_text(encoding="utf-8")
        ]
        self.assertEqual([], offenders)

    def test_generated_state_is_not_managed(self) -> None:
        unmanaged = {
            HOME_SOURCE / "dot_config/alacritty/alacritty.toml.tmpl",
            HOME_SOURCE / "dot_config/discord/settings.json",
            HOME_SOURCE / "dot_config/pavucontrol.ini",
        }
        self.assertEqual([], sorted(str(path.relative_to(ROOT)) for path in unmanaged if path.exists()))
        ignored = (HOME_SOURCE / ".chezmoiignore").read_text(encoding="utf-8")
        self.assertIn(".config/discord/settings.json", ignored)
        self.assertIn(".config/pavucontrol.ini", ignored)
        removed = (HOME_SOURCE / ".chezmoiremove").read_text(encoding="utf-8")
        self.assertIn(".config/alacritty", removed)


class ServiceStateTest(unittest.TestCase):
    def test_cachyos_setup_owns_finite_service_state(self) -> None:
        setup = (HOME_SOURCE / ".chezmoiscripts/linux/run_once_after_02setup-desktop.sh.tmpl").read_text(
            encoding="utf-8"
        )
        setup += (HOME_SOURCE / ".chezmoiscripts/linux/run_once_after_05enable-firewall.sh.tmpl").read_text(
            encoding="utf-8"
        )
        setup += (HOME_SOURCE / ".chezmoiscripts/run_once_after_95ssh-access.sh.tmpl").read_text(
            encoding="utf-8"
        )
        self.assertIn('eq .osid "linux-cachyos"', setup)
        self.assertIn("DOTFILES_ETC", setup)
        self.assertNotIn("dasel", setup)
        self.assertIn("dms-greeter enable --yes", setup)
        self.assertNotIn("dankinstall", setup)
        for unit in (
            "greetd.service",
            "NetworkManager.service",
            "bluetooth.service",
            "sshd.service",
            "cups.service",
            "cups.socket",
            "cups.path",
            "libvirtd.service",
            "dms.service",
            "hyprpolkitagent.service",
            "kanata.service",
            "kanata-switcher.service",
            "openrazer-daemon.service",
        ):
            self.assertIn(unit, setup)
        self.assertIn("ufw enable", setup)

        hyprland = (HOME_SOURCE / "dot_config/hypr/hyprland.lua").read_text(encoding="utf-8")
        self.assertIn("systemctl --user start hyprland-session.target", hyprland)

    def test_security_setup_fails_before_activation(self) -> None:
        chezmoi = os.environ.get("CHEZMOI_BIN")
        if not chezmoi:
            self.skipTest("CHEZMOI_BIN is required for rendered fixture validation")

        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            bin_dir = fixture / "bin"
            home = fixture / "home"
            bin_dir.mkdir()
            home.mkdir()
            log = fixture / "commands.log"
            (bin_dir / "sudo").write_text(
                "#!/usr/bin/env bash\n"
                f"printf '%s\\n' \"$*\" >>{log!s}\n"
                "[[ $* == *\"${FAIL_AT:?}\"* ]] && exit 42\n"
                "if [[ $* == 'sshd -T' ]]; then\n"
                "    printf 'passwordauthentication no\\nkbdinteractiveauthentication no\\n'\n"
                "fi\n",
                encoding="utf-8",
            )
            (bin_dir / "sudo").chmod(0o755)
            config = fixture / "chezmoi.toml"
            config.write_text('[data]\nosid="linux-cachyos"\n', encoding="utf-8")
            cases = (
                (
                    HOME_SOURCE / ".chezmoiscripts/run_once_after_95ssh-access.sh.tmpl",
                    "sshd -t",
                    "systemctl",
                ),
                (
                    HOME_SOURCE / ".chezmoiscripts/linux/run_once_after_05enable-firewall.sh.tmpl",
                    "ufw allow 22",
                    "ufw enable",
                ),
            )
            for index, (source, fail_at, forbidden) in enumerate(cases):
                rendered = fixture / f"security-{index}.sh"
                render = subprocess.run(
                    [
                        chezmoi,
                        "--config",
                        str(config),
                        "--source",
                        str(HOME_SOURCE),
                        "execute-template",
                        "--file",
                        str(source),
                    ],
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertEqual(0, render.returncode, render.stderr)
                rendered.write_text(render.stdout, encoding="utf-8")
                log.unlink(missing_ok=True)
                result = subprocess.run(
                    sandbox_command(
                        fixture,
                        ["/usr/bin/bash", str(rendered)],
                        {
                            "FAIL_AT": fail_at,
                            "HOME": str(home),
                            "PATH": f"{bin_dir}:/usr/bin",
                        },
                    ),
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertNotEqual(0, result.returncode)
                self.assertNotIn(forbidden, log.read_text(encoding="utf-8"))

    def test_rendered_service_setup_uses_only_fixture_mutations(self) -> None:
        chezmoi = os.environ.get("CHEZMOI_BIN")
        if not chezmoi:
            self.skipTest("CHEZMOI_BIN is required for rendered fixture validation")

        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            home = fixture / "home"
            etc = fixture / "etc"
            bin_dir = fixture / "bin"
            (etc / "pam.d").mkdir(parents=True)
            home.mkdir()
            bin_dir.mkdir()
            (etc / "pam.d/greetd").write_text(
                "auth include system-local-login\nsession include system-local-login\n",
                encoding="utf-8",
            )
            config = fixture / "chezmoi.toml"
            config.write_text(
                '[data]\nosid="linux-cachyos"\nname="Fixture"\nemail="fixture@example.invalid"\n'
                'workHost="work"\nvaultsDir="/tmp/fixture-vaults"\nmonitorProfile="none"\nmonitorModel=""\n',
                encoding="utf-8",
            )
            rendered = fixture / "setup.sh"
            source = HOME_SOURCE / ".chezmoiscripts/linux/run_once_after_02setup-desktop.sh.tmpl"
            render = subprocess.run(
                [
                    chezmoi,
                    "--config",
                    str(config),
                    "--source",
                    str(HOME_SOURCE),
                    "--destination",
                    str(home),
                    "execute-template",
                    "--file",
                    str(source),
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            self.assertEqual(0, render.returncode, render.stderr)
            rendered.write_text(render.stdout, encoding="utf-8")
            subprocess.run(["bash", "-n", str(rendered)], check=True)

            log = fixture / "commands.log"
            (bin_dir / "sudo").write_text(
                "#!/usr/bin/env bash\n"
                f"printf 'sudo %s\\n' \"$*\" >>{log!s}\n"
                "[[ ${1-} == -v ]] && exit 0\n"
                '"$@"\n',
                encoding="utf-8",
            )
            for command in ("dms-greeter", "systemctl", "groupadd", "usermod", "udevadm"):
                fail = (
                    '[[ -n ${FAIL_SYSTEMCTL-} && $* == *"$FAIL_SYSTEMCTL"* ]] && exit 42\nexit 0\n'
                    if command == "systemctl"
                    else ""
                )
                (bin_dir / command).write_text(
                    "#!/usr/bin/env bash\n"
                    f"printf '{command} %s\\n' \"$*\" >>{log!s}\n"
                    f"{fail}",
                    encoding="utf-8",
                )
            (bin_dir / "getent").write_text("#!/usr/bin/env bash\nexit 1\n", encoding="utf-8")
            for script in bin_dir.iterdir():
                script.chmod(0o755)

            with tempfile.NamedTemporaryFile(prefix="dotfiles-host-canary-", delete=False) as canary_file:
                canary_file.write(b"unchanged\n")
                canary = Path(canary_file.name)
            result = subprocess.run(
                sandbox_command(
                    fixture,
                    ["/usr/bin/bash", str(rendered)],
                    {
                    "DOTFILES_ETC": str(etc),
                    "HOME": str(home),
                    "HOST_CANARY": str(canary),
                    "PATH": f"{bin_dir}:/usr/bin",
                    "USER": "fixture",
                    },
                ),
                text=True,
                capture_output=True,
                check=False,
            )
            try:
                self.assertEqual(0, result.returncode, result.stderr)
                trace = log.read_text(encoding="utf-8")
                self.assertIn("systemctl --user enable dms.service", trace)
                self.assertIn("sudo systemctl enable greetd.service cups.service libvirtd.service", trace)
                self.assertTrue((etc / "greetd/config.toml").is_file())
                greetd = tomllib.loads((etc / "greetd/config.toml").read_text(encoding="utf-8"))
                self.assertEqual(1, greetd["terminal"]["vt"])
                self.assertEqual("greeter", greetd["default_session"]["user"])
                self.assertEqual(
                    f"dms-greeter --command hyprland --config {etc}/greetd/hypr.conf "
                    "--remember-last-session true --remember-last-user true",
                    greetd["default_session"]["command"],
                )
                self.assertTrue((etc / "udev/rules.d/99-input.rules").is_file())
                self.assertEqual("unchanged\n", canary.read_text(encoding="utf-8"))
                failed = subprocess.run(
                    sandbox_command(
                        fixture,
                        ["/usr/bin/bash", str(rendered)],
                        {
                            "DOTFILES_ETC": str(etc),
                            "FAIL_SYSTEMCTL": "greetd.service",
                            "HOME": str(home),
                            "PATH": f"{bin_dir}:/usr/bin",
                            "USER": "fixture",
                        },
                    ),
                    text=True,
                    capture_output=True,
                    check=False,
                )
                self.assertNotEqual(0, failed.returncode)
            finally:
                canary.unlink(missing_ok=True)


class BootstrapTest(unittest.TestCase):
    def run_bootstrap(
        self,
        os_id: str,
        failing_commands: tuple[str, ...] = (),
        first_time_account: bool = False,
    ) -> tuple[subprocess.CompletedProcess[str], list[str]]:
        with tempfile.TemporaryDirectory() as directory:
            fixture = Path(directory)
            bin_dir = fixture / "bin"
            bin_dir.mkdir()
            log = fixture / "commands.log"
            os_release = fixture / "os-release"
            os_release.write_text(f"ID={os_id}\n", encoding="utf-8")

            for command in ("paru", "chezmoi"):
                script = bin_dir / command
                script.write_text(
                    "#!/usr/bin/env bash\n"
                    f"printf '%s\\n' \"{command} $*\" >>{log!s}\n"
                    f"exit {1 if command in failing_commands else 0}\n",
                    encoding="utf-8",
                )
                script.chmod(0o755)

            (bin_dir / "op").write_text(
                "#!/usr/bin/env bash\n"
                f"printf 'op %s\\n' \"$*\" >>{log!s}\n"
                f"[[ {'1' if 'op' in failing_commands else '0'} == 1 ]] && exit 1\n"
                + (
                    "case $* in\n"
                    "  whoami) [[ -n ${OP_SESSION_fixture-} ]] ;;\n"
                    "  signin) exit 1 ;;\n"
                    "  'account add --signin') printf 'export OP_SESSION_fixture=fixture-session\\n' ;;\n"
                    "  *) exit 99 ;;\n"
                    "esac\n"
                    if first_time_account
                    else "exit 0\n"
                ),
                encoding="utf-8",
            )
            (bin_dir / "op").chmod(0o755)

            installer = fixture / "declarch-installer.sh"
            installer.write_text(
                "#!/usr/bin/env bash\n"
                f"printf 'declarch-installer %s\\n' \"${{DECLARCH_VERSION-}}\" >>{log!s}\n"
                f"cat >{bin_dir / 'declarch'!s} <<'EOF'\n"
                "#!/usr/bin/env bash\n"
                f"printf 'declarch %s\\n' \"$*\" >>{log!s}\n"
                "EOF\n"
                f"chmod +x {bin_dir / 'declarch'!s}\n",
                encoding="utf-8",
            )
            installer.chmod(0o755)
            (bin_dir / "curl").write_text(
                "#!/usr/bin/env bash\n"
                f"printf 'curl %s\\n' \"$*\" >>{log!s}\n"
                f"[[ {'1' if 'curl' in failing_commands else '0'} == 1 ]] && exit 1\n"
                "output=\n"
                "while (($#)); do\n"
                "    if [[ $1 == -o ]]; then output=$2; shift 2; else shift; fi\n"
                "done\n"
                "cp \"${DECLARCH_FIXTURE_INSTALLER:?}\" \"$output\"\n",
                encoding="utf-8",
            )
            (bin_dir / "sha256sum").write_text(
                "#!/usr/bin/env bash\n"
                f"printf 'sha256sum %s\\n' \"$*\" >>{log!s}\n"
                "cat >/dev/null\n"
                f"exit {1 if 'sha256sum' in failing_commands else 0}\n",
                encoding="utf-8",
            )
            (bin_dir / "curl").chmod(0o755)
            (bin_dir / "sha256sum").chmod(0o755)

            sandbox = sandbox_command(
                fixture,
                ["/usr/bin/bash", "/repo/.bootstrap/bootstrap.sh"],
                {
                    "BRANCH": "refactor/cachyos-reproducibility",
                    "DECLARCH_FIXTURE_INSTALLER": str(installer),
                    "DOTFILES_OS_RELEASE": str(os_release),
                    "HOME": str(fixture / "home"),
                    "PATH": f"{bin_dir}:/usr/bin",
                    "USER": "fixture",
                },
            )
            with tempfile.NamedTemporaryFile(prefix="dotfiles-host-canary-", delete=False) as canary_file:
                canary_file.write(b"unchanged\n")
                canary = Path(canary_file.name)
            result = subprocess.run(
                [
                    "script",
                    "--quiet",
                    "--return",
                    "--command",
                    shlex.join(sandbox),
                    "/dev/null",
                ],
                text=True,
                capture_output=True,
                check=False,
            )
            try:
                self.assertEqual("unchanged\n", canary.read_text(encoding="utf-8"))
            finally:
                canary.unlink(missing_ok=True)
            commands = log.read_text(encoding="utf-8").splitlines() if log.exists() else []
            return result, commands

    def test_non_cachyos_is_rejected_before_commands_run(self) -> None:
        result, commands = self.run_bootstrap("arch")
        self.assertNotEqual(0, result.returncode)
        self.assertEqual([], commands)
        self.assertIn("Unsupported OS", result.stdout + result.stderr)

    def test_cachyos_bootstrap_installs_declarch_and_applies_once(self) -> None:
        result, commands = self.run_bootstrap("cachyos")
        self.assertEqual(0, result.returncode, result.stderr)
        package_commands = [command for command in commands if command.startswith("paru ")]
        self.assertEqual(1, len(package_commands))
        self.assertNotIn("declarch", package_commands[0].split())
        self.assertNotIn("metapac", package_commands[0].split())
        self.assertTrue(
            any(
                command.startswith(
                    "curl -fsSL https://raw.githubusercontent.com/nixval/declarch/v0.8.2/install.sh -o "
                )
                for command in commands
            )
        )
        self.assertIn("declarch-installer 0.8.2", commands)
        apply_commands = [command for command in commands if command.startswith("chezmoi ")]
        self.assertEqual(1, len(apply_commands))
        self.assertIn("init --apply", apply_commands[0])

    def test_declarch_installer_checksum_failure_is_propagated(self) -> None:
        result, commands = self.run_bootstrap("cachyos", ("sha256sum",))
        self.assertNotEqual(0, result.returncode)
        self.assertFalse(any(command.startswith("chezmoi ") for command in commands))
        self.assertNotIn("declarch-installer 0.8.2", commands)

    def test_first_time_onepassword_account_is_added_and_verified(self) -> None:
        result, commands = self.run_bootstrap("cachyos", first_time_account=True)
        self.assertEqual(0, result.returncode, result.stderr)
        self.assertIn("op signin", commands)
        self.assertIn("op account add --signin", commands)
        self.assertEqual(2, commands.count("op whoami"))

    def test_unavailable_onepassword_fails_closed(self) -> None:
        result, commands = self.run_bootstrap("cachyos", ("op",))
        self.assertNotEqual(0, result.returncode)
        self.assertIn("1Password sign-in failed", result.stdout + result.stderr)
        self.assertFalse(any(command.startswith("chezmoi ") for command in commands))

    def test_apply_failure_is_propagated(self) -> None:
        result, commands = self.run_bootstrap("cachyos", ("chezmoi",))
        self.assertNotEqual(0, result.returncode)
        self.assertEqual(1, sum(command.startswith("chezmoi init --apply") for command in commands))


class DocumentationTest(unittest.TestCase):
    def test_readme_describes_only_the_production_cachyos_workflow(self) -> None:
        readme = (ROOT / "README.md").read_text(encoding="utf-8")
        self.assertIn("minimal CachyOS", readme)
        self.assertIn("official release installer", readme)
        self.assertIn("installer SHA-256", readme)
        self.assertIn("declarch --dry-run sync", readme)
        self.assertIn("declarch info --list --scope unmanaged", readme)
        self.assertEqual(2, readme.count("Missing Declarch module"))
        self.assertIn("does not remove arbitrary unmanaged packages", readme)
        self.assertNotIn("Run `chezmoi apply` right after", readme)
        self.assertNotIn("metapac", readme.lower())


if __name__ == "__main__":
    unittest.main()
