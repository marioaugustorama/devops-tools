#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define a URL base e o caminho de destino
KUBECTL_URL_BASE="https://dl.k8s.io/release"
KUBECTL_PATH="/usr/local/bin/kubectl"
KUBECTL_VERSION="${KUBECTL_VERSION:-v1.35.2}"

# Define a URL completa para download
DOWNLOAD_URL="${KUBECTL_URL_BASE}/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

# Baixa o binário do kubectl
echo "Baixando kubectl versão ${KUBECTL_VERSION}..."
cache_download "$DOWNLOAD_URL" "${TMP_DIR}/kubectl" "kubectl-${KUBECTL_VERSION}-linux-amd64"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "${TMP_DIR}/kubectl" ]; then
    error_exit "O binário kubectl não foi encontrado."
fi

# Instala o kubectl
echo "Instalando kubectl..."
install -o root -g root -m 0755 "${TMP_DIR}/kubectl" "$KUBECTL_PATH" || error_exit "Falha ao instalar o kubectl"

echo "Instalação do kubectl ${KUBECTL_VERSION} concluída com sucesso."
