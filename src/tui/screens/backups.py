from __future__ import annotations

import asyncio

from textual.containers import Horizontal, Vertical
from textual.widgets import Button, DataTable, Static

from src.tui.models.backup import BackupInfo
from src.tui.services.backup_client import BackupClient
from src.tui.services.command_runner import CommandRunner


class BackupsView(Vertical):
    def __init__(self, backup_client: BackupClient, command_runner: CommandRunner) -> None:
        super().__init__()
        self._backup_client = backup_client
        self._command_runner = command_runner
        self._items: list[BackupInfo] = []

    def compose(self):
        yield Static("Backups", classes="title")
        yield Horizontal(
            Button("Refresh", id="backups-refresh", variant="primary"),
            Button("Create", id="backups-create", variant="success"),
            Button("Details", id="backups-details"),
            Button("Delete", id="backups-delete", variant="error"),
            id="backups-actions",
        )
        table = DataTable(id="backups-table")
        table.cursor_type = "row"
        yield table
        yield Static("", id="backups-status")
        yield Static("", id="backups-details-output")

    def on_mount(self) -> None:
        table = self.query_one("#backups-table", DataTable)
        table.add_columns("Name", "Size", "Modified")
        self.refresh_backups()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        button_id = event.button.id
        if button_id == "backups-refresh":
            self.refresh_backups()
            self._status("Lista de backups atualizada")
            self._log("[backups] refresh")
        elif button_id == "backups-create":
            self.run_worker(self._create_backup(), exclusive=True)
        elif button_id == "backups-details":
            self.run_worker(self._show_details(), exclusive=True)
        elif button_id == "backups-delete":
            self.run_worker(self._delete_backup(), exclusive=True)

    def refresh_backups(self) -> None:
        self._items = self._backup_client.list_backups()
        table = self.query_one("#backups-table", DataTable)
        table.clear()
        for item in self._items:
            table.add_row(item.name, str(item.size), item.mtime)

    async def _create_backup(self) -> None:
        self._status("Criando backup...")
        self._log("[backups] create start")

        result = await asyncio.to_thread(self._backup_client.create_backup, self._command_runner)
        self._log(f"$ {result.command}")
        if result.stdout:
            self._log(result.stdout.strip())
        if result.stderr:
            self._log(result.stderr.strip())

        if result.returncode == 0:
            self._status("Backup criado com sucesso")
        else:
            self._status(f"Falha ao criar backup (code={result.returncode})")

        self.refresh_backups()

    async def _show_details(self) -> None:
        item = self._selected()
        if not item:
            self._status("Selecione um backup")
            return
        details = await asyncio.to_thread(self._backup_client.backup_contents, item.name)
        self.query_one("#backups-details-output", Static).update(details or "Sem detalhes")
        self._status(f"Detalhes carregados para {item.name}")
        self._log(f"[backups] details: {item.name}")

    async def _delete_backup(self) -> None:
        item = self._selected()
        if not item:
            self._status("Selecione um backup")
            return

        ok = await asyncio.to_thread(self._backup_client.delete_backup, item.name)
        if ok:
            self._status(f"Backup removido: {item.name}")
            self._log(f"[backups] deleted: {item.name}")
        else:
            self._status(f"Não foi possível remover: {item.name}")
            self._log(f"[backups] delete failed: {item.name}")

        self.refresh_backups()

    def _selected(self) -> BackupInfo | None:
        if not self._items:
            return None
        row_index = self.query_one("#backups-table", DataTable).cursor_row
        if row_index is None or row_index < 0 or row_index >= len(self._items):
            return None
        return self._items[row_index]

    def _status(self, text: str) -> None:
        self.query_one("#backups-status", Static).update(text)

    def _log(self, message: str) -> None:
        if hasattr(self.app, "append_log"):
            self.app.append_log(message)
