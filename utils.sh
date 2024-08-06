#!/bin/bash

# Função para exibir mensagens de erro e sair
error_exit() {
    echo "Erro: $1" >&2
    exit 1
}

# Função para verificar se está rodando em um container
check_if_in_container() {
    if [ -f "/.dockerenv" ] || grep -q -E '/(lxc|docker|kubepods|containerd)/' /proc/1/cgroup; then
        echo "Executando em um container."
    else
        error_exit "Este script só pode ser executado em um container."
    fi
}

# Função para obter a última versão de um repositório GitHub
get_latest_version() {
    local repo=$1
    local version_pattern=$2
    local release_url="https://github.com/${repo}/releases"
    
    echo "Buscando a última versão de ${repo} em ${release_url}..."

    # Obtém a página de lançamentos e extrai a versão mais recente
    local latest_version=$(curl -sL "$release_url" | \
        grep -oP "$version_pattern" | \
        sort -V | \
        tail -n1)
    
    if [ -z "$latest_version" ]; then
        error_exit "Não foi possível determinar a última versão."
    fi

    echo "Última versão encontrada: $latest_version"
    echo "$latest_version"
}
