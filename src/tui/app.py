from __future__ import annotations

from datetime import datetime

from textual.app import App, ComposeResult
from textual.containers import Container
from textual.widgets import Footer, Header, TabbedContent, TabPane

from src.tui.screens.backups import BackupsView
from src.tui.screens.home import HomeView
from src.tui.screens.logs import LogsView
from src.tui.screens.packages import PackagesView
from src.tui.services.backup_client import BackupClient
from src.tui.services.command_runner import CommandRunner
from src.tui.services.env_service import EnvService
from src.tui.services.package_service import PackageService


class DevOpsTuiApp(App):
    TITLE = "DevOps Tools TUI"
    SUB_TITLE = "MVP"

    CSS = """
    Screen {
        layout: vertical;
    }

    #main-tabs {
        height: 1fr;
    }

    .title {
        text-style: bold;
        padding: 0 0 1 0;
    }

    DataTable {
        height: 1fr;
    }

    #backups-details-output {
        height: 8;
        border: heavy $surface;
        overflow: auto;
    }

    #logs-output {
        height: 1fr;
        border: heavy $surface;
    }
    """

    def __init__(self) -> None:
        super().__init__()
        self.command_runner = CommandRunner()
        self.package_service = PackageService()
        self.backup_client = BackupClient()
        self.env_service = EnvService()

    def compose(self) -> ComposeResult:
        yield Header(show_clock=True)
        with Container(id="main"):
            with TabbedContent(id="main-tabs"):
                with TabPane("Home", id="tab-home"):
                    yield HomeView(self.env_service, self.backup_client)
                with TabPane("Packages", id="tab-packages"):
                    yield PackagesView(self.package_service, self.command_runner)
                with TabPane("Backups", id="tab-backups"):
                    yield BackupsView(self.backup_client, self.command_runner)
                with TabPane("Logs", id="tab-logs"):
                    yield LogsView()
        yield Footer()

    def on_mount(self) -> None:
        self.append_log("DevOps Tools TUI iniciada")

    def append_log(self, message: str) -> None:
        ts = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        full = f"[{ts}] {message}"
        logs_view = self.query_one(LogsView)
        logs_view.append(full)


def main() -> None:
    app = DevOpsTuiApp()
    app.run()


if __name__ == "__main__":
    main()
