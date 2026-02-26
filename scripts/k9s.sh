#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
K9S_VERSION="${K9S_VERSION:-v0.50.16}"
PACKAGE_NAME="k9s_linux_amd64.deb"
DOWNLOAD_URL="https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/${PACKAGE_NAME}"

# Baixa o pacote .deb do K9s
echo "Baixando K9s..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$PACKAGE_NAME" "$DOWNLOAD_URL" || error_exit "Falha ao baixar o K9s"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "$PACKAGE_NAME" ]; then
    error_exit "O pacote $PACKAGE_NAME não foi encontrado."
fi

# Instala o K9s
echo "Instalando K9s..."
dpkg -i "$PACKAGE_NAME" || error_exit "Falha ao instalar o K9s"

# Limpeza
echo "Limpando arquivos temporários..."
rm -f "$PACKAGE_NAME" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do K9s ${K9S_VERSION} concluída com sucesso."
