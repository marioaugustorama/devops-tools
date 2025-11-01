#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define a URL base e o caminho de destino
KUBECTL_URL_BASE="https://dl.k8s.io/release"
KUBECTL_PATH="/usr/local/bin/kubectl"

# Obtém a versão estável mais recente do kubectl
echo "Obtendo a versão estável mais recente do kubectl..."
LATEST_VERSION=$(curl -L -s https://dl.k8s.io/release/stable.txt)

if [ -z "$LATEST_VERSION" ]; then
    error_exit "Não foi possível obter a última versão estável do kubectl."
fi

# Define a URL completa para download
DOWNLOAD_URL="${KUBECTL_URL_BASE}/${LATEST_VERSION}/bin/linux/amd64/kubectl"

# Baixa o binário do kubectl
echo "Baixando kubectl versão ${LATEST_VERSION}..."
curl -sLO "$DOWNLOAD_URL" || error_exit "Falha ao baixar o kubectl"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "kubectl" ]; then
    error_exit "O binário kubectl não foi encontrado."
fi

# Instala o kubectl
echo "Instalando kubectl..."
install -o root -g root -m 0755 kubectl "$KUBECTL_PATH" || error_exit "Falha ao instalar o kubectl"

# Limpeza
echo "Limpando arquivos temporários..."
rm -f kubectl || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do kubectl concluída com sucesso."
