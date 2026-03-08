from __future__ import annotations

import asyncio

from textual.containers import Horizontal, Vertical
from textual.widgets import Button, DataTable, Input, Static

from src.tui.models.package import PackageInfo
from src.tui.services.command_runner import CommandRunner
from src.tui.services.package_service import PackageService


class PackagesView(Vertical):
    def __init__(self, package_service: PackageService, command_runner: CommandRunner) -> None:
        super().__init__()
        self._package_service = package_service
        self._command_runner = command_runner
        self._items: list[PackageInfo] = []

    def compose(self):
        yield Static("Packages", classes="title")
        yield Input(placeholder="Filter by package name or description", id="packages-filter")
        yield Horizontal(
            Button("Refresh", id="packages-refresh", variant="primary"),
            Button("Install Selected", id="packages-install", variant="success"),
            id="packages-actions",
        )
        table = DataTable(id="packages-table")
        table.cursor_type = "row"
        yield table
        yield Static("", id="packages-status")

    def on_mount(self) -> None:
        table = self.query_one("#packages-table", DataTable)
        table.add_columns("Name", "Status", "Group", "Description")
        self.refresh_table("")

    def on_input_changed(self, event: Input.Changed) -> None:
        if event.input.id == "packages-filter":
            self.refresh_table(event.value)

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "packages-refresh":
            term = self.query_one("#packages-filter", Input).value
            self.refresh_table(term)
            self._status("Lista de pacotes atualizada")
            self._log("[packages] refresh")
        elif event.button.id == "packages-install":
            self.run_worker(self._install_selected(), exclusive=True)

    def refresh_table(self, filter_text: str) -> None:
        self._items = self._package_service.list_packages(filter_text=filter_text)
        table = self.query_one("#packages-table", DataTable)
        table.clear()
        for item in self._items:
            table.add_row(item.name, item.status, item.group, item.description)

    async def _install_selected(self) -> None:
        try:
            pkg = self._get_selected_package()
            if not pkg:
                self._status("Selecione um pacote na tabela")
                return

            self._status(f"Instalando {pkg.name}...")
            self._log(f"[packages] install start: {pkg.name}")

            result = await asyncio.to_thread(self._package_service.install_package, self._command_runner, pkg.name)
            self._log(f"$ {result.command}")
            if result.stdout:
                self._log(result.stdout.strip())
            if result.stderr:
                self._log(result.stderr.strip())

            if result.returncode == 0:
                self._status(f"Pacote {pkg.name} instalado com sucesso")
            else:
                self._status(f"Falha ao instalar {pkg.name} (code={result.returncode})")

            term = self.query_one("#packages-filter", Input).value
            self.refresh_table(term)
        except Exception as exc:
            self._status("Erro inesperado durante instalação")
            self._log(f"[packages] erro: {exc}")

    def _get_selected_package(self) -> PackageInfo | None:
        if not self._items:
            return None
        table = self.query_one("#packages-table", DataTable)
        row_index = table.cursor_row
        if row_index is None:
            row_index = 0
        if row_index < 0 or row_index >= len(self._items):
            row_index = 0
        return self._items[row_index]

    def _status(self, text: str) -> None:
        self.query_one("#packages-status", Static).update(text)

    def _log(self, message: str) -> None:
        if hasattr(self.app, "append_log"):
            self.app.append_log(message)
