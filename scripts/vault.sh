#!/bin/bash
set -euo pipefail

# Carrega as funções auxiliares do utils.sh
source /usr/local/bin/utils.sh

VERSION="${VAULT_VERSION:-1.21.1}"

FILENAME="vault_${VERSION}_linux_amd64.zip"

DOWNLOAD_URL="https://releases.hashicorp.com/vault/${VERSION}/${FILENAME}"

# Baixa o arquivo
curl -fL --retry 5 --retry-all-errors --connect-timeout 10 -o "$FILENAME" "$DOWNLOAD_URL" || error_exit "Falha ao baixar o Vault"

# Extrai o arquivo
echo "Extraindo o arquivo ZIP..."
unzip -o "${FILENAME}" || error_exit "Falha ao descompactar o Vault."

# Instala o binário do Vault
install -o root -g root -m 0755 vault /usr/local/bin || error_exit "Falha ao instalar o Vault."

# Limpa os arquivos temporários
rm -f "${FILENAME}" vault LICENSE.txt || error_exit "Falha ao remover arquivos temporários."
echo "Vault ${VERSION} instalado com sucesso."
