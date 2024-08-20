#!/bin/bash

# Define variáveis
AZ_CLI_INSTALL_URL="https://aka.ms/InstallAzureCLIDeb"
AZCOPY_DOWNLOAD_URL="https://aka.ms/downloadazcopy-v10-linux"
AZCOPY_TAR="downloadazcopy-v10-linux"
AZCOPY_BIN="/usr/local/bin/azcopy"

# Inclui o arquivo com as funções genéricas
source /usr/local/bin/utils.sh

# Instala o Azure CLI
echo "Instalando Azure CLI..."
curl -sL $AZ_CLI_INSTALL_URL | bash || error_exit "Falha ao instalar o Azure CLI"

# Baixa o AzCopy
echo "Baixando AzCopy..."
curl -LO $AZCOPY_DOWNLOAD_URL || error_exit "Falha ao baixar o AzCopy"

# Extrai o AzCopy e detecta o nome do diretório
echo "Extraindo AzCopy..."
tar -xzvf $AZCOPY_TAR || error_exit "Falha ao extrair o AzCopy"

# Obtém o nome do diretório extraído
AZCOPY_DIR=$(tar -tzf $AZCOPY_TAR | head -1 | cut -f1 -d"/")

# Verifica se o diretório foi encontrado
if [[ -z "$AZCOPY_DIR" ]]; then
    error_exit "Não foi possível encontrar o diretório extraído"
fi

# Instala o AzCopy
echo "Instalando AzCopy..."
install -o root -g root -m 0755 $AZCOPY_DIR/azcopy $AZCOPY_BIN || error_exit "Falha ao instalar o AzCopy"

# Limpeza
echo "Limpando arquivos temporários..."
rm -rf $AZCOPY_TAR $AZCOPY_DIR || error_exit "Falha ao limpar arquivos temporários"

echo "Instalação concluída com sucesso."
