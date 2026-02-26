#!/bin/bash
set -euo pipefail

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

EKS_NODE_VIEWER_VERSION="${EKS_NODE_VIEWER_VERSION:-v0.7.4}"
INSTALL_PATH="/usr/local/bin/eks-node-viewer"
TMP_FILE="eks-node-viewer"
DOWNLOAD_URL="https://github.com/awslabs/eks-node-viewer/releases/download/${EKS_NODE_VIEWER_VERSION}/eks-node-viewer_Linux_x86_64"

echo "Baixando EKS Node Viewer..."
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$TMP_FILE" "$DOWNLOAD_URL" || error_exit "Falha ao baixar o EKS Node Viewer"

if [ ! -f "$TMP_FILE" ]; then
    error_exit "O binário $TMP_FILE não foi encontrado."
fi

echo "Instalando EKS Node Viewer..."
install -o root -g root -m 0755 "$TMP_FILE" "$INSTALL_PATH" || error_exit "Falha ao instalar o EKS Node Viewer"

echo "Limpando arquivos temporários..."
rm -f "$TMP_FILE" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do EKS Node Viewer ${EKS_NODE_VIEWER_VERSION} concluída com sucesso."
