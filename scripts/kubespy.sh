#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
REPO="pulumi/kubespy"
VERSION_PATTERN='(?<=/v)[0-9]+\.[0-9]+\.[0-9]+'

FILE_PREFIX="kubespy-"
FILE_SUFFIX="-linux-amd64.tar.gz"
TAR_FILENAME=""
BINARY_NAME="kubespy"

# Obtém a última versão do Kubespy
latest_version=$(get_latest_version "$REPO" "$VERSION_PATTERN")

if [ $? -eq 0 ]; then
    # Define a URL de download usando a versão mais recente
    DOWNLOAD_URL="https://github.com/${REPO}/releases/download/${latest_version}/${FILE_PREFIX}${latest_version}${FILE_SUFFIX}"
    TAR_FILENAME="${FILE_PREFIX}${latest_version}${FILE_SUFFIX}"

    echo "Baixando Kubespy versão ${latest_version}..."

    # Baixa o arquivo
    curl -sLO "$DOWNLOAD_URL" || error_exit "Falha ao baixar o Kubespy"

    # Verifica se o arquivo foi baixado corretamente
    if [ ! -f "$TAR_FILENAME" ]; then
        error_exit "O arquivo $TAR_FILENAME não foi encontrado."
    fi

    # Extrai o arquivo
    echo "Extraindo o arquivo TAR..."
    tar xzvf "$TAR_FILENAME" || error_exit "Falha ao extrair o arquivo TAR"

    # Verifica se o binário foi extraído
    if [ ! -f "$BINARY_NAME" ]; then
        error_exit "O binário '$BINARY_NAME' não foi encontrado após a extração."
    fi

    # Instala o Kubespy
    echo "Instalando Kubespy..."
    install -o root -g root -m 0755 "$BINARY_NAME" /usr/local/bin/ || error_exit "Falha ao instalar o Kubespy"

    # Limpeza
    echo "Limpando arquivos temporários..."
    rm -rf "$TAR_FILENAME" "$BINARY_NAME" LICENSE || error_exit "Falha ao limpar arquivos temporários"

    echo "Instalação do Kubespy concluída com sucesso."
else
    echo "Erro ao obter a última versão."
fi
