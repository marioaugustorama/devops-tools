#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
REPO="awslabs/eks-node-viewer"
BINARY_NAME="kubebox-linux"
INSTALL_PATH="/usr/local/bin/eks-node-viewer"

# Obtém a URL do último lançamento para o sistema Linux
echo "Obtendo a URL de download para o EKS Node Viewer..."
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/${REPO}/releases/latest | \
    grep browser_download_url | grep linux | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    error_exit "Não foi possível obter a URL de download do EKS Node Viewer."
fi

# Baixa o binário do EKS Node Viewer
echo "Baixando EKS Node Viewer..."
curl -sL "$DOWNLOAD_URL" -o "$BINARY_NAME" || error_exit "Falha ao baixar o EKS Node Viewer"

# Verifica se o arquivo foi baixado corretamente
if [ ! -f "$BINARY_NAME" ]; then
    error_exit "O binário $BINARY_NAME não foi encontrado."
fi

# Instala o EKS Node Viewer
echo "Instalando EKS Node Viewer..."
install -o root -g root -m 0755 "$BINARY_NAME" "$INSTALL_PATH" || error_exit "Falha ao instalar o EKS Node Viewer"

# Limpeza
echo "Limpando arquivos temporários..."
rm -f "$BINARY_NAME" || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação do EKS Node Viewer concluída com sucesso."
