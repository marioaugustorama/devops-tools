from __future__ import annotations

from pathlib import Path
from typing import Iterable

from src.tui.models.package import PackageInfo
from src.tui.services.command_runner import CommandResult, CommandRunner


class PackageService:
    def __init__(
        self,
        packages_index: str = "/usr/local/scripts/packages.tsv",
        state_file: str = "/var/lib/devops-pkg/installed.list",
    ) -> None:
        self._packages_index = Path(packages_index)
        self._state_file = Path(state_file)

    def list_packages(self, filter_text: str = "") -> list[PackageInfo]:
        installed, status_mode = self._read_installed()
        packages = self._read_packages(status_mode=status_mode, installed=installed)

        needle = filter_text.strip().lower()
        if needle:
            packages = [
                pkg
                for pkg in packages
                if needle in pkg.name.lower() or needle in pkg.description.lower()
            ]
        return sorted(packages, key=lambda p: (p.group, p.name))

    def install_package(self, runner: CommandRunner, package_name: str) -> CommandResult:
        primary = runner.run(["pkg_add", "install", package_name])
        if primary.returncode == 0:
            return primary

        # Fallback útil quando o usuário atual não consegue escrever em /usr/local sem sudo.
        retry = runner.run(["sudo", "-n", "pkg_add", "install", package_name])
        if retry.returncode == 0:
            retry.stdout = (
                (primary.stdout or "")
                + ("\n" if primary.stdout and retry.stdout else "")
                + (retry.stdout or "")
            )
        return retry

    def _read_installed(self) -> tuple[set[str], str]:
        if not self._state_file.exists():
            return set(), "unknown"

        installed: set[str] = set()
        try:
            for line in self._state_file.read_text(encoding="utf-8").splitlines():
                line = line.strip()
                if not line or line.startswith("#"):
                    continue
                installed.add(line)
        except OSError:
            return set(), "unknown"

        return installed, "known"

    def _read_packages(self, *, status_mode: str, installed: Iterable[str]) -> list[PackageInfo]:
        if not self._packages_index.exists():
            return []

        installed_set = set(installed)
        output: list[PackageInfo] = []
        try:
            lines = self._packages_index.read_text(encoding="utf-8").splitlines()
        except OSError:
            return []

        for raw in lines:
            line = raw.strip()
            if not line or line.startswith("#"):
                continue

            cols = line.split("\t")
            name = cols[0].strip() if len(cols) >= 1 else ""
            if not name:
                continue

            description = cols[1].strip() if len(cols) >= 2 else name
            group = cols[2].strip() if len(cols) >= 3 and cols[2].strip() else "general"
            default_install = (cols[3].strip() if len(cols) >= 4 else "0") in {
                "1",
                "true",
                "yes",
                "on",
                "sim",
            }

            if status_mode == "unknown":
                status = "unknown"
            else:
                status = "installed" if name in installed_set else "not installed"

            output.append(
                PackageInfo(
                    name=name,
                    description=description,
                    group=group,
                    status=status,
                    default_install=default_install,
                )
            )

        return output
