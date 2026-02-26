#!/bin/bash
set -euo pipefail

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para obter a última versão de um repositório GitHub
get_latest_version() {
    local repo=$1
    local release_url="https://api.github.com/repos/${repo}/releases/latest"

    local latest_version
    latest_version=$(curl -fsSL --retry 5 --retry-all-errors --connect-timeout 10 "$release_url" | grep -oP '"tag_name":\s*"\K[^\"]+')

    if [ -z "${latest_version:-}" ]; then
        error_exit "Não foi possível determinar a última versão de ${repo}."
    fi

    echo "$latest_version"
}
