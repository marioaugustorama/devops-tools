#!/usr/bin/env python3

import os
import sys
import subprocess
import datetime


def is_docker():
    # Método 1: Verificar a existência de .dockerenv
    if os.path.exists("/.dockerenv"):
        return True

    # Método 2: Verificar a presença de 'docker' nos arquivos cgroup
    try:
        with open("/proc/1/cgroup", "rt") as f:
            for line in f:
                if "docker" in line:
                    return True
    except FileNotFoundError:
        pass

    return False


def backup_name():
    current_date = datetime.datetime.now().strftime("%Y-%m-%d_%H%M%S")
    return f"tools-backup-{current_date}.tar.xz"


def make_backup(directory, filename, backup_dir="/backup"):
    out_path = os.path.join(backup_dir, filename)
    # Excluir diretórios comuns que não interessam no backup do workspace
    excludes = [
        "--exclude=.cache",
        "--exclude=__pycache__",
        "--exclude=.terraform",
        "--exclude=node_modules",
        "--exclude=.venv",
    ]
    command = [
        "tar",
        "cJvf",
        out_path,
        *excludes,
        "-C",
        directory,
        ".",
    ]

    try:
        subprocess.run(command, check=True)

        print(f"Backup criado com sucesso: {out_path}")
        return out_path

    except subprocess.CalledProcessError as e:
        print(f"Erro ao criar o backup: {e}", file=sys.stderr)
        sys.exit(e.returncode or 1)


def main():
    if not is_docker():
        print("Script deve ser executado apenas dentro do container!", file=sys.stderr)
        sys.exit(1)

    dir_to_backup = "/tools"
    backup_dir = "/backup"

    # Verifica destino
    if not os.path.isdir(backup_dir):
        print("Diretório /backup não encontrado. Monte um volume em /backup.", file=sys.stderr)
        sys.exit(1)

    filename = backup_name()
    make_backup(dir_to_backup, filename, backup_dir=backup_dir)


if __name__ == "__main__":
    main()
