#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
KUBEBOX_VERSION="${KUBEBOX_VERSION:-v0.10.0}"
BINARY_NAME="kubebox-linux"
INSTALL_PATH="/usr/local/bin/kubebox"
DOWNLOAD_URL="https://github.com/astefanutti/kubebox/releases/download/${KUBEBOX_VERSION}/${BINARY_NAME}"

# Baixa o binário do Kubebox
echo "Baixando Kubebox..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$BINARY_NAME" "$DOWNLOAD_URL" || error_exit "Falha ao baixar o Kubebox"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "$BINARY_NAME" ]; then
    error_exit "O binário $BINARY_NAME não foi encontrado."
fi

# Instala o Kubebox
echo "Instalando Kubebox..."
install -o root -g root -m 0755 "$BINARY_NAME" "$INSTALL_PATH" || error_exit "Falha ao instalar o Kubebox"

# Limpeza
echo "Limpando arquivos temporários..."
rm -f "$BINARY_NAME" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do Kubebox ${KUBEBOX_VERSION} concluída com sucesso."
