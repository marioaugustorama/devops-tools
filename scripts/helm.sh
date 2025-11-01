#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
REPO="helm/helm"
VERSION_PATTERN='(?<=/v)[0-9]+\.[0-9]+\.[0-9]+'
FILE_PREFIX="helm-"
FILE_SUFFIX="-linux-amd64.tar.gz"

# Obtém a última versão
latest_version=$(get_latest_version "$REPO" "$VERSION_PATTERN")

if [ $? -eq 0 ]; then
    # Define a URL de download usando a versão mais recente
    DOWNLOAD_URL="https://get.helm.sh/${FILE_PREFIX}${latest_version}${FILE_SUFFIX}"
    
    echo "Baixando Helm versão ${latest_version}..."
    
    # Baixa o arquivo
    curl -sLO "$DOWNLOAD_URL" || error_exit "Falha ao baixar o Helm"

    # Verifica se o arquivo foi baixado corretamente
    if [ ! -f "${FILE_PREFIX}${latest_version}${FILE_SUFFIX}" ]; then
        error_exit "O arquivo ${FILE_PREFIX}${latest_version}${FILE_SUFFIX} não foi encontrado."
    fi

    # Extrai o arquivo
    echo "Extraindo o arquivo TAR..."
    tar xzvf "${FILE_PREFIX}${latest_version}${FILE_SUFFIX}" || error_exit "Falha ao extrair o arquivo TAR"

    # Verifica se o binário foi extraído
    if [ ! -f "linux-amd64/helm" ]; then
        error_exit "O binário 'helm' não foi encontrado após a extração."
    fi

    # Instala o Helm
    echo "Instalando Helm..."
    install -o root -g root -m 0755 linux-amd64/helm /usr/local/bin/ || error_exit "Falha ao instalar o Helm"

    # Limpeza
    echo "Limpando arquivos temporários..."
    rm -rf "${FILE_PREFIX}${latest_version}${FILE_SUFFIX}" linux-amd64 || error_exit "Falha ao limpar arquivos temporários"

    echo "Instalação do Helm concluída com sucesso."
else
    echo "Erro ao obter a última versão."
fi
