#!/bin/bash

# Carrega as funções auxiliares do utils.sh
source /usr/local/bin/utils.sh

REPO="hashicorp/vault"
VERSION_PATTERN='(?<=/v)[0-9]+\.[0-9]+\.[0-9]+'

latest_version=$(get_latest_version "$REPO" "$VERSION_PATTERN")
latest_version="${latest_version#v}"

FILENAME="vault_${latest_version}_linux_amd64.zip"

DOWNLOAD_URL="https://releases.hashicorp.com/vault/${latest_version}/${FILENAME}"

# Baixa o arquivo
curl -LO $DOWNLOAD_URL || error_exit "Falha ao baixar o Vault"

# Extrai o arquivo
echo "Extraindo o arquivo ZIP..."
unzip -o "${FILENAME}" || error_exit "Falha ao descompactar o Vault."

# Instala o binário do Vault
install -o root -g root -m 0755 vault /usr/local/bin || error_exit "Falha ao instalar o Vault."

# Limpa os arquivos temporários
rm -f "${FILENAME}" vault LICENSE.txt || error_exit "Falha ao remover arquivos temporários."
echo "Vault ${latest_version} instalado com sucesso."
