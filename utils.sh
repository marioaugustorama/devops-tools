#!/bin/bash

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para obter a última versão de um repositório GitHub
get_latest_version() {
    local repo=$1
    local version_pattern=$2
    local release_url="https://api.github.com/repos/${repo}/releases/latest"

    # Obtém a página de lançamentos e extrai a versão mais recente
    local latest_version=$(curl -sL "$release_url" | grep -oP '"tag_name":\s*"\K[^\"]+')

    if [ -z "$latest_version" ]; then
        error_exit "Não foi possível determinar a última versão."
    fi

    echo "$latest_version"
}
