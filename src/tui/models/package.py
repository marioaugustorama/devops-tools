from dataclasses import dataclass


@dataclass(slots=True)
class PackageInfo:
    name: str
    description: str
    group: str
    status: str  # installed | not installed | unknown
    default_install: bool = False
