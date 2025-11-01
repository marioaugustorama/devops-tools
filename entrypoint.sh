#!/bin/bash

set -euo pipefail

# Define o UID e GID do usuário corrente
USER_ID=$(id -u)
GROUP_ID=$(id -g)

# Cria o diretório home se não existir e define as permissões corretas
if [ ! -d "/tools" ]; then
    mkdir -p /tools
    # Quando o container já roda como devops, o chown pode falhar; ignore nesse caso
    chown "$USER_ID:$GROUP_ID" /tools 2>/dev/null || true
fi

# Se houver argumentos, execute-os como um comando
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    exec bash
fi
