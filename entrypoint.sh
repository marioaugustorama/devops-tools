#!/bin/bash

# Define o UID e GID do usuário corrente
USER_ID=$(id -u)
GROUP_ID=$(id -g)


# Trocar para o usuário devops se não estiver rodando como root
if [ "$(id -u)" -eq 0 ]; then
    exec su devops "$0 $@"
    exit
fi

# Cria o diretório home se não existir e define as permissões corretas
if [ ! -d "/tools" ]; then
    mkdir -p /tools
    chown $USER_ID:$GROUP_ID /tools
fi

# Se houver argumentos, execute-os como um comando
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    exec bash
fi
