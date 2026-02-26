#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

TOFU_VERSION="${TOFU_VERSION:-1.11.1}"
FILENAME="tofu_${TOFU_VERSION}_linux_amd64.zip"
DOWNLOAD_URL="https://github.com/opentofu/opentofu/releases/download/v${TOFU_VERSION}/${FILENAME}"

echo "Baixando OpenTofu ${TOFU_VERSION}..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$FILENAME" "$DOWNLOAD_URL" || error_exit "Falha ao baixar OpenTofu"

echo "Extraindo OpenTofu..."
unzip -o "$FILENAME" tofu || error_exit "Falha ao extrair OpenTofu"

echo "Instalando OpenTofu..."
install -o root -g root -m 0755 tofu /usr/local/bin/tofu || error_exit "Falha ao instalar tofu"
ln -sf /usr/local/bin/tofu /usr/local/bin/opentofu || error_exit "Falha ao criar symlink opentofu"

echo "Limpando arquivos temporários..."
rm -f "$FILENAME" tofu

echo "Instalação do OpenTofu ${TOFU_VERSION} concluída com sucesso."
