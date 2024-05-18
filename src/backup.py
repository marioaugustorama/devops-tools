#!/usr/bin/env python3

import os
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
    current_date = datetime.datetime.now().strftime("%Y-%m-%d")
    return f"tools-backup-{current_date}.tar.xz"


def make_backup(directory, filename):
    command = ["tar", "cJvf", f"/backup/{filename}", "-C", directory, "."]

    try:
        subprocess.run(command, check=True)

        print(f"Backup criado com sucesso: {filename}")

    except subprocess.CalledProcessError as e:
        print(f"Erro ao criar o backup: {e}")


def main():
    if is_docker():
        dir_to_backup = "/tools"

        filename = backup_name()

        make_backup(dir_to_backup, filename)
    else:
        print("Script deve ser executado apenas dentro do container!")
        exit(1)


if __name__ == "__main__":
    main()
