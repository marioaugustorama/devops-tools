#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

TOFU_VERSION="${TOFU_VERSION:-1.11.1}"
FILENAME="tofu_${TOFU_VERSION}_linux_amd64.zip"
DOWNLOAD_URL="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/${FILENAME}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

echo "Baixando OpenTofu ${TOFU_VERSION}..."
cache_download "$DOWNLOAD_URL" "${TMP_DIR}/${FILENAME}" "$FILENAME"

echo "Extraindo OpenTofu..."
unzip -o "${TMP_DIR}/${FILENAME}" tofu -d "$TMP_DIR" || error_exit "Falha ao extrair OpenTofu"

echo "Instalando OpenTofu..."
install -o root -g root -m 0755 "${TMP_DIR}/tofu" /usr/local/bin/tofu || error_exit "Falha ao instalar tofu"
ln -sf /usr/local/bin/tofu /usr/local/bin/opentofu || error_exit "Falha ao criar symlink opentofu"

echo "Instalação do OpenTofu ${TOFU_VERSION} concluída com sucesso."
