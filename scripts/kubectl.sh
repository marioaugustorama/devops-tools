#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define a URL base e o caminho de destino
KUBECTL_URL_BASE="https://dl.k8s.io/release"
KUBECTL_PATH="/usr/local/bin/kubectl"
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.34.1}"

# Define a URL completa para download
DOWNLOAD_URL="${KUBECTL_URL_BASE}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"

# Baixa o binário do kubectl
echo "Baixando kubectl versão ${KUBECTL_VERSION}..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o kubectl "$DOWNLOAD_URL" || error_exit "Falha ao baixar o kubectl"

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

echo "Instalação do kubectl ${KUBECTL_VERSION} concluída com sucesso."
