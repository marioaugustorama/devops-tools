#!/bin/bash

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Define variáveis
REPO="derailed/k9s"
PACKAGE_NAME="k9s_linux_amd64.deb"

# Obtém a URL do último lançamento para o sistema Linux (arquitetura amd64)
echo "Obtendo a URL de download para o K9s..."
DOWNLOAD_URL=$(curl -s https://api.github.com/repos/${REPO}/releases/latest | \
    grep browser_download_url | grep linux_amd64.deb | cut -d '"' -f 4)

if [ -z "$DOWNLOAD_URL" ]; then
    error_exit "Não foi possível obter a URL de download do K9s."
fi

# Baixa o pacote .deb do K9s
echo "Baixando K9s..."
curl -sL "$DOWNLOAD_URL" -o "$PACKAGE_NAME" || error_exit "Falha ao baixar o K9s"

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

echo "Instalação do K9s concluída com sucesso."
