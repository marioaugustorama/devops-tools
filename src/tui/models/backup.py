from dataclasses import dataclass


@dataclass(slots=True)
class BackupInfo:
    name: str
    size: int
    mtime: str
