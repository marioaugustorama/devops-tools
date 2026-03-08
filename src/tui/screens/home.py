from __future__ import annotations

from textual.containers import Horizontal, Vertical
from textual.widgets import Button, DataTable, Static

from src.tui.services.backup_client import BackupClient
from src.tui.services.env_service import EnvService


class HomeView(Vertical):
    def __init__(self, env_service: EnvService, backup_client: BackupClient) -> None:
        super().__init__()
        self._env_service = env_service
        self._backup_client = backup_client

    def compose(self):
        yield Static("Home", classes="title")
        yield Static("", id="home-summary")
        yield Horizontal(
            Button("Refresh", id="home-refresh", variant="primary"),
            Button("Check Backup API", id="home-health"),
            id="home-actions",
        )
        table = DataTable(id="home-checks")
        table.cursor_type = "row"
        yield table

    def on_mount(self) -> None:
        table = self.query_one("#home-checks", DataTable)
        table.add_columns("Check", "Status", "Details")
        self.refresh_data()

    def on_button_pressed(self, event: Button.Pressed) -> None:
        if event.button.id == "home-refresh":
            self.refresh_data()
            self._log("[home] Ambiente atualizado")
        elif event.button.id == "home-health":
            ok = self._backup_client.health()
            self._log(f"[home] backup service: {'OK' if ok else 'NOT AVAILABLE'}")
            self.refresh_data()

    def refresh_data(self) -> None:
        summary = self._env_service.summary()
        backup_ok = self._backup_client.health()

        summary_text = (
            f"User: {summary['user']}\n"
            f"CWD: {summary['cwd']}\n"
            f"Inside Container: {summary['inside_container']}\n"
            f"App Version: {summary['app_version']}\n"
            f"Backup URL: {summary['backup_url']}\n"
            f"Backup API: {'OK' if backup_ok else 'NOT AVAILABLE'}"
        )
        self.query_one("#home-summary", Static).update(summary_text)

        table = self.query_one("#home-checks", DataTable)
        table.clear()
        for check in self._env_service.checks():
            table.add_row(check.name, "ok" if check.ok else "fail", check.details)

    def _log(self, message: str) -> None:
        if hasattr(self.app, "append_log"):
            self.app.append_log(message)
