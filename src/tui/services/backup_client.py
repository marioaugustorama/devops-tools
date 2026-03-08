from __future__ import annotations

import json
import os
from pathlib import Path
from urllib.parse import quote
from urllib import error, request

from src.tui.models.backup import BackupInfo
from src.tui.services.command_runner import CommandResult, CommandRunner


class BackupClient:
    def __init__(
        self,
        base_url: str = "http://127.0.0.1:30000",
        token: str | None = None,
        backup_dir: str = "/backup",
    ) -> None:
        self._base_url = base_url.rstrip("/")
        self._token = token or os.environ.get("TOOLS_WEB_TOKEN") or os.environ.get("BACKUP_WEB_TOKEN")
        self._backup_dir = Path(backup_dir)

    def health(self) -> bool:
        try:
            payload = self._get_json("/api/health")
            return payload.get("status") == "ok"
        except Exception:
            return False

    def list_backups(self) -> list[BackupInfo]:
        try:
            payload = self._get_json("/api/backups")
            items = payload.get("items", [])
            return [
                BackupInfo(
                    name=item.get("name", ""),
                    size=int(item.get("size", 0)),
                    mtime=item.get("mtime", ""),
                )
                for item in items
                if item.get("name")
            ]
        except Exception:
            return self._list_backups_fs()

    def create_backup(self, runner: CommandRunner) -> CommandResult:
        try:
            payload = self._post_json("/api/backup")
            stdout = payload.get("stdout", "")
            if payload.get("path"):
                stdout = (stdout + "\n" + f"Backup criado: {payload['path']}").strip()
            return CommandResult(
                command="tools-web POST /api/backup",
                returncode=0,
                stdout=stdout,
                stderr="",
                duration_seconds=0.0,
            )
        except Exception:
            return runner.run(["backup"]) 

    def backup_contents(self, name: str) -> str:
        try:
            payload = self._get_json(f"/api/backups/{quote(name)}/contents")
            entries = payload.get("entries", [])
            return "\n".join(entries)
        except Exception:
            archive = self._backup_dir / name
            if not archive.exists():
                return "Backup não encontrado."
            return "Visualização de conteúdo indisponível sem API tools-web."

    def delete_backup(self, name: str) -> bool:
        try:
            self._delete_json(f"/api/backups/{quote(name)}")
            return True
        except Exception:
            target = self._backup_dir / name
            if not target.exists() or not target.is_file():
                return False
            target.unlink()
            return True

    def _list_backups_fs(self) -> list[BackupInfo]:
        if not self._backup_dir.exists():
            return []

        result: list[BackupInfo] = []
        for item in self._backup_dir.iterdir():
            if not item.is_file():
                continue
            stat = item.stat()
            result.append(
                BackupInfo(
                    name=item.name,
                    size=stat.st_size,
                    mtime=str(stat.st_mtime),
                )
            )
        result.sort(key=lambda x: x.mtime, reverse=True)
        return result

    def _headers(self) -> dict[str, str]:
        headers = {"Accept": "application/json"}
        if self._token:
            headers["X-Backup-Token"] = self._token
        return headers

    def _get_json(self, path: str) -> dict:
        req = request.Request(self._base_url + path, method="GET", headers=self._headers())
        return self._read_json(req)

    def _post_json(self, path: str) -> dict:
        req = request.Request(self._base_url + path, method="POST", headers=self._headers())
        return self._read_json(req)

    def _delete_json(self, path: str) -> dict:
        req = request.Request(self._base_url + path, method="DELETE", headers=self._headers())
        return self._read_json(req)

    def _read_json(self, req: request.Request) -> dict:
        try:
            with request.urlopen(req, timeout=5) as resp:
                data = resp.read().decode("utf-8")
                return json.loads(data or "{}")
        except error.HTTPError as exc:
            body = exc.read().decode("utf-8", errors="ignore")
            raise RuntimeError(f"HTTP {exc.code}: {body}") from exc
        except error.URLError as exc:
            raise RuntimeError(f"API indisponível: {exc.reason}") from exc
