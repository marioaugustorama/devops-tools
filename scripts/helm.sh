#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
HELM_VERSION="${HELM_VERSION:-v3.19.2}"
FILE_PREFIX="helm-"
FILE_SUFFIX="-linux-amd64.tar.gz"
FILE_NAME="${FILE_PREFIX}${HELM_VERSION}${FILE_SUFFIX}"
DOWNLOAD_URL="https://get.helm.sh/${FILE_NAME}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Baixando Helm versão ${HELM_VERSION}..."
cache_download "$DOWNLOAD_URL" "${TMP_DIR}/${FILE_NAME}" "$FILE_NAME"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "${TMP_DIR}/${FILE_NAME}" ]; then
    error_exit "O arquivo $FILE_NAME não foi encontrado."
fi

# Extrai o arquivo
echo "Extraindo o arquivo TAR..."
tar xzf "${TMP_DIR}/${FILE_NAME}" -C "$TMP_DIR" || error_exit "Falha ao extrair o arquivo TAR"

# Verifica se o binário foi extraído
if [ ! -f "${TMP_DIR}/linux-amd64/helm" ]; then
    error_exit "O binário 'helm' não foi encontrado após a extração."
fi

# Instala o Helm
echo "Instalando Helm..."
install -o root -g root -m 0755 "${TMP_DIR}/linux-amd64/helm" /usr/local/bin/ || error_exit "Falha ao instalar o Helm"

echo "Instalação do Helm ${HELM_VERSION} concluída com sucesso."
