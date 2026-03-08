from __future__ import annotations

import os
import shutil
from dataclasses import dataclass
from pathlib import Path


@dataclass(slots=True)
class EnvCheck:
    name: str
    ok: bool
    details: str


class EnvService:
    def __init__(self, backup_url: str = "http://127.0.0.1:30000") -> None:
        self._backup_url = backup_url

    def summary(self) -> dict[str, str]:
        return {
            "user": os.environ.get("USER", "unknown"),
            "cwd": str(Path.cwd()),
            "inside_container": "yes" if Path("/.dockerenv").exists() else "no",
            "app_version": os.environ.get("APP_VERSION", "unknown"),
            "backup_url": self._backup_url,
        }

    def checks(self) -> list[EnvCheck]:
        checks: list[EnvCheck] = []

        for command in ["pkg_add", "backup", "tools-web", "kubectl", "docker"]:
            found = shutil.which(command)
            checks.append(
                EnvCheck(
                    name=f"bin:{command}",
                    ok=bool(found),
                    details=found or "not found",
                )
            )

        for path in ["/tools", "/backup", "/var/lib/devops-pkg", "/usr/local/scripts/packages.tsv", "/var/run/docker.sock"]:
            p = Path(path)
            checks.append(
                EnvCheck(
                    name=f"path:{path}",
                    ok=p.exists(),
                    details="exists" if p.exists() else "missing",
                )
            )

        return checks
