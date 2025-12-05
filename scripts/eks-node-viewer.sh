#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

REPO="awslabs/eks-node-viewer"
INSTALL_PATH="/usr/local/bin/eks-node-viewer"
TMP_FILE="eks-node-viewer"

echo "Obtendo a URL de download para o EKS Node Viewer..."
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/${REPO}/releases/latest | \
  jq -r '.assets[] | select(.name | test("Linux_x86_64$")) | .browser_download_url' | head -n1)

if [ -z "$DOWNLOAD_URL" ] || [ "$DOWNLOAD_URL" = "null" ]; then
    error_exit "Não foi possível obter a URL de download do EKS Node Viewer."
fi

echo "Baixando EKS Node Viewer..."
curl -fLs "$DOWNLOAD_URL" -o "$TMP_FILE" || error_exit "Falha ao baixar o EKS Node Viewer"

if [ ! -f "$TMP_FILE" ]; then
    error_exit "O binário $TMP_FILE não foi encontrado."
fi

echo "Instalando EKS Node Viewer..."
install -o root -g root -m 0755 "$TMP_FILE" "$INSTALL_PATH" || error_exit "Falha ao instalar o EKS Node Viewer"

echo "Limpando arquivos temporários..."
rm -f "$TMP_FILE" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do EKS Node Viewer concluída com sucesso."
