from __future__ import annotations

import subprocess
import time
from dataclasses import dataclass
from typing import Sequence


@dataclass(slots=True)
class CommandResult:
    command: str
    returncode: int
    stdout: str
    stderr: str
    duration_seconds: float


class CommandRunner:
    """Single command execution entrypoint for the TUI."""

    def run(self, args: Sequence[str], timeout: int = 600) -> CommandResult:
        if not args:
            raise ValueError("args must not be empty")

        start = time.time()
        proc = subprocess.run(
            list(args),
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
            text=True,
            timeout=timeout,
            check=False,
        )
        end = time.time()

        return CommandResult(
            command=" ".join(args),
            returncode=proc.returncode,
            stdout=proc.stdout,
            stderr=proc.stderr,
            duration_seconds=end - start,
        )
