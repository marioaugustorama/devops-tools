#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Defina a versão e o arquivo para download
VERSION="${TERRAFORM_VERSION:-1.14.3}"
FILENAME="terraform_${VERSION}_linux_amd64.zip"
DOWNLOAD_URL="https://releases.hashicorp.com/terraform/${VERSION}/${FILENAME}"
BINARY_NAME="terraform"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Baixando Terraform versão ${VERSION}..."

# Baixa o arquivo
cache_download "$DOWNLOAD_URL" "${TMP_DIR}/${FILENAME}" "$FILENAME"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "${TMP_DIR}/${FILENAME}" ]; then
    error_exit "O arquivo $FILENAME não foi encontrado."
fi

# Extrai o arquivo
echo "Extraindo o arquivo ZIP..."
unzip -o "${TMP_DIR}/${FILENAME}" -d "$TMP_DIR" || error_exit "Falha ao extrair o arquivo ZIP"

# Verifica se o binário foi extraído
if [ ! -f "${TMP_DIR}/${BINARY_NAME}" ]; then
    error_exit "O binário '$BINARY_NAME' não foi encontrado após a extração."
fi

# Instala o Terraform
echo "Instalando Terraform..."
install -o root -g root -m 0755 "${TMP_DIR}/${BINARY_NAME}" /usr/local/bin/ || error_exit "Falha ao instalar o Terraform"

echo "Instalação do Terraform concluída com sucesso."
